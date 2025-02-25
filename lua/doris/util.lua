-- utilities not called directly from "doris"
local novaride = require("doris.novaride").setup()

local function is_win()
  return package.config:sub(1, 1) == "\\"
end

local function path_separator()
  if is_win() then
    return "\\"
  end
  return "/"
end

---get the script path which is slow
---so cache the value in a script if used often
---@return string
_G.script_path = function()
  local str = debug.getinfo(2, "S").source
  if str:sub(1, 1) ~= "@" then
    return "eval: " .. str -- loadstring
  end
  if is_win() then
    str = str:sub(2):gsub("/", "\\")
  end
  return str:match("(.*" .. path_separator() .. ")")
end

---useful for os.execute() of plugin binaries
---"<script_path>/../../" for example
---from "lua/<modname>/<script>.lua"
---@return string
_G.bin_root = function()
  -- from "lua/<modname>/<script>.lua"
  -- to plugin root for binaries and os.execute
  return script_path() .. ".." .. path_separator() .. ".." .. path_separator()
end

-- os utilities not _G ones
local nv = require("doris.novaride")
os = nv.track(os)

---replace double quotes by escaped double quotes only
---then escape $ and add surrounding double quotes
---useful for escaping shell arguments for os.execute()
---@param chars string
---@return string
os.shell_quote = function(chars)
  -- and then there's $ as in os $HOME etc.
  local q = string.gsub(string.gsub(chars, "\\", "\\\\"), '"', '\\"')
  return '"' .. string.gsub(q, "[^\\]%$", "\\$") .. '"'
end

---check if a command exists
---@param cmd string
---@return boolean
os.has = function(cmd)
  return os.execute() == true and os.execute("which " .. cmd) == true
end

os = nv.untrack(os)

novaride.restore()
