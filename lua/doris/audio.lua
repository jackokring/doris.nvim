-- audio function using C binary "audio"
-- "audio <args> | pw-play --channels=1 -&"
-- <args> can be upto 19 arguments
--
-- this library helps with managing sound

local novaride = require("doris.novaride").setup()

novaride.restore()
