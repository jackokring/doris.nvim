-- audio function using C binary "audio"
-- "audio <args> | pw-play --channels=1 -&"
-- <args> can be upto 19 arguments
--
-- this library helps with managing sound

-- yes, it now does compile time locale to keep code compiling
local novaride = require("doris.novaride").setup()

require("doris.util")
-- cache the binary directory
local path = script_path() .. "../../"
local espeak = os.has("espeak-ng")

---make an oscillator
---@param vol number? volume 1.0 is normal maximum
---@param freq number? frequency 440Hz is 0 with +1 per semitone
---@param filt number? offset from frequency in semitones
---@param volDrift number? volume change per 100% played
---@param freqDrift number? frequency change per 100% played
---@param filtDrift number? filter change per 100% played
---@return Osc
_G.osc = function(vol, freq, filt, volDrift, freqDrift, filtDrift)
  ---@class Osc
  ---@field str string
  Table = {
    str = "",
  }
  Table.str = Table.str .. tostring(vol or "1") .. " "
  Table.str = Table.str .. tostring(freq or "0") .. " "
  Table.str = Table.str .. tostring(filt or "0") .. " "
  Table.str = Table.str .. tostring(volDrift or "0") .. " "
  Table.str = Table.str .. tostring(freqDrift or "0") .. " "
  Table.str = Table.str .. tostring(filtDrift or "0") .. " "
  return Table
end

---play an oscillator setup
---@param length number? length in seconds (maximum 16.0)
---@param baseOsc Osc? the base oscillator
---@param modOsc Osc? apply some modulation (uses relative frequency)
---@param hyperOsc Osc? apply changing modulation (uses relative frequency)
_G.play = function(length, baseOsc, modOsc, hyperOsc)
  -- pw-play has locale sensitive floating representations
  local locale = os.setlocale()
  os.setlocale("", "numeric")
  -- just length
  local p = tostring(length or "1") .. " "
  if baseOsc then
    p = p .. baseOsc.str
    if modOsc then
      p = p .. modOsc.str
      if hyperOsc then
        p = p .. hyperOsc.str
      end
    end
  end
  -- play the things
  os.execute(path .. "audio " .. p .. "|pw-play --channels=1 -&")
  os.setlocale(locale)
end

---use the voice synthesis tool to say something
---@param what string
---@param using? string e.g. en_GB.UTF-8
_G.say = function(what, using)
  if espeak then
    local c = using or os.getenv("LANG") or "en_GB"
    -- strip sub representation such as ".UTF-8"
    c = string.gsub(c, "%..*$", "")
    -- needs - instead of _
    c = string.gsub(c, "_", "-")
    -- and all in lower case
    c = string.lower(c)
    -- check language code (nothing said)
    if not os.execute("espeak-ng -v" .. c .. ' ""') then
      -- looks like it's "english" english then
      c = "en-gb"
    end
    -- someone's going to do something with quotes for speech
    -- and perhaps $VAR, so get an escaped quoted string
    os.execute("espeak-ng -v" .. c .. " " .. os.shell_quote(what) .. "&")
  end
end

novaride.restore()
