----------------------------------------------- Test minigame
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
local answerGroup
local answerList
local wrongAnswersGroup
local manager
local tapsEnabled
local isFirstTime
local gameTutorial
local questionText
local question
local correctAnswer
local wrongAnswers
local answers
local washer
local monster
local instructions
local idleAnimation
----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -310}
local OFFSET_WASHER = {x = -display.viewableContentWidth*0.2, y = display.viewableContentHeight*0.1}
local PADDING_ANSWERS = 120
local TOTAL_ANSWERS = 3
----------------------------------------------- Functions
 
local function animateMonster()
	if monster.isSafe then
		manager.correct()
		director.to(scenePath, monster, {delay = 0, time = 500, x = display.contentCenterX-200, y = display.viewableContentHeight*0.8, transition = easing.inOutBack, onComplete = function()
			director.to(scenePath, monster, {delay = 0, time = 300, x = display.contentCenterX-100})
			director.to(scenePath, monster, {delay = 0, time = 200, y = display.viewableContentHeight*0.65, transition = easing.outQuad, onComplete = function() 
				director.to(scenePath, monster, {delay = 0, time = 150, x = display.contentCenterX})
				director.to(scenePath, monster, {delay = 0, time = 100, y = display.viewableContentHeight*0.8, transition = easing.inQuad,})
			end})
		end})
	else
		sound.play("minigamesFlush")
		manager.wrong({id="text", text=correctAnswer, fontSize=40})
		monster.idle.isVisible = false
		monster.washed.isVisible = true
		monster.rotation = 0
		director.to(scenePath, monster, {delay = 0, time = 2000, rotation=360*4, transition = easing.inOutCubic,})
	end
end

local function onAnswerTapped(event)
	local answer = event.target
	
	tutorials.cancel(gameTutorial,300)
	transition.cancel(idleAnimation)
	
	sound.play("pop")
	
	if tapsEnabled then
		if answer.text.text == correctAnswer then
			monster.isSafe = true
			animateMonster()
			tapsEnabled = false
		else
			monster.isSafe = false
			animateMonster()
			tapsEnabled = false
		end
		
		tapsEnabled = false
	end
end

local function removeDynamicAnswers()
	display.remove(answerGroup)
	answerGroup = nil
end

local function createAnswers()

	answerGroup = display.newGroup()
	answersLayer:insert(answerGroup)

	local totalHeight = (TOTAL_ANSWERS - 1) * PADDING_ANSWERS
	local startX = display.contentCenterY - totalHeight * 0.6

	for index = 1, TOTAL_ANSWERS do
		local button = display.newGroup()
		local buttonBg = display.newImage(assetPath.."button.png")
		buttonBg.x = display.viewableContentWidth*0.682
		buttonBg.y = startX + (index - 1) * PADDING_ANSWERS
		buttonBg.xScale, buttonBg.yScale = 1.1, 1.1
		button:insert(buttonBg)
		
		local answerOptions = {
			text = answers[index],     
			x = buttonBg.x,
			y = buttonBg.y,
			width = buttonBg.width*0.7,
			font = settings.fontName,   
			fontSize = 24,
			align = "center"  
		}
		button.text = display.newText(answerOptions)
		button:insert(button.text)
		button.value = answers[index]
		button:addEventListener("tap", onAnswerTapped)
		answerGroup:insert(button)
		answerList[#answerList+1] = button
	end

end

local function animateMonster()
	director.to(scenePath, monster, {time = 1000, y = monster.y - 10, transition = easing.outSine, onComplete = function()
		director.to(scenePath, monster, {time = 2000, y = monster.y + 28, transition = easing.outSine, onComplete = function()
			director.to(scenePath, monster, {time = 1000, y = monster.y -18, onComplete = function() 
				animateMonster()
			end})
		end})
	end})
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	
	question = params.question
	correctAnswer = params.answer
	wrongAnswers = params.wrongAnswers
	answerList = {}
	answers = {}
	answers[1] = correctAnswer
	answers[2] = wrongAnswers[1]
	answers[3] = wrongAnswers[2]
	answers = extratable.shuffle(answers)

	questionText.text = question
	tapsEnabled = true
	
	monster.x = washer.x
	monster.y = washer.y
	monster.idle.isVisible = true
	monster.washed.isVisible = false
	
	idleAnimation = animateMonster()
end

local function tutorial()	
	if isFirstTime then
		
		local correctButton
		
		for index = 1, #answerList do
			if answerList[index].value == correctAnswer then
				correctButton = answerList[index]
			end
		end
		
		local tutorialOptions = {
			iterations = 5,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 3000, x = correctButton.text.x, y = correctButton.text.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = false,
		correctDelay = 1000,
		wrongDelay = 1400,
		
		name = "Geo Lavadora_0026",
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
	
	local background = display.newImage(assetPath.."background.png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.width = display.viewableContentWidth
	background.height = display.viewableContentHeight
	backgroundLayer:insert(background)
	
	local questionOptions = {
		text = "",     
		x = display.contentCenterX,
		y = background.height*0.13,
		width = background.width*0.7,
		font = settings.fontName,   
		fontSize = 30,
		align = "center"  
	}

	questionText = display.newText(questionOptions)
	textLayer:insert(questionText)
	
	washer = display.newImage(assetPath.."washer.png")
	washer.x = display.contentCenterX + OFFSET_WASHER.x
	washer.y = display.contentCenterY + OFFSET_WASHER.y
	washer.xScale, washer.yScale = 0.9, 0.9
	backgroundLayer:insert(washer)
	
	monster = display.newGroup()
	monster.idle = display.newImage(assetPath.."monster1.png")
	monster.idle.xScale, monster.idle.yScale = 0.6, 0.6
	monster:insert(monster.idle)
	monster.washed = display.newImage(assetPath.."monster2.png")
	monster.washed.xScale, monster.washed.yScale = 0.6, 0.6
	monster.isSafe = false
	monster:insert(monster.washed)
	backgroundLayer:insert(monster)
	
	local instructionOptions = {
		text = localization.getString("instructionsGeoLavadora"),     
		x = display.viewableContentWidth*0.75,
		y = display.viewableContentHeight*0.9,
		width = background.width*0.35,
		font = settings.fontName,   
		fontSize = 30,
		align = "center"  
	}

	instructions = display.newText(instructionOptions)
	instructions:setFillColor(13/255,149/255,163/255)
	instructions:toFront()
	backgroundLayer:insert(instructions)
	
end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		instructions.text = localization.getString("instructionsGeoLavadora"),
		initialize(event)
		createAnswers()
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
		tutorials.cancel(gameTutorial)

	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
