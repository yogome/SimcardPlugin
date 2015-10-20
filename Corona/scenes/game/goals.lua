----------------------------------------------- Goals screen
local path = ...
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local settings = require( "settings" )
local database = require( "libs.helpers.database" )
local indicator = require( "libs.helpers.indicator" )
local localization = require( "libs.helpers.localization" )

local scene = director.newScene() 
----------------------------------------------- Variables
local ok
local sceneGroup
local window, title
local parent
local okFunction
local masterSprite
local goalsGroup, textGroup
local currentGoals
----------------------------------------------- Constants
local DEFAULT_TEXT_GOAL = "Defeat the enemy team in less than 1 minute."
local SIZE_FONT_GOAL_TEXT = 30
local WIDTH_GOAL_TEXT = 450

local OFFSET_GOALS_TEXT = {x = -50, y = 20}
local OFFSET_GOAL_TEXT = {x = -50, y = -20}
local OFFSET_COMPLETE_BOX = {x = -100, y = 0}
local PADDING_TEXT_Y = 100

local DEFAULT_GOALS = {
	[1] = {complete = false, text = DEFAULT_TEXT_GOAL, goal = 10, current = 5},
	[2] = {complete = false, text = DEFAULT_TEXT_GOAL, goal = 10, current = 9},
	[3] = {complete = true, text = DEFAULT_TEXT_GOAL, goal = 10, current = 10}
}

local SIDE_MASTER = -1
local SCALE_MASTER = 0.7
local OFFSET_MASTER = {x = -300, y = -10}
local SCALE_CHECKMARK = 0.2

local SCALE_WINDOW = 0.9
local OFFSET_WINDOW = {x = 0, y = 55}
local OFFSET_TITLE = {x = 40, y = -240}
local SCALE_BUTTON_PLAY = 1
local OFFSETS_BUTTONS = {
	OK = {x = 340, y = 270},
}
local PATH_WINDOW = "images/goals/window.png"
local PATH_GOAL_TITLES = "images/goals/goals_%s.png"
local PATH_MISSION_TITLES = "images/goals/mission_%s.png"


local COLOR_BARS = {
	["complete"] = {0, 1, 0},
	["uncomplete"] = {1, 0, 0},
}
----------------------------------------------- Functions
local function okReleased()
	if okFunction and "function" == type(okFunction) then
		okFunction()
	end
end

local function removeTitle()
	display.remove(title)
	title = nil
end

local function createTitle()
	removeTitle()
	title = display.newImage(localization.format(PATH_GOAL_TITLES))
	title.x = display.contentCenterX + OFFSET_TITLE.x
	title.y = display.contentCenterY + OFFSET_TITLE.y
	sceneGroup:insert(title)
end

local function initialize(event)
	local parameters = event.params or {}
	okFunction = parameters.okFunction
	
	currentGoals = parameters.goals or DEFAULT_GOALS

	parent = event.parent
	scene.disableButtons()
end

local function createMaster(sceneGroup)
	
	local masterSheetData1 = { width = 430, height = 512, numFrames = 8, sheetContentWidth = 860, sheetContentHeight = 2048 }
	local masterSheet1 = graphics.newImageSheet( "images/goals/master_goals.png", masterSheetData1 )

	local sequenceData = {
		{ name = "win", sheet = masterSheet1, frames = {1,1,2,3,4,4,5,6,7,8,8,8,8,7,6,5,4,4,3,2,1,1}, loopDirection = "bounce", time = 1200, loopCount = 0 },
	}

	masterSprite = display.newSprite( masterSheet1, sequenceData )
	masterSprite.x = display.contentCenterX + OFFSET_MASTER.x
	masterSprite.y = display.contentCenterY + OFFSET_MASTER.y
	masterSprite.xScale = SCALE_MASTER * SIDE_MASTER
	masterSprite.yScale = SCALE_MASTER
	masterSprite:play()
	
	sceneGroup:insert(masterSprite)
end

