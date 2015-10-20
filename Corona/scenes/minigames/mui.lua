------------------------------------------------ Manager UI
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local colors = require( "libs.helpers.colors" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )

local managerUI = {}
------------------------------------------------ Variables
local initialized
------------------------------------------------ Constants
local TAG_TRANSITION_WINSCREEN = "tagTransitionManagerWinScreen"
local TAG_TRANSITION_LOSESCREEN = "tagTransitionManagerWinScreen"

local DELAY_REMOVE_LOSESCREEN = 2000
local DELAY_REMOVE_WINSCREEN = 1000
local SIZE_CORRECT_ANSWER_TEXT = 140
local SIZE_CUBES_TEXT = 60

local SCALE_WINDOW = 1.1

local DELAY_MAX_CUBES = 500
local TIME_CUBES = 400

local SCALE_TITLE = {
	WIN = 1,
	LOSE = 1,
}
local SCALE_MASTER = 0.9

local SCALE_POWERCUBE = 0.7
local POSITION_CUBE = {
	START = {x = -240, y = 0, scale = 0.5},
	END = {x = 180, y = -65, scale = 0.65},
}

local SIZE_FONT_CORRECTANSWER = 45
local OFFSET_WRONG_MESSAGE_TEXT = {x = 160, y = -100}
local OFFSET_CUBES_TEXT = {x = 190, y = 80}
local OFFSET_CORRECT_ANSWER = {x = 150, y = 55}
local OFFSET_MASTER = {
	WIN = {x = -200, y = -60},
	LOSE = {x = -280, y = -20},
}

local OFFSET_TITLE = {
	WIN = {x = 20, y = -260},
	LOSE = {x = 0, y = -280},
}
------------------------------------------------ Functions
local function newMasterSprite()
	local masterSheetData = { width = 430, height = 512, numFrames = 8, sheetContentWidth = 860, sheetContentHeight = 2048 }
	
	local masterSheet1 = graphics.newImageSheet( "images/manager/master_lose.png", masterSheetData )
	local masterSheet2 = graphics.newImageSheet( "images/manager/master_win.png", masterSheetData )

	local sequenceData = {
		{ name = "lose", sheet = masterSheet1, start = 1, count = 8, time = 500, loopCount = 0},
		{ name = "win", sheet = masterSheet2, start = 1, count = 8, time = 500, loopCount = 0},
	}

	local masterSprite = display.newSprite( masterSheet1, sequenceData )
	masterSprite.xScale = SCALE_MASTER * -1
	masterSprite.yScale = SCALE_MASTER	
	return masterSprite
end

local function initialize()
	if not initialized then
		initialized = true
		
	end
end

local function createCorrectAnswerText(answerOptions)
	local answerTextOptions = {
		x = OFFSET_CORRECT_ANSWER.x,
		y = OFFSET_CORRECT_ANSWER.y,
		font = settings.fontName,
		width = 500,
		align = "center",
		text = answerOptions.text or "",
		fontSize = answerOptions.fontSize or SIZE_CORRECT_ANSWER_TEXT,
	}
	return display.newText(answerTextOptions)
end

local function createCorrectAnswerImage(answerOptions)
	local answerImage = display.newImage(answerOptions.image)
	answerImage.x, answerImage.y = OFFSET_CORRECT_ANSWER.x, OFFSET_CORRECT_ANSWER.y
	answerImage.xScale = answerOptions.xScale or 1
	answerImage.yScale = answerOptions.yScale or 1
	return answerImage
end

local function setAllAlpha(group, alpha)
	if group and group.numChildren then
		group.alpha = 1
		for index = 1, group.numChildren do
			local child = group[index]
			if child then
				child.alpha = 1
				if child.numChildren then
					setAllAlpha(child, alpha)
				end
			end
		end
	end
end
------------------------------------------------ Module functions
function managerUI.newCheckmark(parentPath, totalTime, onComplete)
	local checkmark = display.newGroup()
	checkmark.x = display.contentCenterX
	checkmark.y = display.contentCenterY
	
	local image = display.newImage("images/manager/correct.png")
	image:scale(0.5,0.5)
	image.alpha = 0
	checkmark:insert(image)
	
	local startTime = math.floor(totalTime * 0.25)
	local middleTime = math.floor(totalTime * 0.5)
	local endTime = math.floor(totalTime * 0.25)
	
	director.to(parentPath, image, {time = startTime + middleTime, xScale = 1, yScale = 1, transition = easing.outElastic})
	director.to(parentPath, image, {time = startTime, alpha = 1, transition = easing.outQuad, onComplete = function()
		director.to(parentPath, image, {delay = middleTime, alpha = 0, time = endTime, transition = easing.inQuad, onComplete = function()
			if onComplete and "function" == type(onComplete) then
				onComplete()
			end
		end})
	end})
	
	return checkmark
