-- bus for signalling

local novaride = require("doris.novaride").setup()

---@class Bus
_G.Bus = {}
-- if not find method try class
Bus.__index = Bus
local names = {}

---return a bus object for a name
---this bus object then supports
---send() and listen() with remove()
---@param named string
---@return Bus
function Bus:__call(named)
  -- avoid namespace issues with method names in self
  local b = names[named]
  if not b then
    b = setmetatable({}, self)
    -- remember same one for same string name
    names[named] = b
  end
  return b
end

---send bus arguments on bus actor
---@param ... unknown
function Bus:send(...)
  for _, v in pairs(self) do
    --- call value function
    v(...)
  end
end

---listen for calls on bus actor for function
---@param fn fun(...): nil
function Bus:listen(fn)
  self[fn] = fn
end

---remove function from bus actor
---remember any function in a variable
---if you intend to remove it later
---@param fn fun(...): nil
function Bus:remove(fn)
  self[fn] = nil
end

novaride.restore()
