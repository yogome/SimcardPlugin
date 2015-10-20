----------------------------------------------- animales_ruidosos
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
local answersLayer, dynamicAnswers
local backgroundLayer
local textLayer, instructions1, instructions2
local manager
local tapsEnabled
local isFirstTime
local gameTutorial1, gameTutorial2
local objects
local wrongAnswers
local answerGroup = {}
local answerSplit = {}
local answeredQuestion = {}
local groupObjects = {}
local secondTutorial 
local correctAnswersGroup
----------------------------------------------- Constants
local COLOR_INSTRUCTIONS = {22/255, 145/255, 165/255}
local NUMBER_SOUNDS = 3
local DEFAULT_OBJECTS_CORRECT = {"cat", "cricket", "lion", "motorcycle", "dog", "drums" }
local DEFAULT_OBJECTS_WRONG = {"water", "rabbit", "flower"}
local NUMBER_OBJECTS = 5
local SIZE_FONT = 38
----------------------------------------------- Functions
local function tutorial2()
	if isFirstTime then
		local correctAnswer
		for indexCorrectAnswer = 1, NUMBER_OBJECTS do
			if objects[1] == answerSplit[indexCorrectAnswer] then
				correctAnswer = indexCorrectAnswer
			end
		end
		local tutorialOptions = {
			iterations = 5,
			parentScene = game.view,
			scale = 0.5,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = groupObjects[correctAnswer].x, y = groupObjects[correctAnswer].y, toX = answerGroup[1].x, toY = answerGroup[1].y},
			}
		}
		gameTutorial2 = tutorials.start(tutorialOptions)
	end
end

local function enableSoundButton(ans)
	tapsEnabled = true
	ans.alpha = 0.5
end

local function onBirdTapped(event)
	local answer = event.target
	if tapsEnabled and answer.tapsEnabled then
		tutorials.cancel(gameTutorial1, 300)
		if secondTutorial then
			director.to(scenePath, instructions1, {time = 1000, alpha = 0, onComplete = function() director.to(scenePath, instructions2, {time=1000, alpha=1}) end})
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
			end})
	end
end

local function removeDynamicAnswers()
	display.remove(dynamicAnswers)
	dynamicAnswers = nil

	for IndexRemoveAnswerSplit=1, NUMBER_OBJECTS do
		answerSplit[IndexRemoveAnswerSplit] = nil
		answerGroup[IndexRemoveAnswerSplit] = nil
	end
end

local function onObjectTouched(event)
	local phase = event.phase
	local target = event.target
	if tapsEnabled then
		if phase == "began" then
			transition.cancel(target)
			target:toFront( )
			target.x = event.x
			target.y = event.y
			tutorials.cancel(gameTutorial1, 300)
			tutorials.cancel(gameTutorial2, 300)
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
			local isTimeToCheckAnswer = true
			sound.play("pop")
			for indexAnswer = 1, #answerGroup do
				local currentSlot = answerGroup[indexAnswer]
				if target.x < (currentSlot.x + currentSlot.contentWidth * 0.5) and
					target.x > (currentSlot.x - currentSlot.contentWidth * 0.5) and
					target.y < (currentSlot.y + currentSlot.contentHeight * 0.5) and
					target.y > (currentSlot.y - currentSlot.contentHeight * 0.5) then
						if currentSlot.isEmpty then
							answeredQuestion[answerGroup[indexAnswer].id] = target.char
							currentSlot[2].tapsEnabled = false
							currentSlot.isEmpty = false
							target.onSlot = true
							target.slot = currentSlot
							currentSlot.alpha = 0.5
						end
				end
				if currentSlot.isEmpty then
					currentSlot.alpha = 1
					currentSlot[2].tapsEnabled = true
				end
				isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			end
			
			if target.slot then
				director.to(scenePath, target, {time = 200, x = target.slot.x, y = target.slot.y})
			else
				director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY})
			end
			
			if isTimeToCheckAnswer then
				tapsEnabled = false
				local playerWin = true
				for indexCheckingAnswer = 1, NUMBER_SOUNDS do
					if objects[indexCheckingAnswer] ~= answeredQuestion[indexCheckingAnswer] then
						playerWin = false
					end
				end
				if playerWin then
					if manager then
						manager.correct()
					end
				else
					if manager then
						manager.wrong({id = "group", group = correctAnswersGroup})
						director.to(scenePath, correctAnswersGroup, {delay = 1000, time = 1000, alpha = 1})
					end
				end
			end
			display.getCurrentStage():setFocus( nil )
		end
	end
end

