----------------------------------------------- Math tapthree
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local sound = require("libs.helpers.sound")
local tutorials = require( "libs.helpers.tutorials" )
local database = require( "libs.helpers.database" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")

local game = director.newScene()
----------------------------------------------- Variables
local manager
local correctAnswerX
local questionString
local answerStrings
local answers
local operator, operator2
local instructions
local isFirstTime, gameTutorial
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local FONT_NAME = "VAGRounded"
local FONT_SIZE = 100
local OPERAND_SIZE = 72

local POSITION_Y_ANSWER = display.viewableContentHeight * 0.42
local POSITION_X_ANSWER = display.contentCenterX + 400

local FONT_COLOR_ANSWERS = {20/255, 61/255, 102/255}
local FONT_COLOR_OPERANDS = {255/255, 255/255, 255/255}
local FONT_COLOR_TUTORIAL = {36/255, 81/255, 147/255}


----------------------------------------------- Functions
local function generateEquation(nameImageOperator, operand1, operand2, operand3)
	local sceneView = game.view
	local offsetX = display.contentCenterX - 360
	local posY = POSITION_Y_ANSWER
	local scaleSigns = 0.50
		
	local wagons = display.newImage(assetPath.."vagones.png")
	wagons.x = display.contentCenterX
	wagons.y = posY
	sceneView:insert(wagons)

	local operand1Text = display.newText(operand1, offsetX, posY + 15, FONT_NAME, OPERAND_SIZE)
	operand1Text:setFillColor(unpack(FONT_COLOR_ANSWERS))
	sceneView:insert(operand1Text)

	display.remove(operator)
	display.remove(operator2)

	operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 145
	operator.y = posY + 10
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	sceneView:insert(operator)

	local operand2Text = display.newText(operand2, offsetX + 268, posY + 15, FONT_NAME, OPERAND_SIZE)
	operand2Text:setFillColor(unpack(FONT_COLOR_ANSWERS))
	sceneView:insert(operand2Text)

	operator2 = display.newImage(nameImageOperator)
	operator2.x = offsetX + 385
	operator2.y = posY + 10
	operator2.xScale = scaleSigns
	operator2.yScale = scaleSigns
	sceneView:insert(operator2)

	local operand3Text = display.newText(operand3, offsetX + 510, posY + 15, FONT_NAME, OPERAND_SIZE)
	operand3Text:setFillColor(unpack(FONT_COLOR_ANSWERS))
	sceneView:insert(operand3Text)

	local equalsSign = display.newImage(assetPath.."00-igual.png")
	equalsSign.x = offsetX + 625
	equalsSign.y = posY + 15
	equalsSign.xScale = scaleSigns
	equalsSign.yScale = scaleSigns  
	sceneView:insert(equalsSign)

	local questionMarkGroup = display.newGroup()
	local questionMarkBg = display.newImage(assetPath.."minigames-elements-36.png")
	local questionMarkText = display.newText("?", 0, 0, FONT_NAME, FONT_SIZE)
	questionMarkText:setFillColor(0,0,0)
	questionMarkGroup:insert(questionMarkBg)
	questionMarkGroup:insert(questionMarkText)
	questionMarkGroup.x = POSITION_X_ANSWER
	questionMarkGroup.y = POSITION_Y_ANSWER + 20
	questionMarkGroup.alpha = 0
	sceneView:insert(questionMarkGroup)
end

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
	local sceneView = game.view
	
	local totalAnswers = 3
	local paddingX = display.viewableContentWidth * 0.275
	local offsetX = display.contentCenterX - paddingX * (totalAnswers-1) * 0.5
	local posY = display.viewableContentHeight * 0.8
	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}
	local hasAnswered = false

	answers = {}
	
	for index=1, totalAnswers do

		local answerGroup = display.newGroup()
		answers[index] = answerGroup

		local base = display.newImage(assetPath.."vagon.png")
		base.xScale, base.yScale = 0.9, 0.9
		answerGroup:insert(base)

		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
		repeat 
			fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
		until not extratable.containsValue(answersSettedTable, fakeAnswer)
		table.insert(answersSettedTable, fakeAnswer)

		local answerText = display.newText(fakeAnswer, 0, -25, FONT_NAME, FONT_SIZE - 20)
		answerText:setFillColor(unpack(FONT_COLOR_ANSWERS))
		answerGroup.x = offsetX + paddingX * (index -1)
		answerGroup.y = posY
		answerGroup:insert(answerText)
		local answerListenerFunction

		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
		local correct

		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			answerText.text = correctAnswer
			isCorrectAnswerSetted = true
			correct = true
			correctAnswerX = answerGroup.x
		else
			correct = false			
			table.insert(answersSettedTable, fakeAnswer)
		end
		
		answerStrings = { answerText.text }
		local data = {questionString = questionString, answerStrings = answerStrings}

		answerListenerFunction = function()
					if hasAnswered then return end
					hasAnswered = true
					tutorials.cancel(gameTutorial,300)

					director.to(scenePath, answerGroup, {time = 500, x = POSITION_X_ANSWER - 10, y = POSITION_Y_ANSWER + 40, xScale = 0.8, yScale = 0.8, transition = easing.outQuad})
					sound.play("pop")
					answerGroup:removeEventListener("tap",answerListenerFunction)
					if manager and manager.wrong then
							if(correct) then
								manager.correct(data)
							else
								manager.wrong({id = "text", text = correctAnswer, fontSize = 80})
							end
					end
		end

		answerGroup:addEventListener("tap", answerListenerFunction)

		sceneView:insert(answerGroup)
	end
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		-- TODO verify requires
		-- TODO this game has to work with division and multiplication
		available = true,
		correctDelay = 1000,
		wrongDelay = 1000,
		
		name = "Math balloon",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 3},
			{id = "wrongAnswer", amount = 4, tolerance = 5, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	
	wrongAnswers = event.params.wrongAnswers
	operationResult = event.params.operation.operationString
		
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:toBack()
	sceneView:insert(background)
	
	instructions = display.newText("",  display.viewableContentWidth*0.5, display.viewableContentHeight * 0.1, settings.fontName, 32)
	instructions:setFillColor(unpack(FONT_COLOR_TUTORIAL))
	sceneView:insert(instructions)
end


function game:destroy()

end


function game:show( event )
	local phase = event.phase
		local sceneView = self.view
		
		local parameters = event.params or {}

	if ( phase == "will" ) then
		manager = event.parent
		
		isFirstTime = event.params.isFirstTime
		instructions.text = localization.getString("instructionsMathtapthree")
		
		local colorRGB = (event.params and event.params.colorBg) or {76, 212, 187}

		local operatorFilenames = {
			["addition"] = "images/minigames/plusLightGreen.png",
			["subtraction"] = "images/minigames/minusLightGreen.png",
			["multiplication"] = "images/minigames/multiplyLightGreen.png",
			["division"] = "images/minigames/divisionLightGreen.png",
		}
				
		local chosenCategory = parameters.topic or "addition"
		local operation = parameters.operation or {operands = {0,0}, result = 0, }
		
		local operand1 = operation.operands and operation.operands[1] or 0
		local operand2 = operation.operands and operation.operands[2] or 0
		local operand3 = operation.operands and operation.operands[3] or 0
		local correctAnswer = operation.result or 0
		local nameImageOperator = operatorFilenames[chosenCategory]
		local equalityString = parameters.dataString or "0+0=?"

		generateEquation(nameImageOperator, operand1, operand2, operand3)
		generateAnswers(correctAnswer)
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
		for index = 1, #answers do
			display.remove(answers[index])
		end
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
