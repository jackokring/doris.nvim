-- pure module with no install specifics
-- look up for 'key' in list of tables `plist'

---@class DorisPureModule
local M = {}

---insert into table
_G.insert = table.insert
---concat table
_G.concat = table.concat
---remove from table index (arrayed can store null)
_G.remove = table.remove
---substring of string
_G.sub = string.sub
---match first
_G.match = string.match
---generator match
_G.gmatch = string.gmatch
---substitue in string
_G.gsub = string.gsub
---find in string
_G.find = string.find

---pattern compiler (use \ for insert of a match specifier)
---@param literal string
---@return PatternStatement
_G.pat = function(literal)
  ---@class PatternStatement
  local Table = {
    literal = literal,
    using = {},
    caps = {},
  }

  ---compile the pattern
  ---@return string
  Table.compile = function()
    if literal then
      local p = 1
      local u = 1
      local skip = false
      local magic = "^$()%.[]*+-?"
      for i in range(#magic) do
        local r = "%" .. magic[i]
        -- ironic match
        literal = gsub(literal, r, r)
      end
      repeat
        local s, e, f = find(literal, "\\[^\\]", p)
        if f ~= "\\" then
          skip = true
        else
          local v = Table.using[u]
          assert(v, "not enough variant arguments for pattern")
          -- fill variant
          literal = sub(literal, 1, s - 1) .. v .. sub(literal, e + 1)
          u = u + 1
          p = e + 1
        end
      until skip
      assert(not Table.using[u], "too many variant arguments for pattern")
    end
    return literal
  end
  ---exclude the previous variant match as a non-match
  Table.exclude = function()
    Table.using[#Table.using] = upper(Table.using[#Table.using])
  end
  ---match an alpha character
  Table.alpha = function()
    insert(Table.using, "%a")
  end

  Table.mark = function()
    Table.using[#Table.using] = "(" .. Table.using[#Table.using]
  end

  Table.capture = function()
    Table.using[#Table.using] = Table.using[#Table.using] .. ")"
  end

  return Table
end

---switch statement
---@param is any
---@return SwitchStatement
_G.switch = function(is)
  ---@class SwitchStatement
  ---@field Value any
  ---@field Functions { [any]: fun(is: any): nil }
  local Table = {
    Value = is,
    Functions = {}, -- dictionary as any value
  }

  ---each case
  ---@param testElement any
  ---@param callback fun(is: any): nil
  ---@return SwitchStatement
  Table.case = function(testElement, callback)
    assert(not Table.Functions[testElement], "Duplicate case in switch")
    Table.Functions[testElement] = callback
    return Table
  end

  ---remove case
  ---@param testElement any
  ---@return SwitchStatement
  Table.uncase = function(testElement)
    -- can remove it many times
    Table.Functions[testElement] = nil
    return Table
  end

  ---use newer switch value
  ---@param testElement any
  ---@return SwitchStatement
  Table.reswitch = function(testElement)
    Table.Value = testElement
    return Table
  end

  ---default case
  ---@param callback fun(is: any): nil
  Table.default = function(callback)
    local Case = Table.Functions[Table.Value]
    if Case then
      -- allowing duplicate function usage
      Case(Table.Value)
    else
      callback(Table.Value)
    end
  end

  return Table
end

---modulo statement
---@param over integer
---@return ModuloStatement
_G.modulo = function(over)
  ---@class ModuloStatement
  ---@field Value integer
  ---@field Functions (fun(mod: integer): nil)[]
  ---@field Modulos integer[]
  ---@field Random integer
  local Table = {
    Value = over,
    Functions = {}, -- dictionary as any value
    Modulos = {},
    Random = math.random(over),
  }

  ---each case
  ---@param divElement integer
  ---@param callback fun(mod: integer): nil
  ---@return ModuloStatement
  Table.case = function(divElement, callback)
    Table.Functions[#Table.Functions + 1] = callback
    Table.Modulos[#Table.Modulos + 1] = divElement
    return Table
  end

  ---remove case
  ---@param indexElement integer
  ---@return ModuloStatement
  Table.uncase = function(indexElement)
    remove(Table.Functions, indexElement)
    remove(Table.Modulos, indexElement)
    return Table
  end

  ---run
  Table.run = function()
    for k, v in ipairs(Table.Functions) do
      v(Table.Random % Table.Modulos[k])
    end
    Table.Random = math.random(Table.Value)
  end

  return Table
end

---ranged for by in 1, #n, 1
---@param len integer
---@return fun(iterState: integer, lastIter: integer): integer
---@return integer
---@return integer
_G.range = function(len)
  local state = len
  local iter = 0
  ---iter next function
  ---@param iterState integer
  ---@param lastIter integer
  ---@return integer | nil
  local next = function(iterState, lastIter)
    local newIter = lastIter + 1
    if newIter > iterState then
      return --nil
    end
    return newIter --, xtra iter values, ...
  end
  return next, state, iter
end

---iter for by fn(state)
---more state by explicit closure
---@param fn fun(hidden: any, chain: any): any
---@return fun(iterState: any, lastIter: any): any, any
---@return any
_G.iter = function(fn)
  ---iter next function
  ---@param iterState any
  ---@param lastIter any
  ---@return table
  ---@return any
  local next = function(iterState, lastIter)
    -- maybe like the linked list access problem of needing preceding node
    -- the nil node "or" head pointer
    return fn(iterState, lastIter), lastIter --, xtra iter values, ...
  end
  -- mutable private table closure
  local state = {}
  return next, state -- jump of point 1st (compare?)
end

local co = coroutine

---construct a producer function which can use send(x)
---and receive(producer: thread) using the supply chain
---@param fn fun(chain: thread[]): nil
---@param chain thread[]
---@return thread
_G.producer = function(fn, chain)
  return co.create(function()
    fn(chain)
  end)
end

---receive a sent any from a producer in a thread
---this includes the main thread with it's implicit coroutine
---@param prod thread
---@return any
_G.receive = function(prod)
  -- manual vague about error message (maybe second return, but nil?)
  local ok, value = co.resume(prod)
  -- maybe rx nil ...
  if ok then
    return value
    -- else
    -- return -- nil
  end
end

---send an any from inside a producer thread to be received
---returns success if send(nil) is considered a fail
---@param x any
---@return boolean
_G.send = function(x)
  co.yield(x)
  if x == nil then
    return false
  else
    -- close out (if not send(x) then return end?)
    return true
  end
end

local sf = string.format
local nf = function(x, width, base)
  width = width or 0
  return sf("%" .. sf("%d", width) .. base, x)
end
---decimal string of number
---@param x integer
---@param width integer
---@return string
_G.dec = function(x, width)
  return nf(x, width, "d")
end
---hex string of number
---@param x integer
---@param width integer
---@return string
_G.hex = function(x, width)
  return nf(x, width, "x")
end
---scientific string of number
---@param x integer
---@param width integer
---@param prec integer
---@return string
_G.sci = function(x, width, prec)
  -- default size 8 = 6 + #"x."
  return nf(x, width, "." .. sf("%d", prec or 6) .. "G")
end

_G.upper = string.upper
_G.lower = string.lower
_G.rep = string.rep
_G.reverse = string.reverse
_G.sort = table.sort

---quote a string escaped (includes beginning and end "\"" literal)
---@param str string
---@return string
_G.quote = function(str)
  return sf("%q", str)
end

---unquote a quoted string and remove supposed quote delimiters
---@param str string
---@return string
_G.unquote = function(str)
  local s = {}
  local f = false
  local n = 0
  for m in range(#str) do
    local c = str[m]
    if n > 0 and c == "0" then
      -- miss one
      n = n - 1
    else
      n = 0 -- baulk here on not "0"
      if f then
        f = false
        if c == "r" then
          insert(s, chr(13)) -- and null action for chr(10)
        -- and also null action for quote
        -- and also null action for backslash
        elseif c == "0" then
          --- check hex 000 by missing next 2
          n = 2
        else
          -- null action escaped
          insert(s, c)
        end
      else
        if c == "\\" then
          -- mark
          f = true
        else
          -- normal char
          insert(s, c)
        end
      end
    end
  end
  return concat(s, "", 1, -1)
end

-- then maybe some non _G stuff too for lesser application
return M
