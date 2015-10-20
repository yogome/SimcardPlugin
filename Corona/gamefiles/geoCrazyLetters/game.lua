----------------------------------------------- Crazy Letters
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer
local answersLayer
local textLayer
local gameTutorial
local isFirstTime
local manager
local question
local correctAnswer
local questionText
local answerBg
local answerBoardGroup
local answerCharList
local answerBoardList
local xOption, yOption
local finalAnswer
local spiderGroup
local instructionText
local spiderList
local canTap

----------------------------------------------- Constants
local SCREEN_WIDTH = display.viewableContentWidth
local SCREEN_HEIGHT = display.viewableContentHeight
local COLOR_QUESTION = {1,1,1}
local PADDING_ANSWERS = 64
local COLOR_LETTERS = {86/255,178/255,169/255}
----------------------------------------------- Functions

local function checkAnswer()
	local finalString = ""
	
	for index=1, #finalAnswer do
		finalString = finalString..finalAnswer[index]
	end
	
	if string.upper(correctAnswer) == finalString then
		manager.correct()
	else
		manager.wrong({id = "text", text = correctAnswer, fontSize = 50})
	end
end

local function spiderDrag(event)
	local phase = event.phase
	local target = event.target
	if phase == "began" and canTap then
		sound.stopAll(100)
		transition.cancel(target)
		target:toFront( )
		target.x = event.x
		target.y = event.y
		sound.play("dragtrash")
		target.onSlot = false
		if target.slot then
			target.slot.isEmpty = true
			target.slot = nil
		end
		display.getCurrentStage():setFocus( event.target )
		target.isMoving = true
	elseif phase == "moved" and canTap then
		if target.isMoving then
			target.x = event.x
			target.y = event.y		
		end
	elseif phase == "ended" and canTap then
		local isTimeToCheckAnswer = true
		sound.play("pop")
		for indexAnswer = 1, #answerBoardList do
			
			local currentSlot = answerBoardList[indexAnswer]
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
						finalAnswer[currentSlot.id] = target.letter.text
						currentSlot.isEmpty = false
						target.onSlot = true
						target.slot = currentSlot
					end
			end
			isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
		end
		
		if target.slot then
			director.to(scenePath, target, {time = 200, x = xOption, y = yOption})

		else
			director.to(scenePath, target, {time = 500, x = event.x, y = event.y})
		end
		
		if isTimeToCheckAnswer then
			canTap = false
			checkAnswer()
		end
		
		display.getCurrentStage():setFocus( nil )
	end
	return true
end

local function spiderTapped(event)
	sound.play("pop")
	
	tutorials.cancel(gameTutorial, 300)
	transition.cancel(event.target.transition)
	
	local spider = event.target 
	spider.body:setSequence("tapped")
	spider.body:pause()
	spider.eyes:pause()
	spider.eyes.isVisible = false
	spider.letter.isVisible = true
	spider.body.xScale = 0.43
	spider.body.yScale = 0.43
	
	spider:removeEventListener("tap", spiderTapped)
	spider:addEventListener("touch", spiderDrag)
end

local function generateLetters()
	
	local spiderOptions = {
		width = 256,
		height = 152,
		numFrames = 3,
	}

	local spiderSheet = graphics.newImageSheet( assetPath.."spiderSprite.png", spiderOptions )

	local sequenceSpider = {
		{ name="moving", frames={ 1, 2 }, time=200, loopCount=0 },
		{ name="tapped", frames={ 3 }, time=200, loopCount=0 }
	}

	local eyesOptions = {
		width = 64,
		height = 27,
		numFrames = 2,
	}

	local eyesSheet = graphics.newImageSheet( assetPath.."eyeSprite.png", eyesOptions )

	local sequenceEyes = {
		{ name="moving", frames={ 1, 2 }, time=1000, loopCount=0 },
	}
	
	spiderGroup = display.newGroup()
	answersLayer:insert(spiderGroup)
	
	for indexSprites = 1, string.len(correctAnswer) do
		local spider = display.newGroup()
		spiderGroup:insert(spider)

		spider.body = display.newSprite( spiderSheet, sequenceSpider )
		spider.x = math.random(SCREEN_WIDTH*0.15, SCREEN_WIDTH*0.85)
		spider.y = math.random(SCREEN_HEIGHT*0.25, SCREEN_HEIGHT*0.75)
		spider.body.xScale = 0.4
		spider.body.yScale = 0.4
		spider:insert(spider.body)

		spider.eyes = display.newSprite(eyesSheet, sequenceEyes)
		spider.eyes.x = spider.body.x
		spider.eyes.y = spider.body.y - 15
		spider.eyes.xScale = 0.4
		spider.eyes.yScale = 0.4
		spider:insert(spider.eyes)
		
		spider.letter = display.newText(answerCharList[indexSprites], spider.body.x, spider.body.y, settings.fontName, 30)
		spider.letter:setFillColor(unpack(COLOR_LETTERS))
		spider.letter.isVisible = false
		spider:insert(spider.letter)
		
		spider.onSlot = false
		spiderList[#spiderList+1] = spider
		
		spider:addEventListener("tap", spiderTapped)
		
		director.performWithDelay(scenePath, 50*indexSprites, function()
			spider.body:play()
			spider.eyes:play()
		end)
		
		local yMin = SCREEN_HEIGHT*0.25
		local yMax = SCREEN_HEIGHT*0.75
		local xMin = SCREEN_WIDTH*0.1
		local xMax = SCREEN_WIDTH*0.9
		
		local function spiderMove(answerGroup)
			local toY
			local toX
			repeat 
				toY = math.random(yMin, yMax)
				toX = math.random(xMin, xMax)
			until math.abs(answerGroup.y - toY) > (yMin-yMax)*0.25 and math.abs(answerGroup.x - toX) > (xMin-xMax)*0.3

			local duracion = math.abs(answerGroup.y - toY) / 0.02
			spider.transition = director.to(scenePath, answerGroup, { delay = 0, time = duracion, x = toX, y = toY, onComplete = function()
				spiderMove(answerGroup)
			end})			
		end
		
		director.performWithDelay(scenePath, 2500, spiderMove(spider))
	end
end

local function setAnswerBoard()
	answerCharList = {}
	answerBoardList = {}
	answerBoardGroup = display.newGroup()
	answersLayer:insert(answerBoardGroup)
	
	for charIndex = 1, string.len(correctAnswer) do
		answerCharList[charIndex] = string.upper(correctAnswer:sub(charIndex, charIndex))
	end
	
	local totalWidth = (string.len(correctAnswer) - 1) * PADDING_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5
	
	for index = 1, string.len(correctAnswer) do
		local answerCircle = display.newImage(assetPath.."answer.png")
		answerCircle.x = startX + (index - 1) * PADDING_ANSWERS
		answerCircle.y = answerBg.y
		answerCircle.xScale = 0.5
		answerCircle.yScale = 0.5
		answerCircle.isEmpty = true
		answerCircle.id = index
		answerBoardList[#answerBoardList +1] = answerCircle
		answerBoardGroup:insert(answerCircle)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	isFirstTime = params.isFirstTime
	manager = event.parent
	
	question = params.question
	correctAnswer = params.answer
	canTap = true
	
	instructionText.text = localization.getString("instructionsCrazyLetters")
	questionText.text = question
	finalAnswer = {}
	spiderList = {}
	
	setAnswerBoard()
	generateLetters()
	
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.6,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 1500, getObject = function() return spiderList[1] end},
				[2] = {id = "drag", delay = 800, time = 2500, getObject = function() return spiderList[1] end, toX = answerBoardList[1].x, toY = answerBoardList[1].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 300,
		wrongDelay = 300,
		
		name = "Crazy Letters",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
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
	background.width = SCREEN_WIDTH
	background.height = SCREEN_HEIGHT
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	backgroundLayer:insert(background)
	
	local questionBg = display.newImage(assetPath.."question.png")
	questionBg.x = display.contentCenterX
	questionBg.y = SCREEN_HEIGHT * 0.08	
	questionBg.width = SCREEN_WIDTH * 0.8
	backgroundLayer:insert(questionBg)
	
	local questionOptions = {
		text = "",	 
		x = questionBg.x,
		y = questionBg.y,
		width = questionBg.width * 0.7,
		font = settings.fontName,  
		fontSize = 32,
		align = "center"
	}
		
	questionText = display.newText(questionOptions)
	questionText:setFillColor( unpack(COLOR_QUESTION) ) 
	textLayer:insert(questionText)
	
	local instructionsOptions = {
		text = "",	 
		x = questionBg.x,
		y = questionBg.y + questionBg.height*0.7,
		width = questionBg.width * 0.7,
		font = settings.fontName,  
		fontSize = 24,
		align = "center"
	}
		
	instructionText = display.newText(instructionsOptions)
	instructionText:setFillColor( unpack(COLOR_QUESTION) ) 
	textLayer:insert(instructionText)
	
	answerBg = display.newImage(assetPath.."answerBoard.png")
	answerBg.x = SCREEN_WIDTH * 0.52
	answerBg.y = SCREEN_HEIGHT * 0.9
	answerBg.width = SCREEN_WIDTH * 0.7
	backgroundLayer:insert(answerBg)

end

function game:destroy()
	
end
function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		tutorial()
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
	
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		display.remove(answerBoardGroup)
		display.remove(spiderGroup)
	end
end
----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
