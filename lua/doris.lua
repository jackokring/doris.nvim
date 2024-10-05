-- main module file
-- includes install specifics and config application
-- this keeps the interface separate from the implementation
local module = require("doris.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class DorisModule
local M = {}

-- impure nvim dependent function export
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

M.hello = function()
  return module.my_first_function(M.config.opt)
end

-- pure function import and pass export
M.bind = module.bind
M.extends = module.extends

return M
