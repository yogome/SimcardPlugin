----------------------------------------------- Math tap 4
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
local isGameAnswered
local isFirstTime
local dynamicElementsGroup
local questionString
local instructions
local gameTutorial
local correctObject
local wrongAnswers
local answersSettedTable
local operationResult
----------------------------------------------- Constants
local FONT_NAME = settings.fontName
local SIZE_TEXT = 60
local FONT_COLOR_INSTRUCTIONS = {255/255, 255/255, 255/255}

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local POSITION_Y_ANSWER = display.contentCenterY * .30 + 430
local POSITION_X_ANSWER = display.contentCenterX * .35
----------------------------------------------- Functions
local function generateEquation(operand1, operand2, nameImageOperator)
	local scaleSigns = 0.60
		
	local answerTable = display.newImageRect(assetPath .. "tabla.png", display.viewableContentWidth * 0.65, display.viewableContentHeight)
	answerTable.y = display.contentCenterY
	dynamicElementsGroup:insert(answerTable)
	
	local offsetX = display.contentCenterX * 0.35
	local posY = display.contentCenterY * 0.30
	local bgOp1 = display.newImage(assetPath.."minigames-elements-29.png")
	bgOp1.x = offsetX
	bgOp1.y = posY+75
	dynamicElementsGroup:insert(bgOp1)
	local operand1Text = display.newText(operand1, offsetX, posY + 95, FONT_NAME, SIZE_TEXT)
	operand1Text:setFillColor(255,255,255)
	dynamicElementsGroup:insert(operand1Text)
	
	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX - 100
	operator.y = posY + 150
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	dynamicElementsGroup:insert(operator)
	
	local bgOp2 = display.newImage(assetPath.."minigames-elements-29.png")
	bgOp2.x = offsetX
	bgOp2.y = posY + 250
	dynamicElementsGroup:insert(bgOp2)
	local operand2Text = display.newText(operand2, bgOp2.x, posY + 270, FONT_NAME, SIZE_TEXT)
	operand2Text:setFillColor(255,255,255)
	dynamicElementsGroup:insert(operand2Text)
	
	local equalsSign = display.newImage(assetPath.."igual.png")
	equalsSign.x = offsetX
	equalsSign.y = posY + 350
	dynamicElementsGroup:insert(equalsSign)
	
	local bgQuestionMark = display.newImage(assetPath.."minigames-elements-30.png")
	bgQuestionMark.x = offsetX
	bgQuestionMark.y = posY + 450
	bgQuestionMark.xScale = .65
	bgQuestionMark.yScale = .65
	dynamicElementsGroup:insert(bgQuestionMark)
end

