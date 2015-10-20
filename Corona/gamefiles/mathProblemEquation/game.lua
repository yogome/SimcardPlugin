----------------------------------------------- WordToEquation
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local settings = require( "settings" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer
local backgroundLayer 
local textLayer
local equationTextPlus, equationTextMinus
local dragPositionGroup
local dragPositionList
local answersGroup
local answerBoxes
local finalAnswer
local xOption, yOption
local equationAnswerTextList
local shuffleAnswersList
local backgroundBox
local questionBox
local instructions
local tutoInstructions
local manager
local isFirstTime
local gameTutorial
local number1
local number2
local abletoTouch
local wrongAnswer
local operationResult

----------------------------------------------- Constants

local OFFSET_TEXT = {x = 0, y = -200}
local COLOR_BG = {255/255, 92/255, 131/255}
local COLOR_TEXT = {0/255, 72/255, 155/255}
local COLOR_INSTRUCTIONS = {1,1,1}
local TOTAL_POSITION_BOXES = 5
local TOTAL_ANSWERS = TOTAL_POSITION_BOXES
local SIZE_FONT = 34
local PADDING_POSITION_BOXES = 125
local PADDING_ANSWERS = 150
local OFFSET_Y_ANSWERS = 200
local PLUS_ORATIONS = 4
local MINUS_ORATIONS = 2

----------------------------------------------- Functions
local function getEquationText(operationType, number1, number2)
	local orationNumber
	local unformatedString, formatedString
	
	if operationType == 1 then
		orationNumber = math.random(1,PLUS_ORATIONS)
		unformatedString = localization.getString("mathProblemEquationPlusOration"..orationNumber)
		formatedString = string.format(unformatedString,number1,number2,number1+number2)
	else
		orationNumber = math.random(1,MINUS_ORATIONS)
		unformatedString = localization.getString("mathProblemEquationMinusOration"..orationNumber)
		formatedString = string.format(unformatedString,number1,number2,number1-number2)
	end
	
	return formatedString
end
local function checkAnswer()
	local correctAnswer = ""
	local userAnswer = ""
	
	for index=1, #finalAnswer do
		correctAnswer = correctAnswer.." "..equationAnswerTextList[index]
		userAnswer = userAnswer.." "..finalAnswer[index]
	end
	
	if correctAnswer == userAnswer then
		manager.correct()
	else
		manager.wrong({id = "text", text = operationResult, fontSize = 50})
	end
end

local function dragBox(event)
	local phase = event.phase
	local target = event.target
	if phase == "began" and abletoTouch then
		sound.stopAll(100)
		tutorials.cancel(gameTutorial,300)
		transition.cancel(target)
		target:toFront( )
		target.x = event.x
		target.y = event.y
		sound.play("dragtrash")
		abletoTouch = false
		target.onSlot = false
		if target.slot then
			target.slot.isEmpty = true
			target.slot = nil
		end
		display.getCurrentStage():setFocus( event.target )
		target.isMoving = true
	elseif phase == "moved" then
		if target.isMoving then
			target.x = event.x
			target.y = event.y		
		end
	elseif phase == "ended" then
		local isTimeToCheckAnswer = true
		sound.play("pop")
		for indexAnswer = 1, #dragPositionList do
			
			local currentSlot = dragPositionList[indexAnswer]
			local xCurrentSlot, yCurrentSlot = currentSlot:localToContent( 0, 0 )			
			currentSlot.xCS = xCurrentSlot
			currentSlot.yCS = yCurrentSlot
			if target.x < (currentSlot.xCS + currentSlot.contentWidth * 0.5) and
				target.x > (currentSlot.xCS - currentSlot.contentWidth * 0.5) and
				target.y < (currentSlot.yCS + currentSlot.contentHeight * 0.5) and
				target.y > ( currentSlot.yCS - currentSlot.contentHeight * 0.5) then
				if currentSlot.isEmpty then
					xOption = currentSlot.xCS
					yOption = currentSlot.yCS
					finalAnswer[currentSlot.id] = target.char
					currentSlot.isEmpty = false
					target.onSlot = true
					target.slot = currentSlot
					break
				end
			end
		end
		
		for indexAnswer = 1, #dragPositionList do
			isTimeToCheckAnswer = isTimeToCheckAnswer and not dragPositionList[indexAnswer].isEmpty
		end
		
		
		if target.slot then
			director.to(scenePath, target, {time = 200, x = xOption, y = yOption-2, xScale = 1, yScale = 1, onStart = function() abletoTouch = true end})

		else
			director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY, xScale = 1, yScale = 1, onStart = function() abletoTouch = true end})
		end
		
		if isTimeToCheckAnswer then
			for elementToRemove = 1, #answerBoxes do
				answerBoxes[elementToRemove]:removeEventListener("touch", dragBox)
			end
			checkAnswer()
		end
		
		display.getCurrentStage():setFocus( nil )
	end
