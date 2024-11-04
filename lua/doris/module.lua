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
---utf8 charpattern
_G.utfp = "[\0-\x7F\xC2-\xF4][\x80-\xBF]*"

---pattern compiler (use \ for insert of a match specifier)
---in a string that's "\\" to substitue the patterns appended
---by .function(args).function(args) ... to the pattern
---to the literal argument finalizing on .compile()
---
---so start with an example literal and then replace
---what to find with "\\" and add a .function(args) chain
---for the match kind needed at the "\\" point in the
---literal and be less confused about pattern punctuation chaos
---@param literal string
---@return PatternStatement
_G.pat = function(literal)
  ---@class PatternStatement
  local Table = {
    literal = literal,
    using = {},
    caps = {},
    start_f = "",
    stop_f = "",
  }
  --enhancement
  local tu = Table.using
  local magic = "^$()%.[]*+-?"
  local sane = function(chars)
    for i in range(#magic) do
      local r = "%" .. magic[i]
      -- ironic match
      chars = gsub(chars, r, r)
    end
    return chars
  end

  ---compile the pattern
  ---@return string
  Table.compile = function()
    if literal then
      local p = 1
      local u = 1
      local skip = false
      literal = sane(literal)
      repeat
        local s, e, f = find(literal, "\\[^\\]", p)
        if f ~= "\\" then
          skip = true
        else
          local v = tu[u]
          assert(v, "not enough arguments for pattern")
          -- fill variant
          literal = sub(literal, 1, s - 1) .. v .. sub(literal, e + 1)
          u = u + 1
          p = e + 1
        end
      until skip
      assert(not tu[u], "too many arguments for pattern")
    end
    return Table.start_f .. literal .. Table.stop_f
  end

  ---start of line match
  ---@return PatternStatement
  Table.start = function()
    Table.start_f = "^"
    return Table
  end
  ---end of line match
  ---@return PatternStatement
  Table.stop = function()
    Table.stop_f = "$"
    return Table
  end

  ---invert the previous match as a non-match (postfix)
  ---does not work on an "includes" which has its own invert flag
  ---@return PatternStatement
  Table.invert = function()
    tu[#tu] = upper(tu[#tu])
    return Table
  end
  ---characters to possibly match with invert for not match
  ---may have "x\\-y" quintuples for range x to y and "-" for a literal minus
  ---this uses escape activation, not escape passivation
  ---
  ---the fact that \ needs to be written as "\\" in a string then
  ---becomes the most confusing thing about handling matches
  ---
  ---you can always use "-\\" if you need a either on minus or
  ---backslash in the style of commutative grouping in sets
  ---@param chars string
  ---@param invert boolean
  ---@return PatternStatement
  Table.of = function(chars, invert)
    local i = ""
    if invert then
      i = "^"
    end
    --and use the common escape \ to allow a literal minus sign
    --in the includes match
    chars = sane(chars)
    --undo the escape minus activation
    chars = gsub(chars, "\\%%%-", "-")
    insert(tu, "[" .. i .. chars .. "]")
    return Table
  end
  ---merges the last two pattern parts into one
  ---@return PatternStatement
  Table.merge = function()
    local r = remove(tu)
    assert(#tu < 1, "nothing to merge with in pattern")
    tu[#tu] = tu[#tu] .. r
    return Table
  end
  ---adds in a pattern to the previous of()
  ---it is non-sensical to add in an of() to an of()
  ---but not detected
  ---@return PatternStatement
  Table.also = function()
    local r = remove(tu)
    local p = remove(tu)
    if p and p[-1] == "]" then
      insert(tu, sub(p, 1, -1) .. r .. "]")
    else
      assert(false, "can't apply also to an of in pattern")
    end
    return Table
  end
  ---any single character
  ---@return PatternStatement
  Table.any = function()
    insert(tu, ".")
    return Table
  end
  ---a unicode character but beware it will also match
  ---bad formatting in UTF strings
  ---@return PatternStatement
  Table.unicode = function()
    insert(tu, utfp)
    return Table
  end
  ---match an alpha character
  ---@return PatternStatement
  Table.alpha = function()
    insert(tu, "%a")
    return Table
  end
  ---control code match
  ---@return PatternStatement
  Table.control = function()
    insert(tu, "%c")
    return Table
  end
  ---numeric digit match
  ---@return PatternStatement
  Table.digit = function()
    insert(tu, "%d")
    return Table
  end
  ---lower case match
  ---@return PatternStatement
  Table.lower = function()
    insert(tu, "%l")
    return Table
  end
  ---punctuation match
  ---@return PatternStatement
  Table.punc = function()
    insert(tu, "%p")
    return Table
  end
  ---space equivelent match
  ---@return PatternStatement
  Table.whitepace = function()
    insert(tu, "%s")
    return Table
  end
  ---upper case match
  ---@return PatternStatement
  Table.upper = function()
    insert(tu, "%u")
    return Table
  end
  ---alphanumeric match
  ---@return PatternStatement
  Table.alphanum = function()
    insert(tu, "%w")
    return Table
  end
  ---hex digit match
  ---@return PatternStatement
  Table.hex = function()
    insert(tu, "%x")
    return Table
  end
  ---ASCII NUL code match
  ---@return PatternStatement
  Table.nul = function()
    insert(tu, "%z")
    return Table
  end
  ---match between start and stop delimiters
  ---@param start string
  ---@param stop string
  ---@return PatternStatement
  Table.between = function(start, stop)
    insert(tu, "%b" .. start[1] .. stop[1])
    return Table
  end

  ---starts a capture with the last match (postfix)
  ---@return PatternStatement
  Table.mark = function()
    tu[#tu] = "(" .. tu[#tu]
    return Table
  end
  ---ends a capture with the last match (postfix)
  ---@return PatternStatement
  Table.capture = function()
    tu[#tu] = tu[#tu] .. ")"
    return Table
  end
  ---match a previous capture again (ordered by left first is one)
  ---@param num integer
  ---@return PatternStatement
  Table.again = function(num)
    assert(num > 0 and num < 10, "capture number out of range in pattern")
    insert(tu, "%" .. string.char(num + 48))
    return Table
  end

  ---the last match is optional (postfix)
  ---@return PatternStatement
  Table.option = function()
    tu[#tu] = tu[#tu] .. "?"
    return Table
  end
  ---more repeats of the last match (postfix)
  ---the argument "more" is false zero repeats are allowed
  ---of course no repeat, but found, is acceptable as 1 repeat
  ---@param more boolean
  ---@return PatternStatement
  Table.more = function(more)
    if more then
      tu[#tu] = tu[#tu] .. "+"
    else
      tu[#tu] = tu[#tu] .. "*"
    end
    return Table
  end
  ---as few repeats as possible to obtain a match
  ---@return PatternStatement
  Table.less = function()
    tu[#tu] = tu[#tu] .. "-"
    return Table
  end

  return Table
end

local sf = string.format
---encode_url_part
---@param s string
---@return string
_G.encode_url_part = function(s)
  s = gsub(s, "([&=+%c])", function(c)
    return sf("%%%02X", string.byte(c))
  end)
  s = gsub(s, " ", "+")
  return s
end
---decode_url_part
---@param s string
---@return string
_G.decode_url_part = function(s)
  s = gsub(s, "+", " ")
  s = gsub(s, "%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
  return s
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
          -- independance from doris impure things
          insert(s, string.char(13)) -- and null action for chr(10)
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
