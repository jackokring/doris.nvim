-- extend the object system from plenary
-- places some classes in the _G global context
local novaride = require("doris.novaride").setup()
-- classes
-- class object with mixins via implements list
-- not dynamic mixin binding
_G.Object = require("plenary.class")
---monad unit via Nad(value)
---@class Monad: Object
---@field __ any
_G.Nad = Object:extend()
---@param value any
function Nad:new(value)
  self.__ = value
end
---monad bind
---@param fn fun(value: any):Monad
---@return Monad
function Nad:bind(fn)
  return fn(self.__)
end
---comonad counit
---@return any
function Nad:conad()
  return self.__
end
---comonad extend
---@param fn fun(nad: Monad):any
---@return Monad
function Nad:tend(fn)
  return Nad(fn(self))
end
---flat map "static" functor
---self would represent class
---@param fn fun(value: any):any
---@return fun(nad: Monad):Monad
function Nad:map(fn)
  return function(nad)
    return Nad(fn(nad:conad()))
  end
end
---@class Id: Monad
_G.Id = Nad:extend()
function Id:new()
  self.__ = self
end
---monad join static method
---returned is of type where static
---class used while inner monad used x, ... = conad()
---to account for some extraction to the
---self(value, ...) made
---@param meta Monad
---@return Monad
function Nad:join(meta)
  local i = meta.__
  assert(type(i) == "table", type(i) .. " is not a meta monad to join")
  assert(i.is, type(i) .. " is not a class to join")
  assert(i:is(Nad), type(i) .. " is not a monad to join")
  return self(i:conad())
end
novaride.restore()
