----------------------------------------------- Extra facebook
local path = ...
local folder = path:match("(.-)[^%.]+$")
local database = require( folder.."database" ) 
local logger = require( folder.."logger" ) 
local json = require( "json" )

local extraFacebook = {}
----------------------------------------------- Variables
local facebook 
local fbAppID
local initialized
local canPublish
local dialogOnComplete, shareImageOnComplete
local onLoginSuccess, onLogoutSuccess
local environment
local canPublishCheck
----------------------------------------------- Constants
local TEXT_FACEBOOK_SIMULATOR = "Facebook event simulation"
local DBKEY_TOKEN = "FBToken"
local DBKEY_TOKEN_EXPIRATION = "FBTokenExpiration"
local DBKEY_CAN_PUBLISH = "FBCanPublish"
local DBKEY_EMAIL = "FBUserEmail"
local DBKEY_USERID = "FBUserID"
----------------------------------------------- Functions
local function checkUserData()
	if not database.config(DBKEY_EMAIL) then
		facebook.request("me")
	end
end

local function facebookListener(event)
	local jsonEvent = json.encode(event)
	logger.log(jsonEvent)
	if event.isError then
		if event.phase == "loginFailed" then -- Login failed
			database.config(DBKEY_TOKEN, false)
			database.config(DBKEY_TOKEN_EXPIRATION, 0)
			onLoginSuccess = nil
			canPublishCheck = false
		end
		
		if event.type == "dialog" then
			if dialogOnComplete and "function" == type(dialogOnComplete) then
				event.success = false
				local completeFunction = dialogOnComplete
				dialogOnComplete = nil
				completeFunction(event)
			end
		elseif event.type == "request" then
			if shareImageOnComplete and "function" == type(shareImageOnComplete) then 
				event.success = false
				local completeFunction = shareImageOnComplete
				shareImageOnComplete = nil
				completeFunction(event)
			end
		end
	else
		if event.type == "dialog" then
			event.success = string.find(event.response, "?post_id=") or false
			if dialogOnComplete and "function" == type(dialogOnComplete) then
				local completeFunction = dialogOnComplete
				dialogOnComplete = nil
				completeFunction(event)
			end
			checkUserData()
		elseif event.type == "session" then
			if event.phase == "login" then
				logger.log("Login was successful")
				
				database.config(DBKEY_TOKEN, event.token)
				database.config(DBKEY_TOKEN_EXPIRATION, event.expiration)
				
				if canPublishCheck then
					canPublishCheck = false
					canPublish = true
					database.config(DBKEY_CAN_PUBLISH, true)
				end
				
				if onLoginSuccess and "function" == type(onLoginSuccess) then
					local successFunction = onLoginSuccess
					onLoginSuccess = nil
					successFunction(event)
				end				
			elseif event.phase == "logout" then
				database.config(DBKEY_TOKEN, false)
				database.config(DBKEY_TOKEN_EXPIRATION, 0)
				canPublish = false
				database.config(DBKEY_CAN_PUBLISH, false)
					
				if onLogoutSuccess and "function" == type(onLogoutSuccess) then
					onLogoutSuccess(event)
					onLogoutSuccess = nil
				end
			end
		elseif event.type == "request" then
			if event.response and "string" == type(event.response) then
				local luaResponse = json.decode(event.response)
				if luaResponse and "table" == type(luaResponse) then
					if luaResponse.email then
						database.config(DBKEY_EMAIL, luaResponse.email)
						database.config(DBKEY_USERID, luaResponse.id)
					elseif luaResponse.post_id then
						if shareImageOnComplete and "function" == type(shareImageOnComplete) then 
							event.success = true
							local completeFunction = shareImageOnComplete
							shareImageOnComplete = nil
							completeFunction(event)
						end
						checkUserData()
					end
				end
			end
		else

		end
	end
end

