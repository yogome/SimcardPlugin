------------------------------------------------ Tripas de gato
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local extratable = require( "libs.helpers.extratable" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local screen = require( "libs.helpers.screen" )

local game = director.newScene()
----------------------------------------------- Variables
local manager
local dynamicElementsGroup
local correctAnswers
local answerSelected
local questionSelected
local questionTable
local answerTable
local lineTable, lineIndex
local instructions
local isFirstTime, gameTutorial
local question, correctAnswer, wrongAnswer
local shuffledAnswerTable, shuffledAnswerList
local shuffledQuestionTable, shuffledQuestionList
local drawTable, guidingLine
local questionIndex
----------------------------------------------- Constants

local BACKGROUND_COLOR = { 2/255, 0/255, 81/255 }
local QUESTION_FONT_COLOR = { 131/255, 52/255, 40/255 }
local ANSWER_FONT_COLOR = { 255/255, 255/255, 255/255 }
local TUTORIAL_INSTRUCTIONS_FONT_COLOR = {121/255, 162/255, 168/255}
local FONT_NAME = settings.fontName

local LINE_WIDTH = 8

local QUESTION_NUMBER = 3
local ANSWER_NUMBER = 4

local LINE_COLOR = {0/255, 0/255, 0/255}

------------------------------------- START FUNCTIONS --------------------------------------
local function showTutorial()
	local xPosition = display.viewableContentWidth * 0.82
	local yPosition = nil

	if questionTable[1].id == answerTable[1].id then
		yPosition = display.viewableContentHeight * 0.40
	elseif questionTable[1].id == answerTable[2].id then
		yPosition = display.viewableContentHeight * 0.60
	elseif questionTable[1].id == answerTable[3].id then
		yPosition = display.viewableContentHeight * 0.80
	elseif questionTable[1].id == answerTable[4].id then
		yPosition = display.viewableContentHeight * 1.0
	end
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1500, time = 2500, x = display.viewableContentWidth * 0.45, y = display.viewableContentHeight * 0.35, toX = xPosition, toY = yPosition - 125},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function shuffleAnswerTable()
	shuffledAnswerTable = {
		[1] = {answer = correctAnswer[1], id = 1},
		[2] = {answer = correctAnswer[2], id = 2},
		[3] = {answer = correctAnswer[3], id = 3},
		[4] = {answer = wrongAnswer[1], id = 4},
	}
	
	shuffledAnswerTable = extratable.shuffle(shuffledAnswerTable)
	
	for index = 1, ANSWER_NUMBER do
		shuffledAnswerList[index] = shuffledAnswerTable[index]
	end	
end

local function shuffleQuestionTable()
	shuffledQuestionTable = {
		[1] = {question = question[1], id = 1},
		[2] = {question = question[2], id = 2},
		[3] = {question = question[3], id = 3},
	}
	
	shuffledQuestionTable = extratable.shuffle(shuffledQuestionTable)
	
	for index = 1, QUESTION_NUMBER do
		shuffledQuestionList[index] = shuffledQuestionTable[index]
	end	
end

local function cleanGame()
	for i = 1, #lineTable do
		lineTable[i]:removeSelf()
		lineTable[i] = nil
		display.remove(guidingLine)
	end			
	
	display.remove(guidingLine)
end

local function randomizeColors()
	LINE_COLOR = {R = math.random(1,255)/255, G = math.random(1,255)/255, B = math.random(1,255)/255}
end

