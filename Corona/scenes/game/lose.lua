----------------------------------------------- Lose screen
local path = ...
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local database = require( "libs.helpers.database" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )

local scene = director.newScene() 
----------------------------------------------- Variables
local back, retry, play
local sceneGroup
local window, title
local parent
local backFunction, retryFunction
local buttonsEnabled
local isRetryEnabled
----------------------------------------------- Constants
local OFFSET_MASTER = {x = -60, y = -40}
local SCALE_MASTER = 0.9
local SCALE_WINDOW = 1.1
local OFFSET_TITLE = {x = 0, y = -300}
local OFFSETS_BUTTONS = {
	BACK = {x =0 -70, y = 290},
	RETRY = {x = 70, y = 290},
}
local PATH_WINDOW = "images/lose/window.png"
local PATH_TITLES = "images/lose/lose_%s.png"
----------------------------------------------- Functions
local function backReleased()
	if backFunction and "function" == type(backFunction) then
		backFunction()
	end
end


local function retryPressed()
	if isRetryEnabled then
		sound.play("pop")
	else
		sound.play("wrongAnswer")
	end
end

local function retryReleased()
	if isRetryEnabled then
		if retryFunction and "function" == type(retryFunction) then
			retryFunction()
		end
	end
end

local function removeTitle()
	display.remove(title)
	title = nil
end

local function createTitle()
	removeTitle()
	title = display.newImage(localization.format(PATH_TITLES))
	title.x = display.contentCenterX + OFFSET_TITLE.x
	title.y = display.contentCenterY + OFFSET_TITLE.y
	sceneGroup:insert(title)
end

local function createMaster(sceneGroup)
	
	local masterSheetData1 = { width = 430, height = 512, numFrames = 8, sheetContentWidth = 860, sheetContentHeight = 2048 }
	local masterSheet1 = graphics.newImageSheet( "images/lose/master_lose.png", masterSheetData1 )

	local sequenceData = {
		{ name = "lose", sheet = masterSheet1, start = 1,count = 8, time = 500, loopCount = 0 },
	}

	local masterSprite = display.newSprite( masterSheet1, sequenceData )
	masterSprite.x = display.contentCenterX + OFFSET_MASTER.x
	masterSprite.y = display.contentCenterY + OFFSET_MASTER.y
	masterSprite.xScale = SCALE_MASTER
	masterSprite.yScale = SCALE_MASTER
	masterSprite:play()
	
	sceneGroup:insert(masterSprite)
end

local function initialize(event)
	local parameters = event.params or {}
	backFunction = parameters.backFunction
	retryFunction = parameters.retryFunction
	scene.retrySetEnabled(true)
	parent = event.parent
	scene.disableButtons()
	
	sound.play("lose1")
end
----------------------------------------------- Class functions
function scene.retrySetEnabled(enabled)
	if enabled then
		retry:setFillColor(1)
		isRetryEnabled = true
	else
		retry:setFillColor(0.5)
		isRetryEnabled = false
	end
end 

function scene.enableButtons()
	back:setEnabled(true)
	retry:setEnabled(true)
end

function scene.disableButtons()
	back:setEnabled(false)
	retry:setEnabled(false)
end

function scene:create(event)
	sceneGroup = self.view
	
	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background:setFillColor(0, 0.8)
	sceneGroup:insert(background)
	
	window = display.newImage(PATH_WINDOW, true)
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	window.xScale = SCALE_WINDOW
	window.yScale = SCALE_WINDOW
	sceneGroup:insert(window)
	
	createMaster(sceneGroup)
	
	buttonlist.retry.onPress = retryPressed
	buttonlist.back.onRelease = backReleased
	back = widget.newButton(buttonlist.back)
	back.x = display.contentCenterX + OFFSETS_BUTTONS.BACK.x
	back.y = display.contentCenterY + OFFSETS_BUTTONS.BACK.y
	sceneGroup:insert(back)
	
	buttonlist.retry.onRelease = retryReleased
	retry = widget.newButton(buttonlist.retry)
	retry.x = display.contentCenterX + OFFSETS_BUTTONS.RETRY.x
	retry.y = display.contentCenterY + OFFSETS_BUTTONS.RETRY.y
	sceneGroup:insert(retry)
end

function scene:destroy()
	
end

function scene.show(...)
	local parameters = {...}
	if parameters and parameters[1] and parameters[1] == scene then
		local self = parameters[1]
		local event = parameters[2]
		
		local phase = event.phase

		if ( phase == "will" ) then
			initialize(event)
			createTitle()
		elseif ( phase == "did" ) then
			self.enableButtons()
		end
	else
		director.showOverlay( path, {isModal = true, effect = "fade", time = 400, params = {
			backFunction = parameters[1],
			retryFunction = parameters[2],
		}})
	end
end

function scene:hide( event )
    local phase = event.phase

    if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeTitle()
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene

