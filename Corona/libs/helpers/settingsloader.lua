-------------------------------------------- Colors
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extratable = require( folder.."extratable" )

local settings = {}
-------------------------------------------- Variables
-------------------------------------------- Constants
-------------------------------------------- Functions
-------------------------------------------- Module functions
 
function settings.new()
	local newSettings = {}
	
	local currentMode
	local allSettings = {}
	local defaultSettings
	
	local settingsMetatable = {
		__index = function(tab, key)
			if allSettings[currentMode] and allSettings[currentMode][key] then
				return allSettings[currentMode][key]
			elseif key == "mode" then
				return currentMode
			else
				return defaultSettings[key]
			end
		end,
		__newindex = function(tab, key, value)
			if "table" == type(value) and key == "default" then
				defaultSettings = value
			elseif "table" == type(value) then
				allSettings[key] = value
			elseif key == "mode" and "string" == type(value) and not currentMode then
				currentMode = value
				logger.log("Mode set to "..currentMode)
			end
		end,
		__call  = function( tab, ... )
			local args = {...}
			local lastValue = allSettings[currentMode] or defaultSettings
			if lastValue then
				for index = 1, #args do
					local property = args[index]
					if lastValue[property] then
						lastValue = lastValue[property] 
					else
						return
					end
				end
				return lastValue
			end
		end,
		__metatable = "SETTINGS PROTECT",
	}
	setmetatable(newSettings, settingsMetatable)
	
	return newSettings
end

return settings
