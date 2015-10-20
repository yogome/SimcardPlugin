----------------------------------------------- Math tap 3
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local correctAnswerNumber
local isGameAnswered
local typeGame -- "addition", "subtraction", "multiplication", "division"
local colorRGB
local background
local dynamicElementsGroup
local questionString
local answerStrings
local buttonTrueGroup, buttonFalseGroup
local instructions
local isFirstTime, gameTutorial

----------------------------------------------- Constants
local FONT_NAME = settings.fontName
local SIZE_TEXT = 65 
local DEFAULT_COLOR_BACKGROUND = {255/255,253/255,192/255}
local CORRECT_TEXT_COLOR = {30/255,188/255,56/255}
local INCORRECT_TEXT_COLOR = {191/255, 0, 23/255}

local DEFAULT_GAMETYPE_INDEX = 1
local GAMETYPES = {
	[1] = "addition",
	[2] = "subtraction",
	[3] = "multiplication",
	[4] = "division",
}

local POS_NUMBER_OBJECTS = {
	[0] = {{x=0,y=0},},  -- USED FOR ZERO RESULT, MUST BE REMOVED!
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
local function getCookiesGroup(cookiesNumber)
	local answerGroup = display.newGroup()
	local tablePos = POS_NUMBER_OBJECTS[cookiesNumber]
	for index=1, #tablePos do
		local object = display.newImage(assetPath .. "galleta.png")
		object:scale(0.625, 0.625)
		object.x = tablePos[index].x * (object.width*0.625) * 0.65
		object.y = tablePos[index].y * (object.height*0.625) * 0.75 
		answerGroup:insert(object)
	end
	return answerGroup
end

local function generateEquation(operand1, operand2, answer, nameImageOperator)
	local sceneView = game.view
	local scaleSigns = 1
	
	local offsetX = display.contentCenterX - 300
	local posY = display.contentHeight * 0.37 --300
	
	local backGroundOp1 = display.newImage(assetPath.."charola.png")
	backGroundOp1.x = offsetX
	backGroundOp1.y = posY
	backGroundOp1.xScale = 0.9 ; backGroundOp1.yScale = 0.9
	dynamicElementsGroup:insert(backGroundOp1)
	
	local operand1Group = getCookiesGroup(operand1)
	operand1Group.x = offsetX
	operand1Group.y = posY
	dynamicElementsGroup:insert(operand1Group)
	
	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 150
	operator.y = posY 
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	dynamicElementsGroup:insert(operator)
	
	local backGroundOp2 = display.newImage(assetPath.."charola.png")
	backGroundOp2.x = offsetX + 300
	backGroundOp2.y = posY
	backGroundOp2.xScale = 0.9 ; backGroundOp2.yScale = 0.9
	dynamicElementsGroup:insert(backGroundOp2)
	
	local operand2Group = getCookiesGroup(operand2)
	operand2Group.x = offsetX + 300
	operand2Group.y = posY
	dynamicElementsGroup:insert(operand2Group)
	
	local equalsSign = display.newImage(assetPath.."equalsWhite.png")
	equalsSign.x = offsetX + 450
	equalsSign.y = posY
	equalsSign.xScale = scaleSigns
	equalsSign.yScale = scaleSigns
	dynamicElementsGroup:insert(equalsSign)
	
	local backGroundAnswer = display.newImage(assetPath.."charola2.png")
	backGroundAnswer.x = offsetX + 600
	backGroundAnswer.y = posY
	dynamicElementsGroup:insert(backGroundAnswer)
	
	local answerGroup = getCookiesGroup(answer)
	answerGroup.x = offsetX + 600
	answerGroup.y = posY
	dynamicElementsGroup:insert(answerGroup)
end


-- @param correctAnswer
-- @return

local function generateTrueFalseButtons(correctAnswerBool)
	local sceneView = game.view
	local posY = display.contentCenterY + 120
	local radiusXbuttons = 170
	local hasAnswered = false
	
	local function responder(event)
		if hasAnswered then return end
		hasAnswered = true 
		local respuesta = event.target.respBool
		tutorials.cancel(gameTutorial,300)
		if isGameAnswered then
			return
		end
		isGameAnswered = true
		sound.play("pop")
		buttonTrueGroup:removeEventListener("tap",responder)
		
		if manager then
			answerStrings = {respuesta}
			local data = {questionString = questionString, answerStrings = answerStrings}
			if respuesta == correctAnswerBool then
				manager.correct(data)
			else
				local rightImage
				if correctAnswerBool then
					rightImage = assetPath.."fondoRespuestas1.png"
				else
					rightImage = assetPath.."fondoRespuestas.png"
				end
				manager.wrong({id = "image", image = rightImage, xScale = 0.5, yScale = 0.5})--correctAnswerNumber, data)
			end
		end
	end
		
	-- Button True Group
	display.remove(buttonTrueGroup)
	buttonTrueGroup = display.newGroup()
	buttonTrueGroup.x = display.contentCenterX - radiusXbuttons
	buttonTrueGroup.y = posY
	buttonTrueGroup.respBool = true
	
	--[[local baseTrueButton = display.newImage(assetPath.."fondoRespuestas.png")
	baseTrueButton.xScale = 1
	baseTrueButton.yScale = 1
	buttonTrueGroup:insert(baseTrueButton)]]--
	
	local checkmark = display.newImage(assetPath.."fondoRespuestas1.png")
	checkmark:scale(0.75, 0.75)
	checkmark.y = display.viewableContentHeight*0.1
	buttonTrueGroup:insert(checkmark)
	
	local checkmarkText = display.newText(localization.getString("commonCorrect"), checkmark.x, checkmark.y + checkmark.height/2, settings.fontName, 32)
	checkmarkText:setFillColor(unpack(CORRECT_TEXT_COLOR))
	buttonTrueGroup:insert(checkmarkText)
	
	buttonTrueGroup:addEventListener("tap", responder)
	sceneView:insert(buttonTrueGroup)
	
	-- Button False Group
	display.remove(buttonFalseGroup)
	buttonFalseGroup = display.newGroup()
	buttonFalseGroup.x = display.contentCenterX + radiusXbuttons
	buttonFalseGroup.y = posY
	buttonFalseGroup.respBool = false
	
	--local baseFalseButton = display.newImage(assetPath.."fondoRespuestas.png")
	--buttonFalseGroup:insert(baseFalseButton)
	local cross = display.newImage(assetPath.."fondoRespuestas.png")
	cross:scale( 0.75, 0.75 )
	buttonFalseGroup:insert(cross)
	cross.y = display.viewableContentHeight*0.1
	
	local crossText = display.newText(localization.getString("commonIncorrect"), cross.x, cross.y + cross.height/2, settings.fontName, 32)
	crossText:setFillColor(unpack(INCORRECT_TEXT_COLOR))
	buttonFalseGroup:insert(crossText)
	
	buttonFalseGroup:addEventListener("tap", responder)
	sceneView:insert(buttonFalseGroup)
