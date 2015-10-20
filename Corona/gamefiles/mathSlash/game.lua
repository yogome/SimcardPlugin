----------------------------------------------- Math Slash Images 1
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
local timerTransitionsTable = {}
local gameFinished
local touchEnabled = false
local gameFinished
local background
local isFirstTime
local dynamicElementsGroup
local questionString
local answerStrings
local instructions
local gameTutorial, correctAnswerGroup
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local FONT_NAME = settings.fontName

local TAG_TRANSITION_ANSWERS = "tagTransitionsAnswers"
----------------------------------------------- Functions

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = correctAnswerGroup.x - 160, y = correctAnswerGroup.y - 80, toX = correctAnswerGroup.x + 160, toY = correctAnswerGroup.y - 80},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function createTextAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	answerGroup.x = pX
	answerGroup.y = pY
	
	local rect = display.newRect( 0, 0, 150, 0 )
	rect.anchorY = 0
	rect:setFillColor(0,0,0,0.01)
	answerGroup:insert(rect)
	
	local rope = display.newImage(assetPath .. "20-cuerda" .. math.random(1,3) .. ".png")
	rope.anchorY = 1
	rope.x = 0
	rope.y =  -10
	answerGroup:insert(rope)
	
	local base = display.newImage(assetPath .. "01-cuadro.png")
	base.x = 0
	base.y = 35
	base.xScale = 1.0
	base.yScale = 1.0
	answerGroup:insert(base)
	
	local answerText = display.newText(number, 0, 35, FONT_NAME, 80)
	answerText:setFillColor( 102/255, 33/255, 8/255 )
	answerGroup:insert(answerText)
		
	answerGroup.answerText = answerText
	answerGroup.rope = rope
	
	return answerGroup
end

local function generateEquation(operand1, operand2, nameImageOperator)
	local scaleSigns = 1.5

	local totalWidthGroup = 730
	local offsetX = display.contentCenterX - totalWidthGroup * 0.5
	--local posY = display.contentCenterY + 220
	local operand1Group = display.newGroup( )
	local operand1Image = display.newImage(assetPath .. "numero.png")
	local operand1Text = display.newText(operand1, 0, -5, FONT_NAME, 80)
	operand1Text:setFillColor( 102/255, 33/255, 8/255 )
	operand1Group.y = display.viewableContentHeight * 0.85
	operand1Group.x = display.viewableContentWidth * 0.175
	operand1Group:insert(operand1Image)
	operand1Group:insert(operand1Text)
	dynamicElementsGroup:insert(operand1Group)

	local operand2Group = display.newGroup( )
	local operand2Image = display.newImage(assetPath .. "numero.png")
	local operand2Text = display.newText(operand2, 0, -5, FONT_NAME, 80)
	operand2Text:setFillColor( 102/255, 33/255, 8/255 )
	operand2Group.y = display.viewableContentHeight * 0.85
	operand2Group.x = display.viewableContentWidth * 0.5
	operand2Group:insert(operand2Image)
	operand2Group:insert(operand2Text)
	dynamicElementsGroup:insert(operand2Group)

	local operator = display.newImage(nameImageOperator)
	operator.x = ((operand2Group.x - operand1Group.x)/2)+operand1Group.x
	operator.y = display.viewableContentHeight * 0.85
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	dynamicElementsGroup:insert(operator)

	questionMark = display.newImage(assetPath.."01-cuadro2.png")
	questionMark.x = display.viewableContentWidth*0.825
	questionMark.y = display.viewableContentHeight * 0.85
	dynamicElementsGroup:insert(questionMark)

	local equalsSign = display.newImage("images/minigames/equalsOrange.png")
	equalsSign.x = ((questionMark.x - operand2Group.x)/2)+ operand2Group.x
	equalsSign.y = display.viewableContentHeight * 0.85
	equalsSign.xScale = scaleSigns
	equalsSign.yScale = scaleSigns
	dynamicElementsGroup:insert(equalsSign)

	
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
	local offsetX = display.contentCenterX - 175 * (totalAnswers-1)
	local posY = 300
	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}

	local container = display.newContainer( display.viewableContentWidth, display.viewableContentHeight)
	container.anchorChildren = false 
	container.anchorY = 0
	container.anchorX = 0
	dynamicElementsGroup:insert(container)
	
	for index=1, totalAnswers do

		local posX = offsetX + 350 * (index-1)

		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
	repeat 
		fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
	until not extratable.containsValue(answersSettedTable, fakeAnswer)

		local answerGroup = createTextAnswerGroup(fakeAnswer, posX, posY)
		local answerListenerFunction

		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			answerGroup.answerText.text = correctAnswer
			isCorrectAnswerSetted = true
			correctAnswerGroup = answerGroup
			
			answerListenerFunction = function()
				answerGroup:removeEventListener("touch",answerGroup)
				if manager and manager.correct then
					answerStrings = {answerGroup.answerText.text}
					local data = {questionString = questionString, answerStrings = answerStrings}
					manager.correct(data)
				end
			end
		else
			answerListenerFunction = function()
				answerGroup:removeEventListener("touch",answerGroup)
				if manager and manager.wrong then
					answerStrings = {answerGroup.answerText.text}
					local data = {questionString = questionString, answerStrings = answerStrings}
					manager.wrong({id = "text", text = operationResult, fontSize = 80 })
				end
			end
			table.insert(answersSettedTable, fakeAnswer)
		end
		answerGroup.touch = function()
			if gameFinished then
				return
			end
			gameFinished = true
			tutorials.cancel(gameTutorial,300)
			director.to(scenePath, answerGroup.rope, {tag=TAG_TRANSITION_ANSWERS, time=1000, xScale=0.01, yScale=0.5, onComplete=function()
				display.remove(answerGroup.rope)
			end})
			director.to(scenePath, answerGroup, {tag=TAG_TRANSITION_ANSWERS, time=1500, y=display.viewableContentHeight})
			director.to(scenePath, answerGroup, {tag=TAG_TRANSITION_ANSWERS, delay=300,time=500, alpha=0.0})
			
			director.performWithDelay(scenePath, 500, function()
				-- Creating new Answer Group
				local newAnswerGroup = display.newGroup()
				local pX = questionMark.x
				local pY = questionMark.y
				local base = display.newImage(assetPath .. "01-cuadro.png")
				base.x = pX
				base.y = pY
				base.xScale = 1.0
				base.yScale = 1.0
				newAnswerGroup:insert(base)
				local answerText = display.newText(answerGroup.answerText.text, pX, pY, FONT_NAME, 80)
				answerText:setFillColor( 102/255, 33/255, 8/255 )
				newAnswerGroup:insert(answerText)
				newAnswerGroup.alpha = 0.0
				dynamicElementsGroup:insert(newAnswerGroup)
				director.to(scenePath, questionMark, {time=500, alpha=0.0})
				director.to(scenePath, newAnswerGroup, {time=500, alpha=1.0})
			end, 1)
			
			sound.play("cut")
			answerListenerFunction()
		end
		answerGroup:addEventListener("touch", answerGroup)

		container:insert(answerGroup)
	end
