-- pure module with no install specifics
-- designed to provide global context programming simplifications
-- everything is independant of nvim
-- NOTE: much useful things
-- many standard library functions are placed in the global _G context
-- this shortens code and I like it so there
-- have a look at some of the things like a regex pattern builder
-- a case statement, some iterator generators
-- and all the UTF to do that kind of thing
local nv = require("novaride").setup()

---blank callback no operation
local nop = function()
  return nop
end
_G.nop = nop
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
---length of string
_G.len = string.len
---get ascii char at
---a surprising lack of [index] for strings
---perhaps it's a parse simplification thing
---@param s string
---@param pos integer
---@return string
_G.at = function(s, pos)
  return sub(s, pos, pos)
end
---utf8 charpattern
_G.utf8pattern = "[\0-\x7F\xC2-\xF4][\x80-\xBF]*"

---pattern compiler (use % for insert of a match specifier)
---in a string that's "%" to substitue the patterns appended
---by .function(args).function(args) ... to the pattern
---to the literal argument finalizing on .compile()
---
---so start with an example literal and then replace
---what to find with "%" and add a .function(args) chain
---for the match kind needed at the "%" point in the
---literal and be less confused about pattern punctuation chaos
---
---use "%" for a literal % using .percent() for a literal percent
---@param lit_pattern string
---@return PatternStatement
_G.pattern = function(lit_pattern)
  ---@class PatternStatement
  local Table = {}
  -- store some data in capture
  local literal = lit_pattern
  local start_f = ""
  local stop_f = ""
  --enhancement
  local tu = {}
  -- state machine
  -- 0 = beginning
  -- 1 = beginning after ^
  -- 2 = match
  -- 3 = % match
  local state = 0
  local marks = 0
  local m_array = {}
  local last = 0
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
    if marks ~= 0 then
      error("mark not captured mismatch", 2)
    end
    if last > 0 and #tu > last then
      error("stop must be last", 2)
    end
    local p = 1
    local u = 1
    literal = sane(literal)
    while true do
      local s, e = find(literal, "%%%%", p)
      if not s then
        break
      else
        local v = tu[u]
        if not v then
          error("not enough arguments for pattern", 2)
        end
        literal = sub(literal, 1, s - 1) .. v .. sub(literal, e + 1)
        u = u + 1
        -- non-recursive application
        p = s + len(v)
      end
    end
    if not tu[u] then
      error("too many arguments for pattern", 2)
    end
    -- turn escaped escape into literal backslash
    return start_f .. literal .. stop_f
  end

  ---start of line match
  ---@return PatternStatement
  Table.start = function()
    if state ~= 0 then
      error("must start at the start", 2)
    end
    state = 1
    start_f = "^"
    return Table
  end
  ---end of line match
  ---@return PatternStatement
  Table.stop = function()
    if last > 0 then
      error("only one stop allowed", 2)
    end
    stop_f = "$"
    last = #tu
    return Table
  end

  ---invert the previous match as a non-match (postfix)
  ---does not work on an of which has its own invert flag
  ---@return PatternStatement
  Table.invert = function()
    if state ~= 3 then
      error("must be a match which can be inverted", 2)
    end
    -- also for %b
    tu[#tu] = "%" .. upper(sub(tu[#tu], 2, 2)) .. sub(tu[#tu], 3)
    state = 2
    return Table
  end
  ---characters to possibly match with invert for not match
  ---all characters are literal including ], ^ and -
  ---@param chars string
  ---@param invert boolean
  ---@return PatternStatement
  Table.of = function(chars, invert)
    local i = ""
    if invert then
      i = "^"
    end
    chars = sane(chars)
    --% activation
    insert(tu, "[" .. i .. chars .. "]")
    state = 2
    return Table
  end
  ---a literal percent %
  ---just so you can place %% in the template and allow one %
  ---to be a literal percent
  ---@return PatternStatement
  Table.percent = function()
    state = 2
    insert(tu, "%%")
    return Table
  end
  ---any single character
  ---@return PatternStatement
  Table.any = function()
    state = 2
    insert(tu, ".")
    return Table
  end
  ---a unicode character but beware it will also match
  ---bad formatting in UTF strings
  ---@return PatternStatement
  Table.unicode = function()
    state = 2
    insert(tu, utf8pattern)
    return Table
  end
  ---match an alpha character
  ---@return PatternStatement
  Table.alpha = function()
    state = 3
    insert(tu, "%a")
    return Table
  end
  ---control code match
  ---@return PatternStatement
  Table.control = function()
    state = 3
    insert(tu, "%c")
    return Table
  end
  ---numeric digit match
  ---@return PatternStatement
  Table.digit = function()
    state = 3
    insert(tu, "%d")
    return Table
  end
  ---lower case match
  ---@return PatternStatement
  Table.lower = function()
    state = 3
    insert(tu, "%l")
    return Table
  end
  ---punctuation match
  ---@return PatternStatement
  Table.punc = function()
    state = 3
    insert(tu, "%p")
    return Table
  end
  ---space equivelent match
  ---@return PatternStatement
  Table.whitespace = function()
    state = 3
    insert(tu, "%s")
    return Table
  end
  ---upper case match
  ---@return PatternStatement
  Table.upper = function()
    state = 3
    insert(tu, "%u")
    return Table
  end
  ---alphanumeric match
  ---@return PatternStatement
  Table.alphanum = function()
    state = 3
    insert(tu, "%w")
    return Table
  end
  ---hex digit match
  ---@return PatternStatement
  Table.hex = function()
    state = 3
    insert(tu, "%x")
    return Table
  end
  ---ASCII NUL code match
  ---@return PatternStatement
  Table.nul = function()
    state = 3
    insert(tu, "%z")
    return Table
  end
  ---match between start and stop delimiters
  ---@param start string
  ---@param stop string
  ---@return PatternStatement
  Table.between = function(start, stop)
    state = 3
    if #start > 1 or #stop > 1 then
      error("between must be between two ASCII characters", 2)
    end
    insert(tu, "%b" .. start[1] .. stop[1])
    return Table
  end

  ---starts a capture with the last match (prefix)
  ---which will become a single % capture match
  ---@return PatternStatement
  Table.mark = function()
    marks = marks + 1
    m_array[marks] = #tu + 1
    return Table
  end
  ---ends a capture with the last match (postfix)
  ---combines the pattern parts from mark to capture
  ---together into one capture % match
  ---@return PatternStatement
  Table.capture = function()
    if marks < 1 then
      error("no matching mark for capture", 2)
    end
    -- find last opened mark
    local m_tu = m_array[marks]
    -- free element primitive
    m_array[marks] = nil
    while #tu ~= m_tu do
      -- combine
      local l = remove(tu)
      tu[#tu] = tu[#tu] .. l
    end
    marks = marks - 1
    tu[#tu] = "(" .. tu[#tu] .. ")"
    return Table
  end
  ---match a previous capture again (ordered by left first is 1)
  ---maximum of 9 can be used again but can have as many
  ---mark/captures as you want
  ---@param num integer
  ---@return PatternStatement
  Table.again = function(num)
    if num < 1 or num > 9 then
      error("capture number out of range in pattern")
    end
    insert(tu, "%" .. string.char(num + 48))
    state = 2
    return Table
  end

  ---the last match is optional (postfix)
  ---@return PatternStatement
  Table.option = function()
    if state < 2 then
      error("option must follow match", 2)
    end
    tu[#tu] = tu[#tu] .. "?"
    state = 1
    return Table
  end
  ---more repeats of the last match (postfix)
  ---the argument "more" is false zero repeats are allowed
  ---of course no repeat, but found, is acceptable as 1 repeat
  ---@param more boolean
  ---@return PatternStatement
  Table.more = function(more)
    if state < 2 then
      error("more must follow match", 2)
    end
    if more then
      tu[#tu] = tu[#tu] .. "+"
    else
      tu[#tu] = tu[#tu] .. "*"
    end
    state = 1
    return Table
  end
  ---as few repeats as possible to obtain a match (postfix)
  ---@return PatternStatement
  Table.less = function()
    if state < 2 then
      error("less must follow match", 2)
    end
    tu[#tu] = tu[#tu] .. "-"
    state = 1
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

---preferred date and time format string
---for use in filenames and sortables
---with no conversion or escape needed
---UTC preferred
---@type string
_G.datetime = "!%Y-%m-%d.%a.%H:%M:%S"
---evaluate source code from a string
---this invert quote(code) and is useful
---with anonymous functions
---@param code string
---@return ...
_G.eval = function(code)
  local ok, err = loadstring("return " .. code)
  if not ok then
    error("error in eval compile: " .. err, 2)
  end
  return ok()
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
    if Table.Functions[testElement] then
      error("duplicate case in switch", 2)
    end
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
  ---@param callback fun(...): nil
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

--olde skool num and chr
_G.byte = string.byte
_G.char = string.char

---get UTF code point number
---@param s string
---@return integer | nil
_G.num = function(s)
  local a, b, c, d = byte(match(s, utf8pattern), 1, -1)
  if a == nil or a < 128 then
    return a
  else
    if b == nil then
      return nil
    end
    a = a - 128 - 64
    if a > 31 then
      if c == nil then
        return nil
      end
      a = a - 32
      if a > 15 then
        if d == nil then
          return nil
        end
        a = a - 16
        return ((a * 64 + (b - 128)) * 64 + (c - 128)) * 64 + (d - 128)
      else
        return (a * 64 + (b - 128)) * 64 + (c - 128)
      end
    else
      return a * 64 + (b - 128)
    end
  end
end

---get UTF char from code point
---@param x integer
---@return string | nil
_G.chr = function(x)
  if x < 0 then
    return nil
  end
  if x < 128 then
    return char(x)
  else
    local c = x % 64
    local s = char(c + 128)
    x = (x - c) / 64
    if x < 32 then
      return char(x + 128 + 64) .. s
    else
      c = x % 64
      s = char(c + 128) .. s
      x = (x - c) / 64
      if x < 16 then
        return char(x + 128 + 64 + 32) .. s
      else
        c = x % 64
        s = char(c + 128) .. s
        x = (x - c) / 64
        if x < 8 then
          return char(x + 128 + 64 + 32 + 16) .. s
        else
          --invalid in modern unicode
          return nil
        end
      end
    end
  end
end

---ranged for by in 1, #n, 1
---@param len integer
---@return fun(iterState: integer, lastIter: integer): integer | nil
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

---iter for by fn(state, iterate)
---more state by explicit closure based on type?
---compare hidden and chain equal to start
---return nil to end iterator
---@param fn fun(hidden: table, ...): ...
---@return fun(hidden: table, ...): ...
---@return table
---@return table
_G.iter = function(fn)
  ---iter next function
  ---@param hidden table
  ---@param ... ...
  ---@return fun(table, ...): ...
  local next = function(hidden, ...)
    -- maybe like the linked list access problem of needing preceding node
    -- the nil node "or" head pointer
    return fn(hidden, ...) --, xtra iter values, ...
  end
  -- mutable private table closure
  local state = {}
  return next, state, state -- jump of point 1st (compare state == state)
end

---return a mapping over a varargs
---@param fn fun(any: ...): ...
---@param ... ...
---@return ...
_G.map = function(fn, ...)
  local r = {}
  -- using ipairs has an until nil on ordered number indexing
  -- has non-deterministic fn calling order but allows nil
  for k, v in pairs({ ... }) do
    r[k] = fn(v)
  end
  return unpack(r)
end

local sk = require("novaride").skip()
---an easy fix for one of lua's most anoying things
---@param table table
---@return fun(table, integer): integer, any
---@return table
---@return integer
_G.ipairs = function(table)
  ---iterator
  ---@param t table
  ---@param i integer
  ---@return integer | nil
  ---@return any
  local iter = function(t, i)
    i = i + 1
    -- NOTE: exit condition is length not a nil
    if i > #t then
      return nil
    end
    local v = t[i]
    --if v then
    return i, v
    --end
  end
  return iter, table, 0
end
sk()

---shallow clone a table, object or class
---otherwise passthrough as likely primitive
---@param t any
---@return any
_G.clone = function(t)
  local ret = {}
  for k, v in pairs(t) do
    ret[k] = v
  end
  local ty = type(t)
  if ty == "userdata" then
    error("userdata cloning is C function specific")
  end
  if ty == "table" then
    if ty == "class" then
      error("classes are singletons", 2) -- class singletons
    end
    return setmetatable(ret, getmetatable(t))
  end
  return t
end

---number format helper
---@param x number
---@param width integer
---@param base string
---@return string
local nf = function(x, width, base)
  width = width or 0
  return sf("%" .. sf("%d", width) .. base, x)
end

---decimal string of number with default C numeric locale
---@param x integer
---@param width integer
---@return string
_G.dec = function(x, width)
  local l = os.setlocale()
  os.setlocale("C", "numeric")
  local s = nf(x, width, "d")
  os.setlocale(l, "numeric")
  return s
end
---hex string of number
---@param x integer
---@param width integer
---@return string
_G.hex = function(x, width)
  return nf(x, width, "x")
end
---scientific string of number with default C numeric locale
---@param x integer
---@param width integer
---@param prec integer
---@return string
_G.sci = function(x, width, prec)
  local l = os.setlocale()
  os.setlocale("C", "numeric")
  -- default size 8 = 6 + #"x."
  local s = nf(x, width, "." .. sf("%d", prec or 6) .. "G")
  os.setlocale(l, "numeric")
  return s
end

_G.upper = string.upper
_G.lower = string.lower
_G.rep = string.rep
_G.reverse = string.reverse
_G.sort = table.sort

---number to string with default C numeric locale
---nil return if can't convert to number
---@param num any
---@return string | nil
_G.str = function(num)
  if type(num) ~= "number" then
    return nil
  end
  local l = os.setlocale()
  os.setlocale("C", "numeric")
  local s = tostring(num)
  os.setlocale(l, "numeric")
  return s
end

---string to number with default C numeric locale
---nil return if not a number
---I'm no fan of number? as a vague type
---@param str string
---@return number | nil
_G.val = function(str)
  local l = os.setlocale()
  os.setlocale("C", "numeric")
  local s = tonumber(str)
  os.setlocale(l, "numeric")
  return s
end

---to number from hex integer value only
---@param str string
---@return integer
_G.val_hex = function(str)
  return tonumber(str, 16)
end

---quote a string escaped (includes beginning and end "\"" literal)
---@param str string
---@return string
_G.quote = function(str)
  return sf("%q", str)
end

-- clean up
nv()
