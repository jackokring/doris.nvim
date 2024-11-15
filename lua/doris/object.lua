-- extend the object system from plenary
-- places some classes in the _G global context
local novaride = require("doris.novaride").setup()

-- assume pointer indexed
local priv = {}

-- classes
-- class object with mixins via implements list
-- not dynamic mixin binding
_G.Object = require("plenary.class")
---monad unit via Nad(value)
---i'm sure the super is a joke
---you'd have to self.super.method(self, ...) to use it
---the type of super is a botch to allow method older()
---@class Nad: Object
---@field super Nad
_G.Nad = Object:extend()
---an extended type finder
---this might be useful after extra operators are added
---@param any any
---@return string
_G.typi = function(any)
  ---@type string
  local t = type(any)
  -- ok so far
  if t == "table" then
    -- might be an object
    local is = any.is
    if is then
      -- might be an object
      if is == Object.is then
        t = "object"
        if any:is(Nad) then
          -- ok, it's a nad
          -- they do all that Objects does
          -- but they've got some packed stuff inside
          t = "nad"
        end
      end
    end
  end
  return t
end
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
---return the index private varg
---to prevent excessive use of conad()
---@return unknown
function Nad:varg()
  -- a tabled copy
  return self[priv]
end
---set to string function "static" method
---override subclasses of Nad by supplying
---the strings to instance["field"]
---@param ... unknown
function Nad:str(...)
  local mt = getmetatable(self) -- super as static
  local mtts = mt.__tostring
  local fn
  local p = { ... }
  fn = function(nad)
    local s = "Nad["
    for _, v in ipairs(nad:varg()) do
      s = s .. tostring(v) .. ", "
    end
    return s .. " ...]"
  end
  if #p > 0 then
    fn = function(nad)
      local s = "Object["
      for _, v in ipairs(p) do
        s = s .. tostring(nad[v]) .. ", "
      end
      if mtts then
        s = s .. mtts(nad)
      else
        -- false or nil
        s = s .. tostring(mtts)
      end
      -- capture super nad
      return s .. "]"
    end
  end
  -- static class is metatable
  self.__tostring = fn
end
-- initialize the default tostring
Nad:str()
---check if a nad is terminal
---@return any
function Nad:term()
  -- invert terminal paradigm of nil indicator
  -- it's more of a class "static" though
  if not self[priv] then
    return unpack(priv[self])
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
  priv[self] = { ... }
  -- self[priv] = nil
end
novaride.restore()
