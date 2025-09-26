-- everything using async
local novaride = require("doris.novaride").setup()

local co = coroutine

---wrap a yielding function as an iterator
_G.wrap = co.wrap
---coroutine yeild within a function
_G.yield = co.yield
-- async futures/promises
local as = require("plenary.async.async")
-- function import and pass export
-- from doris module
-- only pure functions not needing vim calls
-- promises/futures async
-- imports async/await into _G
_G.void = as.void
_G.run = as.run
local ch = require("plenary.async.control")
-- control channels
---@type Object
_G.sync = ch
-- context manager
local cm = require("plenary.context_manager")
-- context manager (like python file on each etc.)
---the callable is called with the yeild of enter()
---or the yeild of the thread or the return of the
---function and the return of the callable is passed
---through as the result of with
---suppling an object as the callable instances an
---object with the (...) from enter() and returns it
---all while using exit() to clean up the resources
---used and created in enter()
---@type fun(obj: function|thread|{ enter:function, exit:function }, callable: function|Object): unknown
_G.with = cm.with
---calls a callable with an open file supplying the handle
---as a parameter and closes the file afterwards
---@param filename string | { filename:string }
---@param mode "r" | "w" | "a" | "r+" | "w+" | "a+"
---@param callable function | Object
---@return unknown
_G.withfile = function(filename, mode, callable)
  return with(cm.open(filename, mode), callable)
end

---construct a producer function which can use tx(x)
---and rx(chain: thread) using the supply chain
---@param fn fun(init: unknown): nil
---@param init unknown
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
---@return any
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
---@param x any
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

novaride.restore()
