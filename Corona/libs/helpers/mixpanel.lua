--------------------------------------------- Mixpanel
local path = ...
local folder = path:match("(.-)[^%.]+$")
local offlinequeue = require(folder.."offlinequeue")
local extrastring = require(folder.."extrastring")
local extratable = require(folder.."extratable")
local logger = require(folder.."logger")
local http = require("socket.http")
local crypto = require( "crypto")
local ltn12 = require("ltn12")
local mime = require("mime")
local json = require("json")

local mixpanel = {}
--------------------------------------------- Variables
local initialized 
local distinctID
local mixpanelToken
local properties
local environment
local pushNotificationToken
local currentEmail
local debugMixpanel

local mixpanelGraphicEvents
local pendingIncrementValues
--------------------------------------------- Constants
local TIMEOUT_ASYNC_EVENT = 2 
local ENDPOINT_EVENTS = "https://api.mixpanel.com/track/"
local ENDPOINT_PROFILES = "https://api.mixpanel.com/engage/"
local FILENAME_MIXPANEL = "mixpanel.txt"
local FILEPATH_MIXPANEL_DISTINCT_ID = system.pathForFile( FILENAME_MIXPANEL, system.DocumentsDirectory )

local SIZE_GRAPHIC_MESSAGES = {width = 400, height = 160}
--------------------------------------------- Functions
local function createShortErrorMessage(fullMessage)
	if fullMessage and "string" == type(fullMessage) and string.len(fullMessage) > 0 then
		return string.match(fullMessage, "%a+%/%a+%..+:%d+:.*")
	end
end

local function createShortStackTrace(fullStackTrace)
	if fullStackTrace and "string" == type(fullStackTrace) and string.len(fullStackTrace) > 0 then
		local extrastring = require( "libs.helpers.extrastring" )

		fullStackTrace = string.gsub(fullStackTrace, "\t", "") -- Remove tabs
		local splitTrace = extrastring.split(fullStackTrace, "\n") -- Split on newlines

		local shortTrace = ""
		for index = 1, #splitTrace do
			local errorLine = string.match(splitTrace[index], "%a+%..+:%d+:+") -- Match lua file and line number
			local errorFunction = string.match(splitTrace[index], "%b''") or "" -- Match anything inside single quotes (Usually a function)
			local errorExplain = string.match(splitTrace[index], "%b()") or "" --  Match anything inside parenthesis (Usually an explanation)
			if errorLine and "string" == type(errorLine) and string.len(errorLine) > 0 then
				shortTrace = shortTrace..errorLine.." "..errorFunction.." "..errorExplain.."\n"
			end
		end
		return shortTrace
	end
end

local function createErrorID(fullStackTrace)
	if fullStackTrace and "string" == type(fullStackTrace) and string.len(fullStackTrace) > 0 then
		local shortTrace = createShortStackTrace(fullStackTrace)
		return string.sub(crypto.digest(crypto.md5, shortTrace ), 1, 8)
	end
end

