-- bus for signalling

local novaride = require("doris.novaride").setup()

---@class Bus
_G.Bus = {}
-- if not find method try class
Bus.__index = Bus
local names = {}
-- last ref to bus instance weak as not a names strong
local weak = {}
weak.__mode = "v"
setmetatable(names, weak)
local que = {}
local run = {}
local c = 0
local wait = false

---return a bus object for a name
---this bus object then supports
---send() and listen() with remove()
---@param named string
---@return Bus
function Bus:__call(named)
  -- avoid namespace issues with method names in self
  local b = names[named]
  if not b then
    b = setmetatable({}, self)
    -- remember same one for same string name
    names[named] = b
  end
  return b
end

---send bus arguments on bus actor
---@param ... unknown
function Bus:send(...)
  -- que bus with merge efficiency
  local qs = que[self]
  if not qs then
    que[self] = self
    c = c + 1
  end
  -- processing cycle?
  if wait then
    -- 2nd and later delayed until one que action cycle emptied
    return
  else
    -- only run first qued until cascade ends with
    -- empty que as all bus sends are merged into
    -- one call per cycle of activity
    wait = true
    while c > 0 do
      -- DO NOT add new keys to que in dispatch loop
      for _, b in pairs(que) do
        run[b] = b
      end
      que = {}
      c = 0
      -- dispatch loop doesn't use que
      for _, b in pairs(run) do
        for _, v in pairs(b) do
          --- call value function
          v(...)
        end
      end
      -- end of que
      run = {}
    end
    wait = false
  end
end

---listen for calls on bus actor for function
---@param fn fun(...): nil
function Bus:listen(fn)
  self[fn] = fn
end

---remove function from bus actor
---remember any function in a variable
---if you intend to remove it later
---@param fn fun(...): nil
function Bus:remove(fn)
  self[fn] = nil
end

---destroy a bus so it can be released by the collector
function Bus:destroy()
  -- cancel all bussing
  run[self] = nil
  que[self] = nil
  for k, _ in pairs(self) do
    -- remove listeners
    self[k] = nil
  end
end

novaride.restore()
