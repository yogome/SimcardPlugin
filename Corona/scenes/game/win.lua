----------------------------------------------- Win screen
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
local window, title, masterSprite
local parent
local starAmount, coinsAmount
local stars, coinsText
local backFunction, retryFunction, resumeFunction
----------------------------------------------- Constants
local TAG_WIN_TRANSITION = "tagStarsTransition"
local DEFAULT_STARS = 3
local DEFAULT_COINS = 12345

local SIDE_MASTER = -1
local SCALE_MASTER = 0.9
local OFFSET_MASTER = {x = -250, y = -50}
local SCALE_STARS = 0.38
local OFFSETS_STARS ={
	[1] = {x = 110, y = -29},
	[2] = {x = 200, y = -62},
	[3] = {x = 290, y = -29},
}
local OFFSET_COINS_TEXT = {x = 340, y = 110}
local SIZE_STATS_TEXT_FONT = 65
local WIDTH_STATS_TEXT = 400
local SCALE_WINDOW = 1.1
local OFFSET_TITLE = {x = 100, y = -300}
local SCALE_BUTTON_PLAY = 0.5
local OFFSETS_BUTTONS = {
	BACK = {x =220 -140, y = 290},
	RETRY = {x = 220, y = 290},
	PLAY = {x =220 + 140, y = 290},
}
local PATH_WINDOW = "images/win/window.png"
local PATH_TITLES = "images/win/win_%s.png"
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

local function createMaster(sceneGroup)
	
	local masterSheetData1 = { width = 430, height = 512, numFrames = 8, sheetContentWidth = 860, sheetContentHeight = 2048 }
	local masterSheet1 = graphics.newImageSheet( "images/win/master_win.png", masterSheetData1 )

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
local function initialize(event)
	local parameters = event.params or {}
	backFunction = parameters.backFunction
	retryFunction = parameters.retryFunction
	resumeFunction = parameters.resumeFunction
	
	coinsAmount = parameters.coinsAmount or DEFAULT_COINS
	starAmount = parameters.starAmount or DEFAULT_STARS
	
	if not(coinsAmount and "number" == type(coinsAmount)) then
		error("coinsAmount must be a number", 3)
	end
	
	if not(starAmount and "number" == type(starAmount)) then
		error("starAmount must be a number", 3)
	end

	parent = event.parent
	scene.disableButtons()
	
	back.alpha = 0
	retry.alpha = 0
	play.alpha = 0
		
	transition.to(back, {time = 600, delay = 600, alpha = 1, transition = easing.outQuad})
	transition.to(retry, {time = 600, delay = 700, alpha = 1, transition = easing.outQuad})
	transition.to(play, {time = 600, delay = 800, alpha = 1, transition = easing.outQuad})
	
	scene.retrySetEnabled(true)
	
	sound.play("win1")
end
local function startTransitions()
	local baseDelay = 0
	local transitionTime = 800
	
	local function ceilOutQuad(t, tMax, start, delta)
		return math.ceil(easing.outQuad(t, tMax, start, delta))
	end
	
	coinsText.text = coinsAmount
	transition.from(coinsText, {tag = TAG_WIN_TRANSITION, text = 0, delay  = baseDelay, time = transitionTime + baseDelay * 2, transition = ceilOutQuad})
	
	for index = 1, starAmount do
		local star = stars[index]
		if star then
			local delay = baseDelay + 300 * index
			local halfTime = transitionTime * 0.5
			local startY = display.contentCenterY + OFFSETS_STARS[index].y
			local arcTop = startY - 230
			star.y = startY
			
			transition.to(star, {tag = TAG_WIN_TRANSITION, delay = delay, time = halfTime, y = arcTop, transition = easing.inQuad, onStart = function()
				star.alpha = 1
			end})
			transition.to(star, {tag = TAG_WIN_TRANSITION, delay = delay + halfTime, time = halfTime, y = startY, transition = easing.outBounce})
			transition.from(star, {tag = TAG_WIN_TRANSITION, delay = delay, time = transitionTime, x = masterSprite.x, xScale = 1, yScale = 1, rotation = -1000, transition = easing.outQuad, onComplete = function()
				sound.play("star"..index)
			end})
		end
	end
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
	background:setFillColor(0, 0.9)
	sceneGroup:insert(background)
	
	window = display.newImage(PATH_WINDOW, true)
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	window.xScale = SCALE_WINDOW
	window.yScale = SCALE_WINDOW
	sceneGroup:insert(window)
	
	stars = {}
	for index = 1, #OFFSETS_STARS do
		local star = display.newImage("images/win/star.png")
		star.x = display.contentCenterX + OFFSETS_STARS[index].x
		star.y = display.contentCenterY + OFFSETS_STARS[index].y
		star.xScale = SCALE_STARS
		star.yScale = SCALE_STARS
		star.alpha = 0
		sceneGroup:insert(star)
		
		stars[index] = star
	end
	
	createMaster(sceneGroup)
	
	local coinsTextOptions = {
		x = display.contentCenterX + OFFSET_COINS_TEXT.x,
		y = display.contentCenterY + OFFSET_COINS_TEXT.y,
		width = WIDTH_STATS_TEXT,
		align = "right",
		font = settings.fontName,
		text = 0,
		fontSize = SIZE_STATS_TEXT_FONT,
	}
	
	coinsText = display.newText(coinsTextOptions)
	coinsText.anchorX = 1
	sceneGroup:insert(coinsText)
	
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
			createTitle()
			startTransitions()
		elseif ( phase == "did" ) then
			self.enableButtons()
		end
	else
		director.showOverlay( path, {isModal = true, effect = "fade", time = 800, params = {
			starAmount = parameters[1] or DEFAULT_STARS,
			coinsAmount = parameters[2] or DEFAULT_COINS,
			backFunction = parameters[3],
			retryFunction = parameters[4],
			resumeFunction = parameters[5],
		}})
	end
end

function scene:hide( event )
    local phase = event.phase

    if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeTitle()
		transition.cancel(TAG_WIN_TRANSITION)
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene

