----------------------------------------------- Math cloud
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local sceneGroup
local background
local answerText, operand2Text
local operator
local currentGametype
local correctAnswer
local wrongAnswers
local answersGroup, answerList
local answerBackground

local hasAnswered
local timerGenerateAnswersLeft, timerGenerateAnswersRight
local questionMarkText
local operand1
local questionString
local answerStrings
local gameTutorial
local correctGroup
local operationResult

local sheetData = { width=256, height=256, numFrames=8, sheetContentWidth=1024, sheetContentHeight=512 }
local sheet1 = graphics.newImageSheet(assetPath .. "pajaritosColores.png", sheetData )
local sequenceData =
{
    { name="bird1", frames={ 1, 2}, time=240},
    { name="bird2", frames={ 3, 4}, time=240},
    { name="bird3", frames={ 5, 6}, time=240},
	{ name="bird4", frames={ 7, 8}, time=240},
}

local firstTime, tutorialTap, tutorialHand, instructions
----------------------------------------------- Constants

local POSITION_Y_EQUATION = display.contentCenterY - 270
local SIZE_TEXT = 60
local SCALE_SIGNS = 1

local DEFAULT_COLOR_BACKGROUND = {161/255,229/255,223/255}

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local TAG_TRANSITION_ANSWERS = "tagTransitionsAnswers"
local TAG_TRANSITION_TUTORIAL = "tagTutorial"

local POSITION_X_ANSWER_SPAWN_LEFT = display.screenOriginX - 100
local POSITION_X_ANSWER_SPAWN_RIGHT = display.screenOriginX + display.viewableContentWidth + 100

local POSITION_X_OPERAND1 = display.contentCenterX - 300
local POSITION_X_OPERATOR = display.contentCenterX - 150
local POSITION_X_OPERAND2 = display.contentCenterX
local POSITION_X_EQUALS = display.contentCenterX + 150
local POSITION_X_ANSWER = display.contentCenterX + 300

local HEIGHT_ROW_RESPAWN = 230
local POSITION_Y_SECOND_ROW_RESPAWN = display.screenOriginY + display.viewableContentHeight - HEIGHT_ROW_RESPAWN
local POSITION_Y_FIRST_ROW_RESPAWN = POSITION_Y_SECOND_ROW_RESPAWN - HEIGHT_ROW_RESPAWN

----------------------------------------------- Functions 

local function updateMotion(object)
	object.motionLoop = object.motionLoop + 2

	local radians = object.motionLoop / 57.2957795131 -- Converting to radians

	local offset = math.sin(radians) * 30;   
	object.y = object.originalY + offset

	if object.motionLoop >= 360 then
		object.motionLoop = object.motionLoop - 360
	end
end

local function updateGame()
	for answerIndex = #answerList, 1, -1 do
		local answer = answerList[answerIndex]
		
		if answer and answer.motionLoop then
			updateMotion(answer)
		end
		
		if answer.removeFlag then
			display.remove(answer)
			answer = nil
			table.remove(answerList, answerIndex)
		end
	end
end