end

local function showTutorial(correctAnswerBool)
	local paraX
	local paraY
	if correctAnswerBool == true then
		paraX = buttonTrueGroup.x
		paraY = buttonTrueGroup.y
	else
		paraX = buttonFalseGroup.x
		paraY = buttonFalseGroup.y
	end
	
	paraX = paraX + 25
	paraY = paraY + 50
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = paraX, y = paraY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(parameters)
	local sceneView = game.view
	
	local data = parameters.data or {GAMETYPES[DEFAULT_GAMETYPE_INDEX]}
	colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND
	background:setFillColor(unpack(colorRGB))
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsMathTrueOrNot")
	
	isGameAnswered = false
	
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)
	
	typeGame = data[1]
	
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
	
	correctAnswerNumber = correctAnswer
	
	local fakeAnswer = parameters.wrongAnswers[1]
	
	questionString = equalityString
	
	if math.random(1,2) == 2 then
		generateEquation(operand1, operand2, correctAnswer, nameImageOperator)
		generateTrueFalseButtons(true)
		showTutorial(true)
		
	else
		generateEquation(operand1, operand2, fakeAnswer, nameImageOperator)
		generateTrueFalseButtons(false)
		showTutorial(false)
	end
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		-- TODO check limits to requirements
		available = false,
		correctDelay = 300,
		wrongDelay = 300,		
		
		name = "Math tap cookies",
		category = "math",
		subcategories = {"addition"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			
			{id = "operation", operands = 2, minOperand = 1, maxOperand = 5, maxAnswer = 9, minAnswer = 1},
			{id = "wrongAnswer", amount = 1, minAnswer = 1, maxAnswer = 9},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	background = display.newRect(sceneView, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	local batidora = display.newImage(assetPath .. "1.png")
	batidora.x = display.viewableContentWidth*0.8
	batidora.y = display.viewableContentHeight*0.1
	sceneView:insert(batidora)
	local barra = display.newImage( assetPath .. "barra.png" )
	barra.y = display.viewableContentHeight * 0.375
	barra.x = display.contentCenterX
	barra.width = display.viewableContentWidth*0.875
	barra.height = display.viewableContentHeight*0.425
	sceneView:insert(barra)
	
	instructions = display.newText("",  display.viewableContentWidth/4, display.viewableContentHeight/9, settings.fontName, 32)
	instructions:setFillColor(224/255, 163/255, 40/255)
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
		
	end
end


function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		display.remove(dynamicElementsGroup)
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
