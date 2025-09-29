-- bus for state signalling
-- NOTE: a signalling bus for sending messages by named target
local nv = require("novaride").setup()

local Object = require("class")
--make it fine
---@class Bus: Class
_G.Bus = Object:extend()
local names = {}

---return a bus object for a name
---this bus object then supports
---send() and listen() with remove()
---bus singleton
---@param named string
---@return NamedBus | nil
function Bus:new(named)
  -- avoid namespace issues with method names in self
  local b = names[named]
  if b then
    ---@class NamedBus: Object
    return b
  else
    names[named] = self
  end
end

---send bus arguments on bus actor
---@param self NamedBus
---@param ... ...
function Bus:send(...)
  for k, _ in pairs(self) do
    -- call value function on arguments
    k(...)
  end
end

---listen for calls on bus actor for function
---@param self NamedBus
---@param fn fun(...): nil
function Bus:listen(fn)
  self[fn] = fn
end

---remove listener function from bus
---@param self NamedBus
---@param fn fun(...): nil
function Bus:remove(fn)
  self[fn] = nil
end

---destroy a bus so it can be released by the collector
---@param self NamedBus
function Bus:destroy()
  -- cancel all bussing
  for k, _ in pairs(self) do
    -- remove listeners
    self[k] = nil
  end
  for k, v in pairs(names) do
    if v == self then
      names[k] = nil
      return
    end
  end
end

nv()
