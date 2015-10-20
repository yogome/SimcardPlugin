----------------------------------------------- MathShip
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local questionCounter
local question
local questionList
local yogotarButton
local answerGroup
local answerList
local shuffleAnswers
local answerGroupList
local questionActive
local gameWrong
local questionMark
local instructions
local isFirstTime, gameTutorial, gameTutorial2
local markPosX, markPosY
local wrongAnswers
----------------------------------------------- Constants

local COLOR_BACKGROUND = {237/255, 91/255, 53/255}
local COLOR_QUESTION = {79/255, 172/255, 224/255}
local COLOR_INSTRUCTIONS = {239/255, 236/255, 132/255}
local COLOR_ANSWER2 = {0/255, 105/255, 103/255}

local buttonPosition = {
	[1] = {x = -250, y = -200},
	[2] = {x = 260, y = -200},
	[3] = {x = -250, y = 115},
	[4] = {x = 250, y = 115},
}

----------------------------------------------- Functions
local function createAnswers(sceneGroup)

	answerGroup = display.newGroup( )
	sceneGroup:insert(answerGroup)
	
	answerGroupList = {}

	local function addAnswerButton(index)
		local answer = display.newGroup( )
		answer.answerBg = display.newImage(assetPath.."option"..index..".png")
		answer.answerBg.x = display.contentCenterX + buttonPosition[index].x
		answer.answerBg.y = display.contentCenterY + buttonPosition[index].y
		answer:insert(answer.answerBg)

		local answerOptions = 
		{
			text = " ",	 
			x = answer.answerBg.x,
			y = answer.answerBg.y,
			width = answer.answerBg.width/1.3,
			font = settings.fontName,   
			fontSize = 26,
			align = "center"
		}

		answer.answerText = display.newText(answerOptions)
		answer.answerText.x = answer.answerBg.x
		answer.answerText.y = answer.answerBg.y
		if index == 4 or index == 1 then
			answer.answerText:setFillColor( unpack(COLOR_ANSWER2) )
		end
		answer:insert(answer.answerText)
		answerGroup:insert(answer)
		answerGroupList[#answerGroupList+1] = answer 
	end

	for buttonIndex = 1, 4 do
		addAnswerButton(buttonIndex)
	end
end

local function setAnswers()
	
	shuffleAnswers[1] = questionList[questionCounter].answer
	shuffleAnswers[2] = wrongAnswers[questionCounter]
	shuffleAnswers[3] = wrongAnswers[questionCounter]
	shuffleAnswers[4] = wrongAnswers[questionCounter]
	
	shuffleAnswers = extratable.shuffle(shuffleAnswers)

	for answerIndex = 1, 4 do
		answerGroupList[answerIndex].answerText.text = shuffleAnswers[answerIndex]
	end
end

local function answerTap(event)
	local answer = event.target
	local mark
		
		for index = 1, 4 do
			answerGroupList[index]:removeEventListener( "tap", answerTap )
		end
		
	sound.play("pop")

	if answer.answerText.text == questionList[questionCounter].answer then
		mark = display.newImage(assetPath.."correct.png")
	else
		mark = display.newImage(assetPath.."incorrect.png")
		gameWrong = true
	end

	mark.x = answer.answerText.x + 110
	mark.y = answer.answerText.y + 50
	mark.xScale = 0.1
	mark.yScale = 0.1
	answerGroup:insert(mark)
	mark.alpha = 0

	director.to(scenePath, mark, {time = 500, alpha = 1, xScale = 0.7, yScale = 0.7, transition = easing.inOutBounce, onComplete = function()
		director.to(scenePath, mark, {delay = 500, time = 500, alpha = 0, onComplete = function()
			for indexQuestion = 1, #answerGroupList do
				director.to(scenePath, answerGroupList[indexQuestion].answerText, {time = 100, alpha = 0})			
			end			
			director.to(scenePath, question, {time = 100, alpha = 0, onComplete = function() questionActive = false end})

			if questionCounter == 5 then
				if gameWrong then
					manager.wrong(
						{
							id = "text",
							text = questionList[1].answer.."\n"..
							questionList[2].answer.."\n"..
							questionList[3].answer.."\n"..
							questionList[4].answer,
							fontSize = 40
						})
					questionActive = true
				else
					manager.correct()
					questionActive = true
				end
			end
			mark:removeSelf()
		end})
	end})

	questionCounter = questionCounter + 1
	tutorials.cancel(gameTutorial2, 300)
	return true
end

local function setQuestion()
	questionActive = true
	question.text = questionList[questionCounter].question
	question.alpha = 1
	setAnswers()

	local function addButtonListener(buttonIndex)
		answerGroupList[buttonIndex]:addEventListener( "tap", answerTap )
	end

	for buttonIndex = 1, #answerGroupList do
		addButtonListener(buttonIndex)
		answerGroupList[buttonIndex].answerText.alpha = 1
	end
end

local function showTutorial2()
	for index = 1, 4 do
		if answerGroupList[index].answerText.text == questionList[questionCounter].answer then
			markPosX = answerGroupList[index].answerText.x
			markPosY = answerGroupList[index].answerText.y
		end
	end
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			scale = 0.7,
			parentScene = game.view,
			steps = {
				[1] = {id = "tap", delay = 1200, time = 1600, x = markPosX, y = markPosY},
			}
		}
		gameTutorial2 = tutorials.start(tutorialOptions)
	end
