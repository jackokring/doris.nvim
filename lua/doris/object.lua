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
---a non-ordered identity monad
function Id:new()
  self.__ = self
end

novaride.restore()
