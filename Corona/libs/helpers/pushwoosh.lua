-------------------------------------------- Pushwoosh - Push and local notification system - (c) Basilio Germán
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger") 
local extratime = require(folder.."extratime")
local database = require(folder.."database")
local mixpanel = require(folder.."mixpanel")
local extratable = require(folder.."extratable")
local localization = require(folder.."localization")
local offlinequeue = require(folder.."offlinequeue")
local crypto = require("crypto")
local json = require("json") 

local pushwoosh = {}
-------------------------------------------- Variables
local notifications 
local initialized 
local pushwooshID
local remoteListener, localListener
local scheduledNotifications
local simulatorAlert, simulatedNotificationsTimer
-------------------------------------------- Constants
local TAG_OFFLINEQUEUE = "pushwooshRegister"
local KEY_LOCAL_NOTIFICATIONS = "notificationsLocal" 
local KEY_ORIGINAL_SCHEDULE_TIME = "notificationsTimeRegistered"
local KEY_POPUP_NOTIFICATIONS = "popupNotifications"
local KEY_HIDE_ALERT = "pushwooshHideSimulatorAlert"

local MINUTE_SECONDS = 60
local HOUR_SECONDS = MINUTE_SECONDS * 60
local DAY_SECONDS = HOUR_SECONDS * 24 
local DEFAULT_NOTIFICATION_DAY = 1
local DEFAULT_NOTIFICATION_HOUR = 9
local DEFAULT_NOTIFICATION_MINUTE = 30