local function errorListener(event)
	local errorID = createErrorID(event.stackTrace)
	local eventParameters = {
		errorMessage = createShortErrorMessage(event.errorMessage),
		stackTrace = createShortStackTrace(event.stackTrace),
		errorID = errorID,
	}
	logger.log([[Logging error "]]..errorID)
	mixpanel.logEvent("RuntimeError", eventParameters)
	return false
end 

local function rehashGraphicEvents()
	for index = 1, #mixpanelGraphicEvents do
		local graphicEvent = mixpanelGraphicEvents[index]
		if graphicEvent then
			graphicEvent.index = index
		end
	end
end

local function showEvent(eventName, parameters)
	local mixpanelMessageGroup = display.newGroup()
	mixpanelMessageGroup.x = display.screenOriginX
	mixpanelMessageGroup.y = display.screenOriginY + display.viewableContentHeight
	
	local positionY = -#mixpanelMessageGroup * SIZE_GRAPHIC_MESSAGES.height
	
	local background = display.newRect(0,positionY,SIZE_GRAPHIC_MESSAGES.width, SIZE_GRAPHIC_MESSAGES.height)
	background:setFillColor(0)
	background.anchorX, background.anchorY = 0, 1
	mixpanelMessageGroup:insert(background)
	
	local eventString = eventName.."\n"
	if parameters and "table" == type(parameters) and not extratable.isEmpty(parameters) then
		for key, value in pairs(parameters) do
			eventString = eventString..tostring(key).."="..tostring(value).."\n"
		end
	end
	
	local textOptions = {
		text = eventString,
		x = 0,
		y = 0,
		width = SIZE_GRAPHIC_MESSAGES.width,
		height = SIZE_GRAPHIC_MESSAGES.height,
		font = native.systemFont,   
		fontSize = 22,
		align = "left"
	}
	local eventText = display.newText(textOptions)
	eventText.anchorX, eventText.anchorY = 0, 1
	eventText.x, eventText.y = 0, 0
	mixpanelMessageGroup:insert(eventText)
	
	display.getCurrentStage():insert(mixpanelMessageGroup)
	
	local nextIndex = #mixpanelGraphicEvents + 1
	mixpanelMessageGroup.index = nextIndex
	mixpanelGraphicEvents[nextIndex] = mixpanelMessageGroup
	transition.to(mixpanelMessageGroup, {delay = 3500, time = 500, alpha = 0, transition = easing.outQuad, onComplete = function()
		display.remove(mixpanelMessageGroup)
		table.remove(mixpanelGraphicEvents, mixpanelMessageGroup.index)
		rehashGraphicEvents()
	end})
end

local function mergeTables( destination, source )
	for key, value in pairs(source) do
		destination[key] = value
	end
end

local function urlEncode(encodeString)
	if encodeString and type(encodeString) == "string" then
		encodeString = string.gsub (encodeString, "\n", "\r\n")
		encodeString = string.gsub (encodeString, "([^%w ])", function (c)
			return string.format ("%%%02X", string.byte(c))
		end)
		encodeString = string.gsub (encodeString, " ", "+")

	elseif type(encodeString) == "boolean" then
		encodeString = tostring(encodeString)
	end
	return encodeString
end

local function encodeApiData(data)
	local b64string = ""
	local jsonstring = json.encode(data)

	if jsonstring then
		b64string = mime.b64( jsonstring )
		b64string = urlEncode( b64string )
	end
	return b64string
end

local function mergeIncrementValues(incrementValues)
	pendingIncrementValues = pendingIncrementValues or {}
	
	for index, value in pairs(incrementValues) do
		if pendingIncrementValues[index] then
			pendingIncrementValues[index] = pendingIncrementValues[index] + 1
		else
			pendingIncrementValues[index] = value
		end
	end
end

local function createDistinctID()
	local fileObject = io.open( FILEPATH_MIXPANEL_DISTINCT_ID, "r" )
	if fileObject then
		distinctID = fileObject:read( "*a" )
		io.close(fileObject)
		if extrastring.isValidEmail(distinctID) then
			mixpanel.setProfileEmail(distinctID)
		end
	else
		local data = os.time( os.date("!*t") ) ..":".. system.getInfo("architectureInfo") ..":".. math.random()
		distinctID = mime.b64(crypto.digest(crypto.sha256, data, true))
		fileObject = io.open( FILEPATH_MIXPANEL_DISTINCT_ID, "w" )
		fileObject:write( distinctID )
		io.close(fileObject)
	end
	logger.log((extrastring.isValidEmail(distinctID) and "remote " or "local ").."distinctID: "..distinctID)
	native.setSync(FILENAME_MIXPANEL, {iCloudBackup = false})
end

local function createProperties(gameName, gameVersion)
	local platformName = system.getInfo("platformName")

	properties = {
		["mp_lib"] = "coronasdk",
		["lib_version"] = system.getInfo("build"),
		["$os"] = platformName,
		["$model"] = system.getInfo("model"),
		["$os_version"] = system.getInfo("platformVersion"),
		["$screen_height"] = display.pixelHeight,
		["$screen_width"] = display.pixelWidth,
	}
	
	properties["gameName"] = gameName
	properties["$app_version"] = gameVersion

	if platformName == "Android" then
		properties["$os"] = "android"
		properties["$screen_dpi"] = system.getInfo("androidDisplayXDpi")
		properties["$app_version"] = system.getInfo("androidAppVersionCode")
	elseif platformName == "iPhone OS" then
		properties["$manufacturer"] = "Apple"
		properties["$ios_ifa"] = system.getInfo("iosAdvertisingIdentifier") -- TODO this seems to be broken
		properties["$ios_device_model"] = system.getInfo("architectureInfo")
	end
	
	if network.canDetectNetworkStatusChanges then
		local function networkListener( event )
			if properties then
				properties["$wifi"] = event.isReachableViaWiFi
			end
		end
		network.setStatusListener( "api.mixpanel.com", networkListener)
	end
end

local function validateResponse(response)
	if response and string.len(response) > 4 then
		local eventName = [["]]..string.sub(response, 1, -5)..[["]]
		local number = string.sub(response, -3, -3)
		local success = number == "1"
		if success then
			logger.log("Event "..eventName.." was sent successfully.")
		else
			logger.error("Event "..eventName.." was sent, but was unsuccessful.")
			return false
		end
	else
		logger.error("No valid response received.")
		return false
	end
end

local function trackEvent(eventName, parameters, async)
	local finalProperties = {
		token = mixpanelToken,
		time = os.time(),
		distinct_id = distinctID,
	}

	mergeTables( finalProperties, properties )
	if parameters then
		mergeTables( finalProperties, parameters )
	end
	local eventData = {
		event = eventName,
		properties = finalProperties,
	}
	
	local postBody = "ip=1&data="..encodeApiData(eventData)..[[&callback=]]..eventName
	if async then
		offlinequeue.request(ENDPOINT_EVENTS, "POST", {
			headers = {
				["Content-Type"] = "application/x-www-form-urlencoded",
				["Content-Length"] = string.len(postBody),
			},
			body = postBody,
		}, "mixpanelEvent")
	else
		local oldTimeout = http.TIMEOUT
		http.TIMEOUT = TIMEOUT_ASYNC_EVENT
		local response = {}
		local r,c,h = http.request({
				url = ENDPOINT_EVENTS,
				method = "POST",
				headers = {
					["Content-Type"] = "application/x-www-form-urlencoded",
					["Content-Length"] = string.len(postBody),
				},
				source = ltn12.source.string(postBody),
				sink = ltn12.sink.table(response)
		})
		local responseString = response and response[1] or ""
		validateResponse(responseString)
		http.TIMEOUT = oldTimeout
	end
end

local function getPushToken()
	if pushNotificationToken then
		return {tostring(pushNotificationToken)}
	end
end
--------------------------------------------- Module functions
function mixpanel.updateProfile(setValues, incrementValues, setOnceValues, unionValues)
	if distinctID then
		if currentEmail then
			local profileUpdates = {}

			if currentEmail then
				profileUpdates[#profileUpdates + 1] = {
					["$token"] = mixpanelToken,
					["$distinct_id"] = distinctID,
					["$set"] = {
						["$email"] = currentEmail,
					},
				}
			end
			
			local unionTable = extratable.merge({
				["$ios_devices"] = getPushToken(),
				["AppsUsed"] = properties and properties.gameName and {properties.gameName},
			}, unionValues or {})

			profileUpdates[#profileUpdates + 1] = {
				["$token"] = mixpanelToken,
				["$distinct_id"] = distinctID,
				["$union"] = unionTable,
			}
			
			if setOnceValues and "table" == type(setOnceValues) then
				profileUpdates[#profileUpdates + 1] = {
					["$token"] = mixpanelToken,
					["$distinct_id"] = distinctID,
					["$set_once"] = setOnceValues,
				}
			end

			if setValues and "table" == type(setValues) then
				profileUpdates[#profileUpdates + 1] = {
					["$token"] = mixpanelToken,
					["$distinct_id"] = distinctID,
					["$set"] = setValues,
				}
			end

			if incrementValues and "table" == type(incrementValues) then
				mergeIncrementValues(incrementValues)
				profileUpdates[#profileUpdates + 1] = {
					["$token"] = mixpanelToken,
					["$distinct_id"] = distinctID,
					["$add"] = pendingIncrementValues,
				}
				pendingIncrementValues = {}
			end

			local postBody = "ip=1&data="..encodeApiData(profileUpdates)
			offlinequeue.request(ENDPOINT_PROFILES, "POST", {
				headers = {
					["Accept-Encoding"] = "gzip",
					["Content-Type"] = "application/x-www-form-urlencoded"
				},
				body = postBody,
			}, "mixpanelProfile")
		else
			if incrementValues and "table" == type(incrementValues) then
				mergeIncrementValues(incrementValues)
				logger.log("no distinct id, queueing increment values.")
			else
				logger.error("Profile updating is only available for email distinctID's")
			end
		end
	end
end 

function mixpanel.setPushToken(pushToken)
	logger.log("Setting push token to "..pushToken)
	pushNotificationToken = pushToken
end

function mixpanel.resetProfile()
	local results, reason = os.remove( system.pathForFile( FILENAME_MIXPANEL, system.DocumentsDirectory))
	if results then
		logger.log("Profile was reset locally.")
	end
	currentEmail = nil
	createDistinctID()
end

function mixpanel.initialize(token, gameName, gameVersion, debugFlag)
	if not (token and "string" == type(token) and token:len() > 0) then
		error("Token must be a string and not empty.", 3)
	end
	
	if not( not gameName or (gameName and "string" == type(gameName))) then
		error("gameName be a string or nil.", 3)
	end
	
	if not( not gameVersion or (gameVersion and "string" == type(gameVersion))) then
		error("gameVersion be a string or nil.", 3)
	end
	
	debugMixpanel = debugFlag
	
	if not initialized then
		mixpanelGraphicEvents = {}
		initialized = true
		mixpanelToken = token
		environment = system.getInfo("environment"),
		
		createDistinctID()
		createProperties(gameName, gameVersion)
		
		local function mixpanelEventListener(event)
			if event.isError then
				logger.error("Event was not sent.")
			else
				return validateResponse(event.response)
			end
		end
		
		local function mixpanelProfileListener(event)
			if event.isError then
				logger.error("profile update was not sent.")
			else
				if event.response and event.response == "1" then
					logger.log("Profile was updated!")
				else
					logger.error("profile update was sent but was unsuccessful.")
					return false
				end
			end
		end
		
		Runtime:addEventListener( "unhandledError", errorListener)
		offlinequeue.addResultListener("mixpanelEvent", mixpanelEventListener, true)
		offlinequeue.addResultListener("mixpanelProfile", mixpanelProfileListener, true)
		
		logger.log("Initialized successfully")
	end
end

function mixpanel.logEvent(eventName, parameters, async)
	async = async == nil or async == true or false
	if not( eventName and "string" == type(eventName)) then
		error("eventName must be a string", 3)
	end
	
	if initialized then
		logger.log("Logging event: "..eventName)
		if "device" == environment or debugMixpanel then
			trackEvent(eventName, parameters, async)
			if debugMixpanel == "graphic" then
				showEvent(eventName, parameters)
			end
		end
	else
		logger.error("You must initialize mixpanel first!")
	end
end

function mixpanel.setProfileEmail(email)
	if initialized then
		if email and extrastring.isValidEmail(email) then
			
			currentEmail = email
			distinctID = email
			
			local fileObject = io.open( FILEPATH_MIXPANEL_DISTINCT_ID, "w" )
			fileObject:write( distinctID )
			io.close( fileObject )
			
			-- Mixpanel date format YYYY-MM-DDThh:mm:ss
			local currentUTCDate = os.date("!*t")
			local dateCreatedString = string.format("%04d-%02d-%02dT%02d:%02d:%02d", currentUTCDate.year, currentUTCDate.month, currentUTCDate.day, currentUTCDate.hour, currentUTCDate.min, currentUTCDate.sec)
			mixpanel.updateProfile(nil, nil, {dateCreated = dateCreatedString})
		else
			logger.error("A valid email was not provided!")
		end
	else
		logger.error("You must initialize mixpanel first!")
	end
end
--------------------------------------------- Execution
return mixpanel
