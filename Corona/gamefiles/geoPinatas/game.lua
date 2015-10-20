----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local extratable = require( "libs.helpers.extratable" )

local game = director.newScene()
----------------------------------------------- Variables

local pinatasGroup
local pinatasList
local questionBg
local manager
local instructions
local elementGroup
local isFirstTime
local canTap
local gameTutorial
local question
local correctAnswer
local wrongAnswers
local answers
local correctPinata
----------------------------------------------- Constants

local BACKGROUND_COLOR = {214/255, 255/255, 166/255}
local INSTRUCTIONS_COLOR = {3/255, 119/255, 116/255}
local LINES_COLOR = {55/255, 22/255, 127/255}

----------------------------------------------- Functions
local function breakPinata(pinata)
	if not pinata.firstBreak then
		sound.play("breakSound")
		pinata.firstBreak = true
	end
	
	local rightSide = pinata.right
	local leftSide = pinata.left

	director.to(scenePath, rightSide, {time = 700, alpha = 0, x = 100, rotation = 150, y = 1000}) 
	director.to(scenePath, leftSide, {time = 700, x = -100, alpha = 0, rotation = -150, y = 1000})
end

local function pinataTapped(event)
	if canTap then
		local pinata = event.target
		
		tutorials.cancel(gameTutorial,300)
		if pinata.isBroken then
			if pinata.answerRevealed then
				canTap = false
				if pinata.isCorrect then
					sound.play("pop")
					manager.correct()
				else
					manager.wrong({id = "text", text = correctAnswer, fontSize = 48})
				end
			end
		end

		pinata.taps = pinata.taps + 1
		if pinata.taps <= 4 then
			sound.play("ballImpact")
			pinata.answerRevealed = true
		else
			pinata.isBroken = true
			breakPinata(pinata)
			
		end

		transition.cancel(pinata)
		local targetRotationY = math.random(15,40) * (pinata.rotation < 0 and 1 or -1)
		director.to(scenePath, pinata, {rotation = targetRotationY, time = math.random(200,300), transition = easing.outQuad, onComplete = function()
			director.to(scenePath, pinata, {rotation = 0, time = math.random(500,700), transition = easing.inOutQuad})
		end})

	end
	
	return true
end

local function createPinatas()
	display.remove(pinatasGroup)
	pinatasGroup = display.newGroup()
	elementGroup:insert(pinatasGroup)

	pinatasList = {}

	answers = extratable.shuffle(answers)

	for pinataIndex = 1, 3 do
		local pinataAnswer = display.newGroup()
		pinataAnswer.x = display.screenOriginX + (display.viewableContentWidth * 0.25) * pinataIndex
		pinataAnswer.y = questionBg.y
		pinataAnswer:addEventListener("tap", pinataTapped)
		pinataAnswer.id = pinataIndex
		pinataAnswer.taps = 0
		pinataAnswer.isBroken = false
		pinataAnswer.firstBreak = false
		pinatasList[#pinatasList+1] = pinataAnswer
		
		local ropeLenght = 230 + (pinataIndex % 2) * 50
		
		local pinataLine = display.newRect(0, 0, 5, ropeLenght)
		pinataLine.anchorY = 0
		pinataLine:setFillColor(unpack(LINES_COLOR))
		pinataAnswer:insert(pinataLine)

		local pinataBg = display.newImage(assetPath.."answerBg.png")
		pinataBg.y = ropeLenght
		pinataAnswer:insert(pinataBg)
		pinataAnswer.answerBg = pinataBg.y
		
		local answerOptions = {
			text = answers[pinataIndex],	 
			x = pinataBg.x,
			y = pinataBg.y + 12,
			width = pinataBg.width * 0.75,
			font = settings.fontName,   
			fontSize = 22,
			align = "center"
		}
		pinataAnswer.answer = display.newText( answerOptions )
		pinataAnswer:insert(pinataAnswer.answer)
		
		if pinataAnswer.answer.text == correctAnswer then
			pinataAnswer.isCorrect = true
			correctPinata = pinataAnswer
		else
			pinataAnswer.isCorrect = false
		end

		local pinataRight = display.newImage( assetPath.."rightSide.png" )
		pinataRight.x = pinataBg.x - 3
		pinataRight.y = pinataBg.y - (pinataBg.height * 0.5) + 5
		pinataRight.xScale = 1.2
		pinataRight.yScale = 1.2
		pinataRight.anchorX = 0
		pinataRight.anchorY = 0.1
		pinataAnswer.right = pinataRight
		pinataAnswer:insert(pinataAnswer.right)

		local pinataLeft = display.newImage( assetPath.."leftSide.png" )
		pinataLeft.x = pinataBg.x - 155
		pinataLeft.y = pinataBg.y - (pinataBg.height/2) +1
		pinataLeft.xScale = 1.2
		pinataLeft.yScale = 1.2
		pinataLeft.anchorX = 0
		pinataLeft.anchorY = 0.1
		pinataLeft.rotation = 0
		pinataAnswer.left = pinataLeft
		pinataAnswer:insert(pinataAnswer.left)

		pinatasGroup:insert(pinataAnswer)
	end
end

local function showTutorial()
	if isFirstTime then		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = correctPinata.x, y = correctPinata.answerBg + 70},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	instructions.text = localization.getString("instructionsGeoPinatas")
	isFirstTime = params.isFirstTime
	manager = event.parent
	canTap = true
	
	question = params.question
	correctAnswer = params.answer
	wrongAnswers = params.wrongAnswers
	answers = {}
	answers[1] = correctAnswer
	answers[2] = wrongAnswers[1]
	answers[3] = wrongAnswers[2]
	
	questionBg.text.text = question
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		-- TODO answers are only in spanish
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Geo pinatas",
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

	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) ) 
	sceneView:insert(background)
	
	elementGroup = display.newGroup()
	sceneView:insert(elementGroup)

	questionBg = display.newImage(assetPath.."questionBg.png")
	questionBg.x = display.contentCenterX
	questionBg.y = questionBg.height / 1.7
	questionBg.xScale = 0.8
	questionBg.yScale = 0.8
	sceneView:insert(questionBg)

	-- TODO localize questions
	local questionOptions = {
		text = "",	 
		x = questionBg.x,
		y = questionBg.y,
		width = questionBg.width/1.5,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}

	questionBg.text = display.newText(questionOptions)
	sceneView:insert(questionBg.text)

	local instructionOptions = {
		text = "",	 
		x = questionBg.x,
		y = display.viewableContentHeight - 90,
		width = questionBg.width/1.5,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}

	instructions = display.newText(instructionOptions)
	instructions:setFillColor( unpack(INSTRUCTIONS_COLOR) )
	sceneView:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)
		createPinatas()
		showTutorial()
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		display.remove(pinatasGroup)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
