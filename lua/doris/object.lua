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
---@param fn fun(value: any):Monad | Monad
---@return Monad
function Nad:bind(fn)
  return fn(self:conad())
end
---comonad counit and it's inner return value
---@return any
function Nad:conad()
  return self.__
end
---comonad extend best as a "static" method
---allowing class call new by self(...)
---this avoids the class instance factory pattern
---@param nad Monad
---@param fn fun(nad: Monad):any
---@return Monad
function Nad:tend(nad, fn)
  return self(fn(nad))
end
---flat map "static" functor
---self would represent class new by self(...)
---this avoids the class instance factory pattern
---@param fn fun(value: any):any
---@return fun(nad: Monad):Monad
function Nad:map(fn)
  return function(nad)
    return self(fn(nad:conad()))
  end
end
---this is not like a classic identity as it does not make
---it be it's own unit by the usual method
---@class Id: Monad
_G.Id = Nad:extend()
---the unit for Id is a self referential monad
---it is not used to define join
function Id:new()
  self.__ = self
end
---monad join "static" method
---returned is of type where static
---class used while inner monad used x, ... = conad()
---to account for some extraction to the
---self(value, ...) made
---this avoids the class instance factory pattern
---@param meta Monad
---@return Monad
function Nad:join(meta)
  local i = meta.__
  assert(type(i) == "table", type(i) .. " is not a type to join")
  assert(i.is, type(i) .. " is not a class to join")
  assert(i:is(Nad), type(i) .. " is not a monad to join")
  return self(i:conad())
end
novaride.restore()