local function showTutorial()
	if firstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, getObject = function() return correctGroup end},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function generateAnswers()
	local answerCount = 0
	local indexCorrectAnswer = firstTime and 0 or math.random(0,5)
	local pivotYFirstRow = POSITION_Y_FIRST_ROW_RESPAWN + (HEIGHT_ROW_RESPAWN * 0.5)
	local pivotYSecondRow = POSITION_Y_SECOND_ROW_RESPAWN + (HEIGHT_ROW_RESPAWN * 0.5)
	local radiousSpawnHeight = (HEIGHT_ROW_RESPAWN * 0.5) - 80
	
	local function generateAnswer(positionX, pivotY, endY, scaleImage)
		--imgScale = scaleImage
		local positionY = pivotY + math.random(-radiousSpawnHeight, radiousSpawnHeight)

		local answerGroup = display.newGroup()
		answerGroup.x = positionX
		answerGroup.y = positionY
		answerGroup.originalY = positionY
		answersGroup:insert(answerGroup)

		--local answerBacgkround = display.newImage(assetPath.."minigames-elements-30" .. math.random( 1, 4 ) .. ".png")
		local answerBackground = display.newSprite( sheet1, sequenceData )
		answerBackground:setSequence("bird" .. math.random( 1, 4 ))
		answerBackground:play()
		answerBackground.xScale = scaleImage
		answerGroup:insert(answerBackground)
		answerGroup.background = answerBackground
		answerGroup.imgScale = scaleImage
		
		if answerCount == indexCorrectAnswer or answerCount % 6  == indexCorrectAnswer then
			answerGroup.number = operand1
			correctGroup = answerGroup
		else
			answerGroup.number = wrongAnswers[math.random(1,#wrongAnswers)]
		end
		
		answerCount = answerCount + 1
		local answerText
		if scaleImage == 1 then
			answerText = display.newText(answerGroup.number, 5, 5, settings.fontName, SIZE_TEXT)
		else
			answerText = display.newText(answerGroup.number, -5, 5, settings.fontName, SIZE_TEXT)
		end
		answerText:setFillColor(0.5)
		answerText.fill.effect = "filter.monotone"
		answerText.fill.effect.r = 1
		answerText.fill.effect.g = 1
		answerText.fill.effect.b = 1
		answerGroup:insert(answerText)
		answerGroup.text = answerText
		answerGroup.motionLoop = math.random(0,360)
		answerGroup.removeFlag = false
		
		local function answerListenerFunction()
			Runtime:removeEventListener("enterFrame", updateGame)
			transition.cancel(TAG_TRANSITION_ANSWERS)
			tutorials.cancel(gameTutorial,300)
			if timerGenerateAnswersLeft then
				timer.cancel(timerGenerateAnswersLeft)
			end
			if timerGenerateAnswersRight then
				timer.cancel(timerGenerateAnswersRight)
			end
			timerGenerateAnswersLeft = nil
			timerGenerateAnswersRight = nil
			for index = #answerList, 1, -1 do
				local answer = answerList[index]
				answer:removeEventListener("tap", answerListenerFunction)
				if(answer ~= answerGroup) then
					director.to(scenePath, answer, {alpha = 0, time = 500, transition = easing.outQuad})
				end
			end
			
			--director.to(scenePath, answerGroup.background, {time = 500, alpha = 0, transition = easing.outQuad})
			--director.to(scenePath, answerGroup.text.fill.effect, {time = 500, r = 1, g = 1, b = 1, transition = easing.outQuad})
			--director.to(scenePath, answerGroup.text, {time = 500, xScale = 2, yScale = 2, transition = easing.outQuad})
			
			director.to(scenePath, questionMarkText, {time = 500, alpha = 0, transition = easing.outQuad})
			director.to(scenePath, answerGroup, {time = 500, x = POSITION_X_OPERAND1, y = POSITION_Y_EQUATION, transition = easing.outQuad,  onStart = function() director.to(scenePath, answerBackground, {time = 500, alpha=0}) if answerGroup.imgScale == -1 then answerGroup.xScale = -1 answerGroup[2].xScale = -1 end  end})
			sound.play("pop")
			
			if answerGroup.number == operand1 then
				if manager then
					manager.correct()
				end
			else
				if manager then
					manager.wrong({id = "text", text = operationResult , fontSize = 75})
				end
			end
			
		end
		
		answerGroup:addEventListener("tap", answerListenerFunction)

		local moveTime = 9000

		director.to(scenePath, answerGroup, {tag = TAG_TRANSITION_ANSWERS, time = moveTime, x = endY , onComplete = function()
			answerGroup.removeFlag = true
		end})
		answerList[#answerList + 1] = answerGroup
	end
	
	generateAnswer(POSITION_X_ANSWER_SPAWN_LEFT, pivotYFirstRow, POSITION_X_ANSWER_SPAWN_RIGHT, 1 )
	generateAnswer(POSITION_X_ANSWER_SPAWN_RIGHT, pivotYSecondRow, POSITION_X_ANSWER_SPAWN_LEFT, -1 )
	timerGenerateAnswersLeft = director.performWithDelay(scenePath, 3200,function()
		generateAnswer(POSITION_X_ANSWER_SPAWN_LEFT, pivotYFirstRow, POSITION_X_ANSWER_SPAWN_RIGHT, 1)
		end, 0)
	timerGenerateAnswersRight = director.performWithDelay(scenePath, 3200,function()
		generateAnswer(POSITION_X_ANSWER_SPAWN_RIGHT, pivotYSecondRow, POSITION_X_ANSWER_SPAWN_LEFT, -1 ) 
		end, 0)
		
end

local function createOperator(imagePath)
	local operator = display.newImage(imagePath)
	operator.x = POSITION_X_OPERATOR
	operator.y = POSITION_Y_EQUATION
	operator.xScale = SCALE_SIGNS
	operator.yScale = SCALE_SIGNS
	return operator
end

local function generateEquation(operanduno, operand2, nameImageOperator, correctAnswer, equalityString)
	operand1 = operanduno
	
	questionString = equalityString
	
	display.remove(operator)
	operator = createOperator(nameImageOperator)
	sceneGroup:insert(operator)
	
	answerText.text = correctAnswer
	operand2Text.text = operand2
end

local function createOperationBase(sceneGroup)
	local function createOperand(positionX)
		local operandBackground
		operandBackground = display.newImage(assetPath.."operacion.png")
		operandBackground.x = positionX
		operandBackground.y = POSITION_Y_EQUATION
		sceneGroup:insert(operandBackground)
		local operandText = display.newText("0", positionX, POSITION_Y_EQUATION+5, settings.fontName, SIZE_TEXT)
		operandText:setFillColor(4/255,9/255,102/255)
		sceneGroup:insert(operandText)
		return operandText
	end
	
	answerText = createOperand(POSITION_X_ANSWER)
	operand2Text = createOperand(POSITION_X_OPERAND2)
	
	local equals = display.newImage("images/minigames/equalsGreen.png")
	equals.x = POSITION_X_EQUALS
	equals.y = POSITION_Y_EQUATION
	equals.xScale = SCALE_SIGNS
	equals.yScale = SCALE_SIGNS
	sceneGroup:insert(equals)
	
	answerBackground = display.newImage(assetPath.."minigames-elements-30.png")
	answerBackground.x = POSITION_X_OPERAND1
	answerBackground.y = POSITION_Y_EQUATION
	sceneGroup:insert(answerBackground)
	
	questionMarkText = display.newText("?", answerBackground.x, POSITION_Y_EQUATION - 10, settings.fontName, SIZE_TEXT)
	questionMarkText.isVisible = false
	sceneGroup:insert(questionMarkText)
end

local function cancelTutorial()
	tutorials.cancel(gameTutorial)
end

local function endMinigame()
	if timerGenerateAnswersRight then
		timer.cancel(timerGenerateAnswersRight)
		timerGenerateAnswersRight = nil
	end
	
	if timerGenerateAnswersLeft then
		timer.cancel(timerGenerateAnswersLeft)
		timerGenerateAnswersLeft = nil
	end
		
	for index = #answerList, 1, -1 do
		display.remove(answerList[index])
		answerList[index] = nil
	end
	
	Runtime:removeEventListener("enterFrame", updateGame)
	
end



local function initialize(parameters)
	parameters = parameters or {}
	
	local data = parameters.data or {GAMETYPES[DEFAULT_GAMETYPE_INDEX]}
	local colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND
	firstTime = parameters.isFirstTime
	
	currentGametype = data[1]
	background:setFillColor(unpack(colorRGB))
	
	instructions.text = localization.getString("instructionsMathcloud")
	
	hasAnswered = false
	answerList = {}
	
	questionMarkText.alpha = 1
	Runtime:addEventListener("enterFrame", updateGame)
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusGreen.png",
		["subtraction"] = "images/minigames/minusGreen.png",
		["multiplication"] = "images/minigames/multiplyGreen.png",
		["division"] = "images/minigames/divisionGreen.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	local operand1 = operation.operands and operation.operands[1] or 0
	local operand2 = operation.operands and operation.operands[2] or 0
	correctAnswer = operation.result or 0
	wrongAnswers = parameters.wrongAnswers
	operationResult = operation.operationString
	
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	
	generateEquation(operand1, operand2, nameImageOperator,correctAnswer, equalityString)
	generateAnswers()
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = true,
		wrongDelay = 800,
		correctDelay = 800,
		
		name = "Math birds",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minAnswer = 1},
			{id = "wrongAnswer", amount = 12, tolerance = 7, minNumber = 1},
		},
	}
end 

function game:create(event)
	local sceneGroup = self.view

	background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	for indexNubes = 1, 5 do
		local nube = display.newImage(assetPath .. "nube.png")
		nube.x = math.random(display.viewableContentWidth*0.15, display.viewableContentWidth*0.85)
		nube.y = math.random(display.viewableContentHeight*0.4, display.viewableContentHeight*0.85)
		local escala = (math.random(50, 100))/100
		nube:scale(escala, escala )
		sceneGroup:insert(nube)
	end
	createOperationBase(sceneGroup)
	answersGroup = display.newGroup()
	sceneGroup:insert(answersGroup)
	
	instructions = display.newText("",  display.viewableContentWidth*0.7, display.viewableContentHeight*0.35, settings.fontName, 30)
	instructions:setFillColor(84/255, 17/255, 17/255)
	sceneGroup:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params)
		showTutorial()
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		answerBackground.alpha = 1
		endMinigame()
		cancelTutorial()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
