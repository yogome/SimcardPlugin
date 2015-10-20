----------------------------------------------- Test minigame
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer, dynamicAnswersGroup
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabledRight
local tapsEnabledLeft
local isFirstTime
local correctBox, wrongBox
local gameTutorial
local ecosystems
local rightClick
local leftClick
local ecosystemsTable = {}
local animalsGroup
local animalsContainer
local answerOptionsGroup = {}
local checkingAnswers
local animals
local tapsEnabled
----------------------------------------------- Constants
local BACKGROUND_COLOR = {116/255, 226/255, 213/255}
local BACKGROUND_LIGHT_COLOR = {187/255, 255/255, 245/255}
local INSTRUCTIONS_COLOR = {216/255, 18/255, 108/255}
local ECOSYSTEM_COLOR = {8/255, 56/255, 99/255}
--local ECOSYSTEM_COLOR = {255/255, 102/255, 149/255}
local SIZE_FONT = 40
----------------------------------------------- Functions
local function onLeftScrollTapped(event)
	local answer = event.target
	if tapsEnabledLeft and leftClick > 0 then
		director.to(scenePath, animalsGroup, {time=1000, x = animalsGroup.x + (animalsContainer.width*0.8),
			onStart= function() 
				answer[1].isVisible = true 
				answer[2].isVisible = false
				tapsEnabledLeft = false
				tapsEnabledRight = false 
			end,
			onComplete=function()
				answer[1].isVisible = false 
				answer[2].isVisible = true 
				tapsEnabledLeft = true
				tapsEnabledRight = true 
				leftClick = leftClick - 1
				rightClick = rightClick + 1
			end 
		})
	end
end

local function onRightScrollTapped(event)
	local answer = event.target
	if tapsEnabledRight and rightClick > 0 then
		director.to(scenePath, animalsGroup, {time=1000, x = animalsGroup.x - (animalsContainer.width*0.8),
			onStart= function() 
				answer[1].isVisible = true 
				answer[2].isVisible = false
				tapsEnabledLeft = false
				tapsEnabledRight = false 
			end,
			onComplete=function()
				answer[1].isVisible = false 
				answer[2].isVisible = true 
				tapsEnabledLeft = true
				tapsEnabledRight = true 
				rightClick = rightClick - 1
				leftClick = leftClick + 1
			end 
		})
		--[[tutorials.cancel(gameTutorial1, 300)
		if secondTutorial then
			tutorial2()
		end
		secondTutorial = false
		tapsEnabled = false
		answer.alpha = 1
		
		director.to(scenePath, answer, {time = 3000, 
			onStart = function() 
				sound.play(answer.char) 
			end,
			onComplete = function(obj) 
				enableSoundButton(obj) 
			end})]]--
	end
end
--[[local function onAnswerTapped(event)
	local answer = event.target
	if tapsEnabled then
		tapsEnabled = false
		if answer.isCorrect then
			if manager then
				manager.correct()
			end
		else
			if manager then
				manager.wrong({correctAnswer = "Green box"})
			end
		end
	end
end
]]--
local function removeDynamicAnswers()
	display.remove(dynamicAnswersGroup)
	dynamicAnswersGroup = nil
end