local TYPE_DEVICE_IOS = 1
local TYPE_DEVICE_ANDROID = 3
local ENVIRONMENT = system.getInfo("environment")
local HOST_REGISTER = "https://cp.pushwoosh.com/json/1.3/registerDevice"
-------------------------------------------- Functions 
local function registerDevice(event)
	logger.log("Registering for remote push notifications.")
	local pushToken = event.token
	database.config("pushToken", pushToken)
	mixpanel.setPushToken(pushToken)

	local deviceType = system.getInfo("platformName") == "Android" and TYPE_DEVICE_ANDROID or TYPE_DEVICE_IOS

	local luaBody = {
		request = {
			["application"] = pushwooshID,
			["push_token"] = pushToken,
			["language"] = localization.getLanguage(),
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

	offlinequeue.request(HOST_REGISTER, "POST", params, TAG_OFFLINEQUEUE)
end

local function initialize()
	local success, message = pcall(function()
		notifications = require( "plugin.notifications" )
	end)
	
	local notificationPopup = database.config(KEY_POPUP_NOTIFICATIONS)
	if notificationPopup then
		logger.log("Cancelling all notifications")
		pushwoosh.cancelLocalNotifications()
	end
	
	if not success then
		logger.error([[Could not load notification plugin. make sure it is set on build.settings]])
		notifications = {}
		setmetatable(notifications, {
			__index = function()
				return function()
					return true
				end
			end,
			__newindex = function()
				return function()
					return true
				end
			end
		})
	else
		Runtime:addEventListener("notification", pushwoosh.check)
		
		local pushToken = database.config("pushToken")
		if pushToken then
			mixpanel.setPushToken(pushToken)
		end
		
		offlinequeue.addResultListener(TAG_OFFLINEQUEUE, function(event)
			if event.isError then
				logger.error("Push notification registration failed due to a network error!")
			else
				logger.log("Push notification registration was successful.")
			end
		end, {retryOnError = true})
	end
end

local function simulateNotifications(list)
	list = list or {}
	logger.log("Simulating "..tostring(#list).." local notifications with alerts every 5 seconds")
	if #list > 0 then
		simulatedNotificationsTimer = timer.performWithDelay(5000, function(event)
			local notification = list[tonumber(event.count)]
			if simulatorAlert then native.cancelAlert(simulatorAlert) end
			simulatorAlert = native.showAlert("Simulated local notification "..tostring(event.count), notification.text, {"Open"}, function(event)
				-- TODO could use custom data here
				simulatorAlert = nil
			end)
		end, #list)
	end
end
-------------------------------------------- Module functions
function pushwoosh.check(event)
	event = event or {}
	if initialized then
		logger.log("Received "..tostring(event.type).." push notification"..(event.custom and " with custom data" or "")..".")
		local notificationEventParams = {eventType = event.type, applicationState = event.applicationState}

		local badgeNumber = native.getProperty("applicationIconBadgeNumber") or 0

		if event.type == "remoteRegistration" then
			notificationEventParams.token = event.token
			registerDevice(event)
		elseif event.type == "remote" then
			if remoteListener and "function" == type(remoteListener) then
				remoteListener(event)
			end
			if event.badge and event.badge > 0 then 
				native.setProperty( "applicationIconBadgeNumber", event.badge - 1 )
			end
		elseif event.type == "local" then
			if localListener and "function" == type(localListener) then
				localListener(event)
			end
			badgeNumber = badgeNumber - 1
			native.setProperty( "applicationIconBadgeNumber", badgeNumber )
		end
		
		mixpanel.logEvent("notificationReceived", notificationEventParams)
	else
		logger.error("Notification system was not initialized.")
	end
end

function pushwoosh.registerForPushNotifications()
	database.config(KEY_POPUP_NOTIFICATIONS, true)
	if ENVIRONMENT == "simulator" and not database.config(KEY_HIDE_ALERT) then
		if simulatorAlert then native.cancelAlert(simulatorAlert) end
		simulatorAlert = native.showAlert("Push notifications", "Push notification popup simulation", {"Cancel", "OK", "Dont show again"}, function(event)
			if event.index == 3 then
				database.config(KEY_HIDE_ALERT, true)
			end
			simulatorAlert = nil
		end)
	else
		notifications.registerForPushNotifications()
	end
end

function pushwoosh.cancelLocalNotifications()
	database.config(KEY_POPUP_NOTIFICATIONS, true)
	if scheduledNotifications and "table" == type(scheduledNotifications) and not extratable.isEmpty(scheduledNotifications) then
		for index = 1, #scheduledNotifications do
			pushwoosh.cancelNotification(scheduledNotifications[index])
		end
	end
	
	if simulatedNotificationsTimer then
		timer.cancel(simulatedNotificationsTimer)
		simulatedNotificationsTimer = nil
	end

	native.setProperty("applicationIconBadgeNumber", 1)
	native.setProperty("applicationIconBadgeNumber", 0)
	database.config(KEY_LOCAL_NOTIFICATIONS, json.encode({}))
	pushwoosh.cancelNotification()
end

function pushwoosh.cancelNotification(...)
	database.config(KEY_POPUP_NOTIFICATIONS, true)
	return notifications.cancelNotification(...)
end

function pushwoosh.scheduleNotification(...)
	database.config(KEY_POPUP_NOTIFICATIONS, true)
	return notifications.scheduleNotification(...)
end

function pushwoosh.setRemoteListener(listener)
	remoteListener = listener
end

function pushwoosh.setLocalListener(listener)
	localListener = listener
end

function pushwoosh.initialize(pushwooshAppID, params)
	params = params or {}
	if not initialized and pushwooshAppID then
		initialized = true
		pushwooshID = pushwooshAppID
		
		localListener = params.localListener
		remoteListener = params.remoteListener
	end
end

function pushwoosh.testLocalNotification()
	local badgeNumber = native.getProperty("applicationIconBadgeNumber") or 0
	return pushwoosh.scheduleNotification(10, {badge = badgeNumber + 1})
end

function pushwoosh.scheduleNotificationList(list, options)
	list = list or {}
	options = options or {}
	
	local fastNotifications = options.fastNotifications
	if list and "table" == type(list) and not extratable.isEmpty(list) then
		logger.log("Attempting to schedule "..tostring(#list).." local notifications")
		
		if ENVIRONMENT == "simulator" and not database.config(KEY_HIDE_ALERT) then
			if simulatorAlert then native.cancelAlert(simulatorAlert) end
			simulatorAlert = native.showAlert( "Push notifications", "Push notification list popup simulation", {"Cancel", "OK", "Dont show again"}, function(event)
				if event.index == 2 then
					simulateNotifications(list)
				elseif event.index == 3 then
					database.config(KEY_HIDE_ALERT, true)
				end
				simulatorAlert = nil
			end)
		elseif ENVIRONMENT ~= "simulator" then
			local currentLocalDate = os.date("*t")
			local nextDay = extratable.deepcopy(currentLocalDate)
			nextDay.hour, nextDay.min, nextDay.sec = 0, 0, 0

			currentLocalDate = os.time(currentLocalDate)
			nextDay = os.time(nextDay) + DAY_SECONDS
			local nextDayStartSeconds = nextDay - currentLocalDate
			

			local originalScheduleTime = database.config(KEY_ORIGINAL_SCHEDULE_TIME) or currentLocalDate
			database.config(KEY_ORIGINAL_SCHEDULE_TIME, originalScheduleTime)
			
			local timePassedSinceOriginal = currentLocalDate - originalScheduleTime 
			
			local jsonNotificationData = database.config(KEY_LOCAL_NOTIFICATIONS) or ""
			local notificationData = json.decode(jsonNotificationData) or {}
			
			local successfulNotificationsRegistered = 0
			for index = 1, #list do
				local notification = list[index]

				local options = {
					alert = notification.text,
					badge = 1, -- TODO implement, a bit tricky.
					custom = notification.custom or {},
				}
				local scheduledDay = notification.day or DEFAULT_NOTIFICATION_DAY -- Day 0 means tomorrow. Could use -1 for today, but will not guarantee delivery
				local scheduledHour = notification.hour or DEFAULT_NOTIFICATION_HOUR
				local scheduledMinute = notification.minute or DEFAULT_NOTIFICATION_MINUTE

				local notificationString = "d"..scheduledDay.."h"..scheduledHour.."m"..scheduledMinute
				local ourNotificationID = crypto.digest(crypto.md5, notificationString)
				
				if not notificationData[ourNotificationID] then
					database.config(KEY_POPUP_NOTIFICATIONS, true)

					local scheduledTime = nextDayStartSeconds + (scheduledDay * DAY_SECONDS) + (scheduledHour * HOUR_SECONDS) + (scheduledMinute * MINUTE_SECONDS)
					
					if fastNotifications then -- Start on 30 and every 30 seconds
						scheduledTime = index * 30
					end
					
					-- We must adjust time according to the original schedule date
					scheduledTime = scheduledTime - timePassedSinceOriginal
					
					if scheduledTime > 0 then -- Schedule notification only if original schedule date is OK
						logger.debug("Scheduling "..ourNotificationID.." to "..scheduledTime)
						
						local notificationID = notifications.scheduleNotification(scheduledTime, options) or "simulatedNotificationID"
						
						notificationData[ourNotificationID] = true
						scheduledNotifications = scheduledNotifications or {}
						scheduledNotifications[#scheduledNotifications + 1] = notificationID
						successfulNotificationsRegistered = successfulNotificationsRegistered + 1
					end
				end
			end

			if successfulNotificationsRegistered > 0 then
				logger.log("Successfully registered "..successfulNotificationsRegistered.." local notifications")
			end

			database.config(KEY_LOCAL_NOTIFICATIONS, json.encode(notificationData))
		end
	end
end

initialize()

return pushwoosh
