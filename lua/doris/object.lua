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
---@field super Object
_G.Nad = Object:extend()
---@param value unknown
function Nad:new(value)
  self[priv] = value
end
---bind a super methos just to confuse
---the nature of the word bind
---remember pack(...) == { ... }
---also works for generic entries and
---not just methods
---@param method string
---@param as string
function Nad:super(method, as)
  -- modular import of super methods
  getmetatable(self)[as] = self.super[method]
end
---monad bind
---@param fn Nad
---@return Nad
function Nad:bind(fn)
  return fn(self:conad())
end
---comonad counit and it's inner return value
---@return ...
function Nad:conad()
  return self[priv]
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
---this is not like a classic identity as it does not make
---it be it's own unit by the usual method
---@class Term: Nad
_G.Term = Nad:extend()
---the unit for Term is a self referential monad
---it is not used to define join
function Term:new()
  self[priv] = self
end
---monad join "static" method
---returned is of type where static
---class used while inner monad used x, ... = conad()
---to account for some extraction to the
---self(value, ...) made
---this avoids the class instance factory pattern
---@param meta Nad
---@return Nad
function Nad:join(meta)
  local i = meta[priv]
  assert(type(i) == "table", type(i) .. " is not a type to join")
  assert(i.is, type(i) .. " is not a class to join")
  assert(i:is(Nad), type(i) .. " is not a monad to join")
  return self(i:conad())
end
novaride.restore()
