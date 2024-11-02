-- main module file
-- NeoVim specifics NOT pure lua
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
-- of pure lua functions
-- short forms for terse code coding, as contain many fields
local dd = require("doris.module")
-- async futures/promises
local as = require("plenary.async.async")
local uv = require("plenary.async.uv_async")
local ch = require("plenary.async.control")
-- class object with mixins via implements list
-- not dynamic mixin binding
local cl = require("plenary.class")
-- job control class
local jo = require("plenary.job")
-- context manager
local cm = require("plenary.context_manager")

-- short forms
local f = vim.fn
local a = vim.api

---unicode num cast
---@param c string
---@return integer
_G.num = function(c)
  return f.char2nr(c, true)
end
---unicode char cast
---@param n integer
---@return string
_G.chr = function(n)
  return f.nr2char(n, true)
end

---blank callback no operation
local nop = function() end

---@class DorisModule
local M = {}

-- function import and pass export
-- from doris module
-- only pure functions not needing vim calls
---@type DorisPureModule
M.dd = dd
---nice global
---@type fun(is: any): SwitchStatement
_G.switch = dd.switch
---@type fun(over: integer): ModuloStatement
_G.modulo = dd.modulo
---@type fun(len: integer): (fun(iterState: integer, lastIter: integer): integer), integer, integer
_G.range = dd.range
---@type fun():nil
_G.nop = nop
-- then from plenary modules
-- promises/futures async
---@type Object
M.as = as
-- file ops
---@type Object
M.uv = uv
-- control channels
---@type Object
M.ch = ch
-- classes
---@type Object
M.cl = cl
_G.extends = cl.extend
_G.implements = cl.implement
-- job control class
---@type Job
M.jo = jo
-- context manager (like python file on each etc.)
---@type Object
M.cm = cm

---@class Config
---@field doris table?
---@field popup table?
local config = {
  doris = {},
  popup = {
    pos = "center",
    border = true,
    width = 80,
    height = 24,
  },
}

-- default config export
---@type Config
M.config = config

---@param args Config?
---@return DorisModule
-- you can define your setup function here. Usually configurations can be
-- merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  -- convenience chain
  return M
end

-- impure commands (impure by virtue of command in plugin/doris.lua)
---@return table
M.doris = function()
  return M.config.doris
end

-- impure function collection
-- notify defaults
-- notify status message
---@param msg string
M.notify = function(msg)
  -- can't short name as used for title
  vim.notify(msg, vim.log.INFO, nil)
end

-- supply table of lines and opts
local popup = require("plenary.popup").create

