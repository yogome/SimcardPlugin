-------------------------------------------- Notification service
local extratime = require( "libs.helpers.extratime" )
local database = require( "libs.helpers.database" )
local logger = require( "libs.helpers.logger" )
local settings = require( "settings" )
local json = require("json") 

local notifications = {}
-------------------------------------------- Variables
local visualNotificationCount 
-------------------------------------------- Constants
local TYPE_DEVICE_IOS = 1
local TYPE_DEVICE_ANDROID = 3
-------------------------------------------- Functions 
-------------------------------------------- Module functions
function notifications.check(event)
	logger.log("[Notification] Received "..tostring(event.type).." push notification.")
	visualNotificationCount = 0
	
	if event.type == "remoteRegistration" then
		local pushToken = event.token
		database.config("pushToken", pushToken)
		
		local deviceType = TYPE_DEVICE_IOS
		if system.getInfo("platformName") == "Android" then
			deviceType = TYPE_DEVICE_ANDROID
		end

		local function networkListener( event )
			if event.isError then
				logger.error("[Notification] Push notification registration failed due to a network error!")
			else
				logger.log("[Notification] Push notification registration was successful.")
			end
		end    

		local luaBody = {
			request = {
				["application"] = settings.pushWooshID,
				["push_token"] = pushToken,
				["language"] = database.config("language") or "en",
				["hwid"] = system.getInfo("deviceID"),
				["timezone"] = extratime.getTimezone(),
				["device_type"] = deviceType,
			}
		}

		local headers = {
			["Content-Type"] = "application/json",
			["Accept-Language"] = "en-US"
		}

		local params = {
			headers = headers,
			body = json.encode(luaBody)
		}

		network.request ( settings.pushWooshRegisterHostname, "POST", networkListener, params )
	end
	
	if event.custom then

	end
	
	if event.type then
	end
end

return notifications
