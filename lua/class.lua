---@brief [[
---classic (altered by S. Jackson under MIT)
---now includes Class typedefs
---Copyright (c) 2014, 2025, rxi, S. Jackson
---@brief ]]

-- NOTE: a class implementation from plenary.nvim with some minor improvements
-- support for the factory paradigm by returning another instance from new
-- singletons can also be supported (bus has an example)
-- a new type function for also detecting classes and objects by their
-- metatable arrangement is injected into _G with a novaride skip example

---@class Class: Object
---@field super Class|nil
local Class = { super = nil }
-- static class variables
Class.__index = Class
-- NOTE: is()? it's a consistency thing for me
-- Object was renamed Class as it's a sub-class of Object
local void = {}
-- a special class emptier than a class to give Class a parent from nothing
void.__index = void
local on = {}
-- a special class handling the fallback index checking up on __on being
-- present so that the default error can be avoided in processing
-- is a class not knowing a method a fail or an intended null?
-- "and on the filler of uptime created the void to be filled by all classes"
on.__index = function(t, k)
  -- a second class trace after not found for checking continuation
  local ton = getmetatable(t).__on
  -- seems lua sytyle
  if type(ton) == "function" then
    return ton(t, k)
  end
  return ton
end
setmetatable(void, on)
-- lock metatable on
void.__metatable = false
-- "once there was something preceded by nothing with its symbol"
-- sure now it's a class, but it can't be the terminal beginning
-- it can't be its own meta table or other and so it becomes defered to a
-- hidden void, simplistic in maitaining the integrity of fulfilling the
-- needs of class but performing its own miracle of inacces
setmetatable(Class, void)

---Does nothing.
---You have to implement this yourself for extra functionality when initializing
---You can return a replacement Object (sub class factory)
---nil implies self for convienience of coding
---a class variable can also be used for an object singleton pattern
---NOTE: use Class(...) to make an Object as new(...) is used indirectly
---@param self Object
---@param ... any
---@return Object | nil
function Class:new(...) end

---Create a new class/Class by extending the base Class class.
---The extended Class will have a field called `super` that will access the super class.
---@param self Class
---@return Class
function Class:extend()
  local cls = {}
  for k, v in pairs(self) do
    --behaviours by copying "__metatable of instance == class"
    --not the static class variables as different class
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  --but check own statics not super's statics
  cls.__index = cls
  --static reference to super
  cls.super = self
  --if static not found, check super?
  --no as cls.__index = cls
  --an extra hidden super pointer for is()?
  --I suppose it has a bit of dynamic programming anti-clobber of super
  return setmetatable(cls, self)
  --optimise
end

---Implement a mixin onto this Class.
---@param self Class
---@param ... unknown
function Class:mixin(...)
  for _, cls in pairs({ ... }) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end

---Checks if the Class is an instance
---This will start with the lowest class and loop over all the superclasses.
---@param self Object
---@param T Class
---@return boolean
function Class:is(T)
  --use metatable method as no hash indexing needed
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end

---The default tostring implementation for an Class.
---You can override this to provide a different tostring.
---@param self Object
---@return string
function Class:__tostring()
  return type(self) .. ": " .. tostring(self)
end

---You can call the class the initialize it without using `Class:new`.
---@param self Class
---@param ... unknown
---@return Object
function Class:__call(...)
  --Yes, a Class is an instance of class class
  ---@class Object
  local obj = setmetatable({}, self)
  --compiler type exact not inferred
  --as the : notation just goes funny, and won't
  return self.new(obj, ...) or obj
end

-- NOTE: the novaride skip() example extends type() to detect "object"
-- and "class" by metatable properties as an instance has a "class" as a
-- metatable and a "class" is it's own __index due to methods for "object"
-- needing to be in the "class" table

local nv = require("novaride").skip()
local typi = type
---an extended type finder
---this might be useful after extra operators are added
---@param any any
---@return string
_G.type = function(any)
  ---@type string
  local t = typi(any)
  -- ok so far
  if t == "table" then
    --NON STANDARD BUT THE MANUAL GIVES EXAMPLES IMPLYING SUCH
    -- might be an object
    local mt = getmetatable(any)
    -- might be an object
    if mt and mt.__index == mt then
      t = "object"
      if any.__index == any then
        -- seems to be definitive
        t = "class"
      end
    end
  end
  return t
end
--perhaps re-enable novaride
nv()

return Class
