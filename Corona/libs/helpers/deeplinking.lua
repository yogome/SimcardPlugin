---------------------------------------------- Database
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extrastring = require( folder.."extrastring" )
local extrajson = require( folder.."extrajson" )
local database = require( folder.."database" )
local mime = require( "mime" )

local deeplinking = {}
---------------------------------------------- Variables 
local listeners
local initialized
---------------------------------------------- Local functions
local function initialize()
	if not initialized then
		initialized = true
		listeners = {}
		
		Runtime:addEventListener("system", function(event)
			if event.type and "applicationOpen" == event.type and event.url then
				logger.log("Received url on applicationOpen.")
				deeplinking.check(event.url)
			end
		end)
		
		deeplinking.addEventListener("databaseConfig", function(event)
			if event and event.data then
				local configurationModel = database.getConfigurationModel()
				local newConfig = database.decodeConfig(event.data)
				configurationModel.save(newConfig)
			end
		end)
	end
end

---------------------------------------------- Module functions
function deeplinking.addEventListener(eventName, eventFunction)
	if eventName and "string" == type(eventName) and eventFunction and "function" == type(eventFunction) then
		listeners[eventName] = eventFunction
	end
end

function deeplinking.check(url)
	if url and "string" == type(url) and string.len(url) > 0 then
		local splitUrl = extrastring.split(url, "://")
		if splitUrl and #splitUrl == 2 then -- [1] = deep link name, [2] = custom deep link data
			if splitUrl[2] and "string" == type(splitUrl[2]) and string.len(splitUrl[2]) > 0 then
				logger.log("Received custom data.")
				local customData = extrajson.decodeFixed(mime.unb64(splitUrl[2]))
				
				for index, value in pairs(customData) do
					if listeners[index] then
						listeners[index]({data = value})
					end
				end
			end
		end
	end
end

initialize()

return deeplinking