local function newPointtoPointLine(draw)
	local touchedObject = draw.target
	local correctAnswerNotSelected
	local configDraw = {15}
	
	if draw.phase == "began" then
		display.getCurrentStage():setFocus(touchedObject)
		touchedObject.isFocus = true
		sound.play("dragtrash")
		drawTable[1] = display.newCircle(draw.x, draw.y, configDraw[1])
		drawTable[1].origX = draw.x
		drawTable[1].origY = draw.y
		tutorials.cancel(gameTutorial,300)
		
		for i = 1, QUESTION_NUMBER do
			if drawTable[1].x <=  questionTable[i].contentBounds.xMax and 
				drawTable[1].x >= questionTable[i].contentBounds.xMin and 
				drawTable[1].y >= questionTable[i].contentBounds.yMin and 
				drawTable[1].y <= questionTable[i].contentBounds.yMax then
					questionSelected = questionTable[i].id
					questionIndex = i
			end
		end
		
	elseif touchedObject.isFocus then
		if draw.phase == "moved" then
			display.remove(guidingLine)
			guidingLine = display.newLine(drawTable[1].origX, drawTable[1].origY, draw.x, draw.y)
			guidingLine.strokeWidth = LINE_WIDTH

		elseif draw.phase == "ended" then
			touchedObject.isFocus = false
			display.getCurrentStage():setFocus(nil)

			drawTable[2] = display.newCircle(draw.x,draw.y, configDraw[1])
			drawTable[2]:setFillColor(0,0,255)
			drawTable[2].origX = draw.x
			drawTable[2].origY = draw.y

			local midPointX = math.abs(drawTable[1].origX+drawTable[2].origX)/2
			local midPointY = math.abs(drawTable[1].origY+drawTable[2].origY)/2

			local length = 
					math.sqrt(
					math.abs(drawTable[1].origX-drawTable[2].origX)^2 + 
					math.abs(drawTable[1].origY-drawTable[2].origY)^2
					)

			local deltaX = drawTable[1].origX-drawTable[2].origX
			local deltaY = drawTable[1].origY-drawTable[2].origY
			local angle = math.atan2(deltaY,deltaX)*(180/math.pi)

			lineIndex = #lineTable + 1
			lineTable[lineIndex] = display.newGroup()

			local line = display.newRect(999, 999, length, LINE_WIDTH)
			line.x = midPointX
			line.y = midPointY
			line.rotation = angle
			line:setFillColor(100,255,100)
			lineTable[lineIndex]:insert(line)


			for i = 1, ANSWER_NUMBER do
				if drawTable[2].x <=  answerTable[i].contentBounds.xMax and 
					drawTable[2].x >= answerTable[i].contentBounds.xMin and 
					drawTable[2].y >= answerTable[i].contentBounds.yMin and 
					drawTable[2].y <= answerTable[i].contentBounds.yMax then
						answerSelected = answerTable[i].id		
				end
			end
			
			if questionSelected == answerSelected then
				sound.play("pop")
				correctAnswers = correctAnswers + 1
				questionTable[questionIndex]:removeEventListener( "touch",	newPointtoPointLine)
				if correctAnswers == QUESTION_NUMBER then
					manager.correct() 
					cleanGame()
				end
			elseif questionSelected ~= answerSelected and answerSelected ~= nil then
				for i = 1, ANSWER_NUMBER do
					if shuffledAnswerList[i].id == questionSelected then
						correctAnswerNotSelected = shuffledAnswerList[i].answer
					end
				end
				manager.wrong({id = "text", text = correctAnswerNotSelected, fontSize = 24})
				cleanGame()
			elseif answerSelected == nil then
				display.remove(lineTable[lineIndex])
				display.remove(guidingLine)
			end
			
			for i = 1, #drawTable do
				drawTable[i]:removeSelf()
				drawTable[i] = nil
			end
			
			answerSelected = nil			
		end
	end
end

local function initializeQuestionSpaces()
	for i = 1, QUESTION_NUMBER do
		questionTable[i].id = shuffledQuestionList[i].id
		questionTable[i].textDisplay.text = shuffledQuestionList[i].question
		questionTable[i]:addEventListener( "touch",	newPointtoPointLine)
	end
end

local function initializeAnswerSpaces()
	for i = 1, ANSWER_NUMBER do
		answerTable[i].id = shuffledAnswerList[i].id
		answerTable[i].textDisplay.text = shuffledAnswerList[i].answer
	end
end

