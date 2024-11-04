-- handle the big _G

---track the global context against overriding keys
---@class NovarideModule
local M = {}
-- create private index
local index = {}

-- ignore list
local ignore = {}

-- create metatable
local mt = {
  __index = function(t, k)
    -- print("*access to element " .. tostring(k))
    return t[index][k] -- access the original table
  end,

  __newindex = function(t, k, v)
    -- print("*update of element " .. tostring(k) .. " to " .. tostring(v))
    if t[index][k] ~= nil then -- false? so has to be explicitly checked
      if ignore[k] then
        assert(not ignore[k][t], "novaride key: " .. tostring(k) .. " of: " .. tostring(t) .. " assigned already")
      end
    end
    t[index][k] = v -- update original table
  end,
}

---track a table against overrides
---@param t table
---@return table
M.track = function(t)
  local proxy = {}
  proxy[index] = t or _G
  setmetatable(proxy, mt)
  return proxy
end

-- grab the context
local global = _G
_G = M.track(_G)

---ignore any number of keys to allowing overriding them
---@param t table
---@param ... unknown
M.ignore = function(t, ...)
  t = t or _G
  for _, v in ipairs({ ... }) do
    if ignore[v] then
    else
      ignore[v] = {}
      ignore[v][t] = true
    end
  end
end

---restore the global context
M.restore = function()
  -- restore the context
  _G = global
end

return M
