----------------------------------------------- Math tap 2
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require("libs.helpers.extratable")

local game = director.newScene()
----------------------------------------------- Variables
local manager
local tutorialTimer
local timerGenerateAnswers
local fishQuestionMark
local isGameAnswered
local firstTime
local background
local dynamicElementsGroup
local questionString
local answerStrings
local instructions
local gameTutorial
local correctGroup
local answersSettedTable
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local FONT_NAME = settings.fontName
--local DEFAULT_COLOR_BACKGROUND = {0.5,0.7,0.3}
local SIZE_TEXT = 65

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}
----------------------------------------------- Functions

local function generateEquation(operand1, operand2, nameImageOperator)
	
	local paddingX = display.viewableContentWidth * 0.17
	local offsetX = display.contentCenterX - paddingX * 2
	
	local posY = display.contentCenterY + 220
	local leftFishTankA = display.newImage(assetPath.."pecera1.png")
	leftFishTankA.x = offsetX 
	leftFishTankA.y = posY
	dynamicElementsGroup:insert(leftFishTankA)
	local operand1Text = display.newText(operand1, leftFishTankA.x+30, posY, FONT_NAME, SIZE_TEXT)
	operand1Text:setFillColor( 4/255, 9/255, 102/255 )
	dynamicElementsGroup:insert(operand1Text)
	
	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + paddingX
	operator.y = posY + 15
	dynamicElementsGroup:insert(operator)
	
	local leftFishTankB = display.newImage(assetPath.."pecera2.png")
	leftFishTankB.x = operator.x + paddingX
	leftFishTankB.y = posY
	dynamicElementsGroup:insert(leftFishTankB)
	local operand2Text = display.newText(operand2, leftFishTankB.x-10, posY, FONT_NAME, SIZE_TEXT)
	operand2Text:setFillColor( 4/255, 9/255, 102/255 )
	dynamicElementsGroup:insert(operand2Text)
	
	local equalsSign = display.newImage("images/minigames/equalsWhite.png")
	equalsSign.x = leftFishTankB.x + paddingX
	equalsSign.y = operator.y
	dynamicElementsGroup:insert(equalsSign)
	
	local rightFishTank = display.newImage(assetPath.."pecera.png")
	rightFishTank.x = equalsSign.x + paddingX
	rightFishTank.y = posY
	rightFishTank.isVisible = false
	dynamicElementsGroup:insert(rightFishTank)

	fishQuestionMark = display.newImage(assetPath.."pez-resultado1.png")
	fishQuestionMark.x = rightFishTank.x
	fishQuestionMark.y = posY + 20
	dynamicElementsGroup:insert(fishQuestionMark)
	local questionMarkText = display.newText("?", rightFishTank.x - 10, posY+17.5, FONT_NAME, 70)
	questionMarkText.isVisible = false
	dynamicElementsGroup:insert(questionMarkText)
end

local function tapTutorial()
	local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", time = 2500, getObject = function() return correctGroup end},
			}
		}
	gameTutorial = tutorials.start(tutorialOptions) 
end

