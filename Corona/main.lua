------------------------------------------------ Main
local director = require( "libs.helpers.director" )
local logger = require( "libs.helpers.logger" )
local database = require( "libs.helpers.database" )
local protector = require( "libs.helpers.protector" )
local keyboard = require( "libs.helpers.keyboard" )
--local music = require( "libs.helpers.music" )
--local sound = require( "libs.helpers.sound" )
--local sceneloader = require( "libs.helpers.sceneloader" )
local dialog = require( "libs.helpers.dialog" )
--local musiclist = require( "data.musiclist" )
--local soundlist = require( "data.soundlist" )
--local scenelist = require( "data.scenelist" )
local settings = require( "settings" )
--local minigamesManager = require( "scenes.minigames.manager" )
local players = require( "models.players" )
--local internet = require( "libs.helpers.internet" )
--local notificationService = require( "services.notification" )
local eventCounter = require( "libs.helpers.eventcounter" )
--local localization = require( "libs.helpers.localization" )
local testMenu = require( "libs.helpers.testmenu" )
local testActions = require( "data.testactions" )
--local extrafile = require( "libs.helpers.extrafile" )
local json = require("json")
local subscription = require("services.subscription")
local plugin = require("plugin.simcard")
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

local function errorListener( event )
	logger.error("[Main] There was an error: "..(event.errorMessage or "Unknown error")..": "..(event.stackTrace or "No trace"))
	director.gotoScene( "scenes.home", { effect = "fade", time = 800} )
    return true
end

local function loadTestActions()
	for index = 1, #testActions do
		testMenu.addButton(unpack(testActions[index]))
	end
end

local function initialize()
	--extrafile.cacheFileSystem()
	protector.enabled = settings.enableProtector
	logger.enabled = settings.enableLog
	display.setDefault( "minTextureFilter", "nearest" )
	logger.log("[Main] Initializing game...")
	display.setStatusBar( display.HiddenStatusBar )
	math.randomseed( os.time() )
	system.setIdleTimer( false )
	eventCounter.initialize()
	Runtime:addEventListener( "unhandledError", errorListener)
	logger.log("[Main] Resolution width:"..display.viewableContentWidth..", height:"..display.viewableContentHeight)
	players.initialize()
	loadTestActions()
end

local function startGame()

	local currentPlayer = players.getCurrent()
	
	if system.getInfo("environment") == "simulator" and settings.testMenu then
		director.showScene( "testMenu", 1, { effect = "fade", time = 800} )
	else
		director.gotoScene( "scenes.home" )

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
