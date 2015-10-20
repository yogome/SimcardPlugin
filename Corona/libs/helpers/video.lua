----------------------------------------------- Video scene
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local director = require( folder.."director" )
local media = require( "media" )

local videoScene = director.newScene()
----------------------------------------------- Variables
local platformName, environment
local videoObject
local skipLock

local filename
local nextScene
local nextSceneParams
local hasControls
local tapSkip
local mode
local queuedParams
----------------------------------------------- Constants
local MODE_DEFAULT = "internal" 
----------------------------------------------- Functions
local function videoEnded()
	director.gotoScene(nextScene, {effect = "fade", time = 400, params = nextSceneParams})
end

local function videoListener(event)
	if "external" == mode then
		videoEnded()
	elseif "internal" == mode then
		if "ended" == event.phase then
			videoEnded()
		end
	end
end

local function skipVideo()
	if tapSkip then
		if not skipLock then
			skipLock = true
			if videoObject then
				videoObject:pause()
				display.remove(videoObject)
				videoObject = nil
			end
			videoEnded()
		end
	end
end

local function onSystemEvent(event)
	if event.type == "applicationResume" then
		videoListener()
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or queuedParams or {}
	filename = params.filename or ""
	nextScene = params.nextScene or director.getSceneName("previous")
	nextSceneParams = params.nextSceneParams or {}
	hasControls = params.hasControls
	tapSkip = params.tapSkip
	mode = params.mode or MODE_DEFAULT
	queuedParams = nil
	
	if platformName == "Android" then
		logger.log("[Video] Platform is Android, will add system event listener.")
		Runtime:addEventListener( "system", onSystemEvent )
	end

	if platformName == "Win" then
		logger.log("[Video] Platform is Windows, video is not supported, skipped playing "..filename)
		videoEnded()
	else
		if "external" == mode then
			media.playVideo( filename, hasControls, videoListener )
		elseif "internal" == mode then
			if "device" == environment then
				logger.log("[Video] Will now play "..filename.." in internal mode.")
				
				Runtime:addEventListener( "tap", skipVideo)
				videoObject = native.newVideo( display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2 , display.viewableContentHeight + 2)
				videoObject:load( filename , system.ResourceDirectory )
				videoObject:addEventListener( "video", videoListener )
				videoObject:play()
			else
				logger.error("[Video] Environment is simulator, internal video is not supported, skipped playing "..filename)
				videoEnded()
			end
		end
	end
end

local function reset()
	skipLock = false
	platformName = system.getInfo("platformName")
	environment = system.getInfo("environment")
end

local function endVideo()
	if platformName == "Android" then
		Runtime:removeEventListener( "system", onSystemEvent )
	end
	if "internal" == mode then
		if "device" == environment then
			Runtime:removeEventListener( "tap", skipVideo)
		end
		if videoObject then
			display.remove(videoObject)
			videoObject = nil
		end
	end
end
----------------------------------------------- Module functions
function videoScene.backAction()
	if tapSkip then
		
	end
	return true
end

function videoScene.queueVideo(filename, mode, hasControls, tapSkip, nextScene, nextSceneParams)
	queuedParams = {
		filename = filename,
		mode = mode,
		hasControls = hasControls,
		tapSkip = tapSkip,
		nextScene = nextScene,
		nextSceneParams = nextSceneParams
	}
end

function videoScene.play(filename, mode, hasControls, tapSkip, nextScene, nextSceneParams)
	director.gotoScene(path, {params = {
		filename = filename,
		mode = mode,
		hasControls = hasControls,
		tapSkip = tapSkip,
		nextScene = nextScene,
		nextSceneParams = nextSceneParams
	}})
end

function videoScene:create(event)
	
end

function videoScene:destroy()
	
end

function videoScene:show( event )
	local phase = event.phase

	if phase == "will" then
		reset()
	elseif phase == "did" then
		initialize(event)
	end
end

function videoScene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then

	elseif phase == "did" then
		endVideo()
	end
end

videoScene:addEventListener( "create" )
videoScene:addEventListener( "destroy", videoScene )
videoScene:addEventListener( "hide", videoScene )
videoScene:addEventListener( "show", videoScene )

return videoScene
