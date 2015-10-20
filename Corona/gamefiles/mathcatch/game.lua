----------------------------------------------- Math catch
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local screen = require( "libs.helpers.screen" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local sceneGroup
local background
local operand1Text, operand2Text
local operator
local currentGametype
local correctAnswer
local answersGroup, answerList
local wrongAnswers

local hasAnswered
local catcher
local timerGenerateAnswers
local questionMarkText
local equalityString
local answerStrings
local operandBackgroundGroup
local operandText
local equals
local answerBackground
local answerGp
local hojas
local operationResult

local gameTutorial, isFirstTime, instructions
----------------------------------------------- Constants
local DEBUG = false

local POSITION_Y_EQUATION = display.contentCenterY - 270
local SIZE_TEXT = 100
local SCALE_SIGNS = 1

local PERCENTAGE_SPAWN_WIDTH = 0.8
local RADIUS_COLLISION = 50
local DEFAULT_COLOR_BACKGROUND = {169/255,237/255,152/255}

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local TAG_TRANSITION_ANSWERS = "tagTransitionsAnswers"
local TAG_TRANSITION_TUTORIAL = "tagTutorial"

local POSITION_Y_ANSWER_SPAWN = display.screenOriginY + 100

local POSITION_X_OPERAND1 = display.contentCenterX - 300
local POSITION_X_OPERATOR = display.contentCenterX - 150
local POSITION_X_OPERAND2 = display.contentCenterX
local POSITION_X_EQUALS = display.contentCenterX + 150
local POSITION_X_ANSWER = display.contentCenterX + 300

local POSITION_Y_ANSWER_DESPAWN = display.screenOriginY + display.viewableContentHeight + 200
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = catcher.x, y = catcher.y, toX = catcher.x + 200, toY = catcher.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
		isFirstTime = false
	end
end

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

local function generateAnswers()
	local answerCount = 0
	local indexCorrectAnswer = isFirstTime and 0 or math.random(0,3)
	
	local function generateAnswer()
		local positionX
		if isFirstTime then
			positionX = catcher.x + 200
		else
			local halfSpawnWidth = display.viewableContentWidth * PERCENTAGE_SPAWN_WIDTH * 0.5
			positionX = display.contentCenterX + math.random(-halfSpawnWidth, halfSpawnWidth)
		end

		local answerGroup = display.newGroup()
		answerGroup.x = positionX
		answerGroup.y = POSITION_Y_ANSWER_SPAWN
		answerGroup.alpha = 0
		answerGroup.radius = RADIUS_COLLISION
		answersGroup:insert(answerGroup)
		
		if DEBUG then
			local debugCircle = display.newCircle(answerGroup, 0, 0, answerGroup.radius)
			debugCircle:setFillColor(1,0,0)
		end

		local answerBacgkround = display.newImage(assetPath.."minigames-elements-42.png")
		answerGroup:insert(answerBacgkround)
		answerGroup.background = answerBackground
		
		if (answerCount == indexCorrectAnswer) or (answerCount % 4 == indexCorrectAnswer) then
			answerGroup.number = correctAnswer
			answerGroup.isCorrect = true 
		else
			answerGroup.number = wrongAnswers[math.random(1, #wrongAnswers)]
			answerGroup.isCorrect = false
		end
		
		answerCount = answerCount + 1
		
		local lblSize = SIZE_TEXT --100
		if answerGroup.number >= 100 then lblSize = SIZE_TEXT-12 end
		if answerGroup.number >= 1000 then lblSize = SIZE_TEXT-29 end
		
		local answerText = display.newText(answerGroup.number, 0, 25, settings.fontName, lblSize)
		answerText:setFillColor(255/255, 255/255, 255/255)
		answerText.fill.effect = "filter.monotone"
		answerText.fill.effect.r = 0
		answerText.fill.effect.g = 0
		answerText.fill.effect.b = 0
		answerGroup:insert(answerText)
		answerGroup.text = answerText

		local fallTime = 4000
		local timeDelay = 1000

		director.to(scenePath, answerGroup, {tag = TAG_TRANSITION_ANSWERS, delay = timeDelay, time = fallTime, y = POSITION_Y_ANSWER_DESPAWN, transition = easing.inQuad, onComplete = function()
			answerGroup.removeFlag = true
		end})
		director.to(scenePath,  answerGroup, {tag = TAG_TRANSITION_ANSWERS, delay = timeDelay, transition = easing.inQuad, time = fallTime * 0.4, alpha = 1 } )

		answerList[#answerList + 1] = answerGroup
	end
	
	generateAnswer()
	timerGenerateAnswers = director.performWithDelay(scenePath, 2000, generateAnswer, 0)
end

local function generateSlideCatcher(sceneGroup)
	catcher = display.newImage(assetPath.."minigames-elements-43.png")
	catcher.x = display.contentCenterX
	catcher.y = display.screenOriginY + display.viewableContentHeight - 100
	catcher.radius = RADIUS_COLLISION
	sceneGroup:insert(catcher)
	
	function catcher:touch( event )
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			sound.play("dragtrash")
			display.getCurrentStage():setFocus( self )
			self.isFocus = true
			catcher.deltaX = event.x - catcher.x
		elseif self.isFocus then
			if event.phase == "moved" then
				catcher.x = event.x - catcher.deltaX
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				self.isFocus = nil
			end
		end
	end
	catcher:addEventListener("touch")
end

local function createOperator(imagePath)
	local operator = display.newImage(imagePath)
	operator.x = POSITION_X_OPERATOR
	operator.y = POSITION_Y_EQUATION + 15
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
	
	local lblSize = 80 --100
	if tonumber(operand1Text.text) >= 100 then lblSize = SIZE_TEXT-39 end
	if tonumber(operand1Text.text) >= 1000 then lblSize = SIZE_TEXT-49 end
	operand1Text.size = lblSize
	
	lblSize = 80 --100
	if tonumber(operand2Text.text) >= 100 then lblSize = SIZE_TEXT-39 end
	if tonumber(operand2Text.text) >= 1000 then lblSize = SIZE_TEXT-49 end	
	operand2Text.size = lblSize
end

local function createOperationBase(sceneGroup)
	operandBackgroundGroup = display.newGroup()
	local function createOperand(positionX)
		local operandBackground = display.newImage(assetPath.."operacion.png")
		operandBackgroundGroup:insert( operandBackground )
		--operandBackground:scale(1.5, 1.5)
		operandBackground.x = positionX
		operandBackground.y = POSITION_Y_EQUATION
		--sceneGroup:insert(operandBackground)
		operandText = display.newText("0", positionX, POSITION_Y_EQUATION + 25, settings.fontName, 0)
		operandBackgroundGroup:insert(operandText)
		operandText:setFillColor(1)
		--sceneGroup:insert(operandText)
		return operandText
	end
	
	operand1Text = createOperand(POSITION_X_OPERAND1)
	operand2Text = createOperand(POSITION_X_OPERAND2)
	
	equals = display.newImage("images/minigames/equalsBrown.png")
	equals.x = POSITION_X_EQUALS
	equals.y = POSITION_Y_EQUATION + 15
	equals.xScale = SCALE_SIGNS
	equals.yScale = SCALE_SIGNS
	sceneGroup:insert(equals)
	
	answerBackground = display.newImage(assetPath.."minigames-elements-30.png")
	answerBackground.x = POSITION_X_ANSWER
	answerBackground.y = POSITION_Y_EQUATION
	sceneGroup:insert(answerBackground)
	
	questionMarkText = display.newText("?", answerBackground.x, POSITION_Y_EQUATION - 10, settings.fontName, SIZE_TEXT)
	sceneGroup:insert(questionMarkText)
end

local function updateGame()
	for answerIndex = #answerList, 1, -1 do
		local answer = answerList[answerIndex]
		
		if hasCollided(answer, catcher) and not hasAnswered then
			hasAnswered = true
			
			transition.cancel(TAG_TRANSITION_ANSWERS)
			timer.cancel(timerGenerateAnswers)
			timerGenerateAnswers = nil
			
			for index = 1, #answerList do
				if index ~= answerIndex then
					local otherAnswer = answerList[index]
					director.to(scenePath, otherAnswer, {alpha = 0, time = 500, transition = easing.outQuad})
				end
			end
			
			director.to(scenePath, questionMarkText, {time = 500, alpha = 0, transition = easing.outQuad})
			director.to(scenePath, answer, {time = 500, x = POSITION_X_ANSWER, y = POSITION_Y_EQUATION, transition = easing.outQuad, onStart = function() answerGp:insert(answer) end})--xScale = 1.5, yScale = 1.5, 
			sound.play("pop")
			
			answerStrings = { answerList[answerIndex].number }
			local data = {questionString = equalityString, answerStrings = answerStrings}
			
			if answerList[answerIndex].isCorrect then
				if manager and manager.correct then
					manager.correct(data)
				end
			else
				if manager and manager.wrong then
						manager.wrong({id = "text", text = operationResult, fontSize = 80})
				end
			end
		end
		
		if answer.removeFlag then
			display.remove(answer)
			answer = nil
			table.remove(answerList, answerIndex)
		end
	end
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
	
	Runtime:removeEventListener("enterFrame", updateGame)
end

local function initialize(parameters, sceneView)
	parameters = parameters or {}
	
	local data = parameters.data or {GAMETYPES[DEFAULT_GAMETYPE_INDEX]}
	local colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsMathcatch")
	
	currentGametype = data[1]
	background:setFillColor(unpack(colorRGB))
	
	hasAnswered = false
	answerList = {}
	
	questionMarkText.alhpa = 1
	catcher.x = display.contentCenterX

	answerGp = display.newGroup( )
	
	Runtime:addEventListener("enterFrame", updateGame)
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusBrown.png",
		["subtraction"] = "images/minigames/minusBrown.png",
		["multiplication"] = "images/minigames/multiplyBrown.png",
		["division"] = "images/minigames/divisionBrown.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	correctAnswer = operation.result or 0
	operationResult = operation.operationString
	wrongAnswers = parameters.wrongAnswers
	
	local nameImageOperator = operatorFilenames[chosenCategory]
	
	generateAnswers(correctAnswer)
	hojas = display.newImage(assetPath.."ojas.png")
	hojas.anchorY = 1
	local hojasScale = display.viewableContentWidth/hojas.width
	hojas:scale(hojasScale, hojasScale)
	hojas.x = display.contentCenterX
	hojas.y = screen.getPositionY(0.35)
	
	sceneView:insert(hojas)
	generateEquation(operation.operands[1], operation.operands[2], nameImageOperator)
	sceneView:insert(operandBackgroundGroup)
	equals:toFront( )
	instructions:toFront()
	answerBackground:toFront( )
	sceneView:insert( answerGp)
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Math catch",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2},
			{id = "wrongAnswer", amount = 6, tolerance = 10},
		},
	}
end 

function game:create(event)
	sceneGroup = self.view

	background = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	local tronco = display.newImage(assetPath .. "tronco.png")
	local troncoScale = display.viewableContentWidth/tronco.width
	tronco:scale(troncoScale, troncoScale)
	tronco.x = display.contentCenterX
	tronco.y = (display.viewableContentHeight +10) - ((tronco.height*troncoScale)/2)
	sceneGroup:insert(tronco)
	answersGroup = display.newGroup()
	sceneGroup:insert(answersGroup)
	
	generateSlideCatcher(sceneGroup)
	createOperationBase(sceneGroup)
	
	instructions = display.newText("",  display.contentCenterX, screen.getPositionY(0.45), settings.fontName, 38)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneGroup:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params, sceneGroup)
		showTutorial()
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		display.remove(hojas)
		display.remove(answerGp)
		endMinigame()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
