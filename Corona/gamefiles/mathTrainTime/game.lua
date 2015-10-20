----------------------------------------------- TrainTime
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local extratable = require("libs.helpers.extratable")
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer
local backgroundLayer
local textLayer, instructions
local manager
local isFirstTime
local gameTutorial
local allOptions = {}
local answerOptionsGroup = {}
local xOption, yOption
local minutes
local hours
local wrongAnswer = {}
local answerSplit = {}
local correctAnswerTable
local randomAnswers = {}
local answer = {}
local dynamicAnswers
local inTransition
local outTransition
local previousTarget
local hourTransition
local minuteTransition
local trainTransition
local minuteHandRotation
local hourHandRotation
local trainGroup
local minuteHand
local hourHand
local tapsEnabled
----------------------------------------------- Constants
local WRONG_ANSWERS = 1
local SIZE_FONT = 40
local TOTAL_ANSWERS = 3
local FONT_NAME = settings.fontName
local OPTIONS_QUESTION = 2
local OPTIONS_COLOR = {209/255, 101/255, 35/255}
local INSTRUCTIONS_COLOR = {109/255, 18/255, 18/255}
----------------------------------------------- Functions
local function tutorial()
	if isFirstTime then
		local answerPosition
		for indexCorrectAnswer = 1, TOTAL_ANSWERS do
			if randomAnswers[indexCorrectAnswer] == hours then
				answerPosition = indexCorrectAnswer
			end
		end
		local firstSlot = answerOptionsGroup[1]
		local xFirstSlot, yFirstSlot = firstSlot:localToContent( 0, 0 )
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2000, x = allOptions[answerPosition].x, y = allOptions[answerPosition].y, toX = xFirstSlot, toY = yFirstSlot},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function generateRandomAnswers()
	correctAnswerTable = extratable.deepcopy(answerSplit)
	correctAnswerTable = extratable.shuffle(correctAnswerTable)
	randomAnswers = correctAnswerTable
end

local function answerGroupTouched(event)
	local phase = event.phase
	local target = event.target
	if tapsEnabled then
		if phase == "began" then
			sound.stopAll(100)
			tutorials.cancel(gameTutorial,300)
			transition.cancel( hourTransition )
			hourHand.rotation = hourHandRotation
			transition.cancel(minuteTransition)
			minuteHand.rotation = minuteHandRotation
			transition.cancel(trainTransition)
			trainGroup.x = display.contentCenterX
			if inTransition ~= nil and previousTarget.onSlot then
				transition.cancel( inTransition )
				previousTarget.x = xOption
				previousTarget.y = yOption
			end
			if outTransition ~= nil and previousTarget.onSlot == false then
				transition.cancel( outTransition )
				previousTarget.x = previousTarget.initX
				previousTarget.y = previousTarget.initY
			end
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
			local isTimeToCheckAnswer = true
			sound.play("pop")
			for indexAnswer = 1, #answerOptionsGroup do
				
				local currentSlot = answerOptionsGroup[indexAnswer]
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
							answer[answerOptionsGroup[indexAnswer].id] = target.char
							currentSlot.isEmpty = false
							target.onSlot = true
							target.slot = currentSlot
						end
				end
				isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			end
			
			if target.slot then
				inTransition = director.to(scenePath, target, {time = 200, x = xOption, y = yOption,})
				previousTarget = target

			else
				outTransition = director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY, xScale = 1, yScale = 1})
				previousTarget = target
			end
			
			if isTimeToCheckAnswer then
				tapsEnabled = false
				if answer[1] == hours and answer[2] == minutes then
					if manager then
						manager.correct()
					end
				else
					if manager then
						manager.wrong({id = "text", text = hours .. ":" .. minutes , fontSize = 54})
					end
				end
			end
			
			display.getCurrentStage():setFocus( nil )
		end
	end
end

local function removeDynamicAnswers()
	transition.cancel(hourTransition)
	transition.cancel(minuteTransition)
	transition.cancel(trainTransition)
	display.remove(dynamicAnswers)
	dynamicAnswers = nil
	for IndexRemoveAnswerSplit=1, #answerSplit do
		answerSplit[IndexRemoveAnswerSplit] = nil
	end
	for indexRemoveAnswerOptionsGroup=1, #answerOptionsGroup do
		answerOptionsGroup[indexRemoveAnswerOptionsGroup] = nil
	end
end

