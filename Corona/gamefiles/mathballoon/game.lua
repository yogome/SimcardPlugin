----------------------------------------------- Math balloon
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )
local widget = require( "widget" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local estadoTimer = false
local creadorGlobos
local globito
local sceneGroup
local manager
local background
local operand1Text, operand2Text
local operator
local answersGroup, answerList
local timerGenerateAnswers
local questionMarkText
local answerBackground
local gameTutorial
local firstTime, tutorialText
local textLayer
local correctBallon
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local POSITION_Y_EQUATION = display.viewableContentHeight*0.175
local SIZE_TEXT = 100
local SCALE_SIGNS = 1

local POSITION_X_OPERAND1 = display.contentCenterX - 300
local POSITION_X_OPERATOR = display.contentCenterX - 150
local POSITION_X_OPERAND2 = display.contentCenterX
local POSITION_X_EQUALS = display.contentCenterX + 150
local POSITION_X_ANSWER = display.contentCenterX + 300

----------------------------------------------- Functions
	
local function tutoTap()
	if firstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 1500, x = 125, y = 40, getObject = function() return correctBallon end},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end	
end

local function createOperator(imagePath)
	local operator = display.newImage(imagePath)
	operator.x = POSITION_X_OPERATOR
	operator.y = POSITION_Y_EQUATION
	operator.xScale = SCALE_SIGNS
	operator.yScale = SCALE_SIGNS
	return operator
end