end

local function initialize(parameters)
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime
	
	for index=1, #timerTransitionsTable do
		timer.cancel(timerTransitionsTable[index])
	end
	timerTransitionsTable = {}
	
	instructions.text = localization.getString("instructionsMathslashimages1")

	fruitImagePath = "03-fruta" .. math.random(1,3) .. ".png"
	gameFinished = false
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusOrange.png",
		["subtraction"] = "images/minigames/minusOrange.png",
		["multiplication"] = "images/minigames/multiplyOrange.png",
		["division"] = "images/minigames/divisionOrange.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	local operand1 = operation.operands and operation.operands[1] or 0
	local operand2 = operation.operands and operation.operands[2] or 0
	local correctAnswer = operation.result or 0
	wrongAnswers = parameters.wrongAnswers
	operationResult = operation.operationString
	
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	
	questionString = equalityString

	generateEquation(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
	local superior = display.newImage(assetPath .. "superior.png")
	superior.x = display.contentCenterX
	local superiorScale = display.viewableContentWidth/superior.width
	superior:scale(superiorScale, superiorScale)
	superior.y = superior.height/2
	dynamicElementsGroup:insert(superior)
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		-- TODO check subcategories
		available = false,
		correctDelay = 1000,
		wrongDelay = 1000,
		
		name = "Math slasher fruits",
		category = "math",
		subcategories = {"multiplication"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, maxAnswer = 9, minAnswer = 1, maxOperand = 9, minOperand = 1, amount = 1},
			{id = "wrongAnswer", amount = 5, tolerance = 4},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	background = display.newImage(assetPath .. "fondo.png")	
	background.width = display.viewableContentWidth + 2
	background.height = display.viewableContentHeight + 2
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	sceneView:insert(background)
	
	instructions = display.newText("", display.contentCenterX, display.viewableContentHeight * 0.6, FONT_NAME, 32)
	instructions:setFillColor(102/255, 33/255, 8/255)
	sceneView:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if ( phase == "will" ) then
		display.remove(dynamicElementsGroup)
		dynamicElementsGroup = display.newGroup()
		sceneGroup:insert(dynamicElementsGroup)
		manager = event.parent
		initialize(event.params, sceneGroup)
		showTutorial()
	elseif ( phase == "did" ) then
		touchEnabled = true
		Runtime:addEventListener( "touch", game )
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		touchEnabled = false
		tutorials.cancel(gameTutorial)
		display.remove(dynamicElementsGroup)
		dynamicElementsGroup = nil
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
