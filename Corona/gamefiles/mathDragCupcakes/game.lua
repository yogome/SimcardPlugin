----------------------------------------------- Math Drag and Drop 2
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local tutorials = require( "libs.helpers.tutorials" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local typeGame -- "addition", "subtraction", "multiplication", "division"
local typeOperandsTable --they are either "image" or "number""
local questionMarkGroup, operand1Image, operand2Image, operands, numOperandsSetted, operator
local timerTransitionsTable = {}
local textInstructionsGroup
local questionString
local answerStrings
local operand2ImageX
local answersGroup
--local answerGroup
local instructions
local gameTutorial
local deX, deY, aX, aY
local equalsSign
local nameImageOperator
----------------------------------------------- Constants
local FONT_NAME = settings.fontName
local SIZE_TEXT = 65
local SIZE_ANSWER = 124
local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local FONT_COLOR_ANSWERS = {153/255, 73/255, 13/255}
local FONT_COLOR_TUTORIAL = {255/255, 255/255, 255/255}

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
	local offsetY = -10
	number = number <= #POS_NUMBER_OBJECTS and number or #POS_NUMBER_OBJECTS
	local tablePos = POS_NUMBER_OBJECTS[number]
		
	for index=1, #tablePos do
		local object = display.newImage(assetPath .. "pastelillo.png")
		object.x = pX + tablePos[index].x * object.width * 1.0
		object.y = pY + tablePos[index].y * object.height * 0.95
		answerGroup:insert(object)
		
		local timeTransition1 = math.random(700,900)
		local timeTransition2 = math.random(700,900)
		local totalTime = timeTransition1 + timeTransition1
		local transition = 
		function() 
			director.to(scenePath, object, {timeTransition1, xScale= 1.0, yScale=0.9, onComplete=function() 
				director.to(scenePath, object, {timeTransition2, xScale= 0.9, yScale=1.0})
			end})
		end
		transition()
		timerTransitionsTable[#timerTransitionsTable] = director.performWithDelay(scenePath, totalTime, transition, 0)
	end
	
	return answerGroup
end

local function createTextAnswerGroup(number, pX, pY)
	local answerGroup = display.newGroup()
	
	local base = display.newImage(assetPath .. "contenedor.png")
	base:scale(0.90, 0.90)
	answerGroup:insert(base)
	
	--local answerText = display.newText(number, 0, 10, FONT_NAME, SIZE_ANSWER)
	local answerImage = createImageAnswerGroup(number, 0, 0)
	answerImage.xScale = 0.4 ; answerImage.yScale = 0.4
	answerImage.y = -5
	answerGroup.x = pX
	answerGroup.y = pY
	answerGroup.initX = pX
	answerGroup.initY = pY
	answerGroup:insert(answerImage)
		
	answerGroup.answerText = number
 	return answerGroup
end

local function generateEquationImages(result, nameImageOperator)
	local sceneView = game.view
	local scaleSigns = 1.5
	
	deX = {}
	deY = {}
		
	local totalWidthGroup = 650
	local offsetX = display.contentCenterX - totalWidthGroup * 0.5
	local paddingX = totalWidthGroup * 0.25
	local posY = display.viewableContentHeight * 0.3
	operand1Image = display.newImage(assetPath.."respuesta.png")
	operand1Image.x = offsetX
	operand1Image.y = posY
	deX[1] = offsetX
	deY[1] = posY
	operand1Image:scale(0.90, 0.90)
	sceneView:insert(operand1Image)
	
	operator = display.newImage(nameImageOperator)
	operator.x = operand1Image.x + paddingX
	operator.y = posY
	sceneView:insert(operator)
		
	operand2Image = display.newImage(assetPath.."respuesta.png")
	operand2Image.x = operator.x + paddingX
	operand2ImageX = operand2Image.x
	operand2Image.y = posY
	deX[2] = operator.x + paddingX
	deY[2] = posY
	operand2Image:scale(0.90, 0.90)
	sceneView:insert(operand2Image)
	
	equalsSign = display.newImage("images/minigames/equalsWhite.png")
	equalsSign.x = operand2Image.x + paddingX
	equalsSign.y = posY
	sceneView:insert(equalsSign)
	
	questionMarkGroup = display.newGroup()
	questionMarkGroup = createImageAnswerGroup(result, offsetX, posY)
	questionMarkGroup.x = equalsSign.x
	questionMarkGroup.y = display.viewableContentHeight * 0.06
	questionMarkGroup:scale(.75, .75)
	sceneView:insert(questionMarkGroup)
end


-- @param tableToCheck
-- @param valueToCompare
-- @return

local function notContains(tableToCheck, valueToCompare)
	for  _, value in ipairs(tableToCheck) do
            if (value == valueToCompare) then
                            return false
            end
	end
	return true
end

local function showTutorial()
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1500, time = 2500, x = aX[1], y = aY[1], toX = deX[1], toY = deY[1]},
				[2] = {id = "drag", delay = 500, time = 2500, x = aX[2], y = aY[2], toX = deX[2], toY = deY[2]},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
end

-- @param correctAnswer
-- @return

local function generateAnswers(answers, result, category)
	aX = {}
	aY = {}
	
	local respondio = {
		[1] = 0,
		[2] = 0
	}
	
	local function isCorrect(res1, res2)
		local operacion = {
			['addition'] = res1 + res2,
			['subtraction'] = res1 - res2,
			['multiplication'] = res1 * res2,
			['division'] = res1 / res2,
		}
		return operacion[category] == result		
	end
		
	local sceneView = game.view
	local totalAnswers = 3
	
	local totalWidthGroup = 650
	local offsetX = display.contentCenterX - totalWidthGroup * 0.5
	local paddingX = totalWidthGroup * 0.5
	
	local posY = display.viewableContentHeight * 0.8
	local numberOfCorrectAnswersSetted = 1
	local answersSettedTable = {result, 0}
	for index=1, #answers do
		table.insert(answersSettedTable,answers[index])
	end
	
	display.remove(textInstructionsGroup)
	textInstructionsGroup = display.newGroup()
	sceneView:insert(textInstructionsGroup)
	
	-- Caution: Here begins 'The Step of the Dead' algorithm.
	answersGroup = {}
	for index=1, totalAnswers do
		local correctAnswer = answers[numberOfCorrectAnswersSetted <= #answers and numberOfCorrectAnswersSetted or numberOfCorrectAnswersSetted-1]
		local posX = offsetX + paddingX * (index-1)
		
		-- Check if this answer was setted before, in order to not repeat answers.
		local fakeAnswer
		repeat 
			fakeAnswer = math.abs( math.random(correctAnswer-5, correctAnswer+5) )
		until notContains(answersSettedTable, fakeAnswer)
				
		local answerGroup = createTextAnswerGroup(fakeAnswer, posX, posY)
		answersGroup[index] = answerGroup
				
				local function answerListenerFunction(operando)
					respondio[operando] = answerGroup.answerText
					sound.play("pop")
					answerGroup:removeEventListener("tap",answerListenerFunction)
				end
				
		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index > totalAnswers-#answers)
		
		if (numberOfCorrectAnswersSetted <= #answers and correctAnswerNeedsToBeSetted) then
										aX[#aX+1] = answerGroup.x
										aY[#aY+1] = answerGroup.y
                                        local correctAnswerPosX = answerGroup.x
                                        local correctAnswerPosY = answerGroup.y
                                        display.remove(answerGroup)
                                        
                                        answerGroup = createTextAnswerGroup(correctAnswer, correctAnswerPosX, correctAnswerPosY)
                                        answerGroup.answerText = correctAnswer
                                        
                                        answersGroup[index] = answerGroup
                                        
					numberOfCorrectAnswersSetted = numberOfCorrectAnswersSetted + 1
		else
					table.insert(answersSettedTable, fakeAnswer)
		end
		function answerGroup:touch( event )
			if event.phase == "began" then
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
					local isAnswered = false
					
					for index = 1, #operands do
						if event.x > operands[index].x - radius and event.x < operands[index].x + radius and
						   event.y > operands[index].y - radius and event.y < operands[index].y + radius then
												   
												   local operandsIndexX = operands[index].x
						   
						   numOperandsSetted[#numOperandsSetted+1] = answerGroup.answerText
						   
						   director.to(scenePath, answerGroup, {time=300, x=operands[index].x, y=operands[index].y, transition=easing.outQuad, onComplete=function()
													   local operando = 1
													   if operandsIndexX == operand2ImageX then operando = 2 end
								answerListenerFunction(operando)
								if next(operands) == nil then
									
									if isCorrect(respondio[1], respondio[2]) then
										if manager and manager.correct then
											answerStrings = numOperandsSetted
											local data = {questionString = questionString, answerStrings = answerStrings}
											manager.correct(data)
										end
									else
										if manager and manager.wrong then
											--answerStrings = numOperandsSetted[1] .. numOperandsSetted[2]
											local answerGroup = display.newGroup()
											answerGroup.x = 9999
											answerGroup:insert(createTextAnswerGroup(answers[1], -300, 0))
											answerGroup:insert(display.newImage(nameImageOperator, -150, 0))
											answerGroup:insert(createTextAnswerGroup(answers[2], 0, 0))
											answerGroup:insert(display.newImage("images/minigames/equalsWhite.png", 150, 0))
											answerGroup:insert(createTextAnswerGroup(result, 300, 0))
											answerGroup.xScale = 0.5 ; answerGroup.yScale = 0.5
											manager.wrong({id = "group", group = answerGroup})
										end
									end
									
								end
							end})
							
						   isAnswered = true
						   table.remove(operands, index)
						   answerGroup:removeEventListener("touch", answerGroup);
						   break
						end
					end
					if not isAnswered then
						sound.play("pop")
						director.to(scenePath, answerGroup, {time=500, x=answerGroup.initX, y=answerGroup.initY, transition=easing.outQuad})
					end
				end
			end
			return true
		end 
		answerGroup:addEventListener("touch", answerGroup)
		
		sceneView:insert(answerGroup)
	end
end



local function initialize(parameters)
	parameters = parameters or {}
	local data = parameters.data or {GAMETYPES[DEFAULT_GAMETYPE_INDEX]}
	
	instructions.text = localization.getString("instructionsMathdragdrop2")
	
	typeGame = data[1]
	typeOperandsTable = data[2]
	for index=1, #timerTransitionsTable do
		timer.cancel(timerTransitionsTable[index])
	end
	timerTransitionsTable = {}
	numOperandsSetted = {}
	
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
	nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	--
	
	questionString = equalityString
	
	generateEquationImages(correctAnswer, nameImageOperator)
	generateAnswers({operand1, operand2},correctAnswer, chosenCategory)
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = true,
		correctDelay = 300,
		wrongDelay = 300,
		
		name = "Math drag cakes",
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
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:toBack()
	sceneView:insert(background)		
	
	instructions = display.newText("",  display.contentCenterX, display.screenOriginY + 60, settings.fontName, 32)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end


function game:destroy()
	
end


function game:show( event )
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params)
		if event.params.isFirstTime then
			showTutorial()
		end
	elseif ( phase == "did" ) then
		operands = {operand1Image, operand2Image }
	end
end


function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		display.remove(operand1Image)
		display.remove(operand2Image)
		display.remove(operands)
		for index = 1, #answersGroup do
			display.remove(answersGroup[index])
		end
		display.remove(questionMarkGroup)
		display.remove(operator)
		display.remove(equalsSign)
		--display.remove(answerGroup)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
