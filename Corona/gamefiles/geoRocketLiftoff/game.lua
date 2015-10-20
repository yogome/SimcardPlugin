----------------------------------------------- Cohete_0025
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local extratable = require( "libs.helpers.extratable" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local answersLayer, answersGroup, answerList
local backgroundLayer
local textLayer, instructions
local correctAnswer, correctAnswerTutoX, correctAnswerTutoY
local wrongAnswer
local rocket, rocketFlame, rocketGroup
local isFirstTime, gameTutorial
local questionGroup, question
local answerTable, answer
local isAnswered
----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -200}
local SIZE_FONT = 40
local SIZE_ANSWER_FONT = 18
local FONT_NAME = settings.fontName

local SIZE_TUTORIAL_FONT = 24
local OFFSET_TUTORIAL_TEXT = {x = 200, y = -200}

local PADDING_ANSWERS_NUMBER = 300
local ANSWERS_NUMBER = 3
local OFFSET_Y_ANSWERS_NUMBER = 300
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 5,
			parentScene = game.view,
			scale = 0.6,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 1500, x = correctAnswerTutoX, y = correctAnswerTutoY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function shuffleAnswerTable()
	answerTable = {
		[1] = correctAnswer,
		[2] = wrongAnswer[1],
		[3] = wrongAnswer[2],
	}
	
	answerTable = extratable.shuffle(answerTable)
	
	for index = 1, 3 do
		answerList[index] = answerTable[index]
	end	
end

local function onAnswerTapped(event)
	tutorials.cancel(gameTutorial, 300)
	if isAnswered == false then
		isAnswered = true
		sound.play("pop")
		if event.target.isCorrect then
			rocketFlame.alpha = 1
			sound.play("minigamesRocketLaunch")
			transition.moveTo(rocketGroup, {x = rocketGroup.x, y = rocketGroup.y - 1000, time = 2500})
			manager.correct()
			sound.stopAll(1000)
		else
			manager.wrong({id = "text", text = correctAnswer, fontSize = 50})
		end
	end
end

local function createRocket()
	local rocketScale = .75
	local rocketFlameScale = .75
	rocketGroup = display.newGroup()
	
	rocket = display.newImage(assetPath.."nave.png")
	rocket:scale(rocketScale, rocketScale)
	rocket.x = display.contentCenterX - 300
	rocket.y = display.contentCenterY + 25
	rocketGroup:insert(rocket)
	answersGroup:insert(rocketGroup)
	
	rocketFlame = display.newImage(assetPath.."1.png")
	rocketFlame:scale(rocketFlameScale, rocketFlameScale)
	rocketFlame.x = rocket.x
	rocketFlame.y = rocket.y + 120
	rocketFlame.alpha = 0
	rocketGroup:insert(rocketFlame)
	rocketFlame:toBack()
	answersGroup:insert(rocketGroup)
end

local function createDynamicAnswers()
	answersGroup = display.newGroup()

	local answersSettedTable = {correctAnswer, 0}
	
	local totalWidth = (ANSWERS_NUMBER - 1) * PADDING_ANSWERS_NUMBER
	local startX = display.contentCenterX - totalWidth * 0.50
	local answerScale = 1.0

	for index = 1, ANSWERS_NUMBER do
		answer = display.newGroup()
		
		local answerBackground = display.newImage(assetPath.."opcion.png")
		answerBackground:scale(answerScale, answerScale)
		answerBackground.x = startX + (index - 1) * PADDING_ANSWERS_NUMBER
		answerBackground.y = display.contentCenterY + OFFSET_Y_ANSWERS_NUMBER
		answer:insert(answerBackground)
		
		local optionsAnswerText = 
		{
			text = answerList[index],     
			x = startX + (index - 1) * PADDING_ANSWERS_NUMBER,
			y = display.contentCenterY + OFFSET_Y_ANSWERS_NUMBER - 20,
			font = FONT_NAME,   
			fontSize = SIZE_ANSWER_FONT,
		}
		
		answer.text = answerList[index]
		
		local answerText = display.newText(optionsAnswerText)
		answerText:setFillColor(0,0,0)
		answer:insert(answerText)

		if answer.text == correctAnswer then
			correctAnswerTutoX = answerText.x
			correctAnswerTutoY = answerText.y
			answer.isCorrect = true
		else
			answer.isCorrect = false
		end

		answer:addEventListener("tap", onAnswerTapped)
		
		answersGroup:insert(answer)		
		answersLayer:insert(answersGroup)
	end
end

local function createDynamicQuestion()
	questionGroup = display.newGroup()
	
	local questionOptions = 
	{
		text = question,	 
		x = display.contentCenterX,
		y = display.screenOriginY + 50,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}
	
	local dynamicQuestionText = display.newText(questionOptions)
	questionGroup:insert(dynamicQuestionText)
	textLayer:insert(questionGroup)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	
	manager = event.parent
	
	isFirstTime = params.isFirstTime
	instructions.text = localization.getString("instructionsCohete_0025")
	
	question = params.question
	correctAnswer = params.answer
	wrongAnswer = params.wrongAnswers
	
	isAnswered = false
	
	answerList = {}
		
	shuffleAnswerTable()
	createDynamicQuestion()
	createDynamicAnswers(correctAnswer)
	createRocket()
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		wrongDelay = 200,
		correctDelay = 350,
		
		name = "Cohete_0024",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 2},
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
	
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	backgroundLayer:insert(background)
	
	local instructionOptions = {
		text = "",	 
		x = display.contentCenterX + OFFSET_TUTORIAL_TEXT.x,
		y = display.contentCenterY + OFFSET_TUTORIAL_TEXT.y,
		width = display.viewableContentWidth*0.34,
		font = settings.fontName,  
		fontSize = SIZE_TUTORIAL_FONT,
		align = "center"
	}
	
	instructions = display.newText(instructionOptions)
	textLayer:insert(instructions)
end

function game:destroy()
	
end

function game:show(event)
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		showTutorial()
	elseif phase == "did" then
	
	end
end

function game:hide(event)
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
	
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		display.remove(answersGroup)
		display.remove(questionGroup)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game