end


local function removeDynamicAnswers()
	display.remove(answersGroup)
	answersGroup = nil
end

local function createDynamicAnswers()
	removeDynamicAnswers() 
	
	answersGroup = display.newGroup()
	answersLayer:insert(answersGroup)
	
	local totalWidth = (TOTAL_ANSWERS - 1) * PADDING_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5
	
	local answerBox = display.newGroup()
	answerBox.bg = display.newImage(assetPath.."boxBg.png")
	answerBox.bg.x = dragPositionList[1].x
	answerBox.bg.y = dragPositionList[1].y - 2
	answerBox.bg.isVisible = true
	answerBox:insert(answerBox.bg)
	answerBox.text = display.newText(equationAnswerTextList[1], answerBox.bg.x, answerBox.bg.y, settings.fontName, 70)
	answerBox.text:setFillColor(unpack(COLOR_TEXT))
	answerBox:insert(answerBox.text)
	answerBox.id = 1
	answersGroup:insert(answerBox)
	answerBox:toBack()
	answerBoxes[1] = answerBox
	finalAnswer[1] = equationAnswerTextList[1]
	dragPositionList[1].isEmpty = false
	
	shuffleAnswersList = extratable.shuffle(shuffleAnswersList)
	
	for index = 1, TOTAL_ANSWERS do
		local answerBox = display.newGroup()
		answerBox.backgroundAnswer = display.newImage(assetPath.."boxBg.png")
		answerBox.backgroundAnswer.x = 0
		answerBox.backgroundAnswer.y = 0
		answerBox.backgroundAnswer.isVisible = true
		answerBox.backgroundAnswerTouched = display.newImage(assetPath.."boxTouched.png")
		answerBox.backgroundAnswerTouched.x = 0
		answerBox.backgroundAnswerTouched.y = 0
		answerBox.backgroundAnswerTouched.isVisible = false
		local answerText = display.newText(shuffleAnswersList[index], 0, 0, settings.fontName, 70)
		answerText:setFillColor(unpack(COLOR_TEXT))
		answerBox:insert(answerBox.backgroundAnswer)
		answerBox:insert(answerBox.backgroundAnswerTouched)
		answerBox:insert(answerText)
		answerBox.char = shuffleAnswersList[index]
		answerBox.x = startX + (index - 1) * PADDING_ANSWERS
		answerBox.y = display.contentCenterY + OFFSET_Y_ANSWERS
		answerBox.onSlot = false
		answerBox.initX = startX + (index - 1) * PADDING_ANSWERS
		answerBox.initY = display.contentCenterY + OFFSET_Y_ANSWERS
		answerBox.id = index + 1
		answerBox:addEventListener("touch", dragBox)
		answerBoxes[#answerBoxes+1] = answerBox
		answersGroup:insert(answerBox)
		answerBox:toFront()
	end
end

local function constructAnswerList(operationType)
	equationAnswerTextList = {}
	shuffleAnswersList = {}
	
	equationAnswerTextList[1] = number1
	if operationType == 1 then
		equationAnswerTextList[2] = "+"
		equationAnswerTextList[5] = number1 + number2
		
		shuffleAnswersList[1] = "+"
		shuffleAnswersList[4] = number1 + number2
	else
		equationAnswerTextList[2] = "-"
		equationAnswerTextList[5] = number1 - number2
		
		shuffleAnswersList[1] = "-"
		shuffleAnswersList[4] = number1 - number2
	end
	equationAnswerTextList[3] = number2
	equationAnswerTextList[4] = "="
	
	shuffleAnswersList[2] = number2
	shuffleAnswersList[3] = "="
	shuffleAnswersList[5] = wrongAnswer
	
end

local function initialize(event)
	
	event = event or {}
	local params = event.params or {}
	local operation = params.operation or {operands = {0,0}, result = 0, }
	wrongAnswer = params.wrongAnswers[1]
	
	local numbers = operation.operands or {10, 2}
	number1 = numbers[1]
	number2 = numbers[2]
	
	if number1 < number2 then
		number1 = numbers[2]
		number2 = numbers[1]
	end
	
	abletoTouch = true
	local language = localization.getLanguage()
	answerBoxes = {}
	equationTextPlus = {}
	finalAnswer = {}
	tutoInstructions.text = localization.getString("instructionsWordToEquation")
	isFirstTime = params.isFirstTime
	manager = event.parent
	operationResult = operation.operationString
	
	for index = 2, #dragPositionList do
		dragPositionList[index].isEmpty = true
	end
	
	local operationType = math.random(1,2)
	
	instructions.text = getEquationText(operationType,number1,number2)
	constructAnswerList(operationType)
end

local function tutorial()
	
	if isFirstTime then
		local firstBox 
		for index=1, #answerBoxes do
			if answerBoxes[index].char == "+" then
				firstBox = answerBoxes[index]
			elseif answerBoxes[index].char == "-" then
				firstBox = answerBoxes[index]
			end
		end
	
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = firstBox.x, y = firstBox.y, toX = dragPositionList[2].x, toY = dragPositionList[2].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Word to Equation",
		category = "math",
		subcategories = {"addition", "subtraction"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2},
			{id = "wrongAnswer", amount = 1, tolerance = 1},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	backgroundBox = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	backgroundBox:setFillColor(unpack(COLOR_BG))
	backgroundLayer:insert(backgroundBox)
	
	local backgroundImg = display.newImage(assetPath.."superiorBg.png")
	backgroundImg.xScale, backgroundImg.yScale = 1.055,1.055
	backgroundImg.x = display.contentCenterX
	backgroundImg.y = backgroundImg.height/2
	backgroundLayer:insert(backgroundImg)
	
	dragPositionGroup = display.newGroup()
	backgroundLayer:insert(dragPositionGroup)
	
	local totalWidth = (TOTAL_POSITION_BOXES - 1) * PADDING_POSITION_BOXES
	local startX = display.contentCenterX - totalWidth * 0.5 
	dragPositionList = {}
	
	for index = 1, TOTAL_POSITION_BOXES do
		local positionBox
		if index%2 == 0 then
			positionBox = display.newImage(assetPath.."containerB.png")
		else
			positionBox = display.newImage(assetPath.."containerA.png")
		end
		positionBox.x = startX + (index - 1) * PADDING_POSITION_BOXES
		positionBox.y = display.contentCenterY - 20
		positionBox.isEmpty = true
		positionBox.id = index
		dragPositionGroup:insert(positionBox)
		dragPositionList[#dragPositionList+1] = positionBox
	end
	
	questionBox = display.newImage(assetPath.."question.png")
	questionBox.x = display.contentCenterX
	questionBox.y = questionBox.height/2
	backgroundLayer:insert(questionBox)
	
	local equationTextOptions = 
	{
		text = "",	 
		x = questionBox.x,
		y = questionBox.height*0.5,
		width = questionBox.width/1.5,
		font = settings.fontName,   
		fontSize = SIZE_FONT,
		align = "center"
	}
	instructions = display.newText(equationTextOptions)
	instructions:setFillColor( unpack(COLOR_TEXT))
	backgroundLayer:insert(instructions)
	
	local tutoInstructionsOptions = 
	{
		text = "",	 
		x = display.contentCenterX,
		y = display.viewableContentHeight*0.92,
		width = questionBox.width/1.5,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}
	tutoInstructions = display.newText(tutoInstructionsOptions)
	tutoInstructions:setFillColor( unpack(COLOR_INSTRUCTIONS))
	backgroundLayer:insert(tutoInstructions)

end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createDynamicAnswers()
		tutorial()
	elseif phase == "did" then
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
	elseif phase == "did" then

		removeDynamicAnswers()
		for index=1, #dragPositionList do
			dragPositionList[index].isEmpty = true
		end
		tutorials.cancel(gameTutorial)

	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
