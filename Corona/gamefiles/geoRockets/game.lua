----------------------------------------------- Rocket
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local manager
local dynamicElementsGroup
local correctAnswers
local answerTable, questionTable
local instructions
local isFirstTime, gameTutorial
local shuffledQuestionTable, shuffledQuestionList
local shuffledAnswerTable, shuffledAnswerList
local question, correctAnswer
local isAnsweredFlag
----------------------------------------------- Constants
local BACKGROUND_COLOR = { 160/255, 143/255, 224/255 }
local QUESTION_FONT_COLOR = { 91/255, 71/255, 155/255 }
local ANSWER_FONT_COLOR = { 255/255, 255/255, 255/255 }
local TUTORIAL_INSTRUCTIONS_FONT_COLOR = {255/255, 255/255, 255/255}
local FONT_NAME = settings.fontName

local QUESTION_NUMBER = 3
local ANSWER_NUMBER = 3
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then
		local xPosition
		local yPosition

		for i = 1, 3 do
			if answerTable[i].id == questionTable[1].id then
				yPosition = answerTable[i].y
				xPosition = answerTable[i].x
			end
		end
	
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = xPosition, y = yPosition, toX = questionTable[1].x, toY = questionTable[1].y},
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

local function endGame()
	if correctAnswers == QUESTION_NUMBER then
		manager.correct()
	else
		manager.wrong()
	end
end

local function doTouchedEvent(event)
	local touchedObject = event.target
	if event.phase == "began" then
		tutorials.cancel(gameTutorial,300)
		display.getCurrentStage():setFocus(touchedObject);
		touchedObject.isFocus = true
		transition.cancel( "backTransition" )
		touchedObject.x = event.x
		touchedObject.y = event.y
		
		touchedObject.markedX = touchedObject.initX
		touchedObject.markedY = touchedObject.initY
		
		sound.play("dragtrash")

	elseif touchedObject.isFocus then
		if event.phase == "moved" then			
			touchedObject.x = event.x
			touchedObject.y = event.y

		elseif event.phase=="ended" then
			touchedObject.hasFocus = false
			display.getCurrentStage():setFocus(nil)
			isAnsweredFlag = false

			for i = 1, QUESTION_NUMBER do
				if touchedObject.x <=  questionTable[i].contentBounds.xMax and 
					touchedObject.x >= questionTable[i].contentBounds.xMin and 
					touchedObject.y >= questionTable[i].contentBounds.yMin and 
					touchedObject.y <= questionTable[i].contentBounds.yMax then
						if touchedObject.id == questionTable[i].id then
							isAnsweredFlag = true
							sound.play("pop")
							correctAnswers = correctAnswers + 1
							touchedObject:removeEventListener( "touch", doTouchedEvent )
							transition.moveTo(touchedObject, {time = 500, x = questionTable[i].x + 350, y = questionTable[i].y, onComplete = function()
								sound.play("minigamesRocketLaunch")
								transition.moveTo(questionTable[i], {x = questionTable[i].x - 1000, y = questionTable[i].y, time = 1250})
								transition.moveTo(touchedObject, {x = touchedObject.x - 1000, y = touchedObject.y, time = 1250, onComplete = function()
									sound.stopAll(400)
								end})
							end })

							if correctAnswers == QUESTION_NUMBER then
								endGame()
							end
						end
				
					elseif isAnsweredFlag ~= true then
						sound.play("cut")
						director.to(scenePath, touchedObject, {time = 400, x = touchedObject.initX, y = touchedObject.initY, tag = "backTransition"})
				end
			end
		end
	end
end

local function initializeQuestionSpaces()
	for i = 1, QUESTION_NUMBER do
		questionTable[i].id = shuffledQuestionList[i].id
		questionTable[i].textDisplay.text = shuffledQuestionList[i].question
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

		local questionSpace = display.newImage(assetPath .. "MinigamesGeo-13.png")
		
		questionTable[i]:insert(questionSpace)

		questionTable[i].x = display.contentCenterX * 0.60
		questionTable[i].y = display.contentCenterY * i * 0.50

		local options = 
		{
			text = "",	 
			x = questionSpace.x,
			y = questionSpace.y,
			width = 225,
			height = 0,
			font = FONT_NAME,   
			fontSize = 18,
			align = "center"
		}

		local questionText = display.newText(options)
		questionText:setFillColor(unpack(QUESTION_FONT_COLOR))
		
		questionTable[i].textDisplay = questionText
		questionTable[i]:insert(questionText)
		
		sceneView:insert(questionTable[i])
	end
end

local function generateAnswerSpaces(sceneView)
	answerTable = {}

	for i = 1, ANSWER_NUMBER do
		answerTable[i] = display.newGroup()
		
		local answerSpace = display.newImage(assetPath .. "MinigamesGeo-14.png")

		answerTable[i]:insert(answerSpace)
		
		answerTable[i].x = display.contentCenterX * 1.60
		answerTable[i].y = display.contentCenterY * i * 0.50
		
		answerTable[i].initX = answerTable[i].x
		answerTable[i].initY = answerTable[i].y

		local options = 
		{
			text = "",	 
			x = answerSpace.x - 50,
			y = answerSpace.y,
			width = 75,
			height = 50,
			font = FONT_NAME,   
			fontSize = 18,
			align = "center"
		}

		local answerText = display.newText(options)
		answerText:setFillColor(unpack(ANSWER_FONT_COLOR))

		answerTable[i].textDisplay = answerText
		answerTable[i]:insert(answerText)

		answerTable[i]:addEventListener( "touch", doTouchedEvent )

		sceneView:insert(answerTable[i])
	end
end

local function initialize(parameters)
	local sceneView = game.view

	parameters = parameters or {}

	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsRocket_003")

	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = display.newGroup()
	sceneView:insert(dynamicElementsGroup)

	correctAnswers = 0
		
	answerTable = {}
	
	shuffledQuestionList = {}
	shuffledAnswerList = {}
	
	question = parameters.questions
	correctAnswer = parameters.answers

	shuffleQuestionTable()
	shuffleAnswerTable()
	generateQuestionSpaces(sceneView)
	generateAnswerSpaces(sceneView)
	initializeQuestionSpaces()
	initializeAnswerSpaces()
	
	showTutorial()
end

-----------------------------------------------Module functions
function game.getInfo()
	return {
		-- TODO answers are in spanish only
		available = false,
		correctDelay = 1200,
		wrongDelay = 1200,
		
		name = "Geo Rocket",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 3},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) )
	sceneView:insert(background)
	
	instructions = display.newText("",  display.contentCenterX, display.contentCenterY * 0.15, settings.fontName, 28)
	instructions:setFillColor( unpack(TUTORIAL_INSTRUCTIONS_FONT_COLOR) )
	sceneView:insert(instructions)
end

function game:show(event)
	local sceneGroup = self.view
	local phase = event.phase
	local params = event.params
		
	if ( phase == "will" ) then
		initialize(event.params)
		manager = event.parent

	elseif ( phase == "did" ) then
	end
end

function game:destroy (event)

end

function game:hide ( event )
	local sceneGroup = self.view		
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then	
		tutorials.cancel(gameTutorial)
		for i = 1, QUESTION_NUMBER do
			display.remove(questionTable[i])
		end
		for i = 1, ANSWER_NUMBER do
			display.remove(answerTable[i])
		end
	end
end

game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game