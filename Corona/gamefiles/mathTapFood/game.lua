----------------------------------------------- Math tap images
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local fruitImagePath
local questionMark
local minigameAnswered
local isFirstTime
local background
local dynamicElementsGroup
local equalityString
local answerStrings
local instructions
local gameTutorial, isFirstTime
local wrongAnswers
local correctAnswerPosX, correctAnswerPosY
----------------------------------------------- Constants
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
local FONT_NAME = settings.fontName
----------------------------------------------- Functions
local function createImageAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	local offsetY = -10
	local tablePos = POS_NUMBER_OBJECTS[number]
	for index=1, #tablePos do
		local object = display.newImage(assetPath .. fruitImagePath)
		object.x = pX + tablePos[index].x * object.width * 0.65
		object.y = pY + tablePos[index].y * object.height * 0.75 + offsetY
				object.xScale = 0.5
				object.yScale = 0.5
		answerGroup:insert(object)
		
		local timeTransition1 = math.random(700,900)
		local timeTransition2 = math.random(700,900)
		local totalTime = timeTransition1 + timeTransition1
		local itemTransition = function() 
			director.to(scenePath, object, {time = timeTransition1, xScale= 0.65, yScale=0.55, onComplete=function() 
				director.to(scenePath, object, {time = timeTransition2, xScale= 0.55, yScale=0.65})
			end})
		end
		itemTransition()
		director.performWithDelay(scenePath, totalTime, itemTransition, 0)
	end
	
	return answerGroup
end

local function createTextAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	
	local base = display.newImage(assetPath .. "contenedor.png")
	base.xScale = 0.8
	base.yScale = 0.8
	answerGroup:insert(base)
	
	local answerText = createImageAnswerGroup(number, 0, 0) --display.newText(number, 0, -10, FONT_NAME, 80)
	answerText.xScale = 0.6 ; answerText.yScale = 0.6
	answerGroup:insert(answerText)
		
	answerGroup.x = pX
	answerGroup.y = pY
		
	answerGroup.answerText = number
	return answerGroup
end

local function generateEquationImages(operand1, operand2, nameImageOperator)
	local scaleSigns = 1.5
		
	local totalWidthGroup = 730
	local offsetX = display.contentCenterX - totalWidthGroup * 0.5
	local posY = display.viewableContentHeight * 0.3
	local operand1Group = createImageAnswerGroup(operand1, offsetX, posY)
	dynamicElementsGroup:insert(operand1Group)
	
	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 200
	operator.y = posY
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	dynamicElementsGroup:insert(operator)
		
	local operand2Group = createImageAnswerGroup(operand2, offsetX + 400, posY)
	dynamicElementsGroup:insert(operand2Group)
	
	local equalsSign = display.newImage("images/minigames/equalsWhite.png")
	equalsSign.x = offsetX + 600
	equalsSign.y = posY
	equalsSign.xScale = scaleSigns
	equalsSign.yScale = scaleSigns
	dynamicElementsGroup:insert(equalsSign)
	
	questionMark = display.newImage(assetPath.."01-cuadro2.png")
	questionMark.x = offsetX + 770
	questionMark.y = posY
	dynamicElementsGroup:insert(questionMark)
end

local function contains(tableToCheck, valueToCompare)
	for  _, value in ipairs(tableToCheck) do
		if (value == valueToCompare) then
				return false
		end
	end	
	return true
end

local function generateAnswers(correctAnswer)
	local totalAnswers = 3
	local paddingX = 350
	local offsetX = display.contentCenterX - paddingX * (totalAnswers-1) * 0.5
	local posY = display.viewableContentHeight * 0.8
	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}
	local hasAnswered = false
	
	for index=1, totalAnswers do
		
		local posX = offsetX + paddingX * (index-1)
		
		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)
				
		local answerGroup = createTextAnswerGroup(fakeAnswer, posX, posY)
		local answerListenerFunction
		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
		
		local actionAnswer = function()
			
			if minigameAnswered then
				return
			end
			
			sound.play("pop")
			answerGroup:removeEventListener("tap",answerListenerFunction)
			director.to(scenePath, answerGroup, {time=250, alpha=0, transition=easing.outQuad, onComplete=function()
				answerGroup.x = questionMark.x
				answerGroup.y = questionMark.y
				director.to(scenePath, answerGroup, {time=250, alpha=1, transition=easing.outQuad})
			end})
			minigameAnswered = true
		end
		
		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			--answerGroup.answerText = correctAnswer
			correctAnswerPosX = answerGroup.x
			correctAnswerPosY = answerGroup.y
			display.remove(answerGroup)
			answerGroup = createTextAnswerGroup(correctAnswer, correctAnswerPosX, correctAnswerPosY)
			answerGroup.answerText = correctAnswer
			
			isCorrectAnswerSetted = true
			
			answerListenerFunction = function()
				tutorials.cancel(gameTutorial,300)
				if hasAnswered then return end
				hasAnswered = true
				actionAnswer()
				if manager then
					manager.correct()
				end
			end
		else
			
			answerListenerFunction = function()
				tutorials.cancel(gameTutorial,300)
				if hasAnswered then return end
				hasAnswered = true
				actionAnswer()
				if manager then
					local correctAnswerGroup = createTextAnswerGroup(correctAnswer, 9999, 9999)
					manager.wrong({id = "group", group = correctAnswerGroup , fontSize = 75})
				end
			end
			table.insert(answersSettedTable, fakeAnswer)
		end
		answerGroup:addEventListener("tap", answerListenerFunction)
		
		dynamicElementsGroup:insert(answerGroup)
	end
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1400, time = 1500, x = correctAnswerPosX, y = correctAnswerPosY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(parameters)
	local sceneView = game.view
	parameters = parameters or {}
	
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsMathtapImages1")
		
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
	local correctAnswer = operation.result or 0
	local nameImageOperator = operatorFilenames[chosenCategory]
		
	fruitImagePath = "03-fruta" .. math.random(1,3) .. ".png"
		
	wrongAnswers = parameters.wrongAnswers
	
	generateEquationImages(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
	
	showTutorial()
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		-- TODO verify requirements
		available = true,
		correctDelay = 800,
		wrongDelay = 800,
		
		name = "Math tap images",
		category = "math",
		subcategories = {"addition", "subtraction"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, maxOperand = 9, minAnswer = 1, maxAnswer = 8, minOperand = 1},
			{id = "wrongAnswer", amount = 4, minNumber = 1, maxNumber = 9, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	background = display.newImage(assetPath .. "fondo.png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale(backgroundScale, backgroundScale)
	sceneView:insert(background)
	
	local instructionOptions = {
		text = "",	 
		x = display.viewableContentWidth*0.5,
		y = display.viewableContentHeight * 0.5,
		width = display.viewableContentWidth*0.75,
		font = FONT_NAME,  
		fontSize = 32,
		align = "center"
	}

	instructions = display.newText(instructionOptions)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
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
		minigameAnswered = false
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
