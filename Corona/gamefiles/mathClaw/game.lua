----------------------------------------------- Math Claw
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require ( "libs.helpers.extratable")

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local background
local sceneGroup
local operand1Text, operand2Text
local operator
local currentGametype
local correctAnswer
local wrongAnswers
local correctPosition
local answersGroup, answerList
local hasAnswered
local clawGroup
local claw, rope
local timerGenerateAnswers
local questionMarkText
local equalityString
local answerStrings
local answerBackgroundGroup
local gameTutorial
local operationResult

local isFirstTime
local instructions
----------------------------------------------- Constants

local FONT_COLOR_ANSWERS = {255/255, 255/255, 255/255}
local FONT_COLOR_OPERANDS = {255/255, 255/255, 255/255}


local ANSWER_TEXT = 68

local POSITION_Y_EQUATION = display.contentCenterY - 270
local SIZE_TEXT = 60
local SCALE_SIGNS = .50

local RADIUS_COLLISION = 50
local DEFAULT_COLOR_BACKGROUND = {0.5,0.7,0.3}

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local TAG_TRANSITION_TUTORIAL = "tagTutorial"


local POSITION_X_OPERAND1 = display.contentCenterX - 300
local POSITION_X_OPERATOR = display.contentCenterX - 150
local POSITION_X_OPERAND2 = display.contentCenterX
local POSITION_X_EQUALS = display.contentCenterX + 150
local POSITION_X_ANSWER = display.contentCenterX + 300

local POSITION_Y_GENERATED_ANSWERS = display.screenOriginY + display.viewableContentHeight - 100

local POSITION_X_INSTRUCTIONS = display.screenOriginY + 250
local ORIGIN_Y_BAR = POSITION_X_INSTRUCTIONS + 30
local ORIGIN_Y_CLAW = ORIGIN_Y_BAR + 50

----------------------------------------------- Functions

local function hasCollided( object1, object2 )
	if object1 and object2 then
		local distanceX = object1.x - object2.x
		local distanceY = object1.y - object2.y

		local distanceSquared = distanceX * distanceX + distanceY * distanceY
		local radiusSum = object2.radius + object1.radius
		local radii = radiusSum * radiusSum

		if distanceSquared < radii then
		   return true
		end
	end
	return false
end

local function clawTouch( event )
	local self = event.target

		if event.phase == "began" then
			sound.play("dragtrash")
			tutorials.cancel(gameTutorial,300)
			display.getCurrentStage():setFocus( self )
			self.isFocus = true
			claw.deltaX = event.x - claw.x
			claw.deltaY = event.y - claw.y
		elseif self.isFocus then
			if event.phase == "moved" then
				claw.x = event.x - claw.deltaX
				claw.y = event.y - claw.deltaY
				if claw.y < ORIGIN_Y_CLAW then
					claw.y = ORIGIN_Y_CLAW
				end
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				self.isFocus = nil
				sound.play("pop")
			end
		end
end

local function updateGame()
	for answerIndex = #answerList, 1, -1 do
		local answer = answerList[answerIndex]
		
		if not hasAnswered and hasCollided(answer, claw) then
			hasAnswered = true
			claw:removeEventListener("touch", clawTouch)
			
			answerStrings = { answer.number }
			local data = {equalityString = equalityString, answerStrings = answerStrings}

			if answer.isCorrect then
				if manager and manager.correct then
					manager.correct(data)
				end
			else
				if manager and manager.wrong then
					manager.wrong({id = "text", text = operationResult})
				end
			end
			
			sound.play("minigamesMachineLock")
			director.to(scenePath, claw, {x = answer.x, y = answer.y - 60, time = 500, onComplete = function ()
				local tempX = claw.x
				local tempY = claw.y
				display.remove(claw)
				claw = display.newImage(assetPath .. "minigames-elements-46.png")
				clawGroup:insert(claw)
				claw.x = tempX
				claw.y = tempY
				claw.radius = RADIUS_COLLISION
				sound.play("minigamesMachineDrag")
				director.to(scenePath, claw, {y = ORIGIN_Y_CLAW, time = 1200})
				answerBackgroundGroup:insert(answer)
				director.to(scenePath, answer, {y = ORIGIN_Y_CLAW + 60, time = 1200, onComplete = function()
					sound.stopAll(200)
					director.to(scenePath, answer, {time = 500, xScale = 1, yScale = 1, transition = easing.outQuad})
					director.to(scenePath, questionMarkText, {time = 500, alpha = 0, transition = easing.outQuad})
					director.to(scenePath, answer, {time = 500, x = POSITION_X_ANSWER, y = POSITION_Y_EQUATION , transition = easing.outQuad})
					sound.play("pop")
				end})
			end})
			display.getCurrentStage():setFocus( nil )
			claw.isFocus = nil
		end
	end
	
	rope.x = claw.x
	rope.height = claw.y - ORIGIN_Y_CLAW
