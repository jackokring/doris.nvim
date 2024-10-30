-- pure module with no install specifics
-- look up for 'key' in list of tables `plist'
local function bind(key, plist)
  for i = 1, #plist do
    local v = plist[i][key] -- try 'i'-th superclass
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
  -- remove linter warning and extend nil object
  local parents = { ... }
  if #parents > 0 then
    setmetatable(c, {
      __index = function(t, k)
        -- can't use ... out of varargs fn linter
        -- replaced depricated arg ...
        local v = bind(k, parents)
        -- first lookup optimization
        t[k] = v
        return v
      end,
    })
  end
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

---@class DorisPureModule
local M = {}

M.bind = bind
M.extends = extends

return M
