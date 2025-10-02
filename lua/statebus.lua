-- bus for state signalling
-- NOTE: a state bus for sending messages by named target
-- messages are combined and the last is issued by sync()
-- so used to keep a state current and avoid unsychronized
-- transitions of state
local nv = require("novaride").setup()

---@class StateBus: Bus
---constructor format
---@overload fun(name: string): StateBus
_G.StateBus = Bus:extend()

local que = {}
local last = {}

---send bus arguments on bus actor
---@param self StateBus
---@param ... any
function StateBus:send(...)
  que[self] = { ... }
end

---synchronize to last send(...) only
---@param self StateBus
function StateBus:sync()
  -- don't repeat inactive state changes
  local same = true
  -- aligned atomic
  local qs = que[self]
  for k, v in pairs(qs) do
    if not last[self] or v ~= last[self][k] then
      same = false
      break
    end
  end
  if same then
    return
  end
  -- lock in to commit sending
  last[self] = qs
  for k, _ in pairs(self) do
    -- call value function on last sent arguments
    k(unpack(last[self]))
  end
end

nv()
