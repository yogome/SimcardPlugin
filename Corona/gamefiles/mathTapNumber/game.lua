----------------------------------------------- Math tap 1
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
local questionMarkGroup
local correctAnswerX
local manager
local subcategory -- "addition", "subtraction", "multiplication", "division"
local firstTime
local colorRGB
local background
local dynamicElementsGroup
local equalityString
local answerStrings
local instructions
local isFirstTime, gameTutorial
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local SIZE_TEXT = 65
local FONT_NAME = settings.fontName
local DEFAULT_COLOR_BACKGROUND = {0.5,0.7,0.3}
----------------------------------------------- Functions
local function generateEquation(operand1, operand2, nameImageOperator)
	local offsetX = display.contentCenterX - 300
	local posY = 300
	
	local operand1Group = display.newGroup()
	local operand1Bg = display.newImage(assetPath.."minigames-elements-35.png")
	local operand1Text = display.newText(operand1, 0, -10, FONT_NAME, SIZE_TEXT)
	operand1Text:setFillColor(0,0,0)
	operand1Group:insert(operand1Bg)
	operand1Group:insert(operand1Text)
	operand1Group.x = offsetX
	operand1Group.y = posY
	dynamicElementsGroup:insert(operand1Group)

	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 150
	operator.y = posY
	dynamicElementsGroup:insert(operator)
	
	local operand2Group = display.newGroup()
	local operand2Bg = display.newImage(assetPath.."minigames-elements-35.png")
	local operand2Text = display.newText(operand2, 0, -10, FONT_NAME, SIZE_TEXT)
	operand2Text:setFillColor(0,0,0)
	operand2Group:insert(operand2Bg)
	operand2Group:insert(operand2Text)
	operand2Group.x = offsetX + 300
	operand2Group.y = posY
	dynamicElementsGroup:insert(operand2Group)

	local equalsSign = display.newImage(assetPath.."00-igual.png")
	equalsSign.x = offsetX + 450
	equalsSign.y = posY
	dynamicElementsGroup:insert(equalsSign)
	
	questionMarkGroup = display.newGroup()
	local questionMarkBg = display.newImage(assetPath.."minigames-elements-36.png")
	local questionMarkText = display.newText("?", 0, -10, FONT_NAME, SIZE_TEXT)
	questionMarkText:setFillColor(0,0,0)
	questionMarkGroup:insert(questionMarkBg)
	questionMarkGroup:insert(questionMarkText)
	questionMarkGroup.x = offsetX + 600
	questionMarkGroup.y = posY
	dynamicElementsGroup:insert(questionMarkGroup)
end


-- @param tableToCheck
-- @param valueToCompare
-- @return

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = correctAnswerX, y = display.viewableContentHeight * 0.75},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function generateAnswers(correctAnswer)	
	local totalAnswers = 3
	local paddingX = display.viewableContentWidth * 0.275
	local offsetX = display.contentCenterX - paddingX * (totalAnswers-1) * 0.5
	local posY = display.viewableContentHeight * 0.75
	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}
	local hasAnswered = false
	
	for index=1, totalAnswers do
		
		local answerGroup = display.newGroup()
		
		local base = display.newImage(assetPath.."minigames-elements-35.png")
		base.x = 0
		base.y = 0
		answerGroup.x = offsetX + paddingX * (index -1)
		answerGroup.y = posY
		answerGroup:insert(base)
		
		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)
		
		local answerText = display.newText(fakeAnswer, 0, -10, FONT_NAME, SIZE_TEXT)
		answerText:setFillColor(0,0,0)
		answerGroup:insert(answerText)
		local answerListenerFunction
		
		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
		local correcto = false
		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			correctAnswerX = answerGroup.x
			answerText.text = correctAnswer
			isCorrectAnswerSetted = true
			correcto = true
		else
			table.insert(answersSettedTable, fakeAnswer)
		end
		
		answerListenerFunction = function(event)
			if hasAnswered then return end
			hasAnswered = true
			sound.play("pop")
			answerGroup:removeEventListener("tap",answerListenerFunction)
			tutorials.cancel(gameTutorial,300)
			director.to(scenePath, event.target, {x = questionMarkGroup.x, y = questionMarkGroup.y, time = 500,})
			if manager and manager.wrong then			
				answerStrings = {answerText.text}
				local data = {equalityString = equalityString, answerStrings = answerStrings, correctAnswer = correctAnswer}
				if correcto then
					manager.correct(data)
				else
					manager.wrong({id = "text", text = operationResult, fontSize = 80})
				end
			end			
		end
		
		answerGroup:addEventListener("tap", answerListenerFunction)
		
		dynamicElementsGroup:insert(answerGroup)
	end
end

local function initialize(parameters)
	local sceneView = game.view		
	subcategory = parameters.subcategory
	
	colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND	
	background:setFillColor(unpack(colorRGB))

	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsMathtap1")
	
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)

	background:setFillColor(unpack(colorRGB))
	
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
	equalityString = parameters.dataString or "0+0=?"
	
	operationResult = operation.operationString
	wrongAnswers = parameters.wrongAnswers
	
	generateEquation(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
	
	showTutorial()
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		wrongDelay = 800,
		correctDelay = 800,
		
		name = "Math tap 1",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2},
			{id = "wrongAnswer", amount = 4, tolerance = 3, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	background = display.newRect(sceneView, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	
	instructions = display.newText("", display.contentCenterX, display.viewableContentHeight * 0.55, FONT_NAME, 32)
	instructions:setFillColor(46/255, 37/255, 135/255)
	sceneView:insert(instructions)	
end


function game:destroy()
	
end


function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params or {})
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
