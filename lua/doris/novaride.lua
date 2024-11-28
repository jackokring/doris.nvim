-- handle the big _G

---track the global context against overriding keys
---@class NovarideModule
local M = {}
-- create private index
local index = {}

-- create metatable
local mt = {
  __index = function(t, k)
    -- print("*access to element " .. tostring(k))
    return t[index][k] -- access the original table
  end,

  __newindex = function(t, k, v)
    -- print("*update of element " .. tostring(k) .. " to " .. tostring(v))
    if t[index][k] ~= nil then -- false? so has to be explicitly checked
      -- lock dep on index outside loop
      local i = #index
      for _ = 1, i do
        M.restore()
      end
      -- assume stack 2 as __newindex
      error("novaride key: " .. tostring(k) .. " of: " .. tostring(t) .. " assigned already", 2)
    end
    t[index][k] = v -- update original table
  end,
}

---track a table against overrides
---@param t table
---@return table
M.track = function(t)
  -- already tracked?
  if t[index] then
    return t
  end
  local proxy = {}
  proxy[index] = t
  setmetatable(proxy, mt)
  return proxy
end

---untrack a table allowing overrides
---will not error if t not tracked
---@param t table
---@return table
M.untrack = function(t)
  return t[index] or t
end

-- grab the global context
---allow multiple tracking of the _G context
---@return NovarideModule
M.setup = function()
  _G = M.track(_G)
  -- get locale to eventually restore
  table.insert(index, os.setlocale())
  -- use a standard locale too
  os.setlocale("C")
  return M
end

---restore the global context
---every setup (beginning) must have a restore (end)
---@return NovarideModule
M.restore = function()
  if #index > 0 then
    -- restore locale for UI weirdness
    os.setlocale(index[#index])
    -- and allow new locale context
    table.remove(index, #index)
  else
    error("setup was not called that many times to restore", 2)
  end
  if #index == 0 then
    -- restore the context at last
    _G = M.untrack(_G)
  end
  return M
end

return M
