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
    return "<<<" .. os.shell_quote(str) -- loadstring
  end
  if is_win() then
    str = str:sub(2):gsub("/", "\\")
  end
  return str:match("(.*\\" .. path_separator() .. ")") or ("." .. path_separator())
end

-- os utilities not _G ones
local nv = require("doris.novaride")
os = nv.track(os)

---useful for escaping shell arguments for os.execute()
---@param chars string
---@return string
os.shell_quote = function(chars)
  --use single quote behaviour
  return " '" .. string.gsub(chars, "'", "'\\''") .. "' "
end

---check if a command exists
---@param cmd string
---@return boolean
os.has = function(cmd)
  return not is_win() and os.execute("which " .. cmd) == true
end

os = nv.untrack(os)

novaride.restore()
