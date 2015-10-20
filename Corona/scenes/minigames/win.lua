----------------------------------------------- Win screen
local scenePath = ... 
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local settings = require( "settings" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local uifx = require( "libs.helpers.uifx" )

local scene = director.newScene() 
----------------------------------------------- Variables
local play
local sceneGroup
local window, title, masterSprite
local descriptionText, correctNumber, wrongNumber, powerCubesText
local onComplete
local buttonsEnabled
----------------------------------------------- Constants
local SIDE_MASTER = -1
local SCALE_MASTER = 0.9
local OFFSET_MASTER = {x = -250, y = -50}
local OFFSETS_STARS ={
	[1] = {x = 110, y = -29},
	[2] = {x = 200, y = -62},
	[3] = {x = 290, y = -29},
}
local OFFSET_COINS_TEXT = {x = 340, y = 110}
local SCALE_WINDOW = 1.1
local OFFSET_TITLE = {x = 0, y = -300}
local SCALE_BUTTON_PLAY = 0.5
local OFFSETS_BUTTONS = {
	PLAY = {x = 0, y = 290},
}
local PATH_WINDOW = "images/manager/winlose/win.png"
local PATH_TITLES = "images/manager/winlose/good_%s.png"

local BUTTON_PLAY = { width = 256, height = 256, defaultFile = "images/manager/winlose/playbtn_1.png", overFile = "images/manager/winlose/playbtn_2.png"}
----------------------------------------------- Functions
local function playReleased()
	if buttonsEnabled then
		buttonsEnabled = false
		if onComplete and "function" == type(onComplete) then
			onComplete()
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
	local masterSheet1 = graphics.newImageSheet( "images/manager/master_win.png", masterSheetData1 )

	local sequenceData = {
		{ name = "win", sheet = masterSheet1, start = 1, count = 8, time = 500, loopCount = 0 },
	}

	masterSprite = display.newSprite( masterSheet1, sequenceData )
	masterSprite.x = display.contentCenterX + OFFSET_MASTER.x
	masterSprite.y = display.contentCenterY + OFFSET_MASTER.y
	masterSprite.xScale = SCALE_MASTER * SIDE_MASTER
	masterSprite.yScale = SCALE_MASTER
	masterSprite:play()
	
	sceneGroup:insert(masterSprite)
end
local function initialize(parameters)
	scene.disableButtons()
	
	descriptionText.text = localization.getString("winResultsManager")
	correctNumber.text = parameters.correctAnswers or 8
	wrongNumber.text = parameters.incorrectAnswers or 2
	powerCubesText.text = parameters.powerCubes or 50
	onComplete = parameters.onComplete
		
	uifx.applyBounceTransition(play)
	buttonsEnabled = true
	sound.play("winManager")
end

----------------------------------------------- Class functions

function scene.enableButtons()
	play:setEnabled(true)
end

function scene.disableButtons()
	play:setEnabled(false)
end

function scene:create(event)
	sceneGroup = self.view
	
	window = display.newImage(PATH_WINDOW, true)
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	window.xScale = SCALE_WINDOW
	window.yScale = SCALE_WINDOW
	sceneGroup:insert(window)
	
	createMaster(sceneGroup)
	
	BUTTON_PLAY.onRelease = playReleased
	play = widget.newButton(BUTTON_PLAY)
	play.x = display.contentCenterX + OFFSETS_BUTTONS.PLAY.x
	play.y = display.contentCenterY + OFFSETS_BUTTONS.PLAY.y
	play.xScale = SCALE_BUTTON_PLAY
	play.yScale = SCALE_BUTTON_PLAY
	sceneGroup:insert(play)
	
	local descriptionTextOptions = {
		x = display.contentCenterX + 170,
		y = display.contentCenterY + 233,
		align = "center",
		font = settings.fontName,
		text = "",
		width = 500,
		height = 400,
		fontSize = 32,
	}
	
	descriptionText = display.newText(descriptionTextOptions)
	sceneGroup:insert(descriptionText)
	
	local correctImage = display.newImage("images/manager/winlose/correct.png")
	correctImage.x = display.contentCenterX + 80
	correctImage.y = display.contentCenterY - 180
	correctImage.xScale = 0.4
	correctImage.yScale = 0.4
	sceneGroup:insert(correctImage)
	
	correctNumber = display.newText("", correctImage.x - 87, correctImage.y, settings.fontName, 64)
	sceneGroup:insert(correctNumber)
	
	local wrongImage = display.newImage("images/manager/winlose/incorrect.png")
	wrongImage.x = correctImage.x
	wrongImage.y = correctImage.y + 110
	wrongImage.xScale = 0.4
	wrongImage.yScale = 0.4
	sceneGroup:insert(wrongImage)
	
	wrongNumber = display.newText("", wrongImage.x - 87, wrongImage.y, settings.fontName, 64)
	sceneGroup:insert(wrongNumber)
	
	local powerCubesTextOptions = {
		x = wrongImage.x + 180,
		y = wrongImage.y + 13,
		align = "center",
		font = settings.fontName,
		text = "",
		fontSize = 52,
	}
	powerCubesText = display.newText(powerCubesTextOptions)
	sceneGroup:insert(powerCubesText)
	
end

function scene:destroy()
	
end

function scene:show(event)
	local phase = event.phase
	local params = event.params

	if ( phase == "will" ) then
		initialize(params)
		createTitle()
	elseif ( phase == "did" ) then
		self.enableButtons()
	end
end

function scene:hide( event )
    local phase = event.phase

    if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeTitle()
		uifx.cancelBounceTransition(play)
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene



