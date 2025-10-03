-- handle the big _G

---track the global context against overriding keys
---@class NovarideModule
local M = {}
-- create private index
local index = {}
-- used for error supression when defining a type template
local stoperror = nil

-- fix possible over sharing when in an nvim context
local printnv = function(...)
  if _G.vim then
    return
  end
  print(...)
end

---restore the global context
---every setup (beginning) must have a restore (end)
local restore = function()
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
    printnv("untracked")
  end
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
      if not stoperror then
        local i = #index
        for _ = 1, i do
          restore()
        end
        -- NOTE: makes an error if _G[...] gets clobbered
        -- assume stack 2 as __newindex
        error("novaride: " .. tostring(k) .. " of: " .. tostring(t) .. " assigned already", 2)
      else
        printnv("template: " .. tostring(k) .. " note: ", unpack(stoperror))
        --leave C alone
        return
      end
    end
    printnv("adding " .. tostring(k))
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
  printnv("tracking")
  return proxy
end

---skip novaride checks and enable later by
---calling the returned lambda expression
---@return fun():nil
M.skip = function()
  -- NOTE: use to wrap a definitive clobber you desire
  if _G[index] then
    printnv("skipping")
    _G = M.untrack(_G)
    return function()
      _G = M.track(_G)
    end
  else
    return function() end
  end
end

---untrack a table allowing overrides
---will not error if t not tracked
---@param t table
---@return table
M.untrack = function(t)
  if stoperror then
    stoperror = nil
  end
  return t[index] or t
end

-- grab the global context
---allow multiple tracking of the _G context
---@param ... any
---@return fun():nil
M.setup = function(...)
  -- NOTE: using any arguments prevents errors but has no assignment
  -- the args will be displayed if say a C function is loaded
  -- and a LSP template for it is not then loaded
  stoperror = { ... }
  if #stoperror == 0 then
    stoperror = nil
  end
  _G = M.track(_G)
  -- get locale to eventually restore
  table.insert(index, os.setlocale())
  -- use a standard locale too
  os.setlocale("C")
  return restore
end

return M