end

function managerUI.newCross(parentPath, totalTime, onComplete)
	local cross = display.newGroup()
	cross.x = display.contentCenterX
	cross.y = display.contentCenterY
	
	local image = display.newImage("images/manager/incorrect.png")
	image.alpha = 0
	image:scale(0.5,0.5)
	cross:insert(image)
	
	local startTime = math.floor(totalTime * 0.25)
	local middleTime = math.floor(totalTime * 0.5)
	local endTime = math.floor(totalTime * 0.25)
	
	director.to(parentPath, image, {time = startTime + middleTime, xScale = 1, yScale = 1, transition = easing.outElastic})
	director.to(parentPath, image, {time = startTime, alpha = 1, transition = easing.outQuad, onComplete = function()
		director.to(parentPath, image, {delay = middleTime, alpha = 0, time = endTime, transition = easing.inQuad, onComplete = function()
			if onComplete and "function" == type(onComplete) then
				onComplete()
			end
		end})
	end})
	
	return cross
end

function managerUI.newWinScreen(options)
	options = options or {}
	local powerCubesStart = options.powerCubesStart or 0
	local powerCubesEnd = options.powerCubesEnd or 50
	local onComplete = options.onComplete
	
	local winScreen = display.newGroup()
	winScreen.alpha = 0
	winScreen:addEventListener("tap", function() return true end)
	winScreen:addEventListener("touch", function() return true end)
	winScreen.x = display.contentCenterX
	winScreen.y = display.contentCenterY
	
	local fadeRect = display.newRect(winScreen, 0, 0, display.viewableContentWidth, display.viewableContentHeight)
	fadeRect:setFillColor(0)
	fadeRect.alpha = 0.4
	
	local background = display.newImage("images/manager/windowWin.png")
	background:scale(SCALE_WINDOW, SCALE_WINDOW)
	winScreen:insert(background)
	
	local cubesTextOptions = {
		x = OFFSET_CUBES_TEXT.x,
		y = OFFSET_CUBES_TEXT.y,
		font = settings.fontName,
		text = powerCubesStart,
		fontSize = SIZE_CUBES_TEXT,
	}
	local cubesText = display.newText(cubesTextOptions)
	winScreen:insert(cubesText)
	
	local totalCubes = powerCubesEnd - powerCubesStart
	
	local incrementStep = math.ceil(totalCubes/5)
	local totalSteps = totalCubes / incrementStep
	local cubeDelay = math.ceil(DELAY_MAX_CUBES / totalSteps)

	local currentStep = 1
	for index = incrementStep, totalCubes, incrementStep do
		local powerCube = display.newImage("images/manager/powerCube1.png")
		powerCube.x = POSITION_CUBE.START.x
		powerCube.y = POSITION_CUBE.START.y
		powerCube:scale(POSITION_CUBE.START.scale, POSITION_CUBE.START.scale)
		powerCube.rotation = -360
		powerCube.isVisible = false
		winScreen:insert(powerCube)
		
		local transitionOptions = {
			tag = TAG_TRANSITION_WINSCREEN,
			delay = DELAY_REMOVE_WINSCREEN * 0.5 + cubeDelay * currentStep,
			time = TIME_CUBES,
			xScale = POSITION_CUBE.END.scale,
			yScale = POSITION_CUBE.END.scale,
			rotation = 0,
			x = POSITION_CUBE.END.x,
			y = POSITION_CUBE.END.y,
			onStart = function()
				sound.play("powerCubeMove")
				powerCube.isVisible = true
			end, 
			onComplete = function()
				sound.play("scoreGiven")
				display.remove(powerCube)
				cubesText.text = powerCubesStart + index
				transition.cancel(cubesText)
				cubesText.xScale = 1.3
				cubesText.yScale = 1.2
				transition.to(cubesText, {tag = TAG_TRANSITION_WINSCREEN, time = 500, yScale = 1, xScale = 1, transition = easing.outElastic})
			end
		}
		
		transition.to(powerCube, transitionOptions)
		currentStep = currentStep + 1
	end
	
	local powerCube = display.newImage("images/manager/powerCube1.png")
	powerCube.x = POSITION_CUBE.END.x
	powerCube.y = POSITION_CUBE.END.y
	powerCube:scale(SCALE_POWERCUBE, SCALE_POWERCUBE)
	winScreen:insert(powerCube)
	
	local masterSprite = newMasterSprite()
	masterSprite.x = OFFSET_MASTER.WIN.x
	masterSprite.y = OFFSET_MASTER.WIN.y
	masterSprite:setSequence("win")
	masterSprite:play()
	winScreen:insert(masterSprite)
	
	local title = display.newImage(localization.format("images/manager/good_%s.png"))
	title.x = OFFSET_TITLE.WIN.x
	title.y = OFFSET_TITLE.WIN.y
	title.xScale = 0.05
	title.yScale = 0.05
	winScreen:insert(title)
	transition.to(title, {tag = TAG_TRANSITION_WINSCREEN, time = 800, xScale = SCALE_TITLE.WIN, yScale = SCALE_TITLE.WIN, transition = easing.outQuad})
	
	local totalDelay = totalSteps * cubeDelay + TIME_CUBES + DELAY_REMOVE_WINSCREEN
	
	transition.to(winScreen, {tag = TAG_TRANSITION_LOSESCREEN, delay = 100, time = 600, alpha = 1, transition = easing.outQuad})
	transition.to(winScreen, {tag = TAG_TRANSITION_LOSESCREEN, delay = totalDelay, time = 500, alpha = 0, onComplete = function()
		if onComplete and "function" == type(onComplete) then
			onComplete()
		end
		display.remove(winScreen)
		winScreen = nil
	end})
	
	return winScreen
