----------------------------------------------- Pause screen
local path = ...
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local settings = require( "settings" )
local database = require( "libs.helpers.database" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local scene = director.newScene() 
----------------------------------------------- Variables
local back, retry, play
local sceneGroup
local window, title
local parent
local goalsGroup, textGroup
local backFunction, retryFunction, resumeFunction
local currentGoals, isRetryEnabled
----------------------------------------------- Constants
local DEFAULT_TEXT_GOAL = "Defeat the enemy team"
local SIZE_FONT_GOAL_TEXT = 35
local WIDTH_GOAL_TEXT = 600

local OFFSET_GOALS_TEXT = {x = -120, y = -30}
local OFFSET_GOAL_TEXT = {x = -50, y = 0}
local OFFSET_COMPLETE_BOX = {x = -100, y = 0}
local PADDING_TEXT_Y = 75

local DEFAULT_GOALS = {
	[1] = {complete = false, text = DEFAULT_TEXT_GOAL},
	[2] = {complete = false, text = DEFAULT_TEXT_GOAL},
}
local SCALE_CHECKMARK = 0.2

local SCALE_WINDOW = 1.05
local OFFSET_TITLE = {x = 0, y = -240}
local SCALE_BUTTON_PLAY = 0.5
local OFFSETS_BUTTONS = {
	BACK = {x = -140, y = 177},
	RETRY = {x = 0, y = 177},
	PLAY = {x = 140, y = 177},
}
local PATH_WINDOW = "images/pause/window.png"
local PATH_TITLES = "images/pause/pause_%s.png"
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

local function playReleased()
	if resumeFunction and "function" == type(resumeFunction) then
		resumeFunction()
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
	end
end

local function initialize(event)
	local parameters = event.params or {}
	backFunction = parameters.backFunction
	retryFunction = parameters.retryFunction
	resumeFunction = parameters.resumeFunction
	
	currentGoals = parameters.goals or DEFAULT_GOALS
	scene.retrySetEnabled(true)

	parent = event.parent
	scene.disableButtons()
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
	play:setEnabled(true)
end

function scene.disableButtons()
	back:setEnabled(false)
	retry:setEnabled(false)
	play:setEnabled(false)
end

function scene:create(event)
	sceneGroup = self.view
	
	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background:setFillColor(0, 0.8)
	sceneGroup:insert(background)
	
	window = display.newImage(PATH_WINDOW)
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	window.xScale = SCALE_WINDOW
	window.yScale = SCALE_WINDOW
	sceneGroup:insert(window)
	
	textGroup = display.newGroup()
	sceneGroup:insert(textGroup)
	
	buttonlist.back.onRelease = backReleased
	back = widget.newButton(buttonlist.back)
	back.x = display.contentCenterX + OFFSETS_BUTTONS.BACK.x
	back.y = display.contentCenterY + OFFSETS_BUTTONS.BACK.y
	sceneGroup:insert(back)
	
	buttonlist.retry.onPress = retryPressed
	buttonlist.retry.onRelease = retryReleased
	retry = widget.newButton(buttonlist.retry)
	retry.x = display.contentCenterX + OFFSETS_BUTTONS.RETRY.x
	retry.y = display.contentCenterY + OFFSETS_BUTTONS.RETRY.y
	sceneGroup:insert(retry)
	
	buttonlist.play.onRelease = playReleased
	play = widget.newButton(buttonlist.play)
	play.x = display.contentCenterX + OFFSETS_BUTTONS.PLAY.x
	play.y = display.contentCenterY + OFFSETS_BUTTONS.PLAY.y
	play.xScale = SCALE_BUTTON_PLAY
	play.yScale = SCALE_BUTTON_PLAY
	sceneGroup:insert(play)
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
			backFunction = parameters[2],
			retryFunction = parameters[3],
			resumeFunction = parameters[4],
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