local function createDynamicAnswers()
	display.remove(correctAnswersGroup)
	correctAnswersGroup = nil

	dynamicAnswers = display.newGroup()
	answersLayer:insert(dynamicAnswers)

	correctAnswersGroup = display.newGroup( )
	
	local offsetCorrectAnswer = -100
	for indexSounds = 1, NUMBER_SOUNDS do
		local birdGroup = display.newGroup( )
		local birdSound = display.newImage(assetPath .. "caja.png")
		birdGroup:insert(birdSound)
		local birdPlay = display.newImage(assetPath .. "audio" .. ((indexSounds%3)+1) .. ".png")
		birdPlay.y = 10
		birdPlay.alpha = 0.5
		birdGroup:insert(birdPlay)
		birdGroup.x = display.screenOriginX+(display.viewableContentWidth/(NUMBER_SOUNDS +1))*indexSounds
		birdGroup.y = display.viewableContentHeight*0.35
		birdGroup.isEmpty = true
		birdGroup.id = indexSounds
		birdPlay.char = "minigames" .. objects[indexSounds]
		birdPlay.tapsEnabled = true
		birdPlay:addEventListener("tap", onBirdTapped)
		answerGroup[indexSounds] = birdGroup
		dynamicAnswers:insert(birdGroup)
		local correctAnswerImg = display.newImage(assetPath .. objects[indexSounds] .. ".png")
		correctAnswerImg.x = offsetCorrectAnswer
		offsetCorrectAnswer = correctAnswerImg.width + offsetCorrectAnswer
		correctAnswersGroup:insert(correctAnswerImg)
	end

	correctAnswersGroup.alpha = 0

	for indexObjects = 1, NUMBER_OBJECTS do
		local objectImage = display.newImage(assetPath.. answerSplit[indexObjects] .. ".png")
		local positionX = display.screenOriginX+(display.viewableContentWidth/(NUMBER_OBJECTS +1))*indexObjects
		local positionY = math.random(display.viewableContentHeight * 0.8, display.viewableContentHeight*0.9)
		objectImage.x = positionX
		objectImage.y = positionY
		objectImage.initX = positionX
		objectImage.initY = positionY
		objectImage.onSlot = false
		objectImage.char = answerSplit[indexObjects]
		groupObjects[indexObjects] = objectImage
		objectImage:addEventListener("touch", onObjectTouched)
		dynamicAnswers:insert(objectImage)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent

	secondTutorial = true

	objects = params.objects or DEFAULT_OBJECTS_CORRECT
	wrongAnswers = params.wrongObjects or DEFAULT_OBJECTS_WRONG
	objects = extratable.shuffle(objects)
	wrongAnswers = extratable.shuffle(wrongAnswers)
	
	for indexCorrectAnswer = 1, NUMBER_SOUNDS do
		answerSplit[#answerSplit+1] = objects[indexCorrectAnswer]
	end
	for indexWrongAnswer = 1, NUMBER_OBJECTS-NUMBER_SOUNDS do
		answerSplit[#answerSplit+1] = wrongAnswers[indexWrongAnswer]
	end

	answerSplit = extratable.shuffle(answerSplit)
	instructions1.text = localization.getString("instructionsScienceAnimals1")
	instructions2.text = localization.getString("instructionsScienceAnimals2")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial1()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 5,
			scale = 0.5,
			parentScene = game.view,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2000, x = answerGroup[1].x, y = answerGroup[1].y},
			}
		}
		gameTutorial1 = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		wrongDelay = 500,
		correctDelay = 500,
		
		name = "Noisy animals",
		category = "science",
		subcategories = {"sounds"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		musicVolume = 0.15,
		gamemode = "findAnswer",
		requires = {
			{id = "objects", amount = 5, language = "en"},
			{id = "wrongAnswers", amount = 2, language= "en"},
		},
	}
end

function game:create(event)
	local sceneView = self.view


	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	local background = display.newImage(assetPath .. "fondo.png")
	background.anchorY = 0.45
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight*0.45
	background:scale(backgroundScale, backgroundScale)
	backgroundLayer:insert(background)

	local instructionsImg = display.newImage(assetPath .. "contenedorinstruccion.png")
	instructionsImg.x = display.contentCenterX
	instructionsImg.y = display.viewableContentHeight*0.05
	instructionsImg.width = display.viewableContentWidth*0.8
	backgroundLayer:insert(instructionsImg)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	instructions1 = display.newText("", display.contentCenterX, display.viewableContentHeight*0.05, settings.fontName, SIZE_FONT)
	instructions1:setFillColor( unpack( COLOR_INSTRUCTIONS ) )
	textLayer:insert(instructions1)

	instructions2 = display.newText("", display.contentCenterX, display.viewableContentHeight*0.05, settings.fontName, SIZE_FONT)
	instructions2.alpha = 0
	instructions2:setFillColor( unpack( COLOR_INSTRUCTIONS ) )
	textLayer:insert(instructions2)

end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createDynamicAnswers()
		tutorial1()
	elseif phase == "did" then
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		
	elseif phase == "did" then
		disableButtons()
		removeDynamicAnswers()
		tutorials.cancel(gameTutorial1)
		tutorials.cancel(gameTutorial2)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