local function animalTouched(event)
	local phase = event.phase
	local target = event.target
	local parent = target.parent
	--local xTarget, yTarget = target:localToContent( 0, 0 )	
	--animalsGroup.anchorChildren = true
	if tapsEnabled then
		if phase == "began" then
			transition.cancel(target)
			parent:remove(target)
			dynamicAnswersGroup:insert(target)
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
		elseif phase == "moved" then
			if target.isMoving then
				target.x = event.x
				target.y = event.y		
			end
		elseif phase == "ended" then
			local isTimeToCheckAnswer = false
			sound.play("pop")
			for indexAnswer = 1, #ecosystemsTable do
				local currentSlot = ecosystemsTable[indexAnswer]
				if target.x < (currentSlot.x + currentSlot.contentWidth * 0.4) and
					target.x > (currentSlot.x - currentSlot.contentWidth * 0.4) and
					target.y < (currentSlot.y + currentSlot.contentHeight * 0.4) and
					target.y > ( currentSlot.y - currentSlot.contentHeight * 0.4) then
					tutorials.cancel(gameTutorial, 300)
					for indexCheckingAnswer = 1, #animals do
						if animals[indexCheckingAnswer].img == target.char then
							animals[indexCheckingAnswer].answer = currentSlot.char
						end
					end
						--if currentSlot.isEmpty then
							--tutorials.cancel(gameTutorial, 300)
							--xOption = currentSlot.xCS
							--yOption = currentSlot.yCS
							--answer[answerOptionsGroup[indexAnswer].id] = target.char
							--currentSlot.isEmpty = false
							target.onSlot = true
							target.slot = currentSlot
						--end
				end
				if parent.numChildren == #animals * 2 then
					isTimeToCheckAnswer = true
				end
				--isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			end
			
			if target.slot then
				director.to(scenePath, target, {time = 200, x = event.x, y = event.y, xScale = 1, yScale = 1})
			else
				dynamicAnswersGroup:remove(target)
				animalsGroup:insert(target)
				target.x = target.initX
				target.y = target.initY
				--target.x = target.initX
				--target.y = target.initY
				--director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY, xScale = 1, yScale = 1})
			end
			
			if isTimeToCheckAnswer then
				tapsEnabled = false
				local playerWin = true
				for indexCheckingCorrectAnswer = 1, #animals do
					if animals[indexCheckingCorrectAnswer].typeEcosystem ~= animals[indexCheckingCorrectAnswer].answer then
						playerWin = false
					end
				end
				if playerWin then
					manager.correct()
				else
					local offsetXEcosystemName = -150
					local offsetYEcosystemName = -75
					local offsetCorrectAnimalX
					local offsetCorrectAnimalY
					local correctAnswersGroup = display.newGroup()
					correctAnswersGroup.alpha = 0
					for indexCorrectEcosystem = 1, #ecosystems do
						local correctEcosystemsText = display.newText( ecosystems[indexCorrectEcosystem].name, offsetXEcosystemName, offsetYEcosystemName, settings.fontName, SIZE_FONT * 0.5 )
						correctAnswersGroup:insert(correctEcosystemsText)
						if indexCorrectEcosystem % 2 == 0 then
							offsetXEcosystemName = -150
							offsetYEcosystemName = offsetYEcosystemName + 125
						else
							offsetXEcosystemName = offsetXEcosystemName + 300
						end
						offsetCorrectAnimalX = correctEcosystemsText.x - 50
						offsetCorrectAnimalY = correctEcosystemsText.y + 50
						for indexCorrectAnimals = 1, #animals do
							if ecosystems[indexCorrectEcosystem].img == animals[indexCorrectAnimals].typeEcosystem then
								local correctAnimal = display.newImage( assetPath .. animals[indexCorrectAnimals].img .. ".png" )
								correctAnswersGroup: insert(correctAnimal)
								correctAnimal:scale(0.5, 0.5)
								correctAnimal.x = offsetCorrectAnimalX
								correctAnimal.y = offsetCorrectAnimalY
								offsetCorrectAnimalX = offsetCorrectAnimalX + (correctAnimal.width*0.5)
							end
						end
					end
					director.to(scenePath, correctAnswersGroup, {time=1000, alpha=1}) 
					manager.wrong({id = "group", group = correctAnswersGroup, fontSize = 40})
				end
				--[[if answer[1] == hours and answer[2] == minutes then
					if manager then
						manager.correct()
					end
				else
					if manager then
						manager.wrong({correctAnswer = hours .. ":" .. minutes})
					end
				end]]--
			end
			
			display.getCurrentStage():setFocus( nil )
		end
	end
end

