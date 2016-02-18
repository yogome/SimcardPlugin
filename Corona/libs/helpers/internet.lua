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
local dispatcher
--------------------------------------------- Constants
local HOSTNAME_1 = "www.apple.com"
local HOSTNAME_2 = "www.google.com"
local modeOverride = false
local loopCountCheck = 10000
local connectedTimer
local DELAY_ENABLE = 500
--------------------------------------------- Functions
local function networkListener(event)
	if connectedTimer then
		timer.cancel(connectedTimer)
	end
	if event.isReachable and (event.isReachableViaWiFi or event.isReachableViaCellular) then
		connectedTimer = timer.performWithDelay(DELAY_ENABLE, function()
			isConnected = true
			dispatcher:dispatchEvent({name = "onChange", isConnected = isConnected})
		end)
	else
		isConnected = false
		dispatcher:dispatchEvent({name = "onChange", isConnected = isConnected})
	end
end

local function checkInternet()
	network.request("http://"..HOSTNAME_1, "GET", function(event)
		if "ended" == event.phase then
			if not event.isError then
				isConnected = true
			else
				isConnected = false
			end
			dispatcher:dispatchEvent({name = "onChange", isConnected = isConnected})
		end
	end)
end

local function alternateStatusListener()
	logger.log("Using alternate status listener.")
		
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
		logger.log("Initializing internet checker.")
		
		dispatcher = Runtime._super:new()
		
		local platformName = system.getInfo("platformName")
		
		if platformName == "Android" or platformName == "Win" or modeOverride then
			alternateStatusListener()
		else
			if network.canDetectNetworkStatusChanges then
				logger.log("Will use normal network listener.")
				network.setStatusListener( HOSTNAME_1, networkListener )
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

function internet.addChangeListener(onChange)
	dispatcher:addEventListener("onChange", onChange)
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


