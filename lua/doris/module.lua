-- pure module with no install specifics
-- look up for 'k' in list of tables `plist'
local function search(k, plist)
  for i = 1, #plist do
    local v = plist[i][k] -- try 'i'-th superclass
    if v then
      return v
    end
  end
end
-- a simple multi class inheritance scheme
-- supply classes order as arguments
local function extends(...)
  local c = {} -- new class
  -- class will search for each method in the list of its
  -- parents ('arg' is the list of parents)
  setmetatable(c, {
    __index = function(t, k)
      return search(k, arg)
    end,
  })
  -- prepare 'c' to be the metatable of its instances
  c.__index = c
  -- define a new constructor for this new class
  function c:new(o)
    o = o or {}
    setmetatable(o, c)
    return o
  end
  -- return new class
  return c
end

---@class CustomModule
local M = {}

---@return string
M.my_first_function = function(greeting)
  return greeting
end

M.extends = extends

return M