local function generateQuestionSpaces(sceneView)
	questionTable = {}
	
	for i = 1, QUESTION_NUMBER do
		questionTable[i] = display.newGroup()

		local questionSpace = display.newImage(assetPath .. "pregunta.png")
		questionSpace.x = display.contentCenterX * 0.60
		questionSpace.y = display.contentCenterY * i * 0.53 - 40

		questionSpace.anchorY = 0.10
		questionSpace:scale( .90, .90 )

		questionTable[i]:insert(questionSpace)

		local options = 
		{
			text = "",	 
			x = display.contentCenterX * 0.56,
			y = display.contentCenterY * i * 0.53,
			width = 225,
			height = 140,
			font = FONT_NAME,   
			fontSize = 18,
			align = "center"
		}

		local questionText = display.newText(options)
		questionText:setFillColor(unpack(QUESTION_FONT_COLOR))
		questionText.anchorY = 0

		questionTable[i].textDisplay = questionText
		questionTable[i]:insert(questionText)
		sceneView:insert(questionTable[i])
	end
end

local function generateAnswerSpaces(sceneView)
	answerTable = {}

	for i = 1, ANSWER_NUMBER do
		answerTable[i] = display.newGroup()

		local answerSpace = display.newImage(assetPath .. "respuesta.png")
		answerSpace.x = display.contentCenterX * 1.60
		answerSpace.y = display.contentCenterY * i * 0.45 - 30
		answerSpace:scale( .87, .87 )

		answerTable[i]:insert(answerSpace)

		local options = 
		{
			text = "",	 
			x = display.contentCenterX * 1.6,
			y = display.contentCenterY * i * 0.45 - 20,
			width = 150,
			height = 60,
			font = FONT_NAME,   
			fontSize = 18,
			align = "center"
		}

		local answerText = display.newText(options)
		answerText:setFillColor(unpack(ANSWER_FONT_COLOR))
		answerTable[i]:insert(answerText)

		answerTable[i].textDisplay = answerText
		answerTable[i]:insert(answerText)

		sceneView:insert(answerTable[i])
	end
end

local function initialize(parameters)
	local sceneView = game.view

	parameters = parameters or {}

	isFirstTime = parameters.isFirstTime	
	instructions.text = localization.getString("instructionsTripasDeGato")
		
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)

	correctAnswers = 0
	questionIndex = 0
	
	lineTable = {}	
	drawTable = {}
	
	shuffledAnswerList = {}
	shuffledQuestionList = {}
	
	question = parameters.questions
	correctAnswer = parameters.answers
	wrongAnswer = parameters.wrongAnswers

	answerSelected = nil
		
	shuffleAnswerTable()
	shuffleQuestionTable()
	initializeQuestionSpaces()
	initializeAnswerSpaces()
	
	showTutorial()
end

-------------------------------------------------- Module functions
function game.getInfo()
	return {
		available = false,
		correctDelay = 300,
		wrongDelay = 300,
		
		name = "Tripas de gato",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 3},
			{id = "wrongAnswer", amount = 1},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) )
	sceneView:insert(background)

	local tutorialBox = display.newImage(assetPath .. "barra.png")
	tutorialBox.x = screen.getPositionX(0.3)
	tutorialBox.y = screen.getPositionY(0.1)
	tutorialBox:scale( 0.45, 0.40 )
	sceneView:insert(tutorialBox)
	
	local options = {
		text = "",	 
		x = display.contentCenterX * 0.6,
		y = display.viewableContentHeight * 0.15,
		width = 330,
		height = 140,
		font = FONT_NAME,   
		fontSize = 24,
		align = "center"
	}

	instructions = display.newText(options)
	instructions:setFillColor(unpack(TUTORIAL_INSTRUCTIONS_FONT_COLOR))
	sceneView:insert(instructions)
	
	generateQuestionSpaces(sceneView)
	generateAnswerSpaces(sceneView)
end

function game:show(event)
	local sceneGroup = self.view
	local phase = event.phase
		
	if ( phase == "will" ) then
		initialize(event.params)
		manager = event.parent

	elseif ( phase == "did" ) then
		
	end
end

function game:destroy(event)

end

function game:hide(event)
	local sceneGroup = self.view		
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		for i = 1, QUESTION_NUMBER do
			questionTable[i]:removeEventListener( "touch",	newPointtoPointLine)
		end
		cleanGame()
	end
end

game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