local function generateAnswers(correctAnswer)
	local pivotPosY = display.viewableContentHeight * 0.275
	local isFirstAnswerInAppear = true
	local generalAnswersGroup = display.newGroup()
	generalAnswersGroup.y = 60
	dynamicElementsGroup:insert(generalAnswersGroup)
	local hasAnswered = false
	
	local generatingAnswers = function()
		local isCorrectAnswerSetted = false
		local totalAnswers = 4
		local timeAnimation = 10000
		
		answersSettedTable = {correctAnswer, 0}

		for index = 1, totalAnswers do
			local answerGroup = display.newGroup()
			local radious = display.viewableContentHeight*0.17
			local posY = pivotPosY + math.random(-radious, radious)
			answerGroup.y = posY

			local base = display.newImage(assetPath.."boton_opciones" .. math.random(1, 5) .. ".png")
			base.x = -15
			answerGroup:insert(base)

			-- Check if this answer was setted before, in order to not repeat answers.
			local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)

			local answerText = display.newText(fakeAnswer, 0, 0, FONT_NAME, SIZE_TEXT)
			answerText:setFillColor(0,0,0)
			answerGroup:insert(answerText)
			
			local answerListenerFunction
			local answerAction = function()
				if isGameAnswered then
					return
				end
				tutorials.cancel(gameTutorial,300)

				isGameAnswered = true
				transition.cancel(answerGroup.transition)
				if base.xScale > 0 then
					director.to(scenePath, base, {time=500, xScale=-1, x=15, transition=easing.outQuad})
				end
				director.to(scenePath, fishQuestionMark, {time=500, alpha=0, transition=easing.outQuad})
				director.to(scenePath, answerGroup, {time=500, x=fishQuestionMark.x-10, y=fishQuestionMark.y-75, transition=easing.outQuad})
				sound.play("pop")
				answerGroup:removeEventListener("tap",answerListenerFunction)
			end

			local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
			if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) or (fakeAnswer == correctAnswer) then
				answerText.text = correctAnswer
				isCorrectAnswerSetted = true
				answerListenerFunction = function()
					if hasAnswered then return end
					hasAnswered = true
					answerAction()
					if manager and manager.correct then
						answerStrings = {answerText.text}
						local data = {questionString = questionString, answerStrings = answerStrings}
						manager.correct(data)
					end
				end
			else
				answerListenerFunction = function()
					if hasAnswered then return end
					hasAnswered = true
					answerAction()
					if manager and manager.wrong then
						answerStrings = {answerText.text}
						local data = {questionString = questionString, answerStrings = answerStrings}
						manager.wrong({id = "text", text = operationResult, fontSize = 80})
					end
				end
			end

			answerGroup:addEventListener("tap", answerListenerFunction)

			local isAnimationRighToLeft = (posY % 2 == 0)
			local boundLeftSide = display.screenOriginX - base.width * base.xScale
			local boundRightSide = display.viewableContentWidth + base.width * base.xScale
			local timeDelay = 2000 * (index-1)

			if isFirstAnswerInAppear then
				isFirstAnswerInAppear = false
				timeDelay = 0
			end

			local initX = boundLeftSide
			local finalX = boundRightSide

			if isAnimationRighToLeft then
				initX = boundRightSide
				finalX = boundLeftSide
				base.x = 15
				base.xScale = base.xScale * -1
			end

			answerGroup.x = initX
			answerGroup.transition = director.to(scenePath, answerGroup, {delay = timeDelay, time = timeAnimation, x = finalX, onComplete = function()
				display.remove(answerGroup)
				answerGroup = nil
			end})
			
			if firstTime and tonumber(answerText.text) == correctAnswer then 
				tutorialTimer = director.performWithDelay(scenePath, timeAnimation/3 + timeDelay, function()
					correctGroup = answerGroup								
					tapTutorial()
				end) 
				firstTime = false
			end

			generalAnswersGroup:insert(answerGroup)
		end
	end
	
	generatingAnswers()
	timerGenerateAnswers = director.performWithDelay(scenePath, 8000, generatingAnswers, 0)
end



local function initialize(parameters)
	local sceneView = game.view
	
	firstTime = parameters.isFirstTime	
	instructions.text = localization.getString("instructionsMathtap2")
	
	operationResult = parameters.operation.operationString
	
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)	
	--
	
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
	local equalityString = parameters.dataString or "0+0=?"
	
	wrongAnswers = parameters.wrongAnswers
	
	generateEquation(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = true,
		wrongDelay = 1000,
		correctDelay = 1000,
		
		name = "Math tap fishes",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minOperand = 1},
			{id = "wrongAnswer", amount = 6, tolerance = 5, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	background = display.newImage(assetPath .. "fondo.png")
	background.anchorY = 0.65
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight * 0.65
	
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale(backgroundScale, backgroundScale)
	sceneView:insert(background)
	
	instructions = display.newText("", display.contentCenterX, display.screenOriginY+40, settings.fontName, 32)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end



function game:destroy()
	
end


function game:show( event )
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params or {})
	elseif ( phase == "did" ) then
		isGameAnswered = false
	end
end


function game:hide( event )
	--local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
				
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		if timerGenerateAnswers then
			timer.cancel(timerGenerateAnswers)
			timerGenerateAnswers = nil
		end
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