local function createDynamicAnswers()
	dynamicAnswersGroup = display.newGroup( )
	answersLayer:insert(dynamicAnswersGroup)
	local ecosystemImg
	local ecosystemImgScale

	for indexEcosystems = 1, #ecosystems do
		ecosystemImg = display.newImage( assetPath .. ecosystems[indexEcosystems].img .. ".png" )
		ecosystemImgScale = (display.viewableContentHeight*0.3)/ecosystemImg.height
		ecosystemImg:scale(ecosystemImgScale, ecosystemImgScale)
		ecosystemImg.char = ecosystems[indexEcosystems].img
		ecosystemsTable[indexEcosystems] = ecosystemImg

		dynamicAnswersGroup:insert(ecosystemImg)
	end

	local widthContainer = ecosystemImg.width*ecosystemImgScale*(#ecosystems*0.5)
	local heightContainer = (ecosystemImg.height*ecosystemImgScale*2) + 40
	local lightBackground = display.newRoundedRect( display.contentCenterX, display.viewableContentHeight* 0.6, widthContainer, heightContainer, 20 )
	lightBackground:setFillColor( unpack(BACKGROUND_LIGHT_COLOR) )
	backgroundLayer:insert(lightBackground)
	
	local offsetX = (lightBackground.x - widthContainer * 0.25)
	local offsetY = (lightBackground.y - heightContainer * 0.25) + 10
	for indexEcosystemsPositions = 1, #ecosystems do
		ecosystemsTable[indexEcosystemsPositions].x = offsetX
		ecosystemsTable[indexEcosystemsPositions].y = offsetY
		local ecosystemText = display.newText(ecosystems[indexEcosystemsPositions].name, offsetX, offsetY-(ecosystemImg.height*0.25), settings.fontName, SIZE_FONT*0.75)
		ecosystemText:setFillColor( unpack(ECOSYSTEM_COLOR) )
		dynamicAnswersGroup:insert(ecosystemText)
		if indexEcosystemsPositions%2 == 0 then
			offsetX = lightBackground.x - widthContainer * 0.25 
			offsetY = offsetY + (ecosystemImg.height * ecosystemImgScale)
		else
			offsetX = offsetX + (ecosystemImg.width * ecosystemImgScale)
		end
	end

	local scrollAnimals = display.newImage(assetPath .. "ecosistemas-06.png")
	scrollAnimals.x = display.contentCenterX
	scrollAnimals.y = display.viewableContentHeight*0.125

	local leftScroll = display.newGroup()
	local leftScrollEnable = display.newImage( assetPath .. "2.png" )
	leftScroll:insert(leftScrollEnable)
	leftScrollEnable.isVisible = false
	local leftScrollDisable = display.newImage( assetPath .. "1.png")
	leftScroll:insert(leftScrollDisable)
	leftScroll.x = scrollAnimals.x - (scrollAnimals.width*0.35)
	leftScroll.y = scrollAnimals.y
	leftClick = 0
	tapsEnabledLeft = false
	leftScroll:addEventListener("tap", onLeftScrollTapped)


	local rightScroll = display.newGroup()
	local rightScrollEnable = display.newImage( assetPath .. "4.png" )
	rightScroll:insert(rightScrollEnable)
	rightScrollEnable.isVisible = false
	local rightScrollDisable = display.newImage( assetPath .. "3.png")
	rightScroll:insert(rightScrollDisable)
	rightScroll.x = scrollAnimals.x + (scrollAnimals.width*0.35)
	rightScroll.y = scrollAnimals.y
	tapsEnabledRight = true
	rightClick = 3
	rightScroll:addEventListener("tap", onRightScrollTapped)

	animalsContainer = display.newContainer( scrollAnimals.width*0.6, scrollAnimals.height )
	animalsContainer.x = display.contentCenterX
	animalsContainer.y = display.viewableContentHeight*0.125
	dynamicAnswersGroup:insert(animalsContainer)
	dynamicAnswersGroup:insert(scrollAnimals)
	dynamicAnswersGroup:insert(leftScroll)
	dynamicAnswersGroup:insert(rightScroll)

	animalsGroup = display.newGroup()
	animalsContainer:insert(animalsGroup, true)

	local offsetAnimalX = -(animalsContainer.width*0.35)
	for indexAnimals = 1, #animals do
		local animalImg = display.newImage(assetPath .. animals[indexAnimals].img .. ".png")
		animalImg.x = offsetAnimalX 
		animalImg.onSlot = false
		animalImg.initX = offsetAnimalX
		animalImg.initY = 0
		animalImg.char = animals[indexAnimals].img
		offsetAnimalX = offsetAnimalX + animalImg.width
		animalsGroup:insert(animalImg)
		animalImg:addEventListener( "touch", animalTouched )
	end
--[[
	removeDynamicAnswers()

	wrongAnswersGroup = display.newGroup()
	answersLayer:insert(wrongAnswersGroup)


	local totalWidth = (WRONG_ANSWERS - 1) * PADDING_WRONG_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5

	for index = 1, WRONG_ANSWERS do
		local wrongBox = display.newRect(startX + (index - 1) * PADDING_WRONG_ANSWERS, display.contentCenterY + OFFSET_Y_WRONG_ANSWERS, SIZE_BOXES, SIZE_BOXES)
		wrongBox.isCorrect = false
		wrongBox:addEventListener("tap", onAnswerTapped)
		wrongAnswersGroup:insert(wrongBox)
		wrongBox:setFillColor(unpack(COLOR_WRONG))
	end

	director.to(scenePath, wrongAnswersGroup, {time = 20000, alpha = 0.2})]]--
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	tapsEnabled = true

	isFirstTime = params.isFirstTime
	manager = event.parent

	ecosystems = { {img = "artico", name=localization.getString("instructionsEcosistemasArtico")}, {img = "bosque", name=localization.getString("instructionsEcosistemasBosque")}, {img="mar", name=localization.getString("instructionsEcosistemasMar")}, {img = "selvatropical", name=localization.getString("instructionsEcosistemasSelvaTropical")}}
	ecosystems = extratable.shuffle(ecosystems)

	animals = {
		{img = "selva1", typeEcosystem = "selvatropical", answer=""},
		{img = "selva2", typeEcosystem = "selvatropical", answer=""},
		{img = "selva3", typeEcosystem = "selvatropical", answer=""},
		{img = "artico1", typeEcosystem = "artico", answer=""},
		{img = "artico2", typeEcosystem = "artico", answer=""},
		{img = "artico3", typeEcosystem = "artico", answer=""},
		{img = "bosque1", typeEcosystem = "bosque", answer=""},
		{img = "bosque2", typeEcosystem = "bosque", answer=""},
		{img = "bosque3", typeEcosystem = "bosque", answer=""},
		{img = "mar1", typeEcosystem = "mar", answer=""},
		{img = "mar2", typeEcosystem = "mar", answer=""},
		{img = "mar3", typeEcosystem = "mar", answer=""},
	}
	animals = extratable.shuffle(animals)

	instructions.text = localization.getString("instructionsEcosistemas")
end

local function tutorial()
	if isFirstTime then
		local correctX
		local correctY
		for correctAnswerIndex = 1, #ecosystemsTable do
			if ecosystemsTable[correctAnswerIndex].char == animals[1].typeEcosystem then
				correctX = ecosystemsTable[correctAnswerIndex].x
				correctY = ecosystemsTable[correctAnswerIndex].y
			end
		end
		local tutorialOptions = {
			iterations = 5,
			scale = 0.5, 
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 800, time = 2500, x = display.contentCenterX - 150, y = display.viewableContentHeight*0.1, toX = correctX, toY = correctY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Ecosystems",
		category = "science",
		subcategories = {"ecosystems"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {

		},
	}
end

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	backgroundLayer:insert(background)

	--[[local lightBackground = display.newRoundedRect( display.contentCenterX, display.contentCenterY, 1024, 584, 20 )
	lightBackground:setFillColor( unpack(BACKGROUND_LIGHT_COLOR) )
	backgroundLayer:insert(lightBackground)]]--

	--[[correctBox = destroisplay.newRect(display.contentCenterX + -OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	correctBox.isCorrect = true
	correctBox:setFillColor(unpack(COLOR_CORRECT))
	correctBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(correctBox)

	wrongBox = display.newRect(display.contentCenterX + OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	wrongBox.isCorrect = false
	wrongBox:setFillColor(unpack(COLOR_WRONG))
	wrongBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(wrongBox)]]--


	local instructionsOptions = 
	{
		text = "",
		x = display.contentCenterX,
		y = display.viewableContentHeight*0.24,
		font = settings.fontName,
		fontSize = SIZE_FONT* 0.6,
		align = "center"
	}
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor( unpack( INSTRUCTIONS_COLOR ) )
	textLayer:insert(instructions)

end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createDynamicAnswers()
		tutorial()
	elseif phase == "did" then
		--enableButtons()
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
