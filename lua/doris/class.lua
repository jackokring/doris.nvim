---@brief [[
---classic (altered by S. Jackson under MIT)
---now includes Class typedefs
---Copyright (c) 2014, 2025, rxi, S. Jackson
---@brief ]]

---@class Class: Object
---@field super Class|nil
local Class = { super = nil }
-- static class variables
Class.__index = Class
-- is()?
setmetatable(Class, Class)

---Does nothing.
---You have to implement this yourself for extra functionality when initializing
---@param self Object
---@param ... unknown
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
	return "Object " .. tostring(self)
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
	getmetatable(obj).new(obj, ...)
	return obj
end

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
		-- might be an object
		if any.is then
			-- might be an object
			if any:is(Class) then
				t = "object"
				if any.__index == any then
					-- seems to be definitive
					t = "class"
				end
			end
		end
	end
	return t
end

return Class
