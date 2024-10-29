-- main module file
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
local module = require("doris.module")

-- supply table of lines and opts
local popup = require("plenary.popup").create

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
M.popup = function(what)
  return popup(what, M.config.popup)
end

-- pure function import and pass export
M.bind = module.bind
M.extends = module.extends

return M
