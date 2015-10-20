----------------------------------------------- Math Drag and Drop
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require( "libs.helpers.extratable")

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local fruitImagePath
local questionMark
local questionString
local answerStrings
local operand1Group, operand2Group
local operator, answers
local instructions
local gameTutorial, isFirstTime
local elementsGroup
local dynamicGroup
local correctAnswerPosX, correctAnswerPosY
local wrongAnswers
----------------------------------------------- Constants
local ANIMATED_FRUITS = false
local FONT_NAME = settings.fontName
local FRUIT_SCALE = 0.7
local INSTRUCTIONS_COLOR = {1,1,1}
local POS_NUMBER_OBJECTS = {
	[0] = {{x=0,y=0},},
	[1] = {{x=0,y=0},},
	[2] = {{x=-0.5,y=0},{x=0.5,y=0},},
	[3] = {{x=-1,y=0},{x=0,y=0},{x=1,y=0},},
	[4] = {{x=-0.8,y=-0.8},{x=0.8,y=0.8},{x=-0.8,y=0.8},{x=0.8,y=-0.8},},
	[5] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=0,y=0},},
	[6] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},},
	[7] = {{x=-1,y=-1},{x=0,y=-1},{x=1,y=-1},{x=-1,y=0},{x=0,y=0},{x=1,y=0},{x=-1,y=1},},
	[8] = {{x=-1,y=-1},{x=0,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},{x=0,y=0},{x=0,y=-1},},
	[9] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},{x=0,y=0},{x=0,y=-1},{x=0,y=1},},
}
----------------------------------------------- Functions

local function createImageAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	local offsetY = -5
	local tablePos = POS_NUMBER_OBJECTS[number]
	for index=1, #tablePos do
		local object = display.newImage(assetPath .. fruitImagePath)
		object.x = pX + tablePos[index].x * object.width * 0.65
		object.y = pY + tablePos[index].y * object.height * 0.75 + offsetY
		object.xScale = FRUIT_SCALE ; object.yScale = FRUIT_SCALE
		answerGroup:insert(object)
		
		if ANIMATED_FRUITS then
			local timeTransition1 = math.random(700,900)
			local timeTransition2 = math.random(700,900)
			local totalTime = timeTransition1 + timeTransition1
			local transition = 
			function() 
				director.to(scenePath, object, {timeTransition1, xScale= FRUIT_SCALE * 1.1, yScale= FRUIT_SCALE * 1.0, onComplete=function() 
					director.to(scenePath, object, {timeTransition2, xScale= FRUIT_SCALE * 1.0, yScale= FRUIT_SCALE * 1.1})
				end})
			end
			transition()
			director.performWithDelay(scenePath, totalTime, transition, 0)
		end
	end
	
	return answerGroup
end

local function createTextAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	
	local base = display.newImage(assetPath .. "cajadefrutas.png")
	base.xScale = 0.8
	base.yScale = 0.8
	answerGroup:insert(base)
	
	local answerImage = createImageAnswerGroup(number, 0, 0)
	answerImage.xScale = 0.6 ; answerImage.yScale = 0.6
	answerGroup:insert(answerImage)
	
	answerGroup.x = pX
	answerGroup.y = pY
	answerGroup.initX = pX
	answerGroup.initY = pY
		
	answerGroup.answerText = number
	return answerGroup
end

local function generateEquationImages(operand1, operand2, nameImageOperator)
	local scaleSigns = 1.5
		
	local totalWidthGroup = 730
	local offsetX = display.contentCenterX - totalWidthGroup * 0.5
	local posY = display.viewableContentHeight * 0.37
	operand1Group = createImageAnswerGroup(operand1, offsetX, posY)
	dynamicGroup:insert(operand1Group)
	
	operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 200
	operator.y = posY
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	dynamicGroup:insert(operator)
	
	operand2Group = createImageAnswerGroup(operand2, offsetX + 400, posY)
	dynamicGroup:insert(operand2Group)
	
	local equalsSign = display.newImage("images/minigames/equalsWhite.png")
	equalsSign.x = offsetX + 600
	equalsSign.y = posY
	equalsSign.xScale = scaleSigns
	equalsSign.yScale = scaleSigns
	dynamicGroup:insert(equalsSign)
	
	questionMark = display.newImage(assetPath.."respuesta.png")
	questionMark.x = offsetX + 770
	questionMark.y = posY
	questionMark.xScale = 0.7 ; questionMark.yScale = 0.7
	dynamicGroup:insert(questionMark)
end

