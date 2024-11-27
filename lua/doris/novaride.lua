-- handle the big _G

---track the global context against overriding keys
---@class NovarideModule
local M = {}
-- create private index also ignore list
local index = {}

-- make keys weak so keys when unrefrenced collect
local weak = {}
weak.__mode = "k"
setmetatable(index, weak)

local locale = ""
local unleak = function()
  os.setlocale(locale)
  -- do first global restore complete
  _G = M.untrack(_G)
end

-- create metatable
local mt = {
  __index = function(t, k)
    -- print("*access to element " .. tostring(k))
    return t[index][k] -- access the original table
  end,

  __newindex = function(t, k, v)
    -- print("*update of element " .. tostring(k) .. " to " .. tostring(v))
    if t[index][k] ~= nil then -- false? so has to be explicitly checked
      if not index[k] or (index[k] and not index[k][t]) then
        -- no key escape or no key for table
        unleak()
        -- assume stack 2 as __newindex
        error("novaride key: " .. tostring(k) .. " of: " .. tostring(t) .. " assigned already", 2)
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

---fully untrack a table allowing overrides
---can supply second argument to just unroll one layer of tracking
---will not error if t not tracked
---@param t table
---@param once? boolean
---@return table
M.untrack = function(t, once)
  t = t or _G
  local g = t[index]
  -- while is proxy
  while g do
    t[index] = nil -- the reference reset
    t = g
    if once then
      break
    end
  end
  return t
end

-- grab the global context
---allow multiple tracking of the _G context
---@return NovarideModule
M.setup = function()
  _G = M.track(_G)
  -- get locale to eventually restore
  if locale == "" then
    locale = os.setlocale()
  end
  -- use a standard locale too
  os.setlocale("C")
  return M
end

---index any number of keys to allowing overriding them
---@param t table
---@param ... unknown
---@return NovarideModule
M.index = function(t, ...)
  t = t or _G
  if not t[index] then
    unleak()
    error("novaride requires table: " .. tostring(t) .. " to be a tracked table for index", 2)
  end
  for _, v in ipairs({ ... }) do
    if not index[v] then
      -- must start a table
      index[v] = {}
      -- also weak on table name not referenced
      setmetatable(index[v], weak)
    end
    -- and fill it with applies to table lookup
    index[v][t] = true
  end
  return M
end

---restore the global context
---every setup (beginning) must have a restore (end)
---@return NovarideModule
M.restore = function()
  -- restore the context
  -- this does mean some ease
  if not _G[index] then
    unleak()
    error("novaride was not setup that many times", 2)
  end
  _G = M.untrack(_G, true)
  if not _G[index] then
    -- restore locale for UI weirdness
    os.setlocale(locale)
    -- and allow new locale context
    locale = ""
  end
  return M
end

return M
