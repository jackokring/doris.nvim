-- extend the object system from plenary
-- places some classes in the _G global context
local novaride = require("doris.novaride").setup()

local priv = {}

-- classes
-- class object with mixins via implements list
-- not dynamic mixin binding
_G.Object = require("plenary.class")
---monad unit via Nad(value)
---i'm sure the super is a joke
---you'd have to self.super.method(self, ...) to use it
---@class Nad: Object
---@field super Nad
_G.Nad = Object:extend()
---@param ... unknown
function Nad:new(...)
  self[priv] = { ... }
end
---used to call the super constructor
---@param ... unknown
function Nad:older(...)
  self.super.new(self, ...)
end
---bind a super method just to confuse
---the nature of the word bind
---remember pack(...) == { ... }
---also works for generic entries and
---not just methods
---@param method string
---@param as string
function Nad:as(method, as)
  -- modular import of super methods
  getmetatable(self)[as] = self.super[method]
end
---is nad of type?
---the same metatable implies so, Y?
---this almost got called dad(T)
---@param T Nad class
---@return boolean
function Nad:class(T)
  return getmetatable(self) == T
end
---monad bind
---@param fn Nad
---@return Nad
function Nad:bind(fn)
  return fn(self:conad())
end
---comonad counit and it's inner return value
---@return unknown
function Nad:conad()
  return unpack(self[priv])
end
---comonad extend best as a "static" method
---allowing class call new by self(...)
---this avoids the class instance factory pattern
---@param nad Nad
---@param fn fun(nad: Nad):unknown
---@return Nad
function Nad:tend(nad, fn)
  return self(fn(nad))
end
---flat map "static" functor
---self would represent class new by self(...)
---this avoids the class instance factory pattern
---@param fn fun(value: unknown):unknown
---@return fun(nad: Nad):Nad
function Nad:map(fn)
  return function(nad)
    return self(fn(nad:conad()))
  end
end
local cb = {}
---check if a nad is terminal
---@return any
function Nad:term()
  -- invert terminal paradigm of nil indicator
  -- it's more of a class "static" though
  if not self[priv] then
    return unpack(cb[self])
  end
  return nil
end
---this is not like a classic identity as it does not make
---it be it's own unit by the usual method
---@class Term: Nad
_G.Term = Nad:extend()
---Term is a terminal referential monad
---it is not used to define join
---@param ... unknown
function Term:new(...)
  -- becomes terminal
  cb[self] = { ... }
  -- self[priv] = nil
end
novaride.restore()
