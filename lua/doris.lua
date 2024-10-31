-- main module file
-- NeoVim specifics NOT pure lua
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
-- of pure lua functions
-- short forms for terse code coding, as contain many fields
local d = require("doris.module")
-- async futures/promises
local p = require("plenary.async")
-- iterators
local i = require("plenary.iterators")
-- class object with mixins via implements list
-- not dynamic mixin binding
local c = require("plenary.class")
-- enums e { "x", ... }
local e = require("plenary.enum")
-- job control class
local j = require("plenary.job")
-- context manager
local m = require("plenary.context_manager")

-- short forms
local a = vim.api
local f = vim.fn

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
  vim.notify(msg, vim.log.INFO, nil)
end

-- supply table of lines and opts
local popup = require("plenary.popup").create

---@param what table
---@param inkey function(string)
---@param process function
-- table of details and callbacks
---@return table
M.popup = function(what, inkey, process)
  local win, xtra = popup(what, M.config.popup)
  xtra.what = what
  local buf = a.nvim_win_get_buf(win)
  -- add new key definitions for buffer
  local keys = "abcdefghijklmnopqrstuvwxyz"
  local function nmap(key)
    vim.keymap.set("n", key, function()
      inkey(key)
    end, { buffer = buf })
  end
  for x = 1, #keys, 1 do
    nmap(keys[x])
  end
  -- specials
  vim.keymap.set("n", "<esc>", xtra.close, {
    buffer = buf,
  })
  -- must follow this for to be defined for "recursive call"
  -- 10 fps
  xtra.run = true
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
  end, function() end)
end

-- function import and pass export
-- api
M.a = a
-- fn
M.f = f
-- then from plenary modules
-- promises/futures async
M.p = p
-- iterators
M.i = i
-- classes
M.c = c
-- enums (capitalized string table)
M.e = e
-- job control class
M.j = j
-- context manager (like python file on each etc.)
M.m = m
-- then from doris module
-- only pure functions not needing vim calls
M.d = d

return M
