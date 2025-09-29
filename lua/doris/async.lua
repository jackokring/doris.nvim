-- everything using async
-- NOTE: all the threading routines I'm likely to use under shorter names
-- some are adapted from the manual with shorter names
local nv = require("novaride").setup()

local co = coroutine

---wrap a yielding function as an iterator
_G.wrap = co.wrap
---coroutine yeild within a function
_G.yield = co.yield

---construct a producer function which can use tx(x)
---and rx(chain: thread) using the supply chain
---@param fn fun(init: ...): nil
---@param init ...
---@return thread
_G.chain = function(fn, init)
  return co.create(function()
    -- generic ... and other info supply
    fn(init)
  end)
end

---rx a sent any from a producer in a thread
---this includes the main thread with it's implicit coroutine
---@param chain thread
---@return ...
_G.rx = function(chain)
  -- manual vague about error message (maybe second return, but nil?)
  local ok, value = co.resume(chain)
  if not ok or value == nil then
    --if rx(x) then ... else ... exit ... end
    return nil
  end
  return value
end

---tx(x) an any from inside a producer thread to be received
---returns success if send(nil) is considered a fail
---@param x ...
---@return boolean
_G.tx = function(x)
  yield(x)
  if x == nil then
    --if not tx(x) then ... exit ... end
    return true
  else
    return false
  end
end

nv()
