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
        assert(ignore[k][t], "novaride key: " .. tostring(k) .. " of: " .. tostring(t[index]) .. " assigned already")
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
---allow multiple tracking of the _G context
---@return NovarideModule
M.setup = function()
  _G = M.track(_G)
  return M
end

---ignore any number of keys to allowing overriding them
---@param t table
---@param ... unknown
M.ignore = function(t, ...)
  t = t or _G
  assert(t[index], "novaride requires table: " .. tostring(t) .. " to be a tracked table for ignore")
  for _, v in ipairs({ ... }) do
    if not ignore[v] then
      -- must start a table
      ignore[v] = {}
    end
    -- and fill it with applies to table lookup
    ignore[v][t] = true
  end
end

---restore the global context
M.restore = function()
  -- restore the context
  -- this does mean some ease
  assert(_G[index], "novaride was not setup that many times")
  _G = _G[index]
end

---useful for clearing all the _G proxy tables after an error
M.unleak = function()
  while _G[index] do
    M.restore()
  end
end

return M
