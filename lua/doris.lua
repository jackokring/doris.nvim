-- main module file
-- NeoVim specifics NOT pure lua
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
-- of pure lua functions
-- short forms for terse code coding, as contain many fields
local novaride = require("doris.novaride").setup()
require("doris.module")
require("doris.async")
require("doris.object")
require("doris.bus")
require("doris.audio")
-- and why not? it's in LazyVim anyhow
local uv = require("plenary.async.uv_async")
-- job control class
local jo = require("plenary.job")

-- short forms
---via vimscript commands
_G.fn = vim.fn
---looks more C like
_G.ap = vim.api

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

---@class DorisModule
local M = {}

-- file ops vim specific uv embedded
---@type Object
_G.uv = uv
-- job control class vim specific
---@type Job
_G.job = jo

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

-- impure function collection
-- notify defaults
-- notify status message
---@param msg string
M.notify = function(msg)
  -- can't short name as used for title
  vim.notify(msg, vim.log.levels.ERROR)
end

-- supply table of lines and opts
local popup = require("plenary.popup").create

---@param inkey fun(key: integer, player: Socket):nil
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
      insert(j, concat(what[i]))
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
    local u = match(c, utfpat)
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
    local ip = vim.ui.input({ prompt = "Server IP Address" })
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
          if xtra.poke(num(at(chunky, 1)), num(at(chunky, 2))) then
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
            blank = true -- do ghost again
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
        inkey(code, server)
      end
    end, { buffer = buf })
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
    local y = at(keys, x)
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
  local curs = { "left", "right", "up", "down", "pgup", "pgdn", "home", "end", "ins" }
  -- some strange key intercepts
  local vi = "hlkjafds\\"
  for x in range(#vi) do
    local y = at(vi, x)
    local c = num(y)
    nmap("<" .. curs[x] .. ">", c)
    nmap("<C-" .. curs[x] .. ">", c - 96)
    nmap("<S-" .. curs[x] .. ">", c - 32)
  end
  -- specials
  -- a close callback for clean up
  local run = false
  local socks = {}
  -- weak references on close socket
  local weak = {}
  weak.__mode = "k"
  setmetatable(socks, weak)
  local uvdo = true
  ---close the server and window for "<esc>"
  local function close()
    -- close run
    run = false
    ap.nvim_win_close(win, true)
    -- stop TCP server
    server:close()
    -- terminate all client sockets
    for k, _ in pairs(socks) do
      k:shutdown()
      k:close()
    end
    -- close client
    if client then
      session:shutdown()
      session:close()
    end
    uvdo = false
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
          if num(at(chunk, 1)) == 27 then
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
          local c = at(chunk, i)
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
          elseif n < 128 then
            inkey(n, sock)
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
  local function uvrun()
    vim.uv.run("nowait")
    -- closed streams
    if uvdo then
      vim.defer_fn(uvrun, 10)
    end
  end
  -- start game default
  xtra.play_pause()
  -- networking
  uvrun()
  return xtra
end

-- test the popup by showing notify of key events recieved
---@type fun():nil
M.test_popup = function()
  M.popup(function(key)
    if key < 32 then
      M.notify("<C-" .. chr(key + 64) .. ">")
    else
      M.notify(chr(key))
    end
  end, nop, nop)
end

-- impure commands (impure by virtue of command in plugin/doris.lua)
---@return table
M.doris = function()
  return M.config.doris
end

-- clean up
novaride.restore()
return M
