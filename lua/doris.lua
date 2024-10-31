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
-- iterators
local it = require("plenary.iterators")
-- class object with mixins via implements list
-- not dynamic mixin binding
local cl = require("plenary.class")
-- enums e { "x", ... }
local en = require("plenary.enum")
-- job control class
local jo = require("plenary.job")
-- context manager
local cm = require("plenary.context_manager")

-- short forms
local f = vim.fn
local a = vim.api

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

---@class DorisModule
local M = {}

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
M.notify = function(msg)
  -- can't short name as used for title
  vim.notify(msg, vim.log.INFO, nil)
end

-- supply table of lines and opts
local popup = require("plenary.popup").create

local np = function() end

---@param what table
---@param inkey function(string)
---@param process function
---@param reset function
-- table of details and callbacks
---@return table
M.popup = function(what, inkey, process, reset)
  local win, xtra = popup(what, M.config.popup)
  xtra.what = what
  local buf = a.nvim_win_get_buf(win)
  -- add new key definitions for buffer
  local keys = "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_"
  local function nmap(key)
    vim.keymap.set("n", key, function()
      inkey(key)
    end, { buffer = buf })
  end
  local function off(key, y)
    return f.nr2char(f.char2nr(key, true) + y, true)
  end
  for x = 1, #keys, 1 do
    local y = keys[x]
    nmap(y)
    nmap("<C-" .. y .. ">")
    nmap(off(y, 32))
    nmap(off(y, -32))
  end
  -- specials
  vim.keymap.set("n", "<esc>", xtra.close, {
    buffer = buf,
  })
  -- must follow this for to be defined for "recursive call"
  -- 10 fps
  xtra.run = true
  reset()
  local function do_proces()
    if not xtra.run then
      return
    end
    pcall(process)
    vim.defer_fn(do_proces, 100)
  end
  vim.defer_fn(do_proces, 100)
  -- an on change callback function closure
  xtra.show = function()
    a.nvim_buf_set_lines(buf, 0, a.nvim_buf_line_count(buf) - 1, false, what)
  end
  -- a close callback for clean up
  xtra.close = function()
    -- close run
    xtra.run = false
    a.nvim_win_close(win, true)
    a.nvim_buf_delete(buf, { force = true })
  end
  return xtra
end

-- test the popup by showing notify of key events recieved
M.test_popup = function()
  M.popup({ "test", "line 2" }, function(key)
    M.notify(key)
  end, np, np)
end

-- function import and pass export
-- from doris module
-- only pure functions not needing vim calls
M.dd = dd
-- vim.fn
-- might be extended
M.fn = f
M.np = np
-- then from plenary modules
-- promises/futures async
M.as = as
-- file ops
M.uv = uv
-- control channels
M.ch = ch
-- iterators
M.it = it
-- classes
M.cl = cl
-- enums (capitalized string table)
M.en = en
-- job control class
M.jo = jo
-- context manager (like python file on each etc.)
M.cm = cm

return M
