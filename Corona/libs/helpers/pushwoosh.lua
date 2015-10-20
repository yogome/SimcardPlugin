-------------------------------------------- Pushwoosh
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local extratime = require( folder.."extratime" )
local database = require( folder.."database" )
local mixpanel = require( folder.."mixpanel" )
local extratable = require( folder.."extratable" )
local localization = require( folder.."localization" )
local crypto = require("crypto")
local json = require("json") 

local pushwoosh = {}
-------------------------------------------- Variables
local notifications 
local initialized 
local pushwooshID
local remoteListener, localListener
local scheduledNotifications
-------------------------------------------- Constants
local KEY_LOCAL_NOTIFICATIONS = "notificationsLocal" 
local KEY_POPUP_NOTIFICATIONS = "popupNotifications"

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
	logger.log("[Notification] Registering for remote push notifications.")
	local pushToken = event.token
	database.config("pushToken", pushToken)
	mixpanel.setPushToken(pushToken)

	local deviceType = system.getInfo("platformName") == "Android" and TYPE_DEVICE_ANDROID or TYPE_DEVICE_IOS

	local function networkListener( event )
		if event.isError then
			logger.error("[Notification] Push notification registration failed due to a network error!")
		else
			logger.log("[Notification] Push notification registration was successful.")
		end
	end    

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

	network.request(HOST_REGISTER, "POST", networkListener, params )
end

local function initialize()
	local success, message = pcall(function()
		notifications = require( "plugin.notifications" )
	end)
	
	local notificationPopup = database.config(KEY_POPUP_NOTIFICATIONS)
	if notificationPopup then
		logger.log("[Pushwoosh] Cancelling all notifications")
		pushwoosh.cancelLocalNotifications()
	end
	
	if not success then
		logger.error([[[Pushwoosh] Could not load notification plugin. make sure it is set on build.settings]])
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
	end
end
-------------------------------------------- Module functions
function pushwoosh.check(event)
	event = event or {}
	if initialized then
		logger.log("[Notification] Received "..tostring(event.type).." push notification.")
		mixpanel.logEvent("notificationReceived", {eventType = event.type, applicationState = event.applicationState})

		local badgeNumber = native.getProperty("applicationIconBadgeNumber") or 0

		if event.type == "remoteRegistration" then
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
	else
		logger.error("[Pushwoosh] Notification system was not initialized.")
	end
end

function pushwoosh.registerForPushNotifications()
	database.config(KEY_POPUP_NOTIFICATIONS, true)
	if ENVIRONMENT == "simulator" then
		local alert = native.showAlert( "Push notifications", "Push notification popup simulation", {"Cancel", "OK"})
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

	native.setProperty( "applicationIconBadgeNumber", 1)
	native.setProperty( "applicationIconBadgeNumber", 0)
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

function pushwoosh.scheduleNotificationList(list)
	list = list or {}
	if list and "table" == type(list) and not extratable.isEmpty(list) then
		if ENVIRONMENT == "simulator" then
			local alert = native.showAlert( "Push notifications", "Push notification list popup simulation", {"Cancel", "OK"})
		else
			local currentLocalDate = os.date("*t")
			local nextDay = extratable.deepcopy(currentLocalDate)
			nextDay.hour, nextDay.min, nextDay.sec = 0, 0, 0

			currentLocalDate = os.time(currentLocalDate)
			nextDay = os.time(nextDay) + DAY_SECONDS
			local nextDayStartSeconds = nextDay - currentLocalDate

			local jsonNotificationData = database.config(KEY_LOCAL_NOTIFICATIONS) or ""
			local notificationData = json.decode(jsonNotificationData) or {}

			local successfulNotificationsRegistered = 0
			for index = 1, #list do
				local notification = list[index]

				local options = {
					alert = notification.text,
					badge = 1,
				}
				local scheduledDay = notification.day or DEFAULT_NOTIFICATION_DAY
				local scheduledHour = notification.hour or DEFAULT_NOTIFICATION_HOUR
				local scheduledMinute = notification.minute or DEFAULT_NOTIFICATION_MINUTE

				local notificationString = "d"..scheduledDay.."h"..scheduledHour.."m"..scheduledMinute
				local ourNotificationID = crypto.digest(crypto.md5, notificationString)

				if not notificationData[ourNotificationID] then
					database.config(KEY_POPUP_NOTIFICATIONS, true)

					local scheduledTime = nextDayStartSeconds + (scheduledDay * DAY_SECONDS) + (scheduledHour * HOUR_SECONDS) + (scheduledMinute * MINUTE_SECONDS)
					local notificationID = notifications.scheduleNotification(scheduledTime, options) or "simulatedNotificationID"

					notificationData[ourNotificationID] = true
					scheduledNotifications = scheduledNotifications or {}
					scheduledNotifications[#scheduledNotifications + 1] = notificationID
					successfulNotificationsRegistered = successfulNotificationsRegistered + 1
				end
			end

			if successfulNotificationsRegistered > 0 then
				logger.log("[Pushwoosh] Successfully registered "..successfulNotificationsRegistered.." local notifications")
			end

			database.config(KEY_LOCAL_NOTIFICATIONS, json.encode(notificationData))
		end
	end
end

initialize()

return pushwoosh
