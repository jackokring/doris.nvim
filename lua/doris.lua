-- main module file
-- NeoVim specifics NOT pure lua
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
-- of pure lua functions
-- short forms for terse code coding, as contain many fields
require("doris.module")
-- and why not? it's in LazyVim anyhow
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
---via vimscript commands
_G.fn = vim.fn
---looks more C like
_G.ap = vim.api
local co = coroutine
---unicode num cast
---@param c string
---@return integer
_G.num = function(c)
  return fn.char2nr(c, true)
end
---unicode char cast
---@param n integer
---@return string
_G.chr = function(n)
  return fn.nr2char(n, true)
end
---blank callback no operation
local nop = function() end

---@class DorisModule
local M = {}

-- function import and pass export
-- from doris module
-- only pure functions not needing vim calls
---@type fun():nil
_G.nop = nop
---wrap a yielding function as an iterator
_G.wrap = co.wrap
---coroutine yeild within a function
_G.yield = co.yield
---make a producer which can send and even receive, from an anonymous function
-- then from plenary modules
-- promises/futures async
-- imports async/await into _G
---@type Object
M.as = as
-- file ops
---@type Object
M.uv = uv
-- control channels
---@type Object
M.ch = ch
-- classes
_G.extends = cl.extend
_G.implements = cl.implement
_G.new = cl.new
_G.is = cl.is
-- job control class
---@type Job
M.jo = jo
-- context manager (like python file on each etc.)
---@type Object
M.cm = cm

---@alias Socket uv_tcp_t

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

---@param inkey fun(key: string, player: Socket):nil
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
      insert(l, " ")
    end
    insert(what, l)
  end
  ---join raster
  ---@return string[]
  local function join()
    local j = {}
    for i in range(24) do
      insert(j, concat(what[i], ""))
    end
    return j
  end
  local disp = join()
  local ns = ap.nvim_create_namespace("")
  local hl = function(name, fg, bg, bold, italic, underline)
    ap.nvim_set_hl(ns, name, {
      fg = fg,
      bg = bg,
      bold = bold,
      italic = italic,
      underline = underline,
    })
  end
  -- highlight kinds named index
  hl("name", "red", "green", true, false, false) -- a config
  local win, xtra = popup(disp, M.config.popup)
  local buf = ap.nvim_win_get_buf(win)
  -- an anon namespace for highlights
  -- and that means byte columns
  local c2b = function(x, y)
    return fn.virtcol2col(win, y, x)
  end
  xtra.highlight = function(x, y, name)
    local byte = c2b(x, y)
    -- span of 1 character
    ap.nvim_buf_add_highlight(buf, ns, name, y, byte, byte)
  end
  local client = false
  local server
  ---place character
  ---@param x integer
  ---@param y integer
  ---@param c string
  xtra.insert = function(x, y, c)
    if x < 1 or x > 80 or y < 1 or y > 24 then
      return
    end
    -- trim utf8
    local u = match(c, utfp)
    what[y][x] = u
  end
  ---character placed at location
  ---@param x integer
  ---@param y integer
  ---@return string
  xtra.at = function(x, y)
    return what[y][x]
  end
  local ghostx, ghosty
  local _, yf, xf = unpack(fn.getcursorcharpos())
  ---place cursor ghost (returns true if off screen)
  ---@param x integer
  ---@param y integer
  ---@return boolean
  xtra.poke = function(x, y)
    if x < 1 or x > 80 or y < 1 or y > 24 then
      return true -- if err?
    end
    ghostx, ghosty = x, y
    return false
  end
  xtra.poke(xf, yf)
  ---get cursor location x, y
  ---@return integer
  ---@return integer
  xtra.peek = function()
    return ghostx, ghosty
  end
  -- client session socket
  local session = vim.uv.new_tcp()
  -- keys for sending
  local keybuf = {}
  ---open client connection to a server
  xtra.connect = function()
    -- make connection to server
    local ip = fn.input({ prompt = "Server IP Address" })
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
            -- the location was off screen so open to protocol extension
            return
          end
          blank = false
          chunky = sub(chunky, 2)
        end
        if #chunky > 1 then
          -- get len of line
          local l = num(chunky)
          if #chunky < l + 2 then
            return
          else
            -- a UTF-8 length may have a space postfix or be over 80*4
            raster[#raster + 1] = sub(chunky, 3, l + 2)
            chunky = sub(chunky, l + 3)
            if #raster == 24 then
              disp = raster
              raster = {}
            end
          end
        end
      end)
    end)
  end
  -- add new key definitions for buffer
  local keys = "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
  ---map a normal mode key
  ---@param key string
  ---@param code integer
  local function nmap(key, code)
    vim.keymap.set("n", key, function()
      if client then
        insert(keybuf, code)
      else
        inkey(key, server)
      end
    end, { buffer = buf })
  end
  ---unmap a normal mode key
  ---@param key string
  local function umap(key)
    vim.keymap.del("n", key, { buffer = buf })
  end
  ---calculate an offset ASCII character
  ---@param key string
  ---@param y integer
  ---@return string
  local function off(key, y)
    return chr(num(key) + y)
  end
  -- direct all key binds to inkey process functions
  -- no alt combinations are considered
  -- partially how I've set up dwm
  -- partially as "<esc><...>" has processing delays
  -- just don't touch the alt key ...
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
  ---close the server and window for "<esc>"
  local function close()
    -- close run
    run = false
    ap.nvim_win_close(win, true)
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
    ap.nvim_buf_delete(buf, { force = true })
    -- stop TCP server
    server:close()
  end
  -- add in game exit
  vim.keymap.set("n", "<esc>", close, {
    buffer = buf,
  })
  -- no key now to insert ("i" key remapped)
  ap.nvim_command("stopinsert")
  -- 10 fps
  -- perform all reset intialization
  reset()
  ---perform raster display dependant on client/server status
  local function show()
    if not client then
      -- perform service
      disp = join()
    else
      -- append display request
      insert(keybuf, chr(27))
      session:write(keybuf)
      -- new round of keys
      keybuf = {}
    end
    ap.nvim_buf_set_lines(buf, 0, -1, false, disp)
    -- set cursor "ghost"
    local x, y = xtra.peek()
    fn.setcursorcharpos(y, x)
  end
  ---the main event loop for draw/process
  local function do_proces()
    -- avaid buffer access on potential close event
    if not run then
      return
    end
    -- reschedule and wrapped for IO (closer timing)
    -- stack nest over?
    -- I assume longer delays are possible (event not interrupt based)
    vim.defer_fn(do_proces, 100)
    -- should never do after end of run
    -- as no window or buffer
    show()
    -- process next frame based on key events
    process()
  end
  ---invert the game runnig state with a restart delay
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
  ---create game server
  ---@param host string IP address
  ---@param port integer
  ---@param on_connect fun(sock: Socket): nil
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
          if num(sub(chunk, 1, 1)) == 27 then
            -- strip <esc> protocol start
            chunk = sub(chunk, 2)
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
            -- requested show dispay data
            local x, y = xtra.peek()
            local d = {}
            for k, v in ipairs(disp) do
              -- mark length of raster line
              local c2 = sub(chr(#v) .. " ", 1, 2)
              d[k] = c2 .. v
            end
            -- multiplayer 3 send raster packet
            sock:write({ chr(x), chr(y), unpack(d) })
          elseif n >= 0 and n < 32 then
            -- process key events from client
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
  -- start game default
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