local function generateAnswers(correctAnswer)
	local answersGroup = display.newGroup()
	local deltaDistance = 190
	local horizontalOffset = 20
	local centerX = display.contentCenterX * 1.33
	local centerY = display.contentCenterY
	local finalPositions = {
		{x=centerX + deltaDistance + horizontalOffset, y=centerY},
		{x=centerX - deltaDistance - horizontalOffset, y=centerY},
		{x=centerX, y=centerY - deltaDistance},
		{x=centerX, y=centerY + deltaDistance},
	}
	dynamicElementsGroup:insert(answersGroup)
	
	-- Base to Hide Answers
	local baseToHideAnswers = display.newImage(assetPath.."minigames-elements-27.png")
	baseToHideAnswers.x = centerX
	baseToHideAnswers.y = centerY
	baseToHideAnswers:scale(.90, .90)
	dynamicElementsGroup:insert(baseToHideAnswers)
	
	-- Function To Generate Answers
	local generatingAnswers = function()
		local isCorrectAnswerSetted = false
		local totalAnswers = 4
		
		local canPlaySound = true
		local function playWhooshSound()
			if canPlaySound then
				canPlaySound = false
				sound.play("minigamesWhoosh")
			end
		end
		
		answersSettedTable = {correctAnswer, 0}
		
		for index=1, totalAnswers do

			local answerGroup = display.newGroup()
			local base = display.newImage(assetPath.."boton_opciones.png")
			base:scale(0.60, 0.60)
			answerGroup:insert(base)

			-- Check if this answer was setted before, in order to not repeat answers.
			local fakeAnswer
			repeat 
				fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
			until not extratable.containsValue(answersSettedTable, fakeAnswer)
			table.insert(answersSettedTable, fakeAnswer)

			local answerText = display.newText(fakeAnswer, 4, 15, FONT_NAME, SIZE_TEXT)
			answerText:setFillColor(255,255,255)
			answerGroup:insert(answerText)
			local answerListenerFunction

			local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
			if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) or (fakeAnswer == correctAnswer) then
				correctObject = answerGroup
				answerText.text = correctAnswer
				isCorrectAnswerSetted = true
				answerListenerFunction = function()
					if isGameAnswered then
						return
					end
					isGameAnswered = true
					tutorials.cancel(gameTutorial,300)
					director.to(scenePath, answerGroup, {time = 1000, x = POSITION_X_ANSWER, y = POSITION_Y_ANSWER + 20, xScale = 1.2, yScale = 1.2, transition = easing.outQuad})
					sound.play("pop")
					answerGroup:removeEventListener("tap",answerListenerFunction)
					if manager and manager.correct then
						manager.correct()
					end
				end
			else
				answerListenerFunction = function()
					if isGameAnswered then
						return
					end
					isGameAnswered = true
					tutorials.cancel(gameTutorial,300)
					director.to(scenePath, answerGroup, {time = 1000, x = POSITION_X_ANSWER, y = POSITION_Y_ANSWER + 20, xScale = 1.2, yScale = 1.2, transition = easing.outQuad})
					sound.play("pop")
					answerGroup:removeEventListener("tap",answerListenerFunction)
					if manager and manager.wrong then
						manager.wrong({id = "text", text = operationResult})
					end
				end
			end
			--answerGroup:addEventListener("tap",answerListenerFunction)

			answerGroup.x = centerX
			answerGroup.y = centerY
			
			director.to(scenePath, answerGroup, {delay= 1000, time = 1000, x=finalPositions[index].x, y=finalPositions[index].y, transition=easing.outQuad,onStart = function() 
				playWhooshSound()
			end, onComplete=function()
				answerGroup:addEventListener("tap",answerListenerFunction)
				director.to(scenePath, answerGroup, {delay = 3000, time = 1000, x=centerX, y=centerY, transition=easing.outQuad, 
				onStart = function()
					answerGroup:removeEventListener("tap",answerListenerFunction)
				end,
				onComplete=function()
					canPlaySound = true
					display.remove(answerGroup)
				end})
			end})

			answersGroup:insert(answerGroup)
		end
	end
	
	generatingAnswers()
	director.performWithDelay(scenePath, 6000, generatingAnswers, 0)
end


local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	manager = event.parent
	
	local sceneView = game.view
	
	operationResult = parameters.operation.operationString
	
	instructions.text = localization.getString("instrutcionsMathtap4")
	
	isFirstTime = parameters.isFirstTime
	
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)

	local operatorFilenames = {
		["addition"] = "images/minigames/plusBeige.png",
		["subtraction"] = "images/minigames/minusBeige.png",
		["multiplication"] = "images/minigames/multiplyBeige.png",
		["division"] = "images/minigames/divisionBeige.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0,}
	wrongAnswers = parameters.wrongAnswers
	
	local operand1 = operation.operands and operation.operands[1] or 0
	local operand2 = operation.operands and operation.operands[2] or 0
	local correctAnswer = operation.result or 0
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	
	questionString = equalityString
	
	generateEquation(operand1, operand2, nameImageOperator)
	generateAnswers(correctAnswer)
end

local function getCorrectObject()
	return correctObject
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, getObject = getCorrectObject, x = 45, y = 45},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 1000,
		wrongDelay = 1000,
		
		name = "Math cat tap",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minOperand = 1},
			{id = "wrongAnswer", amount = 7, tolerance = 8, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
		
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:toBack()
	sceneView:insert(background)
	
	local instructionOptions = {
		text = "",	 
		x = (display.viewableContentWidth/3)*2,
		y = display.viewableContentHeight/9,
		width = display.viewableContentWidth*0.4,
		font = FONT_NAME,  
		fontSize = 32,
		align = "center"
	}

	instructions = display.newText(instructionOptions)
	instructions:setFillColor(unpack( FONT_COLOR_INSTRUCTIONS ))
	sceneView:insert(instructions)
	instructions:toFront()
end


function game:destroy()
	
end


function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)
		showTutorial()
	elseif ( phase == "did" ) then
		isGameAnswered = false
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