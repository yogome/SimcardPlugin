---------------------------------------------- internet
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local network = require( "network" )

local internet = {}
--------------------------------------------- Variables
local isConnected
local initialized
local simulatedLatency
--------------------------------------------- Constants
local hostName = "www.apple.com"
local modeOverride = false
local loopCountCheck = 10000
--------------------------------------------- Functions
local function networkListener(event)
	if event.isReachable then
		isConnected = true
	else
		isConnected = false
	end
end

local function checkInternet()
	network.request("http://"..hostName, "GET", function(event)
		if "ended" == event.phase then
			if not event.isError then
				isConnected = true
			else
				isConnected = false
			end
		end
	end)
end

local function alternateStatusListener()
	logger.log("[Internet] Using alternate status listener.")
		
	local loop = 0
	Runtime:addEventListener("enterFrame", function()
		if loop % loopCountCheck == 0 then
			checkInternet()
			loop = 0
		end
		loop = loop + 1
	end)
end

local function initialize()
	if not initialized then
		initialized = true
		logger.log("[Internet] Initializing internet checker.")
		
		local platformName = system.getInfo("platformName")
		
		if platformName == "Android" or platformName == "Win" or modeOverride then
			alternateStatusListener()
		else
			if network.canDetectNetworkStatusChanges then
				logger.log("[Internet] Will use normal network listener.")
				network.setStatusListener( hostName, networkListener )
			else
				alternateStatusListener()
			end
		end
	end
end
--------------------------------------------- Module functions
function internet.connectionStatus()
	return network.getConnectionStatus()
end

function internet.isConnected()
	return isConnected
end

function internet.setLatency(latencyTime)
	latencyTime = latencyTime or 0
	if not simulatedLatency then
		local networkRequest = network.request
		network.request = function(...)
			local params = {...}
			timer.performWithDelay(simulatedLatency, function()
				networkRequest(unpack(params))
			end)
		end
	end
	simulatedLatency = latencyTime
end

initialize()

return internet


