----------------------------------------------- Math invaders
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local widget = require( "widget" )
local screen = require( "libs.helpers.screen" )
local extratable = require( "libs.helpers.extratable" )

local game = director.newScene() 
----------------------------------------------- Variables
local nave
local shooter 
local balas

local manager
local background
local operand1Text, operand2Text
local operator
local correctAnswer
local answersSettedTable
local wrongAnswers
local answersGroup, answerList
local questionString
local answerStrings
local sceneGroup 
local answerBackground

local notHasAnswered
local questionMarkText
local instructions
local isFirstTime, gameTutorial
local operationResult
----------------------------------------------- Constants
local DEBUG = false 
local Velocidad_Estrellas = 0.02 --pixeles /ms

local POSITION_Y_EQUATION = display.viewableContentHeight * 0.20
local SIZE_TEXT = 50
local RADIUS_COLLISION = 50
local TAG_TRANSITION_ANSWERS = "tagTransitionsAnswers"

local POSITION_X_OPERAND1 = display.contentCenterX - 300
local POSITION_X_OPERATOR = display.contentCenterX - 150
local POSITION_X_OPERAND2 = display.contentCenterX
local POSITION_X_EQUALS = display.contentCenterX + 150
local POSITION_X_ANSWER = display.contentCenterX + 300

