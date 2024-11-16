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
---due to the way new is called the self
---context is not the class but the instance
---as class(...) uses the __callable metatable
---entry to make the instance and then call
---instance:new(...) on it for a more regular
---OOP style
---@param ... unknown
function Nad:new(...)
  self[priv] = { ... }
end
---used to call the super constructor
---the plenary code of extend() explains
---how a class copies all __ fields
---keeps it's own methods by __index and
---and sets the right super
---@param ... unknown
function Nad:older(...)
  local sup = self.super(...)
  -- for all instance things in super
  -- we don't want to spanner the class methods
  for k, v in pairs(sup) do
    -- place super initialization into self
    -- unlike java it is not necessary to call before
    -- other methods, and can be done after other
    -- constructor things
    self[k] = v
  end
end
---mixin the data and methods of a set of
---instances of any classes so like implement(...)
---but also add in any instance variables
---and it's used in the constructor in an instance context
---calling for each instance does add a little to the
---constructor time, but implement(...) will have no other
---effects than a slight speed delay for the second and further
---instances along with better code readability by not having
---to go crazy on adding in instance variables to each instance
---@param ... [Object, ...]
function Nad:mixin(...)
  local inst = { ... }
  local cls = {}
  for _, i in ipairs(inst) do
    for k, v in pairs(i) do
      -- instance variables
      if not self[k] then
        self[k] = v
      end
    end
    insert(cls, getmetatable(i))
  end
  -- fallback to default supplied by plenary
  -- to copy safely all the methods in a priority order
  getmetatable(self):implement(cls)
end
---a "static" method applied to a class
---bind a super method just to confuse
---the nature of the word bind
---remember pack(...) == { ... }
---self.super.method(self, ...) is long winded
---if you're not looking for methods
---then perhaps use self:older(...)
---in the class:new(...) consrtuctor
---@param method string
---@param as string
function Nad:as(method, as)
  -- modular import of super methods
  self[as] = self.super[method]
end
---is nad of type?
---the same metatable implies so, Y?
---this almost got called dad(T)
---the no free class return prevents it's abuse
---by locking it to a boolean result
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
  -- allow override of presentation
  return unpack(self:varg())
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
  while not mtts do
    local mt2 = getmetatable(mt)
    if not mt2 then
      -- no found __tostring better
      break
    end
    -- next possible __tostring
    mt = mt2
    mtts = mt.__tostring
  end
  -- should have next higher up defined __tostring
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
        -- print previous __tostring too
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