local function createGoalsText()
	display.remove(goalsGroup)
	goalsGroup = display.newGroup()
	textGroup:insert(goalsGroup)
	
	local startY = display.contentCenterY - (PADDING_TEXT_Y * (#currentGoals - 1)) * 0.5 + OFFSET_GOALS_TEXT.y
	for goalIndex = 1, #currentGoals do
		
		local currentY = startY + (goalIndex - 1) * PADDING_TEXT_Y + OFFSET_COMPLETE_BOX.y
		local positionX = OFFSET_GOALS_TEXT.x + display.contentCenterX + OFFSET_COMPLETE_BOX.x
		
		local completeBox = display.newRoundedRect(positionX, currentY, 50, 50, 15)
		completeBox.fill = { 1, 1, 1, 0 }
		completeBox.stroke = { 1, 1, 1 }
		completeBox.strokeWidth = 6
		goalsGroup:insert(completeBox)
		
		
		local checkmark = display.newImage("images/general/checkmark.png")
		checkmark.x = completeBox.x
		checkmark.y = completeBox.y
		checkmark.xScale = SCALE_CHECKMARK
		checkmark.yScale = SCALE_CHECKMARK
		goalsGroup:insert(checkmark)
		
		checkmark.isVisible = currentGoals[goalIndex].complete
		
		local goalTextOptions = {
			x = display.contentCenterX + OFFSET_GOAL_TEXT.x + OFFSET_GOALS_TEXT.x,
			y = currentY + OFFSET_GOAL_TEXT.y,
			width = WIDTH_GOAL_TEXT,
			align = "left",
			font = settings.fontName,
			text = currentGoals[goalIndex].text,
			fontSize = SIZE_FONT_GOAL_TEXT,
		}

		local goalsText = display.newText(goalTextOptions)
		goalsText.anchorX = 0
		goalsGroup:insert(goalsText)
		
		local current = currentGoals[goalIndex].current or 0
		local goal = currentGoals[goalIndex].goal or 10
		
		local barOptions = {
			width = 400,
			height = 30,
			barPadding = 0,
			text = current .. "/" .. goal,
			fontSize = 30
		}
		
		local bar = indicator.newBar(barOptions)
		bar.anchorX = 0
		bar.anchorY = 0
		bar.x = goalsText.x
		bar.y = goalsText.y + 20
		bar:setFillAmount(current/goal)
		local colorBar = currentGoals[goalIndex].complete and COLOR_BARS["complete"] or COLOR_BARS["uncomplete"]
		bar.bar:setFillColor(unpack(colorBar))
		goalsGroup:insert(bar)
		
		
	end
end
----------------------------------------------- Class functions 
function scene.enableButtons()
	ok:setEnabled(true)
end

function scene.disableButtons()
	ok:setEnabled(false)
end

function scene:create(event)
	sceneGroup = self.view
	
	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background:setFillColor(0, 0.8)
	sceneGroup:insert(background)
	
	window = display.newImage(PATH_WINDOW)
	window.x = display.contentCenterX + OFFSET_WINDOW.x
	window.y = display.contentCenterY + OFFSET_WINDOW.y
	window.xScale = SCALE_WINDOW
	window.yScale = SCALE_WINDOW
	sceneGroup:insert(window)
	
	textGroup = display.newGroup()
	sceneGroup:insert(textGroup)
	
	createMaster(sceneGroup)
	
	buttonlist.ok.onRelease = okReleased
	ok = widget.newButton(buttonlist.ok)
	ok.x = display.contentCenterX + OFFSETS_BUTTONS.OK.x
	ok.y = display.contentCenterY + OFFSETS_BUTTONS.OK.y
	ok.xScale = SCALE_BUTTON_PLAY
	ok.yScale = SCALE_BUTTON_PLAY
	sceneGroup:insert(ok)
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
			createGoalsText()
			createTitle()
		elseif ( phase == "did" ) then
			self.enableButtons()
		end
	else
		director.showOverlay( path, {isModal = true, effect = "fade", time = 400, params = {
			goals = parameters[1] or DEFAULT_GOALS,
			okFunction = parameters[2],
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



