-- main module file
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
local module = require("doris.module")

-- supply table of lines and opts
local popup = require("plenary.popup").create

-- short forms
local a = vim.api
local f = vim.fn
local n = function(msg)
  vim.notify(msg, vim.log.INFO, nil)
end

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
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

-- external commands
M.hello = function()
  return module.my_first_function(M.config.opt)
end

-- impure function collection
---@param what table
---@param inkey function(key: string, mod: integer)
-- table of details and callbacks
---@return table
M.popup = function(what, inkey)
  local win, xtra = popup(what, M.config.popup)
  xtra.what = what
  -- open new namespace for key listener
  local keycb = function(key, typed)
    local k = f.getcharstr()
    -- check ESC or unassigned ALT
    if f.char2nr(k) == 27 then
      -- escape exit and dual on alt call solved?
      xtra.close()
      -- then wait for an escape key
      while f.getchar() ~= 27 do
        n("Press <esc> again.")
      end
    end
    -- will this technically consume a key event?
    -- 2 = shift
    -- 4 = control
    -- 8 = alt
    -- 128 = super
    inkey(k, f.getcharmod())
  end
  xtra.keyns = vim.on_key(keycb, 0)
  local buf = a.nvim_win_get_buf(win)
  -- an on change callback function closure
  xtra.show = function()
    a.nvim_buf_set_lines(buf, 0, a.nvim_buf_line_count(buf) - 1, false, what)
  end
  -- a close callback for clean up
  xtra.close = function()
    -- close key listener
    vim.on_key(nil, xtra.keyns)
    a.nvim_win_close(win, true)
    a.nvim_buf_delete(buf, { force = true })
  end
  return xtra
end

-- pure function import and pass export
M.a = a
M.f = f
M.n = n
M.bind = module.bind
M.extends = module.extends

return M
