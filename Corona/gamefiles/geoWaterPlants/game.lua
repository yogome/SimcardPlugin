----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local extratable = require( "libs.helpers.extratable" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables

local backgroundLayer
local answersLayer
local textLayer
local answerGroup
local answerList
local answers
local answerIcon
local abletoAnswer
local answeredQuestions
local currentQuestion
local flowerPotGroup
local flowerPotList
local flowersGroup
local questionBg
local questionText
local manager
local waterCanList
local waterCan
local isFirstTime
local questions
local questionList
local correctAnswers
local wrongAnswers
local instructions
local gameTutorial
local correctAnswerString


----------------------------------------------- Constants

local BACKGROUND_COLOR = {242/255, 240/255, 165/255}
local COLOR_INSTRUCTIONS = {80/255, 98/255, 183/255}
local COLOR_ANSWERS = {13/255, 51/255, 117/255}

----------------------------------------------- Functions

local function flowerGrow(flowerPot)
	local flowerButton = display.newImage(assetPath.."flower1.png")
	flowerButton.x = flowerPot.x
	flowerButton.y = flowerPot.y -80
	flowerButton.xScale = 0.1
	flowerButton.yScale = 0.1 
	flowerButton.alpha = 0
	flowersGroup:insert(flowerButton) 
	
	local fullFlower = display.newImage(assetPath.."flower2.png")
	fullFlower.x = flowerButton.x
	fullFlower.y = flowerButton.y -50
	fullFlower.xScale = 0.25
	fullFlower.yScale = 0.25
	fullFlower.alpha = 0
	flowersGroup:insert(fullFlower)
	
	sound.play("minigamesAscendence")
	director.to(scenePath, flowerButton, {tag = "bloomAnimation", delay = 300, time = 600, alpha = 1, y = flowerButton.y - 30, xScale = 0.25, yScale = 0.25, onComplete = function() 
		director.to(scenePath, fullFlower, {tag = "flowerAnimation", delay = 300, time = 600, xScale = 0.5, yScale = 0.5, alpha = 1})
	end})
	
end

local function finishGameHide()
	director.to(scenePath, flowersGroup, {time = 300, alpha = 0,})
	director.to(scenePath, waterCan, {time = 300, alpha = 0,})
end

local function waterCanAnimation()
	if waterCan.status == 0 then
		manager.wrong({id = "text", text = correctAnswerString, fontSize = 42})
		director.to(scenePath, waterCanList[1], {tag = "canAnimation0", delay = 1000, time = 600, y = waterCanList[1].y - 100, onComplete = function() 
			director.to(scenePath, waterCanList[1], {delay = 100, time = 600, rotation = 180, onComplete = function() 
				director.to(scenePath, waterCanList[1], {delay = 0, time = 150, y = waterCanList[1].y + 30, onComplete = function() 
					director.to(scenePath, waterCanList[1], {delay = 0, time = 150, y= waterCanList[1].y -30, onComplete = function() 
						director.to(scenePath, waterCanList[1], {delay = 0, time = 150, y = waterCanList[1].y + 30, onComplete = function() 
							director.to(scenePath, waterCanList[1], {delay = 0, time = 150, y= waterCanList[1].y -30,})
							finishGameHide()
						end})
					end})
				end})
			end})
		end })
	elseif waterCan.status == 1 then
		manager.wrong({id = "text", text = correctAnswerString, fontSize = 42},{delay = 6800}) --ADD DELAY
		director.to(scenePath, waterCanList[2], {tag = "canAnimation1", delay = 2000, time = 800, x = flowerPotList[1].x-130, y = waterCanList[2].y - 230, onComplete = function() 
			director.to(scenePath, waterCanList[2], {delay = 500, time = 600, rotation = 45, onComplete = function() 
				waterCanList[1].isVisible = true
				waterCanList[1].x = waterCanList[2].x
				waterCanList[1].y = waterCanList[2].y
				waterCanList[1].rotation = 45
				local waterDropPlant = display.newImage(assetPath.."water.png")
				waterDropPlant.x = flowerPotList[1].x 
				waterDropPlant.y = flowerPotList[1].y -150
				waterDropPlant.xScale = 0.1
				waterDropPlant.yScale = 0.1
				sound.play("waterBigImpact")
				director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[1].y-10, onComplete = function() 
					waterCanList[2].isVisible = false
					waterDropPlant:removeSelf( )
					flowerGrow(flowerPotList[1])
					director.to(scenePath, waterCanList[1], {delay=500, time=800, rotation = 0, onComplete=function() 
						director.to(scenePath, waterCanList[1], {tag = "timer", delay=0, time=1000,})
						finishGameHide()
					end})
				end})
			end})
		end})
	elseif waterCan.status == 2 then
		manager.wrong({id = "text", text = correctAnswerString, fontSize = 42},{delay = 9500}) --ADD DELAY
		director.to(scenePath, waterCanList[3], {tag = "canAnimation2", delay = 2000, time = 800, x = flowerPotList[1].x-130, y = waterCanList[3].y - 230, onComplete = function() 
			director.to(scenePath, waterCanList[3], {delay = 500, time = 600, rotation = 45, onComplete = function() 
				waterCanList[2].isVisible = true
				waterCanList[2].x = waterCanList[3].x
				waterCanList[2].y = waterCanList[3].y
				waterCanList[2].rotation = 45
				local waterDropPlant = display.newImage(assetPath.."water.png")
				waterDropPlant.x = flowerPotList[1].x 
				waterDropPlant.y = flowerPotList[1].y -150
				waterDropPlant.xScale = 0.1
				waterDropPlant.yScale = 0.1
				sound.play("waterBigImpact")
				director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[1].y-10, onComplete = function() 
					waterCanList[3].isVisible = false
					waterDropPlant:removeSelf( )
					director.to(scenePath, waterCanList[2], {delay=500, time=800, rotation = 0})
					flowerGrow(flowerPotList[1])
					director.to(scenePath, waterCanList[2], {delay=500, time = 800, x = flowerPotList[2].x-130, onComplete = function() 
						director.to(scenePath, waterCanList[2], {delay = 500, time = 600, rotation = 45, onComplete = function() 
							waterCanList[1].isVisible = true
							waterCanList[1].x = waterCanList[2].x
							waterCanList[1].y = waterCanList[2].y
							waterCanList[1].rotation = 45
							local waterDropPlant = display.newImage(assetPath.."water.png")
							waterDropPlant.x = flowerPotList[2].x 
							waterDropPlant.y = flowerPotList[2].y -150
							waterDropPlant.xScale = 0.1
							waterDropPlant.yScale = 0.1
							sound.play("waterBigImpact")
							director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[2].y-10, onComplete = function() 
								waterCanList[2].isVisible = false
								waterDropPlant:removeSelf( )
								director.to(scenePath, waterCanList[1], {delay=500, time=800, rotation = 0, onComplete=function() 
									director.to(scenePath, waterCanList[1], {tag = "timer", delay=0, time=800,})
									finishGameHide()
								end})
								flowerGrow(flowerPotList[2])
							end})
						end})
					end})
				end})
			end})
		end})
	elseif waterCan.status == 3 then
		manager.correct()
		director.to(scenePath, waterCanList[4], {tag = "canAnimation3", delay = 2000, time = 800, x = flowerPotList[1].x-130, y = waterCanList[4].y - 230, onComplete = function() 
			director.to(scenePath, waterCanList[4], {delay = 500, time = 600, rotation = 45, onComplete = function() 
				waterCanList[3].isVisible = true
				waterCanList[3].x = waterCanList[4].x
				waterCanList[3].y = waterCanList[4].y
				waterCanList[3].rotation = 45
				local waterDropPlant = display.newImage(assetPath.."water.png")
				waterDropPlant.x = flowerPotList[1].x 
				waterDropPlant.y = flowerPotList[1].y -150
				waterDropPlant.xScale = 0.1
				waterDropPlant.yScale = 0.1
				sound.play("waterBigImpact")
				director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[1].y-10, onComplete = function() 
					waterCanList[4].isVisible = false
					waterDropPlant:removeSelf( )
					director.to(scenePath, waterCanList[3], {delay=500, time=800, rotation = 0})
					flowerGrow(flowerPotList[1])
					director.to(scenePath, waterCanList[3], {delay=500, time = 800, x = flowerPotList[2].x-130, onComplete = function() 
						director.to(scenePath, waterCanList[3], {delay = 500, time = 600, rotation = 45, onComplete = function() 
							waterCanList[2].isVisible = true
							waterCanList[2].x = waterCanList[3].x
							waterCanList[2].y = waterCanList[3].y
							waterCanList[2].rotation = 45
							local waterDropPlant = display.newImage(assetPath.."water.png")
							waterDropPlant.x = flowerPotList[2].x 
							waterDropPlant.y = flowerPotList[2].y -150
							waterDropPlant.xScale = 0.1
							waterDropPlant.yScale = 0.1
							sound.play("waterBigImpact")
							director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[2].y-10, onComplete = function() 
								waterCanList[3].isVisible = false
								waterDropPlant:removeSelf( )
								director.to(scenePath, waterCanList[2], {delay=500, time=800, rotation = 0})
								flowerGrow(flowerPotList[2])
								director.to(scenePath, waterCanList[2], {delay=500, time = 800, x = flowerPotList[3].x-130, onComplete = function() 
									director.to(scenePath, waterCanList[2], {delay = 500, time = 600, rotation = 45, onComplete = function() 
										waterCanList[1].isVisible = true
										waterCanList[1].x = waterCanList[2].x
										waterCanList[1].y = waterCanList[2].y
										waterCanList[1].rotation = 45
										local waterDropPlant = display.newImage(assetPath.."water.png")
										waterDropPlant.x = flowerPotList[3].x 
										waterDropPlant.y = flowerPotList[3].y -150
										waterDropPlant.xScale = 0.1
										waterDropPlant.yScale = 0.1
										sound.play("waterBigImpact")
										director.to(scenePath, waterDropPlant, {delay = 400, time = 300, y = flowerPotList[3].y-10, onComplete = function() 
											waterCanList[2].isVisible = false
											waterDropPlant:removeSelf( )
											director.to(scenePath, waterCanList[1], {delay=500, time=800, rotation = 0, onComplete=function() 
												director.to(scenePath, waterCanList[1], {tag = "timer", delay=0, time=800,})
												finishGameHide()
											end})
											flowerGrow(flowerPotList[3])
										end})
									end})
								end})
							end})
						end})
					end})
				end})
			end})
		end})
	end
