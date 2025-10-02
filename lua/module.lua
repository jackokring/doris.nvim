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
---string format
_G.format = string.format

---get ascii char at
---a surprising lack of [index] for strings
---perhaps it's a parse simplification thing
---@param s string
---@param pos integer
---@return string
_G.at = function(s, pos)
  return sub(s, pos, pos)
end
string.at = _G.at

---utf8 charpattern
---apparently NUL is not allowed in patterns (%z)
---likely some embedding maybe relies on C library termination of string
_G.utf8pattern = "[\1-\x7F\xC2-\xF4%z][\x80-\xBF]*"

local magic = "^$().[]*+-?"
---make sane split on %
---@param chars string
---@return table
local sane = function(chars)
  local t = {}
  for s in gmatch(chars .. "%", "(.-)%%") do
    for i in range(#magic) do
      local mi = magic:at(i)
      local r = "%" .. mi
      -- ironic match
      s = gsub(s, mi, r)
    end
    insert(t, s)
  end
  return t
end

---so a bit like format, but puts a pattern item at every %
---@alias asval string
---@overload fun(s: string, ...: asval): string
local as = setmetatable({}, {
  __call = function(s, ...)
    local r = ""
    local t = sane(s)
    local p = { ... }
    -- then just % handling
    for i, v in ipairs(t) do
      r = r .. v
      if i == #t then
        break
      end
      r = r .. p[i]
    end
    -- then return
    return r
  end,
})

---literal percent
---@type asval
as.percent = "%%"
---@type asval
as.first = "^"
---@type asval
as.last = "$"

---regular classes
---@type asval
as.any = "."
---@type asval
as.letter = "%a"
---@type asval
as.control = "%c"
---@type asval
as.digit = "%d"
---@type asval
as.lower = "%l"
---@type asval
as.punct = "%p"
---@type asval
as.space = "%s"
---@type asval
as.upper = "%u"
---@type asval
as.alphanum = "%w"
---@type asval
as.hex = "%x"
---@type asval
as.nul = "%z"

---@type fun(s: asval): asval
as.compl = function(s)
  if s:at(1) == "%" then
    return "%" .. s:at(2):upper()
  end
  if s:at(1) == "[" then
    return "[^" .. s:sub(2, -1)
  end
  error("only character sets or classes maybe complemented", 2)
end

---@type fun(...: asval): asval
local collect = function(...)
  local t = { ... }
  local s = ""
  for _, v in ipairs(t) do
    s = s .. v
  end
  return s
end

---@type fun(...: asval): asval
as.set = function(...)
  -- special minus handling as seems more rational
  local t = collect(...)
  t = gsub(t, "%-", "%-")
  t = gsub(t, "%^", "%^")
  return "[" .. t .. "]"
end

---@type fun(...: asval): asval
as.capture = function(...)
  return "(" .. collect(...) .. ")"
end

---@type fun(i: integer): asval
as.captured = function(i)
  if i < 1 and i > 9 then
    error("only capture 1 to 9 supported", 2)
  end
  return "%" .. tostring(i):at(1)
end

---@type fun(s: asval): asval
as.short = function(s)
  return s .. "-"
end

---@type fun(s: asval): asval
as.long = function(s)
  return s .. "*"
end

---@type fun(s: asval): asval
as.some = function(s)
  return s .. "+"
end

---@type fun(s: asval): asval
as.option = function(s)
  return s .. "?"
end

_G.as = as

---encode_url_part
---@param s string
---@return string
_G.encode_url_part = function(s)
  s = gsub(s, "([&=+%c])", function(c)
    return format("%%%02X", byte(c))
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
    return char(tonumber(h, 16))
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
---@return any ...
_G.eval = function(code)
  local ok, err = loadstring("return " .. code)
  if not ok then
    error("error in eval: " .. err, 2)
  end
  return ok()
end

---simplified table case
---@param t table
---@param k any
---@return any ...
_G.case = function(t, k, ...)
  local v = t[k]
  local ty = type(v)
  if ty == "function" then
    return v(t, k, ...)
  end
  if ty == "object" or ty == "class" then
    --a self named method
    local vt = v[t]
    if type(vt) == "function" then
      return v:vt(t, k, ...)
    end
  end
  if ty == "table" then
    return v[k], ...
  end
  return v, ...
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
---@return fun(iterState: integer, lastIter: integer): integer?
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

---return a mapping over a varargs
---@param fn fun(val: any): any
---@param ... any
---@return any ...
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
  ---@return integer?
  ---@return any?
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

---number format helper
---@param x number
---@param width integer
---@param base string
---@return string
local nf = function(x, width, base)
  width = width or 0
  return format("%" .. format("%d", width) .. base, x)
end

---locale wrap helper
---@param fn fun(): any
local inc = function(fn)
  local l = os.setlocale()
  os.setlocale("C", "numeric")
  local ret = fn()
  os.setlocale(l, "numeric")
  return ret
end

---decimal string of number with default C numeric locale
---@param x integer
---@param width integer
---@return string
_G.dec = function(x, width)
  return inc(function()
    return nf(x, width, "d")
  end)
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
  -- default size 8 = 6 + #"x."
  return inc(function()
    return nf(x, width, "." .. format("%d", prec or 6) .. "G")
  end)
end

_G.upper = string.upper
_G.lower = string.lower
_G.rep = string.rep
_G.reverse = string.reverse
_G.sort = table.sort

---number to string with default C numeric locale
---nil return if can't convert to number
---@param num any
---@return string?
_G.str = function(num)
  if type(num) ~= "number" then
    return nil
  end
  return inc(function()
    return tostring(num)
  end)
end

---string to number with default C numeric locale
---nil return if not a number
---I'm no fan of number? as a vague type
---@param str string
---@return number?
_G.val = function(str)
  return inc(function()
    return tonumber(str)
  end)
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
  return format("%q", str)
end

-- clean up
nv()