local function initialize()
	local success, message = pcall(function()
		facebook = require("facebook")
	end)
	
	if not success then
		logger.error([[Could not load plugin. make sure it is specified on build.settings]])
		facebook = {}
		setmetatable(facebook, {
			__index = function()
				return function()
					logger.error([[Facebook plugin not installed. Add in build.settings!]])
					return true
				end
			end,
			__newindex = function()
				return function()
					logger.error([[Facebook plugin not installed. Add in build.settings!]])
					return true
				end
			end
		})
	end
end
----------------------------------------------- Module functions
function extraFacebook.login(onSuccess)
	if fbAppID and initialized then
		logger.log("Logging in")
		facebook.login(fbAppID, facebookListener, {"email"})

		onLoginSuccess = onSuccess or function()
			checkUserData()
		end
	end
end

function extraFacebook.isValidLogin()
	local tokenExpiration = database.config(DBKEY_TOKEN_EXPIRATION) or 0
	local validLogin = ((tokenExpiration - os.time()) > 0) and database.config(DBKEY_TOKEN)
	return validLogin
end

function extraFacebook.getUserData()
	
	local userData = {
		email = database.config(DBKEY_EMAIL),
		id = database.config(DBKEY_USERID),
	}
	
	return userData
end

function extraFacebook.initialize(appID, login)
	if not initialized then
		initialized = true
		fbAppID = appID
		logger.log("Initializing, setting appID to "..appID)
		environment = system.getInfo( "environment" )
		
		canPublishCheck = false
		canPublish = database.config(DBKEY_CAN_PUBLISH) or false
		
		facebook.publishInstall(appID)
		
		if login or extraFacebook.isValidLogin() then
			extraFacebook.login()
		end
	end
end

function extraFacebook.shareImage(shareOptions, onComplete) -- TODO check system on resume to see if user loaded page
	if fbAppID and initialized then
		shareOptions = shareOptions or {}

		local message = shareOptions.message or ""
		local baseDir = shareOptions.baseDir or system.DocumentsDirectory
		local filename = shareOptions.filename

		local attachment = {
			message = message,
			source = {
				baseDir = baseDir,
				filename = filename,
				type = "image",
			}
		}
				
		local function sendImage()			
			local function postImage()
				shareImageOnComplete = function(event)
					timer.performWithDelay(50, function()
						native.setActivityIndicator(false)
						if onComplete and "function" == type(onComplete) then
							onComplete(event)
						end
					end)
				end
				facebook.request( "me/photos", "POST", attachment )
			end

			if canPublish then
				postImage()
			else
				timer.performWithDelay(10, function() -- FB listener gets messed up when calling a login after a previous one was completed.
					canPublishCheck = true
					onLoginSuccess = postImage
					facebook.login(fbAppID, facebookListener, {"publish_actions"})
				end)
			end
		end
		
		native.setActivityIndicator(true)
		if extraFacebook.isValidLogin() then
			sendImage()
		else
			extraFacebook.login(sendImage)
		end
	end
end

function extraFacebook.postMessage(postOptions, onComplete)
	if fbAppID and initialized then
		postOptions = postOptions or {}
		local options = {
			link = postOptions.link,
			picture = postOptions.picture,
			name = postOptions.name,
			caption = postOptions.caption,
			description = postOptions.description,
		}
			
		local function sendMessage()
			dialogOnComplete = onComplete
			facebook.showDialog( "feed", options)
		end
		
		if environment == "simulator" then
			local alert = native.showAlert( "Facebook test", options.name or TEXT_FACEBOOK_SIMULATOR, { "Cancel", "Share" }, function(event)
				if "clicked" == event.action then
					if dialogOnComplete then dialogOnComplete({success = event.index == 2}) end
				end
			end)
		else
			if extraFacebook.isValidLogin() then
				sendMessage()
			else
				extraFacebook.login(sendMessage)
			end
		end
	else
		logger.error("You must call initialize with a valid appID first!")
	end
end

function extraFacebook.logout()
	if fbAppID then
		facebook.logout()
	end
end

initialize()

return extraFacebook