---@param inkey fun(key: string, player: any):nil
---@param process fun():nil
---@param reset fun():nil
-- a gaming character canvas
-- using a forward defined local to store the popup function table
-- allows inkey and process to closure on control functions
---@return table
M.popup = function(inkey, process, reset)
  local what = {}
  for _ in range(24) do
    local l = {}
    for _ in range(80) do
      table.insert(l, " ")
    end
    table.insert(what, l)
  end
  local function join()
    local j = {}
    for i in range(24) do
      table.insert(j, table.concat(what[i], ""))
    end
    return j
  end
  local disp = join()
  local win, xtra = popup(disp, M.config.popup)
  local client = false
  local server
  xtra.insert = function(x, y, c)
    if x < 1 or x > 80 or y < 1 or y > 24 then
      return
    end
    -- trim utf8
    local u = string.match(c, "[%z\1-\127\194-\244][\128-\191]*")
    what[y][x] = u
  end
  xtra.at = function(x, y)
    return what[y][x]
  end
  local ghost = a.nvim_win_get_cursor(win)
  xtra.poke = function(x, y)
    if x < 1 or x > 80 or y < 1 or y > 24 then
      return true -- if err?
    end
    ghost[1], ghost[2] = y, x - 1
    return false
  end
  xtra.peek = function()
    return ghost[2] + 1, ghost[1]
  end
  -- client session socket
  local session = vim.uv.new_tcp()
  -- keys for sending
  local keybuf = {}
  xtra.connect = function()
    -- make connection to server
    local ip = f.input({ prompt = "Server IP Address" })
    session:nodelay(true)
    session:connect(ip, 287, function(err)
      if err then
        M.notify(err)
        return
      end
      client = true
      -- send connect header
      session:write(chr(27))
      local chunky = ""
      local raster = {}
      local blank = true
      session:read_start(function(err2, chunk)
        if err2 then
          M.notify(err2)
          client = false
          return
        end
        -- accumulate a long enough
        if chunk then
          chunky = chunky .. chunk
        else
          client = false
          session:shutdown()
          session:close()
        end
        -- check processing
        if #chunky > 1 and blank then
          if xtra.poke(num(chunky[1]), num(chunky[2])) then
            -- ghost protocol
            return
          end
          blank = false
          chunky = string.sub(chunky, 2)
        end
        if #chunky > 1 then
          -- get len of line
          local l = num(chunky)
          if #chunky < l + 2 then
            return
          else
            raster[#raster + 1] = string.sub(chunky, 3, l + 2)
            chunky = string.sub(chunky, l + 3)
            if #raster == 24 then
              disp = raster
              raster = {}
            end
          end
        end
      end)
    end)
  end
  local buf = a.nvim_win_get_buf(win)
  -- add new key definitions for buffer
  local keys = "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_"
  local function nmap(key, code)
    vim.keymap.set("n", key, function()
      if client then
        table.insert(keybuf, code)
      else
        inkey(key, server)
      end
    end, { buffer = buf })
  end
  local function umap(key)
    vim.keymap.del("n", key, { buffer = buf })
  end
  local function off(key, y)
    return chr(num(key) + y)
  end
  for x in range(#keys) do
    local y = keys[x]
    local c = num(y)
    nmap(y, c)
    nmap("<C-" .. y .. ">", c - 64)
    if y == "_" then
      -- delete is special, very special
      nmap("<del>", c)
    else
      nmap(off(y, 32), c + 32)
    end
    nmap(off(y, -32), c - 32)
  end
  -- specials
  -- a close callback for clean up
  local run = false
  local function close()
    -- close run
    run = false
    a.nvim_win_close(win, true)
    -- remove keymap from buffer
    umap("<esc>")
    for x in range(#keys) do
      local y = keys[x]
      umap(y)
      umap("<C-" .. y .. ">")
      if y == "_" then
        -- delete is special, very special
        umap("<del>")
      else
        umap(off(y, 32))
      end
      umap(off(y, -32))
    end
    a.nvim_buf_delete(buf, { force = true })
    -- stop TCP server
    server:close()
  end
  vim.keymap.set("n", "<esc>", close, {
    buffer = buf,
  })
  -- no key now to insert ("i" key remapped)
  a.nvim_command("stopinsert")
  -- must follow this for to be defined for "recursive call"
  -- 10 fps
  -- perform all reset intialization
  reset()
  local function show()
    if not client then
      -- perform service
      disp = join()
    else
      -- append display request
      table.insert(keybuf, chr(27))
      session:write(keybuf)
      -- new round of keys
      keybuf = {}
    end
    a.nvim_buf_set_lines(buf, 0, -1, false, disp)
    a.nvim_win_set_cursor(win, ghost)
  end
  local function do_proces()
    if not run then
      return
    end
    -- reschedule and wrapped for IO (closer timing)
    -- stack nest over?
    vim.defer_fn(do_proces, 100)
    -- should never do after end of run
    -- as no window or buffer
    show()
    -- process next frame based on key events
    process()
  end
  xtra.play_pause = function()
    if run then
      run = false
    else
      run = true
      -- play setup time
      vim.defer_fn(do_proces, 1000)
    end
  end
  local socks = {}
  local function create_server(host, port, on_connect)
    server = vim.uv.new_tcp()
    server:bind(host, port)
    server:listen(128, function(err)
      if err then
        M.notify(err)
        return
      end -- Check for errors.
      local sock = vim.uv.new_tcp()
      -- don't group writes
      sock:nodelay(true)
      socks[sock] = true
      server:accept(sock) -- Accept client connection.
      on_connect(sock) -- Start reading messages.
    end)
  end
  -- port 287 use <esc> as 1st byte (invalid protocol version number)
  -- I decided the version 27 will be an invalid version
  create_server("0.0.0.0", 287, function(sock)
    sock:read_start(function(err, chunk)
      if err then
        M.notify(err)
        return
      end -- Check for errors.
      if chunk then
        -- add traffic stripped of <esc>
        if socks[sock] then
          if num(string.sub(chunk, 1, 1)) == 27 then
            -- strip <esc>
            chunk = string.sub(chunk, 2)
            -- got header 27
            socks[sock] = false
          else
            -- bad protocol (reserved for unrelated purposes IANA)
            sock:shutdown()
            sock:close()
          end
        end
        for i in range(#chunk) do
          local c = chunk[i]
          local n = num(c)
          if n == 27 then
            -- requested show and no shutdown
            local x, y = xtra.peek()
            local d = {}
            for k, v in ipairs(disp) do
              local c2 = string.sub(chr(#v) .. " ", 1, 2)
              d[k] = c2 .. v
            end
            -- multiplayer 3
            sock:write({ chr(x), chr(y), unpack(d) })
          elseif n >= 0 and n < 32 then
            inkey("<C-" .. c .. ">", sock)
          elseif n < 127 then
            inkey(c, sock)
          elseif n == 127 then
            inkey("<del>", sock)
          else
            -- MSB protocol (extension of protocol)
          end
        end
      else -- EOF (stream closed).
        sock:shutdown()
        sock:close() -- Always close handles to avoid leaks.
      end
    end)
  end)
  -- start
  xtra.play_pause()
  return xtra
end

-- test the popup by showing notify of key events recieved
---@type fun():nil
M.test_popup = function()
  M.popup(function(key)
    M.notify(key)
  end, nop, nop)
end

return M