end

function managerUI.newLoseScreen(options)
	options = options and "table" == type(options) and options or {
		correctAnswer = {id = "text", text = "???", fontSize = SIZE_FONT_CORRECTANSWER}
	}
	local onComplete = options.onComplete
	local showTime = options.showTime or DELAY_REMOVE_LOSESCREEN
	
	local loseScreen = display.newGroup()
	loseScreen.alpha = 0
	loseScreen:addEventListener("tap", function() return true end)
	loseScreen:addEventListener("touch", function() return true end)
	loseScreen.x = display.contentCenterX
	loseScreen.y = display.contentCenterY
	
	local fadeRect = display.newRect(loseScreen, 0, 0, display.viewableContentWidth, display.viewableContentHeight)
	fadeRect:setFillColor(0)
	fadeRect.alpha = 0.4
	
	local background = display.newImage("images/manager/windowLose.png")
	background:scale(SCALE_WINDOW, SCALE_WINDOW)
	loseScreen:insert(background)
	
	local messageOptions = {
		x = OFFSET_WRONG_MESSAGE_TEXT.x,
		y = OFFSET_WRONG_MESSAGE_TEXT.y,
		font = settings.fontName,
		text = localization.getString("theCorrectAnswerIs"),
		fontSize = SIZE_FONT_CORRECTANSWER,
		width = 300,
		align = "center"
	}
	local messageText = display.newText(messageOptions)
	messageText:setFillColor(unpack(colors.yellow))
	loseScreen:insert(messageText)
	
	local correctAnswer = options.correctAnswer
	if correctAnswer and correctAnswer.id then
		if correctAnswer.id == "text" then
			local correctAnwerText = createCorrectAnswerText(correctAnswer)
			loseScreen:insert(correctAnwerText)
		elseif correctAnswer.id == "group" then
			local correctAnswerGroup = correctAnswer.group
			correctAnswerGroup.x, correctAnswerGroup.y = OFFSET_CORRECT_ANSWER.x, OFFSET_CORRECT_ANSWER.y
			loseScreen:insert(correctAnswerGroup)
			correctAnswerGroup.isVisible = true
			setAllAlpha(correctAnswerGroup, 1)
		elseif correctAnswer.id == "image" then
			local correctAnswerImage = createCorrectAnswerImage(correctAnswer)
			loseScreen:insert(correctAnswerImage)
		end
	end
	
	local masterSprite = newMasterSprite()
	masterSprite.x = OFFSET_MASTER.LOSE.x
	masterSprite.y = OFFSET_MASTER.LOSE.y
	masterSprite:setSequence("lose")
	masterSprite:play()
	loseScreen:insert(masterSprite)
	
	local message = display.newImage(localization.format("images/manager/dont_%s.png"))
	message.x = OFFSET_TITLE.WIN.x
	message.y = OFFSET_TITLE.WIN.y
	message.xScale = 0.05
	message.yScale = 0.05
	loseScreen:insert(message)
	transition.to(message, {tag = TAG_TRANSITION_WINSCREEN, time = 800, xScale = SCALE_TITLE.LOSE, yScale = SCALE_TITLE.LOSE, transition = easing.outQuad})
	
	transition.to(loseScreen, {tag = TAG_TRANSITION_LOSESCREEN, delay = 100, time = 600, alpha = 1, transition = easing.outQuad})
	transition.to(loseScreen, {tag = TAG_TRANSITION_LOSESCREEN, delay = 700 + showTime, time = 500, alpha = 0, onComplete = function()
		if onComplete and "function" == type(onComplete) then
			onComplete()
		end
		display.remove(loseScreen)
		loseScreen = nil
	end})
	
	return loseScreen
end

initialize()

return managerUI