end

local function setQuestionAnswer(currentQuestion)
	questionText.text = questionList[currentQuestion].question
	
	answers = {
		[1] = questionList[currentQuestion].answer,
		[2] = wrongAnswers[currentQuestion],
		[3] = wrongAnswers[currentQuestion],
	}
	
	answers = extratable.shuffle(answers)
	
	for index = 1, 3 do
		answerList[index].text.text = answers[index]
		answerList[index].value = answers[index]
	end
	
	abletoAnswer = true
	
	correctAnswerString = correctAnswerString..questionList[currentQuestion].answer.."\n"
end

local function addWater()
	local xValue = waterCanList[1].x - 25
	local waterList = {}
	sound.play("minigamesBubblesSurface")
	
	local function waterAnimation(waterArray)
		director.to(scenePath, waterArray[1], {delay = 400, time = 500, y = waterArray[1].y+150})
		director.to(scenePath, waterArray[2], {delay = 600, time = 500, y = waterArray[2].y+150})
		director.to(scenePath, waterArray[3], {delay = 800, time = 500, y = waterArray[3].y+150, onComplete = function () 
			waterCan.status = waterCan.status + 1
			if waterCan.status == 1 then
				waterCanList[1].isVisible = false
				waterCanList[2].isVisible = true
				
				if answeredQuestions == 3 then
					waterCanAnimation()
				end

			elseif waterCan.status == 2 then
				waterCanList[1].isVisible = false
				waterCanList[2].isVisible = false 
				waterCanList[3].isVisible = true
				
				if answeredQuestions == 3 then
					waterCanAnimation()
				end

			elseif waterCan.status == 3 then
				waterCanList[1].isVisible = false
				waterCanList[2].isVisible = false 
				waterCanList[3].isVisible = false
				waterCanList[4].isVisible = true
				
				if answeredQuestions == 3 then
					waterCanAnimation()
				end
			end

			for index = 1, 3 do
				waterArray[index]:removeSelf()
				waterArray[index] = nil
			end
		end})
	end
	
	for index = 1, 3 do
		local waterDrop = display.newImage(assetPath.."water.png")
		
		waterDrop.x = xValue - 5
		waterDrop.y = math.random(waterCan[1].y-200, waterCan[1].y-100)
		waterDrop.xScale = 0.1
		waterDrop.yScale = 0.1
		
		xValue = xValue + 25
		waterList[#waterList+1] = waterDrop
	end
	
	waterAnimation(waterList)
end

local function iconCheck(value, target)
	answerIcon = display.newImage(assetPath..value..".png")
	answerIcon.xScale = 0.5
	answerIcon.yScale = 0.5
	answerIcon.x = target.x + 80
	answerIcon.y = target.y + 20
	
	return answerIcon
end

local function checkAnswer(target)
	
	answeredQuestions = answeredQuestions + 1
	
	local function refreshQuestion()
		answerIcon:removeSelf( )
		if currentQuestion < 3 then
			currentQuestion = currentQuestion + 1
			setQuestionAnswer(currentQuestion)
		end	
	end
	
	if target.text.text == questionList[currentQuestion].answer and currentQuestion <= 3 then
		local answerIcon = iconCheck("correct", target)
		addWater()
		director.performWithDelay(scenePath,  1000, refreshQuestion )
		
	else
		local answerIcon = iconCheck("incorrect", target)
		director.performWithDelay(scenePath,  1000, refreshQuestion )
		
		if currentQuestion == 3 then
			waterCanAnimation()
		end
	end
	
end

local function tap( event ) 
	tutorials.cancel(gameTutorial)
	sound.play("pop")
	if currentQuestion <= 3 and abletoAnswer then
		checkAnswer(event.target)
		abletoAnswer = false
	end
	return true
end

local function createWaterCan()
	waterCan = display.newGroup( )
	backgroundLayer:insert(waterCan)
	waterCanList = {}
	
	for index = 1, 4 do
		local waterCanObject
		waterCanObject = display.newImage(assetPath.."waterCan"..(index-1)..".png")
		waterCanObject.x = 200
		waterCanObject.y = display.viewableContentHeight - 70
		waterCanList[index] = waterCanObject
		waterCan:insert(waterCanObject)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	isFirstTime = params.isFirstTime
	manager = event.parent
	--canTap = true

	questions = params.questions
	correctAnswers = params.answers
	wrongAnswers = params.wrongAnswers
	instructions.text = localization.getString("instructionsGeoPlants")
	
	questionList = {}
	for index = 1, #questions do
		questionList[index] = {question = questions[index], answer = correctAnswers[index]}
	end
	
	currentQuestion = 1
	correctAnswerString = ""
	setQuestionAnswer(currentQuestion)
	
	answeredQuestions = 0
	flowersGroup = display.newGroup()
	
	createWaterCan()
	waterCan.status = 0
	waterCanList[1].isVisible = true
	waterCanList[2].isVisible = false
	waterCanList[3].isVisible = false
	waterCanList[4].isVisible = false
	
end

local function tutorial()
	if isFirstTime then
		local correctBox
		for index=1, #answerList do
			if answerList[index].value == questionList[currentQuestion].answer then
				correctBox = answerList[index]
			end
		end
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1400, time = 1450, x = correctBox.x, y = correctBox.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = false,
		correctDelay = 12500,
		wrongDelay = 3500,
		
		name = "",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 3},
			{id = "wrongAnswer", amount = 3},
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
	
	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) ) 
	backgroundLayer:insert(background)
	
	questionBg = display.newImage(assetPath.."questionBg.png")
	questionBg.x = display.contentCenterX
	questionBg.y = questionBg.height / 1.7
	questionBg.xScale = 0.8
	questionBg.yScale = 0.8
	backgroundLayer:insert(questionBg)
	
	local questionOptions = 
	{
		text = "",	 
		x = questionBg.x,
		y = questionBg.y-10,
		width = questionBg.width/1.5,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}
	
	questionText = display.newText(questionOptions)
	textLayer:insert(questionText)
	
	flowerPotGroup = display.newGroup( )
	backgroundLayer:insert(flowerPotGroup)
	flowerPotList = {}
	
	for flowerPotIndex = 1, 3 do
		local flowerPot = display.newImage(assetPath.."flowerPot.png")
		flowerPot.x = (display.viewableContentWidth/5)*flowerPotIndex + display.viewableContentWidth/4
		flowerPot.y = display.viewableContentHeight - 90
		flowerPot.xScale = 0.7
		flowerPot.yScale = 0.7
		
		flowerPotList[#flowerPotList+1] = flowerPot
		flowerPotGroup:insert(flowerPot)
	end
	
	local instructionOptions = 
		{
			text = "",	 
			x = display.contentCenterX,
			y = display.contentCenterY - 190,
			width = display.viewableContentWidth*0.7,
			font = settings.fontName,   
			fontSize = 22,
			align = "center"
		}
		
	instructions = display.newText(instructionOptions)
	instructions:setFillColor(unpack(COLOR_INSTRUCTIONS))
	textLayer:insert(instructions)
	
	answerGroup = display.newGroup( )
	backgroundLayer:insert(answerGroup)
	answerList = {}
	
	for index = 1, 3 do
		local answer = display.newGroup( )
		
		answer.x = (display.viewableContentWidth/4)*index
		answer.y = display.contentCenterY - 100
		
		local answerBg = display.newImage(assetPath.."answerBg.png")
		answerBg.xScale = 0.4
		answerBg.yScale = 0.4
		answer:insert(answerBg)
		
		local answerOptions = 
		{
			text = "",	 
			x = answerBg.x,
			y = answerBg.y,
			width = answerBg.width/2.7,
			font = settings.fontName,   
			fontSize = 22,
			align = "center"
		}
		
		answer.text = display.newText(answerOptions)
		answer.text:setFillColor(unpack(COLOR_ANSWERS))
		answer:insert(answer.text)
		
		answerList[#answerList+1] = answer
		answer:addEventListener("tap", tap)
		answerGroup:insert(answer)
	end

end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if ( phase == "will" ) then
		initialize(event)
		tutorial()
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		display.remove( flowersGroup )
		display.remove( waterCan )
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