end

local function tutorial()
	if isFirstTime then
	
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = claw.x, y = claw.y, toX = correctPosition.x, toY = correctPosition.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function generateAnswers(correctAnswer)
	
	local indexCorrectAnswer = isFirstTime and 0 or math.random(0, 3)
	local answerCount = 0
	local answersSettedTable = {correctAnswer, 0}
	for indexAnswer = 4, 1, -1 do
		
		local answerGroup = display.newGroup()
		answerGroup.x = display.screenOriginX + (display.viewableContentWidth * (0.20 * indexAnswer))
		answerGroup.y = display.screenOriginY + display.viewableContentHeight - 150
		answerGroup.radius = RADIUS_COLLISION
		answersGroup:insert(answerGroup)
		
		local answerBacgkround = display.newImage(assetPath.."minigames-elements-28.png")
		answerBacgkround:scale(.65, .65)
		answerGroup:insert(answerBacgkround)
		answerGroup.background = answerBacgkround
		
		if (answerCount == indexCorrectAnswer) or (answerCount % 4 == indexCorrectAnswer) then
			answerGroup.number = correctAnswer
			answerGroup.isCorrect = true
			correctPosition = answerGroup
		else
			local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)
			
			answerGroup.number = fakeAnswer
			answerGroup.isCorrect = false
		end
		
		answerCount = answerCount + 1
		
		local answerText = display.newText(answerGroup.number, 13, 10, settings.fontName, ANSWER_TEXT)
		answerText:setFillColor(unpack( FONT_COLOR_ANSWERS ))
		answerGroup:insert(answerText)
		answerGroup.text = answerText
		
		answerList[#answerList + 1] = answerGroup
	end
end

local function generateClaw(sceneGroup)	
	rope = display.newImage(assetPath.."cadena.png")
	rope.x = display.contentCenterX
	rope.y = ORIGIN_Y_CLAW - 50
	rope.anchorY = 0
	clawGroup = display.newGroup()
	clawGroup:insert(rope)
	sceneGroup:insert(clawGroup)
end

local function createOperator(imagePath)
	local operator = display.newImage(imagePath)
	operator.x = POSITION_X_OPERATOR
	operator.y = POSITION_Y_EQUATION
	operator.xScale = SCALE_SIGNS
	operator.yScale = SCALE_SIGNS
	return operator
end

local function generateEquation(operand1, operand2, nameImageOperator)	
	display.remove(operator)
	operator = createOperator(nameImageOperator)
	sceneGroup:insert(operator)
	
	operand1Text.text = operand1
	operand2Text.text = operand2
end

local function createOperationBase(sceneGroup)
	
	answerBackgroundGroup = display.newGroup()
		
		local topbar = display.newImage(assetPath.."barrasuperior.png", display.viewableContentWidth, display.viewableContentHeight * 0.17)
		topbar.x = display.contentCenterX
		topbar:scale(1.25, 1.15)
		--topbar.y = display.viewableContentHeight * 0.15
		answerBackgroundGroup:insert(topbar)
		
	local answerBackground = display.newImage(assetPath.."minigames-elements-50.png")
		answerBackground:scale(.65,.65)
	answerBackground.x = POSITION_X_ANSWER
	answerBackground.y = POSITION_Y_EQUATION
	answerBackgroundGroup:insert(answerBackground)
	sceneGroup:insert(answerBackgroundGroup)
		

	
	local function createOperand(positionX)
		local operandBackground = display.newImage(assetPath.."minigames-elements-29.png")
				operandBackground:scale(.65, .65)
		operandBackground.x = positionX
		operandBackground.y = POSITION_Y_EQUATION
		sceneGroup:insert(operandBackground)
		local operandText = display.newText("0", positionX + 13, POSITION_Y_EQUATION + 10, settings.fontName, SIZE_TEXT)
		operandText:setFillColor(unpack(FONT_COLOR_OPERANDS))
		sceneGroup:insert(operandText)
		return operandText
	end
	
	operand1Text = createOperand(POSITION_X_OPERAND1)
	operand2Text = createOperand(POSITION_X_OPERAND2)
	
	local equals = display.newImage("images/minigames/equalsDarkGreen.png")
	equals.x = POSITION_X_EQUALS
	equals.y = POSITION_Y_EQUATION
	equals.xScale = SCALE_SIGNS
	equals.yScale = SCALE_SIGNS
	sceneGroup:insert(equals)
	
	questionMarkText = display.newText("?", answerBackground.x, POSITION_Y_EQUATION - 10, settings.fontName, SIZE_TEXT)
	sceneGroup:insert(questionMarkText)
end

local function endMinigame()
	if timerGenerateAnswers then
		timer.cancel(timerGenerateAnswers)
		timerGenerateAnswers = nil
	end
		
	for index = #answerList, 1, -1 do
		display.remove(answerList[index])
		answerList[index] = nil
	end
	
	display.remove(claw)
	Runtime:removeEventListener("enterFrame", updateGame)
	
end

local function initialize(parameters)
	parameters = parameters or {}
	
	operationResult = parameters.operation.operationString
	
	local data = parameters.data or {GAMETYPES[DEFAULT_GAMETYPE_INDEX]}
	local colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND

	isFirstTime = parameters.isFirstTime
	
	currentGametype = data[1]
	
	instructions.text = localization.getString("instructionsMathclaw")
	
	hasAnswered = false
	answerList = {}
	
	questionMarkText.alpha = 0
	claw = display.newImage(assetPath.."minigames-elements-45.png")
	claw.x = display.contentCenterX
	claw.y = ORIGIN_Y_CLAW
	claw.radius = RADIUS_COLLISION
	clawGroup:insert(claw)
	rope.x = claw.x
	rope.y = ORIGIN_Y_CLAW - 50
	rope.height = 0
	claw:addEventListener("touch", clawTouch)
	Runtime:addEventListener("enterFrame", updateGame)
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusDarkGreen.png",
		["subtraction"] = "images/minigames/minusDarkGreen.png",
		["multiplication"] = "images/minigames/multiplyDarkGreen.png",
		["division"] = "images/minigames/divisionDarkGreen.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	correctAnswer = operation.result or 0
	wrongAnswers = parameters.wrongAnswers
	
	local nameImageOperator = operatorFilenames[chosenCategory]
	
	generateEquation(operation.operands[1], operation.operands[2], nameImageOperator)
	generateAnswers(correctAnswer)
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = true,
		correctDelay = 2800,
		wrongDelay = 2800,
		
		name = "Math claw",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minAnswer = 1, minOperand = 1},
			{id = "wrongAnswer", amount = 6, tolerance = 8, minNumber = 1},
		},
	}
end 

function game:create(event)
	local sceneGroup = self.view
		
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:toBack()
	sceneGroup:insert(background)	
		
	answersGroup = display.newGroup()
	sceneGroup:insert(answersGroup)
	
	generateClaw(sceneGroup)
	createOperationBase(sceneGroup)	
	
	instructions = display.newText("",  display.contentCenterX, display.screenOriginY + 250, settings.fontName, 32)
	instructions:setFillColor(255/255, 255/255, 255/255)
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
		tutorial(sceneGroup)
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		endMinigame()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game