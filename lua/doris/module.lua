-- pure module with no install specifics
-- designed to provide global context programming simplifications
-- everything is independant of nvim
local novaride = require("doris.novaride").setup()

---blank callback no operation
_G.nop = function() end
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
_G.utfpat = "[\0-\x7F\xC2-\xF4][\x80-\xBF]*"

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
    stop_f = "$"
    return Table
  end

  ---invert the previous match as a non-match (postfix)
  ---does not work on an "includes" which has its own invert flag
  ---@return PatternStatement
  Table.invert = function()
    if state ~= 3 then
      error("must be a type match to invert", 2)
    end
    tu[#tu] = upper(tu[#tu])
    state = 2
    return Table
  end
  ---characters to possibly match with invert for not match
  ---
  ---you can always use "[-xxx]" if you need a minus
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
    insert(tu, utfpat)
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
  Table.whitepace = function()
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
    state = 2
    insert(tu, "%b" .. start[1] .. stop[1])
    return Table
  end

  ---starts a capture with the last match (postfix)
  ---which will become a single % capture match
  ---@return PatternStatement
  Table.mark = function()
    marks = marks + 1
    tu[#tu] = "(" .. tu[#tu]
    m_array[marks] = marks
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
    tu[#tu] = tu[#tu] .. ")"
    return Table
  end
  ---match a previous capture again (ordered by left first is one)
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
  ---as few repeats as possible to obtain a match
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
_G.datetime = "%Y-%m-%d.%a.%H:%M:%S"
---evaluate source code from a string
---this invert quote(code) and is useful
---with anonymous functions
---@param code string
---@return any
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
---@param fn fun(hidden: any, chain: any): any
---@return fun(hidden: table, chain: any): any
---@return table
---@return table
_G.iter = function(fn)
  ---iter next function
  ---@param hidden table
  ---@param chain any
  ---@return any
  local next = function(hidden, chain)
    -- maybe like the linked list access problem of needing preceding node
    -- the nil node "or" head pointer
    return fn(hidden, chain) --, xtra iter values, ...
  end
  -- mutable private table closure
  local state = {}
  return next, state, state -- jump of point 1st (compare state == state)
end

---convenient wrapper for varargs
---actually consistently defined to allow nil
---as ipairs({ ... }) may terminate on a nil
---@param ... unknown
---@return fun(table: table, integer: integer):integer, any
---@return table
---@return integer
_G.gargs = function(...)
  local next = function(tab, idx)
    local newIdx = idx + 1
    if newIdx > #tab then
      return
    end
    return newIdx, tab[newIdx]
  end
  local tab = {}
  for i = 1, select("#", ...) do
    tab[i] = select(i, ...)
  end
  return next, tab, 0
end

---return a table of the mapping over a varargs
---it seemed a possible waste to not offer
---the intermediate table for processing
---@param fn fun(any: any): any
---@param ... unknown
---@return table
_G.gmapto = function(fn, ...)
  local r = {}
  for _, v in gargs(...) do
    insert(r, fn(v))
  end
  return r
end

---apply function over varargs
---useful for argument sanitation
---@param fn fun(any: any): any
---@param ... unknown
---@return unknown
_G.gmap = function(fn, ...)
  return unpack(gmapto(fn, ...))
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

_G.str = tostring
_G.val = tonumber

---quote a string escaped (includes beginning and end "\"" literal)
---@param str any
---@return string
_G.quote = function(str)
  return sf("%q", str)
end

-- clean up
novaride.restore()