end

local function yogotarTap(event)
	sound.play("pop")
	tutorials.cancel(gameTutorial, 300)
	if questionActive then
		director.to(scenePath, yogotarButton, {delay = 50, time = 50, x = display.contentCenterX-20, onComplete = function() 
			director.to(scenePath, yogotarButton, {delay = 50, time = 50, x = display.contentCenterX+20, onComplete = function() 
				director.to(scenePath, yogotarButton, {delay = 50, time = 50, x = display.contentCenterX-10, onComplete = function()
					director.to(scenePath, yogotarButton, {delay = 50, time = 50, x = display.contentCenterX})
				end})
			end})
		end})

	elseif questionCounter <= 5 then
		director.to(scenePath, yogotarButton, {delay = 50, time = 100, xScale = 0.9, yScale = 0.9, transition = easing.inOutBounce, onComplete = function() 
			director.to(scenePath, yogotarButton, {delay = 50, time = 100, xScale = 0.7, yScale = 0.7, transition = easing.inOutBounce})
			director.to(scenePath, questionMark, {delay = 50, time = 450, alpha = 1, xScale = 0.5, yScale=0.5, y = display.contentCenterY - 210, transition = easing.outBack})
			for index = 1, 4 do
				director.to(scenePath, answerGroupList[index].answerBg, {delay = 0, time = 200, xScale = 1.02, yScale = 1.02, transition = easing.inOutBounce, onComplete = function() 
					director.to(scenePath, answerGroupList[index].answerBg, {delay = 0, time = 200, xScale = 1, yScale = 1, transition = easing.inOutBounce})
				end})
			end
		end})
		if questionCounter <=4 then
			setQuestion()
		end
			
		if questionCounter == 1 then
			showTutorial2()
		end
	end
end

local function createQuestion(sceneView)
		
	local questionBg = display.newImage(assetPath.."questionBg.png")
	questionBg.x = display.contentCenterX
	questionBg.y = display.viewableContentHeight - 40
	sceneView:insert(questionBg)
		
	local questionOptions = 
	{
		text = " ",	 
		x = questionBg.x,
		y = questionBg.y - 5,
		width = questionBg.width/1.1,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}

	question = display.newText( questionOptions )
	question:setFillColor( unpack( COLOR_QUESTION ) )
	sceneView:insert(question)
	question:toFront( )

	yogotarButton = display.newImage(assetPath.."yogotar.png")
	yogotarButton.x = display.contentCenterX
	yogotarButton.y = display.contentCenterY - 50
	yogotarButton.xScale = 0.7
	yogotarButton.yScale = 0.7
	yogotarButton:addEventListener( "tap", yogotarTap )
	sceneView:insert(yogotarButton)

	questionMark = display.newImage(assetPath.."questionMark.png")
	questionMark.x = display.contentCenterX
	questionMark.y = display.contentCenterY - 140
	questionMark.xScale = 0.1
	questionMark.yScale = 0.1
	questionMark.alpha = 0
	sceneView:insert(questionMark)
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			scale = 0.7,
			parentScene = game.view,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = display.contentCenterX, y = display.contentCenterY - 70},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(event)
	local params = event.params
	isFirstTime = event.params.isFirstTime
	instructions.text = localization.getString("instructionsGeoDoor")
	
	answerList = {}
	questionActive = false
	gameWrong = false

	for indexAnswer = 1, #answerGroupList do
		answerGroup[indexAnswer].answerText.text = ""
	end

	question.text = ""
	questionCounter = 1
	questionActive = false
	shuffleAnswers = {}
	
	local questions = params.questions
	answerList = params.answers
	wrongAnswers = params.wrongAnswers
	
	questionList = {}
	
	for index = 1, #questions do
		questionList[index] = {question = questions[index], answer = answerList[index]}
	end
	
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		wrongDelay = 1000,
		correctDelay = 1000,
		
		name = "Geo door",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 4},
			{id = "wrongAnswer", amount = 4},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight )
	bg:setFillColor( unpack( COLOR_BACKGROUND ) )
	sceneView:insert(bg)
	bg:toBack( )

	createQuestion(sceneView)
	createAnswers(sceneView)
	
	instructions = display.newText("",  display.contentCenterX, display.viewableContentHeight - 95, settings.fontName, 24)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)	
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase
		
	if ( phase == "will" ) then
		--print("will show - levels")
		manager = event.parent
		
		initialize(event)
		--createAnswers(sceneGroup)
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
		tutorials.cancel(gameTutorial2)
	end
end
----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
