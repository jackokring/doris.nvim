-- audio function using C binary "audio"
-- "audio <args> | pw-play --channels=1 -&"
-- <args> can be upto 19 arguments
--
-- this library helps with managing sound

local novaride = require("doris.novaride").setup()

require("doris.util")
-- cache the binary directory
local path = bin_root()

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
end

novaride.restore()