----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then
		local correctAnswerX
		for i=1, #answerList do
			if answerList[i].number == correctAnswer then
				correctAnswerX = answerList[i].x
				break
			end
		end
		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2000, getObject = function() return nave end, toX = correctAnswerX, toY = nave.y},
				[2] = {id = "tap", delay = 1000, time = 1500, x = shooter.x, y = shooter.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function hasCollided( object1, object2 )
	if object1 and object2 then
		local distanceX = object1.x - object2.x
		local distanceY = object1.y - object2.y
		
		local minDist = 50
		
		return math.abs(distanceX) < minDist and math.abs(distanceY) < minDist 
	end
	return false
end

local function generateAnswers(numEstrellas)
	local answerCount = 0
	local indexCorrectAnswer = math.random(1, numEstrellas)
	
	local marginXizq = display.viewableContentWidth * 0.15
	local marginXder = display.viewableContentWidth-shooter.contentWidth
	local minY = 160 + operand1Text.contentBounds.yMax
	local maxY = -80 + nave.contentBounds.yMin
	
	local distEntreEstrellas = (marginXder - marginXizq) / (numEstrellas)
	local posX = marginXizq + distEntreEstrellas/2
	
	answerList = {}
	
	local function generateAnswer()		
		local answerGroup = display.newGroup()
		answerGroup.x = posX
		
		answerGroup.y = display.contentCenterY + math.random(-100, 100)
		answerGroup.alpha = 0
		answerGroup.radius = RADIUS_COLLISION
		
		answersGroup:insert(answerGroup)
		
		if DEBUG then
			local debugCircle = display.newCircle(answerGroup, 0, 0, answerGroup.radius)
			debugCircle:setFillColor(1,0,0)
		end

		local answerBacgkround = display.newImage(assetPath.."estrella.png")
		answerGroup:insert(answerBacgkround)
		answerGroup.background = answerBacgkround
		
		answerCount = answerCount + 1
		if (answerCount == indexCorrectAnswer) or (currentIndex == (indexCorrectAnswer % 4)) then
			answerGroup.number = correctAnswer
		else
			local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)
			answerGroup.number = fakeAnswer
		end

		local answerText = display.newText(answerGroup.number, 0, -30, settings.fontName, SIZE_TEXT)
		answerText:setFillColor(0.23, 0.11, 0.59)
		answerGroup:insert(answerText)
		answerGroup.text = answerText
		
		director.to(scenePath,  answerGroup, {tag = TAG_TRANSITION_ANSWERS, delay = 500, transition = easing.inQuad, time=1000, alpha = 1 } )

		local function movimientoY(answerGroup)
			local toY = display.contentCenterY + math.random(-50, 50)
			
			local duracion = math.abs(answerGroup.y - toY) / Velocidad_Estrellas
			director.to(scenePath, answerGroup, {tag = TAG_TRANSITION_ANSWERS, delay = 0, time = duracion, y = toY, transition = easing.inOutQuad, onComplete = function()
				movimientoY(answerGroup)
			end})			
		end
		
		local function movimientoX(answerGroup, centroX)
			local toX = math.random(centroX - distEntreEstrellas/3, centroX + distEntreEstrellas/3)
			
			local duracion = math.abs(answerGroup.x - toX) / Velocidad_Estrellas
			director.to(scenePath, answerGroup, {tag = TAG_TRANSITION_ANSWERS, delay = 0, time = duracion, x = toX, transition = easing.inOutQuad, 
				onComplete = function()
					movimientoX(answerGroup, centroX)
				end})			
		end
		
		movimientoY(answerGroup)
		movimientoX(answerGroup, answerGroup.x)
		
		answerList[#answerList + 1] = answerGroup
		posX = posX + distEntreEstrellas
	end
	
	for i=1,numEstrellas do
		generateAnswer(i)
	end
end

local function generateNave()
	nave = display.newImage(assetPath.."nave.png")
	nave.y = display.screenOriginY + display.viewableContentHeight - 100
	sceneGroup:insert(nave)
	
	function nave:touch( event )
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			sound.play("dragUnit")
			display.getCurrentStage():setFocus( self )
			self.isFocus = true
			nave.deltaX = event.x - nave.x
		elseif self.isFocus then
			local limiteShooterX = shooter.contentBounds.xMin-nave.contentWidth/3
			if event.phase == "moved" and event.x < limiteShooterX then
				nave.x = event.x - nave.deltaX
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				sound.play("pop")
				self.isFocus = nil
			end
		end
	end
	nave:addEventListener("touch")
end

local function generateShooter()
	balas = {}	
	local function disparo( event )
		if event.phase == "ended" then
			sound.play("superLightBeamGun")
			local disparoSizeY = 50
			local disparoSizeX = 16
			local origenX = nave.x
			local origenY = nave.contentBounds.yMin +82 +disparoSizeY/2
			local disparoTempo = 900
			
			local balaIndex = #balas+1
			balas[balaIndex] = {}
			local rect = display.newRect(origenX, origenY, disparoSizeX, disparoSizeY)
			balas[balaIndex]["rect"] = rect
			sceneGroup:insert(rect)
			nave:toFront()
			balas[balaIndex]["transition"] = director.to(scenePath, rect, {x = origenX, y = operand1Text.contentBounds.yMax, time=disparoTempo})
		end
	end
	
	shooter =  widget.newButton{
		width = 128,
		height = 128,
		defaultFile = assetPath.."shooter.png",
		overFile = assetPath.."shooterDown.png",
		onEvent = disparo
	}
	shooter.x = display.viewableContentWidth-120
	shooter.y = display.viewableContentHeight-120
	
	sceneGroup:insert(shooter)
end

local function createOperator(imagePath)
	local operator = display.newImage(imagePath)
	operator.x = POSITION_X_OPERATOR - 10
	operator.y = POSITION_Y_EQUATION - 30
--	operator.xScale = SCALE_SIGNS
--	operator.yScale = SCALE_SIGNS
	return operator
end

local function generateEquation(operand1, operand2, nameImageOperator, equalityString)
	questionString = equalityString
	
	display.remove(operator)
	operator = createOperator(nameImageOperator)
	sceneGroup:insert(operator)
	
	operand1Text.text = operand1
	operand2Text.text = operand2
end

local function createOperationBase()
	
	local function createOperand(positionX)
		local operandBackground = display.newImage(assetPath.."estrella.png")
		operandBackground.x = positionX
		operandBackground.y = POSITION_Y_EQUATION - 40
		sceneGroup:insert(operandBackground)
		local operandText = display.newText("0", positionX, POSITION_Y_EQUATION - 70, settings.fontName, SIZE_TEXT)
		operandText:setFillColor(59/255, 29/255, 152/255)
		sceneGroup:insert(operandText)
		return operandText
	end
	
	operand1Text = createOperand(POSITION_X_OPERAND1 - 40)
	operand2Text = createOperand(POSITION_X_OPERAND2 + 20)
	
	local equals = display.newImage("images/minigames/equalsWhite.png")
	equals.x = POSITION_X_EQUALS + 40
	equals.y = POSITION_Y_EQUATION -30
--	equals.xScale = SCALE_SIGNS
--	equals.yScale = SCALE_SIGNS
	sceneGroup:insert(equals)
	
	answerBackground = display.newImage(assetPath.."contorno.png")
	answerBackground.x = POSITION_X_ANSWER + 60
	answerBackground.y = POSITION_Y_EQUATION - 40
	sceneGroup:insert(answerBackground)
	
	questionMarkText = display.newText("?", answerBackground.x, POSITION_Y_EQUATION - 10, settings.fontName, SIZE_TEXT)
	questionMarkText.isVisible = false
	sceneGroup:insert(questionMarkText)
end

local function endMinigame()		
	for index = #answerList, 1, -1 do
		display.remove(answerList[index])
		answerList[index] = nil
	end
	
	Runtime:removeEventListener("enterFrame", updateGame)
end

local function updateGame()
	local function removerBala(idx)
		transition.cancel(balas[idx]["transition"])
		display.remove(balas[idx]["rect"])		
		table.remove(balas, idx)
	end
	
	local hasAnswered = false
	
	local function endGame(answer)
		if hasAnswered then return end
		hasAnswered = true
		transition.cancel(TAG_TRANSITION_ANSWERS)
		
		for index = 1, #answerList do
			if answerList[index] ~= answer then
				local otherAnswer = answerList[index]
				director.to(scenePath, otherAnswer, {alpha = 0, time = 500, transition = easing.outQuad})
			end
		end

		director.to(scenePath, answerBackground, {time=500, alpha = 0})
		director.to(scenePath, questionMarkText, {time = 500, alpha = 0, transition = easing.outQuad})
		director.to(scenePath, answer, {time = 500, x = POSITION_X_ANSWER+60, y = POSITION_Y_EQUATION - 40, transition = easing.outQuad})
		sound.play("pop")
		
		answerStrings = { answer.number }
		local data = {questionString = questionString, answerStrings = answerStrings}
		
		if answer.number == correctAnswer then
			if manager then
				manager.correct(data)
			else
				director.gotoScene("minigames.mathinvaders.game")
			end
		else
			if manager then
				manager.wrong({id = "text", text = operationResult, size = 80})
			else
				director.gotoScene("minigames.mathinvaders.game")
			end
		end
	end
	
	if notHasAnswered then
		for i=#balas,1,-1 do
			if balas[i]["rect"].y < operand1Text.contentBounds.yMax+1 then
				removerBala(i)
				break
			end
			for j=1, #answerList do
				if hasCollided(balas[i]["rect"], answerList[j]) then
					notHasAnswered = false
					removerBala(i)
					endGame(answerList[j])
					return
				end
			end
		end
	end
end

local function initialize(parameters)
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsMathinvaders")
	
	notHasAnswered = true
	answerList = {}
	operationResult = parameters.operation.operationString
	
	questionMarkText.alhpa = 1
	nave.x = display.contentCenterX
	
	Runtime:addEventListener("enterFrame", updateGame)
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusWhite.png",
		["subtraction"] = "images/minigames/minusWhite.png",
		["multiplication"] = "images/minigames/multiplyWhite.png",
		["division"] = "images/minigames/divisionWhite.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	local operand1 = operation.operands and operation.operands[1] or 0
	local operand2 = operation.operands and operation.operands[2] or 0
	correctAnswer = operation.result or 0
	wrongAnswers = parameters.wrongAnswers
	answersSettedTable = {correctAnswer, 0}
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	
	generateEquation(operand1, operand2, nameImageOperator, equalityString)
	generateAnswers(3)
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 600,
		wrongDelay = 600,
		
		name = "Math invaders",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2},
			{id = "wrongAnswer", amount = 4, tolerance = 5},
		},
	}
end 

function game:create(event)
	sceneGroup = self.view

	background = display.newImage(assetPath .. "background.png")
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale(backgroundScale, backgroundScale)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	sceneGroup:insert(background)
		
	local instructionOptions = {
		text = "",	 
		x = display.viewableContentWidth*0.2,
		y = display.viewableContentHeight*0.7,
		width = display.viewableContentWidth*0.3,
		font = settings.fontName,  
		fontSize = 32,
		align = "center"
	}

	instructions = display.newText(instructionOptions)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneGroup:insert(instructions)
	background:toBack()
		
	answersGroup = display.newGroup()
	sceneGroup:insert(answersGroup)
	
	generateNave()
	generateShooter()
	createOperationBase()
end

function game:destroy()
	
end

function game:show( event )
	local phase = event.phase

	if ( phase == "will" ) then
		sceneGroup = self.view
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
		tutorials.cancel(gameTutorial)
		transition.cancel(TAG_TRANSITION_ANSWERS)
		endMinigame()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
