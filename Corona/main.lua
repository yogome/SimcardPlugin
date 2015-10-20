------------------------------------------------ Main
local director = require( "libs.helpers.director" )
local logger = require( "libs.helpers.logger" )
local database = require( "libs.helpers.database" )
local protector = require( "libs.helpers.protector" )
local keyboard = require( "libs.helpers.keyboard" )
local music = require( "libs.helpers.music" )
local sound = require( "libs.helpers.sound" )
local sceneloader = require( "libs.helpers.sceneloader" )
local dialog = require( "libs.helpers.dialog" )
local musiclist = require( "data.musiclist" )
local soundlist = require( "data.soundlist" )
local scenelist = require( "data.scenelist" )
local settings = require( "settings" )
local minigamesManager = require( "scenes.minigames.manager" )
local players = require( "models.players" )
local internet = require( "libs.helpers.internet" )
local notificationService = require( "services.notification" )
local eventCounter = require( "libs.helpers.eventcounter" )
local localization = require( "libs.helpers.localization" )
local testMenu = require( "libs.helpers.testmenu" )
local testActions = require( "data.testactions" )
local extrafile = require( "libs.helpers.extrafile" )
local json = require("json")
local subscription = require("services.subscription")
local plugin = require "plugin.simcard"
global_isSubscribed = false

local launchArgs = ... 
----------------------------------------------- Constants
----------------------------------------------- Local functions
-- local function onKeyEvent( event )
-- 	local handled = false
-- 	local phase = event.phase
-- 	local keyName = event.keyName

-- 	if "back" == keyName and phase == "up" then
-- 		local sceneName = director.getSceneName("overlay")
-- 		if not sceneName then sceneName = director.getSceneName("current") end
-- 		local currentScene = director.getScene(sceneName)
-- 		if not currentScene then
-- 			logger.log("[Main] No current scene found!")
-- 			sceneName = director.getSceneName("previous")
-- 			if sceneName then
-- 				director.gotoScene(sceneName)
-- 			end
-- 		else
-- 			if currentScene.backAction ~= nil and type(currentScene.backAction) == "function" then
-- 				handled = currentScene.backAction()
-- 			end
-- 		end
		
-- 	end
-- 	return handled
-- end 

local function setupLanguage()
	local localizationParams = {
		dataPath = settings.languagesDataPath,
	}
	localization.initialize(localizationParams)
	localization.setLanguage("es")
	logger.log([[[Main] Language is set to "]]..localization.getLanguage()..[[".]])
end

local function setupMusic()
	music.setTracks(musiclist)
	local musicEnabled = database.config( "music" )
	if musicEnabled == nil then
		musicEnabled = true
		database.config( "music", musicEnabled )
	end
	logger.log([[[Main] Music is set to "]]..tostring(musicEnabled)..[[".]])
	music.setEnabled(musicEnabled, true)
end

local function setupSound()
	sound.loadDirectory(settings.soundlistPath)
	logger.log([[[Main] Sound is set to "]]..tostring(sound.isEnabled())..[[".]])
end

local function increaseTimesRan()
	local timesRan = database.config("timesRan") or 0
	timesRan = timesRan + 1
	database.config("timesRan", timesRan)
	logger.log("[Main] Times ran: "..timesRan)
	return timesRan
end

local function setupKeyboard()
	keyboard:setSoundFunction(function()
		sound.play(settings.keySound)
	end)
end

local function initializeDatabase()
	
end

local function checkSecurity()
	if settings.databaseChecksum then
		if not database.compareChecksum() then
			timer.performWithDelay(500, function()
				local alertOptions = {
					text = "Database was corrupt, will erase all database content.",
					time = 3000,
				}
				dialog.newAlert(alertOptions)
			end)
			logger.error("[Main] Database checksum does not match or is inexistent.")
			database.delete()
			initializeDatabase()
		else
			logger.log("[Main] Security check OK.")
		end
	else
		logger.log("[Main] Skipping security check.")
	end
end

local function errorListener( event )
	logger.error("[Main] There was an error: "..(event.errorMessage or "Unknown error")..": "..(event.stackTrace or "No trace"))
	director.gotoScene( "scenes.menus.home", { effect = "fade", time = 800} )
    return true
end

local function notificationListener( event )
	native.setProperty( "applicationIconBadgeNumber", 1)
	native.setProperty( "applicationIconBadgeNumber", 0)
	system.cancelNotification()
	if event then
		notificationService.check(event)
	end
end

local function loadScenes()
	if settings.autoLoadScenes then
		sceneloader.loadScenes(scenelist.menus)
		sceneloader.loadScenes(scenelist.game)
	end
end

local function loadTestActions()
	for index = 1, #testActions do
		testMenu.addButton(unpack(testActions[index]))
	end
end

local function initialize()
	extrafile.cacheFileSystem()
	protector.enabled = settings.enableProtector
	logger.enabled = settings.enableLog
	display.setDefault( "minTextureFilter", "nearest" )
	logger.log("[Main] Initializing game...")
	display.setStatusBar( display.HiddenStatusBar )
	math.randomseed( os.time() )
	system.setIdleTimer( false )
	initializeDatabase()
	eventCounter.initialize()
	Runtime:addEventListener( "notification", notificationListener )
	--Runtime:addEventListener( "key", onKeyEvent )
	Runtime:addEventListener( "unhandledError", errorListener)
	logger.log("[Main] Resolution width:"..display.viewableContentWidth..", height:"..display.viewableContentHeight)
	checkSecurity()
	setupLanguage()
	setupMusic()
	setupSound()
	setupKeyboard()
	loadScenes()
	players.initialize()
	minigamesManager.initialize()
	loadTestActions()
end

local function startGame()

	local currentPlayer = players.getCurrent()

	if launchArgs and launchArgs.notification then
		logger.log("[Main] Received notification as launch argument.")
		notificationListener(launchArgs.notification)
	end
	
	if system.getInfo("environment") == "simulator" and settings.testMenu then
		director.showScene( "testMenu", 1, { effect = "fade", time = 800} )
	else
		director.gotoScene( "scenes.menus.home" )

		if not global_isSubscribed then
				logger.log("Ready to open webview")
 				plugin.openWebview(currentPlayer.subscriptionConfig.urlNoSubscriptor)
 				--plugin.openWebview("http://192.168.15.67")
 		end

		local oldGotoScene = director.gotoScene
		director.gotoScene = function(...)
			print(global_isSubscribed)
			if global_isSubscribed then
		 		oldGotoScene(...)
		 	else
		 		native.showAlert("Subscripción Invalida", "¡Obtenga una subscripción al servicio!", {"OK"}, function()
		 			plugin.openWebview(currentPlayer.subscriptionConfig.urlNoSubscriptor)
		 			--plugin.openWebview("http://192.168.15.67")
		 		end)
		 	end
 		end

	end
end

local function start()
	initialize()
	subscription.check(startGame)
	startGame()
end
----------------------------------------------- Execution
start() 