local function createDynamicAnswers()
	removeDynamicAnswers()
	dynamicAnswers = display.newGroup()
	trainGroup = display.newGroup( )
	local trainImage = display.newImage(assetPath .. "reloj.png")
	trainGroup:insert(trainImage)
	local paddingOptions = 7
	for indexOptions = 1, OPTIONS_QUESTION do
		local trainOptions = display.newImage( assetPath .. "cuadrito.png")
		trainOptions:scale(0.75, 0.75)
		trainOptions.x = (trainOptions.width*(indexOptions-1))+ paddingOptions
		trainOptions.y = trainImage.height*0.1
		trainGroup:insert(trainOptions)
		answerOptionsGroup[#answerOptionsGroup+1] = trainOptions
		answerOptionsGroup[#answerOptionsGroup].id = indexOptions
		trainOptions.isEmpty = true
	end
	hourHand = display.newImage(assetPath .. "horas.png")
	hourHand:scale(0.5, 0.5)
	minuteHand = display.newImage(assetPath .. "minutero.png")
	minuteHand:scale(0.5, 0.5)
	hourHand.x = trainImage.width * -0.3
	hourHand.y = trainImage.height * 0.05
	hourHand.anchorY = 0.75
	hourHandRotation = 30 * tonumber( hours )
	minuteHand.x = trainImage.width * -0.3
	minuteHand.y = trainImage.height * 0.05
	minuteHand.anchorY = 0.8
	minuteHandRotation = (30 * (tonumber(minutes)/5)) + ((tonumber(hours)-1)*360)
	trainGroup:insert(hourHand)
	trainGroup:insert(minuteHand)
	trainGroup.x = display.contentCenterX*3
	trainGroup.y = display.viewableContentHeight*0.4 -- 26
	
	--trainGroup.xScale, trainGroup.yScale = 1.3, 1.3
	
	local initialX = display.viewableContentWidth*1.5
	local initialY = display.viewableContentHeight*0.88
	for indexAnswers = 1, TOTAL_ANSWERS do
		local answerGroup = display.newGroup( )
		local answerImage = display.newImage(assetPath .. "carta.png")
		answerImage:scale(0.7, 0.7)
		local answerText = display.newText( randomAnswers[indexAnswers], 0, 0, FONT_NAME, SIZE_FONT*2.75 )
		answerText:setFillColor(unpack(OPTIONS_COLOR)  )
		answerGroup:insert(answerImage)
		answerGroup:insert(answerText)
		answerGroup.x = initialX
		answerGroup.y = initialY
		answerGroup.onSlot = false
		answerGroup.initX = display.screenOriginX+(display.viewableContentWidth/(TOTAL_ANSWERS +1))*indexAnswers
		answerGroup.initY = initialY
		answerGroup.char = randomAnswers[indexAnswers]
		director.to(scenePath, answerGroup, {time = 500, delay = 250*indexAnswers, x = display.screenOriginX+(display.viewableContentWidth/(TOTAL_ANSWERS +1))*indexAnswers })
		allOptions[indexAnswers] = answerGroup
		dynamicAnswers:insert(answerGroup)
		answerGroup:addEventListener( "touch", answerGroupTouched )
	end

	trainTransition = director.to(scenePath, trainGroup, {time = 1000, x = display.contentCenterX, delay = 500, onComplete = tutorial, onStart = function() sound.play("minigamesTrain") end})
	minuteTransition = director.to(scenePath, minuteHand, {time = 3000, rotation = minuteHandRotation, delay = 500})
	hourTransition = director.to(scenePath, hourHand, {time = 3000, rotation = hourHandRotation, delay = 500, onComplete = function() sound.stopAll(100) end})
	
	dynamicAnswers:insert(trainGroup)	
	answersLayer:insert(dynamicAnswers)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	hours = math.random(1, 12)
	minutes = math.random(1,12) * 5
	answerSplit[1] = hours
	tapsEnabled = true
	if minutes > 55 then
		minutes = "00"
		answerSplit[2] = minutes
	else
		if minutes < 10 then
			minutes = "0" .. tostring(minutes)
			answerSplit[2] = minutes
		else
			minutes = tostring(minutes)
			answerSplit[2] = minutes
		end
	end

	for indexWrongAnswer = 1, WRONG_ANSWERS do
		wrongAnswer[indexWrongAnswer] = math.random(1, 12)
		answerSplit[#answerSplit+1] = wrongAnswer[indexWrongAnswer]
	end

	instructions.text = localization.getString("instructionsTrainTime")
end
---------------------------------------------
function game.getInfo()
	return {
		-- TODO mark as available once complete!!!
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "train Time",
		category = "math",
		subcategories = {"clock"},
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

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	local background = display.newImage(assetPath .. "fondo.png")
	background.anchorY = 0.65
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight*0.65
	background:scale(backgroundScale, backgroundScale)
	backgroundLayer:insert(background)

	for indexCloud = 1 , 5 do
		local randomCloud = math.random(1,2)
		local randomCloudScale = math.random(60, 70)
		local randomPositionY = math.random(display.viewableContentHeight*0.05, display.viewableContentHeight*0.25)
		local cloud = display.newImage(assetPath .. "nube" .. randomCloud .. ".png")
		cloud:scale(randomCloudScale/100, randomCloudScale/100)
		cloud.x = display.screenOriginX+(display.viewableContentWidth/(6))*indexCloud
		cloud.y = randomPositionY
		backgroundLayer:insert(cloud)
	end
	
	local instructionsTip = display.newImage(assetPath .. "instruccion.png")
	instructionsTip.x = display.contentWidth * 0.65 ; instructionsTip.y = display.screenOriginY+50
	instructionsTip.xScale = 1.3
	textLayer:insert(instructionsTip)

	instructions = display.newText("", instructionsTip.x, instructionsTip.y, settings.fontName, SIZE_FONT)
	instructions:setFillColor( unpack(INSTRUCTIONS_COLOR) )
	textLayer:insert(instructions)
end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		generateRandomAnswers()
		createDynamicAnswers()
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
		sound.stopAll(100)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
