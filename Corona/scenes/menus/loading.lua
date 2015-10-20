----------------------------------------------- Menus Loading scene
local director = require( "libs.helpers.director" )
local sceneloader = require( "libs.helpers.sceneloader" )
local logger = require( "libs.helpers.logger" )
local settings = require( "settings" )
local players = require( "models.players" )
local localization = require( "libs.helpers.localization" )
local game = director.newScene() 
----------------------------------------------- Variables
local dynamicScale 
local rotatingEffect1, rotatingEffect2
local loadingBar
local sceneList
local nextScene, nextSceneParameters
local energyRemoveText
local energyRemoveGroup
local loadingText
local currentPlayer
local loadingBarContainer
----------------------------------------------- Constants
local FILENAME_BACKGROUND = "images/loading/background.png"
local FILENAME_FOREGROUND = "images/loading/foreground.png"
local FILENAME_ROTATING_EFFECT = "images/loading/destello.png"
local FILENAME_BAR = "images/loading/bar.png"
local BAR_OFFSET_X = 2
local OFFSET_LOADING_TEXT = {x = 0, y = 200}
local SIZE_FONT_LOADING = 50
local BACKGROUND_SIZE = 1024
local EFFECT_ROTATION_RATE_1 = 0.4
local EFFECT_ROTATION_RATE_2 = 0.2
local OFFSET_LOGO = {x = 0, y = -50}
local OFFSET_LOADINGBAR = {x = 0, y = 125}

local TEXT_LOADING = {
	en = "Loading...",
	es = "Cargando...",
}

local SIZE_FONT_ENERGY_REMOVE = 40
local SCALE_ENERGY_ICON = 0.5
local SIZE_ENERGY_REMOVE = {width = 400, height = 100}
local OFFSET_ENERGY_ICON = {x = SIZE_ENERGY_REMOVE.width * 0.5, y = 0}
local OFFSET_ENERGY_REMOVE = {x = 0, y = -200}

local LOAD_DELAY = 100
local TIME_TRANSITION_RATIO_LOAD_DELAY = 0.8
----------------------------------------------- Functions
local function sceneLoaded(event)
	local percentage = event.percentage
	local index = event.index
	
	local finalScale = percentage
	transition.cancel(loadingBarContainer)
	if index > 1 then
		loadingBarContainer.xScale = (percentage - event.percentagePerScene) * dynamicScale
	end
	transition.to(loadingBarContainer, {time = LOAD_DELAY * TIME_TRANSITION_RATIO_LOAD_DELAY, xScale = finalScale, transition = easing.outQuad})
	
	if index >= #sceneList then
		timer.performWithDelay(1500, function()
			director.gotoScene(nextScene, {effect = "fade", time = 800, params = nextSceneParameters})
		end)
	end
end

local function initialize(parameters)
	parameters = parameters or {}
	sceneList = parameters.sceneList or {}
	nextScene = parameters.nextScene or "scenes.menus.home"
	nextSceneParameters = parameters.nextSceneParameters
	
	local language = localization.getLanguage()
	
	loadingText.text = TEXT_LOADING[language]
	loadingBarContainer.xScale = 0.01
	
	transition.from(rotatingEffect1, {alpha = 0, xScale = 0.05, yScale = 0.05, time = 500, transition = easing.outQuad})
	transition.from(rotatingEffect2, {alpha = 0, xScale = 0.05, yScale = 0.05, time = 500, transition = easing.outQuad})
	
	logger.log("[Loading] Will remove hidden scenes.")
	director.removeHidden(true)
	collectgarbage("collect")
end

local function enterFrame()
	rotatingEffect1.rotation = rotatingEffect1.rotation + EFFECT_ROTATION_RATE_1
	rotatingEffect2.rotation = rotatingEffect2.rotation + EFFECT_ROTATION_RATE_2
end

----------------------------------------------- Module functions 
function game:create(event)
	local sceneView = self.view
	dynamicScale = display.viewableContentWidth / BACKGROUND_SIZE
	local background = display.newImageRect(FILENAME_BACKGROUND, BACKGROUND_SIZE, BACKGROUND_SIZE)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = dynamicScale
	background.yScale = dynamicScale
	sceneView:insert(background)
	
	rotatingEffect1 = display.newImage(FILENAME_ROTATING_EFFECT)
	rotatingEffect1.x = display.contentCenterX
	rotatingEffect1.y = display.contentCenterY
	rotatingEffect1.xScale = dynamicScale
	rotatingEffect1.yScale = dynamicScale
	sceneView:insert(rotatingEffect1)
	
	rotatingEffect2 = display.newImage(FILENAME_ROTATING_EFFECT)
	rotatingEffect2.x = display.contentCenterX
	rotatingEffect2.y = display.contentCenterY
	rotatingEffect2.xScale = dynamicScale
	rotatingEffect2.yScale = dynamicScale
	sceneView:insert(rotatingEffect2)
	
	loadingBar = display.newImage(FILENAME_BAR)
	loadingBar.xScale = dynamicScale * 0.98
	loadingBar.yScale = dynamicScale
	
	loadingBarContainer = display.newContainer(loadingBar.contentWidth, 400)
	loadingBarContainer.xScale = 0.01
	loadingBarContainer.x = display.contentCenterX
	loadingBarContainer.y = display.contentCenterY + OFFSET_LOADINGBAR.y
	loadingBarContainer:insert(loadingBar)
	sceneView:insert(loadingBarContainer)
	
	local foreground = display.newImage(FILENAME_FOREGROUND)
	foreground.x = display.contentCenterX
	foreground.y = display.contentCenterY + OFFSET_LOADINGBAR.y
	foreground.xScale = dynamicScale
	foreground.yScale = dynamicScale
	sceneView:insert(foreground)
	
	local logo = display.newImage("images/home/logo_yappkids.png")
	logo.x = display.contentCenterX + OFFSET_LOGO.x
	logo.y = display.contentCenterY + OFFSET_LOGO.y
	logo.xScale = 0.4
	logo.yScale = 0.4
	sceneView:insert(logo)
	
	local loadingTextOptions = {
		x = display.contentCenterX + OFFSET_LOADING_TEXT.x,
		y = display.contentCenterY + OFFSET_LOADING_TEXT.y,
		align = "center",
		font = settings.fontName,
		text = "",
		fontSize = SIZE_FONT_LOADING,
	}

	loadingText = display.newText(loadingTextOptions)
	sceneView:insert(loadingText)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		currentPlayer = players.getCurrent()
		initialize(event.params)
		Runtime:addEventListener("enterFrame", enterFrame)
	elseif ( phase == "did" ) then
		timer.performWithDelay(1000, function()
			sceneloader.loadScenes(sceneList, sceneLoaded, LOAD_DELAY)
		end)
	end
end

function game:hide( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		Runtime:removeEventListener("enterFrame", enterFrame)
		players.save(currentPlayer)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game