local function generateAnswers(correctAnswer)
	local totalAnswers = 3
	local paddingX = 350
	local offsetX = display.contentCenterX - paddingX * (totalAnswers-1) * 0.5
	local posY = display.viewableContentHeight * 0.8
	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}
	local hasAnswered = false
	
	answers = {}
	
	for index=1, totalAnswers do
		local posX = offsetX + paddingX * (index-1)
		
		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
		repeat 
			fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
		until not extratable.containsValue(answersSettedTable, fakeAnswer)
				
		local answerGroup = createTextAnswerGroup(fakeAnswer, posX, posY)
		answers[index] = answerGroup
		local answerListenerFunction
		
		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			correctAnswerPosX = answerGroup.x
			correctAnswerPosY = answerGroup.y
			display.remove(answerGroup)
			answerGroup = createTextAnswerGroup(correctAnswer, correctAnswerPosX, correctAnswerPosY)
			answerGroup.answerText = correctAnswer
			
			isCorrectAnswerSetted = true
			
			answerListenerFunction = function()
				if hasAnswered then return end
				hasAnswered = true
				sound.play("pop")
				answerGroup:removeEventListener("tap",answerListenerFunction)
				if manager and manager.correct then
					manager.correct()
				end
			end
		else
			
			answerListenerFunction = function()
				if hasAnswered then return end
				hasAnswered = true
				sound.play("pop")
				answerGroup:removeEventListener("tap",answerListenerFunction)
				if manager and manager.wrong then
					answerStrings = {answerGroup.answerText}
					local data = {questionString = questionString, answerStrings = answerStrings}
					local correctAnswerGroup = createTextAnswerGroup(correctAnswer, 9999, 9999)
					manager.wrong({id = "group", group = correctAnswerGroup, font = 80})
				end
			end
			table.insert(answersSettedTable, fakeAnswer)
		end
		function answerGroup:touch( event )
			if event.phase == "began" then
				tutorials.cancel(gameTutorial,300)
				
				sound.play("dragtrash")
				display.getCurrentStage():setFocus( self )
				self.isFocus = true
				answerGroup.xScale=1.1
				answerGroup.yScale=1.1
				answerGroup.x = event.x
				answerGroup.y = event.y
				transition.cancel(self)

			elseif self.isFocus then
				if event.phase == "moved" then
					answerGroup.x = event.x
					answerGroup.y = event.y
					
				elseif event.phase == "ended" or event.phase == "cancelled" then
					display.getCurrentStage():setFocus( nil )
					self.isFocus = nil
					answerGroup.xScale=1
					answerGroup.yScale=1
					local radius = 100
					if event.x > questionMark.x - radius and event.x < questionMark.x + radius and
					   event.y > questionMark.y - radius and event.y < questionMark.y + radius then
					   director.to(scenePath, answerGroup, {time=500, x=questionMark.x, y=questionMark.y, transition=easing.outQuad, onComplete=answerListenerFunction()})
					else
						sound.play("cut")
						director.to(scenePath, answerGroup, {time=500, x=answerGroup.initX, y=answerGroup.initY, transition=easing.outQuad})
					end
				end
			end
			return true
		end 
		answerGroup:addEventListener("touch", answerGroup)
		
		dynamicGroup:insert(answerGroup)
	end
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 800, time = 2500, x = correctAnswerPosX, y = correctAnswerPosY, toX = questionMark.x, toY = questionMark.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(parameters)
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime
	
	instructions.text = localization.getString("instructionsMathdragdrop")
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusWhite.png",
		["subtraction"] = "images/minigames/minusWhite.png",
		["multiplication"] = "images/minigames/multiplyWhite.png",
		["division"] = "images/minigames/divisionWhite.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	local operand1 = operation.operands[1] or 0
	local operand2 = operation.operands[2] or 0
	local correctAnswer = operation.result or 0
	
	wrongAnswers = parameters.wrongAnswers
	
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"

	fruitImagePath = "fruit" .. math.random(1,3) .. ".png"
		
	questionString = equalityString
	
	display.remove(dynamicGroup)
	dynamicGroup = display.newGroup()
	elementsGroup:insert(dynamicGroup)
	
	generateEquationImages(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
	
	showTutorial()
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Math drag drop",
		category = "math",
		subcategories = {"addition", "subtraction"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minAnswer = 1, maxAnswer = 8, maxOperand = 9, minOperand = 1},
			{id = "wrongAnswer", amount = 5, minNumber = 1, maxNumber = 9,},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	
	--background = display.newRect(sceneView, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	local background = display.newImage(assetPath.."fondo.png")
	background.x = display.contentCenterX ; background.y = display.contentCenterY
	local backgroundScale = display.contentWidth / background.width
	background.xScale = backgroundScale ; background.yScale = backgroundScale
	sceneView:insert(background)
	
	local instructionsTip = display.newImage(assetPath.."instruccion.png")
	instructionsTip.xScale = backgroundScale ; instructionsTip.yScale = backgroundScale
	instructionsTip.x = display.contentCenterX; instructionsTip.y = display.screenOriginY + (instructionsTip.height*0.75)
	sceneView:insert(instructionsTip)
	
	instructions = display.newText("",  instructionsTip.x, instructionsTip.y, FONT_NAME, 40)
	instructions:setFillColor(unpack(INSTRUCTIONS_COLOR))
	sceneView:insert(instructions)
	
	elementsGroup = display.newGroup()
	sceneView:insert(elementsGroup)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params)
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