local function generateAnswers(correctAnswer)
	answerList = {}
	local correctAnswerIdx = math.random(1, 4)
	local anchoDeImg = 257
	local spawnX = display.viewableContentWidth + anchoDeImg
	local tempo = 10000
	local hasAnswered = false
	
	local function ponchar(event)
		if hasAnswered then return end
		tutorials.cancel(gameTutorial,300)
		hasAnswered = true
		sound.play("pop")
		timer.cancel( creadorGlobos )
		estadoTimer = false
		globito = event.target
		local label = globito:getLabel()
		local trans = globito.transition
		transition.cancel(trans)
		
		director.to(scenePath, questionMarkText, {time=300, alpha = 0})
		director.to(scenePath, globito, {time = 500, x=answerBackground.x, y=answerBackground.y, onStart = function() director.to(scenePath, answerBackground, {time = 500, alpha = 0}) end ,onStart= function()
			questionMarkText.text = globito:getLabel()
			questionMarkText.alpha = 1
			if tonumber(label) == correctAnswer then
				manager.correct()
			else
				manager.wrong({id = "text", text = operationResult, fontSize = 75})
			end
		end})
		for i=1, #answerList do
			answerList[i]:setEnabled(false)
		end	
		globito.alpha = 1	
	end
	
	local function globoImg()
		local globoIdx = math.random(1, 4)
		return assetPath.."g"..globoIdx
	end
	
	local function newGlobo()
		estadoTimer = true
		local answerListIdx = #answerList+1
		local dFile = globoImg()
		local numero 
		if answerListIdx == correctAnswerIdx then
			numero = correctAnswer
		else
			numero = wrongAnswers[math.random(1, #wrongAnswers)]
		end
		local moveX = -20

		
		local lblSize = SIZE_TEXT --100
		if numero >= 100 then lblSize = SIZE_TEXT-10 end
		if numero >= 1000 then lblSize = SIZE_TEXT-20 end
		
		local globo = widget.newButton({
			width = anchoDeImg,
			height = anchoDeImg,			
			defaultFile = dFile..".png",
			overFile = dFile.."ponchado.png",
			label = numero,
			
			labelYOffset = -20,
			labelXOffset = 20 + moveX,
			labelColor = { default={ 0, 0, 0 }, over={ 0, 0, 0 } },
			fontSize = lblSize,
			font = settings.fontName,
			onPress = ponchar,
			left = spawnX,
			top = math.random(POSITION_Y_EQUATION + 150, display.viewableContentHeight - anchoDeImg),
			transition = 0	
		})
		globo.alpha = 1
		
		answerList[answerListIdx] = globo
		sceneGroup:insert(globo)

		if answerListIdx == correctAnswerIdx then
			correctBallon = globo
			tutoTap()			
			correctAnswerIdx = -1
		end

		globo.transition = director.to(scenePath, globo, {time = tempo, x = -globo.contentWidth, onComplete = function()
				if tonumber(globo:getLabel()) == correctAnswer then
					local buenasRespuestas = false
					for i=2, #answerList do						
						if tonumber(answerList[i]:getLabel()) == correctAnswer then 
							buenasRespuestas = true
							break
						end
					end
					if not buenasRespuestas then
						local glob = answerList[#answerList]
						glob:setLabel(correctAnswer)
					end
				end
				display.remove(globo)
				globo = nil
				table.remove(answerList, 1)
			end})
	end
	newGlobo()
	creadorGlobos = director.performWithDelay(scenePath, tempo / 7, newGlobo, -1)
end

local function generateEquation(operand1, operand2, nameImageOperator)	
	display.remove(operator)
	operator = createOperator(nameImageOperator)
	sceneGroup:insert(operator)
	
	operand1Text.text = operand1	
	operand2Text.text = operand2
	
	local lblSize = SIZE_TEXT
	if operand1 > 100 then lblSize = SIZE_TEXT-20 end
	if operand1 > 1000 then lblSize = SIZE_TEXT-30 end
	operand1Text.size = lblSize
	
	lblSize = SIZE_TEXT
	if operand2 > 100 then lblSize = SIZE_TEXT-20 end
	if operand2 > 1000 then lblSize = SIZE_TEXT-30 end
	operand2Text.size = lblSize	
end

local function createOperationBase(sceneGroup)
	
	local function createOperand(positionX)
		local operandBackground = display.newImage(assetPath.."g0.png")
		operandBackground.x = positionX
		operandBackground.y = POSITION_Y_EQUATION
		sceneGroup:insert(operandBackground)
		
		local operandText = display.newText("0", positionX, POSITION_Y_EQUATION, settings.fontName, SIZE_TEXT)
		operandText:setFillColor(12/255, 21/255, 66/255)
		sceneGroup:insert(operandText)
		return operandText
	end
	
	operand1Text = createOperand(POSITION_X_OPERAND1)
	operand2Text = createOperand(POSITION_X_OPERAND2)
	
	local equals = display.newImage("images/minigames/equalsWhite.png")
	equals.x = POSITION_X_EQUALS
	equals.y = POSITION_Y_EQUATION
	equals.xScale = SCALE_SIGNS
	equals.yScale = SCALE_SIGNS
	sceneGroup:insert(equals)
	
	answerBackground = display.newImage(assetPath.."respuesta.png")
	answerBackground.x = POSITION_X_ANSWER
	answerBackground.y = POSITION_Y_EQUATION
	sceneGroup:insert(answerBackground)
	
	questionMarkText = display.newText("?", answerBackground.x, POSITION_Y_EQUATION - 10, settings.fontName, SIZE_TEXT)
	questionMarkText.isVisible = false
	sceneGroup:insert(questionMarkText)
	questionMarkText:setFillColor(0)
end

local function cancelTutorial()
	tutorials.cancel(gameTutorial)
end

local function endMinigame()
	if timerGenerateAnswers then
		timer.cancel(timerGenerateAnswers)
		timerGenerateAnswers = nil
	end
		
	for index = #answerList, 1, -1 do
		display.remove(answerList[index])
		answerList[index] = nil
	end
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	manager = event.parent
	wrongAnswers = parameters.wrongAnswers
	operationResult = parameters.operation.operationString
	
	firstTime = parameters.isFirstTime
	
	questionMarkText.alpha = 1
	questionMarkText.text = "?"

	tutorialText.text = localization.getString("tutoMathballoon")
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusWhite.png",
		["subtraction"] = "images/minigames/minusWhite.png",
		["multiplication"] = "images/minigames/multiplyWhite.png",
		["division"] = "images/minigames/divisionWhite.png",
	}
	
	local chosenTopic = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	local nameImageOperator = operatorFilenames[chosenTopic]
	
	generateEquation(operation.operands[1], operation.operands[2], nameImageOperator)
	generateAnswers(operation.result)
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		-- TODO this game appears to not be responsive (iPhone 5)
		available = false,
		correctDelay = 800,
		wrongDelay = 1000,		
		
		name = "Math balloon",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, maxAnswer = 9, minAnswer = 1, maxOperand = 9, minOperand = 1, amount = 1},
			{id = "wrongAnswer", amount = 9, tolerance = 5},
		},
	}
end 

function game:create(event)
	local sceneGroup = self.view

	background = display.newImage(assetPath .. "fondo.png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale(backgroundScale, backgroundScale)
	sceneGroup:insert(background)
	
	answersGroup = display.newGroup()
	sceneGroup:insert(answersGroup)
	createOperationBase(sceneGroup)

	textLayer = display.newGroup( )
	sceneGroup:insert(textLayer)

	tutorialText = display.newText("",  display.contentCenterX, display.screenOriginY + 290, settings.fontName, 32)
	textLayer:insert(tutorialText)
end

function game:destroy()
	
end

function game:show( event )
	sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)	
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then
		answerBackground.alpha = 1
		display.remove(globito)
		if estadoTimer == true then
			timer.cancel(creadorGlobos)
			estadoTimer = false
		end
		for indexgloblos = 1, #answerList do
			answerList[indexgloblos]:removeSelf( )
			answerList[indexgloblos] = nil
		end
		endMinigame()
		cancelTutorial()
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game