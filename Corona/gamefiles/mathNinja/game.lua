--------------------------------------------- MATHNINJA v1.0
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local sound = require("libs.helpers.sound")
local physics = require( "physics" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene()
--------------------------------------------- Variables
local gameEnded, gameStarted, updateTouch
local difficulty
local currentLoop
local itemArray, fruitGroup, correctFruitGroup
local currentThrownItems, spawnItems
local touchEventsArray
local dynamicElementsGroup
local manager
local requiredItemType
local startGameTimer
local correctAnswer
local wrongAnswers
local instructionsText
local elementsGroup
local operand1, operand2, nameImageOperator
local isFirstTime
local gameTutorial
local correctGroup
local operationResult
--------------------------------------------- Constants
local BACKGROUND_COLOR = colors.convertFrom256({ 235, 174, 255 })

local FRUIT_FONT_COLOR = colors.convertFrom256({ 255, 255, 255 })
local OPERAND_FONT_COLOR = colors.convertFrom256({ 29, 0, 84 })
local TUTORIAL_INSTRUCTIONS_FONT_COLOR = colors.convertFrom256({ 64, 20, 131 })

local OPERAND_FONT_SIZE = 72

local SLASH_COLOR = colors.convertFrom256({64, 20, 131})

local OFFSET_TOP_NUMBER = {x = 0, y = 10}
local FONT_NAME = settings.fontName
local SIZE_TEXT = 65

local SLICE_THICKNESS = 20
local SLICE_FADE_TIME = 250
local MAX_POINTS = 5

local SCALE_ENEMY = 0.75

local CENTERX = display.contentWidth / 2
local HALFVIEWX = display.viewableContentWidth / 2
local BOTTOMY = display.screenOriginY + display.viewableContentHeight

local SIMULTANEOUSONDIFFICULTY = {1,2,2,3,4}
--------------------------------------------- Functions
local function generateEquation()
	dynamicElementsGroup = display.newGroup()
	elementsGroup:insert(dynamicElementsGroup)	
	
	local paddingX = display.viewableContentWidth * 0.15
	local offsetX = display.contentCenterX - paddingX * 2
	local posY = display.contentCenterY - 250

	local FirstEquationSpace = display.newImage(assetPath .. "minigames-elements-35.png")
	FirstEquationSpace:scale(.75,.75)
	FirstEquationSpace.x = offsetX 
	FirstEquationSpace.y = posY
	dynamicElementsGroup:insert(FirstEquationSpace)
	local operand1Text = display.newText(operand1, FirstEquationSpace.x, posY, FONT_NAME, OPERAND_FONT_SIZE)
	operand1Text:setFillColor(unpack(OPERAND_FONT_COLOR))
	dynamicElementsGroup:insert(operand1Text)
	
	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + paddingX
	operator.y = posY + 15
	operator:scale(1.25,1.25)
	dynamicElementsGroup:insert(operator)

	local SecondEquationSpace = display.newImage(assetPath .. "minigames-elements-35.png")
	SecondEquationSpace:scale(.75,.75)
	SecondEquationSpace.x = operator.x + paddingX
	SecondEquationSpace.y = posY
	dynamicElementsGroup:insert(SecondEquationSpace)
	local operand2Text = display.newText(operand2, SecondEquationSpace.x, posY, FONT_NAME, OPERAND_FONT_SIZE)
	operand2Text:setFillColor(unpack(OPERAND_FONT_COLOR))
	dynamicElementsGroup:insert(operand2Text)
	
	local equalsSign = display.newImage(assetPath .. "00-igual.png")
	equalsSign.x = SecondEquationSpace.x + paddingX
	equalsSign.y = operator.y
	equalsSign:scale(1.25,1.25)
	dynamicElementsGroup:insert(equalsSign)
	
	local ResultEquationSpace = display.newImage(assetPath .. "minigames-elements-36.png")
	ResultEquationSpace:scale(.75,.75)
	ResultEquationSpace.x = equalsSign.x + paddingX
	ResultEquationSpace.y = posY
	dynamicElementsGroup:insert(ResultEquationSpace)	
	local questionMarkText = display.newText("?", ResultEquationSpace.x - 10, posY+17.5, FONT_NAME, 70)
	questionMarkText.alpha = 0
	dynamicElementsGroup:insert(questionMarkText)
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 800, time = 1200, getObject = function() return correctGroup end, toX = display.contentCenterX, toY = display.contentCenterY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function sceneTouched( event )
	if updateTouch == true then
		
		local touchExists = false
		local touchIndex = 1
		for index = 1, #touchEventsArray do
			if touchEventsArray[index].id == event.id then
				touchExists = true
				touchIndex = index
			end
		end
		
		if touchExists == true then
			local slashPoints = touchEventsArray[touchIndex].slashPoints
			if(slashPoints ~= nil and slashPoints[1] ~= nil) then
				local distance = math.sqrt(math.pow(event.x - slashPoints[1].x, 2) + math.pow(event.y - slashPoints[1].y, 2))
			end
			
			table.insert(slashPoints, 1, {x = event.x, y = event.y, line= nil}) 

			if(#slashPoints > MAX_POINTS) then 
				table.remove(slashPoints)
			end

			for index = 1,#slashPoints do
				local endpoint = slashPoints[index]
				local line = display.newLine(endpoint.x, endpoint.y, event.x, event.y)
				-- Slash Color is set here
				line:setStrokeColor(unpack(SLASH_COLOR))
				line.strokeWidth = SLICE_THICKNESS
				director.to(scenePath, line, {time = SLICE_FADE_TIME, alpha = 0, strokeWidth = 0, onComplete = function()
					line:removeSelf() 
				end})		
			end

			if(event.phase == "ended") then
				while(#slashPoints > 0) do
					table.remove(slashPoints)
				end
				table.remove(touchEventsArray, touchIndex)
			end
		else

			local newIndex = #touchEventsArray + 1
			touchEventsArray[newIndex] = { }
			touchEventsArray[newIndex].id = event.id
			touchEventsArray[newIndex].slashPoints = { }
		end
	end
end

local function gameSuccess()
	local function listener( event )
		updateTouch = false
		if manager then
			manager.correct()
		end
	end

	gameEnded = true
	spawnItems = false
	director.performWithDelay(scenePath, 200, listener )	 
end

local function gameFailure()
	local function listener( event )
		updateTouch = false
		if manager then
			manager.wrong({id = "text", text = operationResult, fontSize = 80})
		end
	end

	gameEnded = true
	spawnItems = false
	director.performWithDelay(scenePath, 200, listener )	
end

local function objectTouched(event)
	local object = event.target
	tutorials.cancel(gameTutorial, 300)
	if gameEnded ~= true then
		if object.pressed ~= true then
			object.pressed = true -- Lock the object
			if object.name == "fruit" then
				sound.play("cut")
				sound.play("hit")
				if object.number == requiredItemType then
					gameSuccess()
				elseif object.type ~= requiredItemType then
					gameFailure()
				end
			end
			director.to(scenePath, object, { alpha = 0, xScale = 0.1, yScale = 0.1, time = 300, transition = easing.outQuad, onComplete = function()
				object.removeFlag = true
				object.remove = true
			end})
		end
	end
end

local function createFruit(side)
	local startingForceX = math.random(4,10)
	local startingForceY = math.random(-23,-18)
	local positionY = BOTTOMY + 60
	local positionX = CENTERX - ((math.random(0,HALFVIEWX)) * side)
	
	local enemy = display.newGroup()
	enemy.x = positionX
	enemy.y = positionY
	enemy.alpha = 0
	director.to(scenePath, enemy, {time = 400, alpha = 1})
	enemy.side = side
	enemy.name = "fruit"

	local enemyNumber = math.random(1,4)
	local enemyData = { width = 256, height = 256, numFrames = 1 }
	local enemySheet = graphics.newImageSheet(assetPath .. "03-fruta"..enemyNumber..".png", enemyData )
	local enemySequenceData = {
		{ name="normal", sheet=enemySheet, start=1, count=1, time=900, loopCount=0 },
	}

	local fruitSprite = display.newSprite( enemySheet, enemySequenceData )
	fruitSprite.xScale = side * SCALE_ENEMY
	fruitSprite.yScale = SCALE_ENEMY
	fruitSprite:setSequence( "normal" )
	fruitSprite:play()
	enemy:insert(fruitSprite)
	table.insert(itemArray, enemy)
	
	physics.addBody( enemy, "dynamic", { friction = 1, radius = 30, density=0, isSensor = true } )
	enemy:applyForce((startingForceX + math.random(0,2)) * side, startingForceY - math.random(0,2), enemy.x, enemy.y);
	enemy:applyTorque(math.random(-5,5)*.1)
		
	local itemNumber
	local indexAnswer = math.random(1,#wrongAnswers + 3)
		
	if indexAnswer > #wrongAnswers then
		itemNumber = correctAnswer
	else
		itemNumber = wrongAnswers[indexAnswer]
	end
	
	local itemText = display.newText(itemNumber, OFFSET_TOP_NUMBER.x, OFFSET_TOP_NUMBER.y, FONT_NAME, SIZE_TEXT)
	itemText:setFillColor(unpack(FRUIT_FONT_COLOR))
	enemy.number = itemNumber
	enemy:insert(itemText)
	
	enemy:addEventListener("touch", objectTouched)
	
	if itemNumber == requiredItemType then
		correctGroup = enemy
		if isFirstTime then
			showTutorial()
			isFirstTime = false
		end
		correctFruitGroup:insert(enemy)
	else
		fruitGroup:insert(enemy)
	end
end

local function onFrameUpdate(event)
	if gameEnded ~= true and gameStarted == true then
		currentLoop = currentLoop + 1
		
		-- Dynamic Object Creation
		if currentLoop % 30 == 0 then
			currentLoop = 0
			for index = 0, SIMULTANEOUSONDIFFICULTY[difficulty] do
				if spawnItems ~= false then
					local randomItem = math.random(1, 10 - (difficulty * 2))
					currentThrownItems = currentThrownItems + 1
					
					local randomSide = (math.random(1,2) * 2) - 3
					
					if currentThrownItems > difficulty + 1 then
						currentThrownItems = 0
						createFruit(randomSide, randomItem ~= 1)
					else
						if randomItem > 5 then
							createFruit(randomSide)
						end
					end
				end
			end
		end
		
		if currentLoop % 10 == 0 then
			for index = #itemArray,1,-1 do
				local item = itemArray[index]
				if item.y > BOTTOMY + 100 or item.removeFlag == true then
					display.remove(item)
					table.remove(itemArray, index)
				end
			end
		end
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	manager = event.parent
	difficulty = params.difficulty or 3
	
	isFirstTime = params.isFirstTime

	itemArray = {}
	touchEventsArray = {}		
	spawnItems = false
	currentThrownItems = 0
	updateTouch = false
	gameStarted = false
	gameEnded = false
	currentLoop = 0

	system.activate( "multitouch" )
	physics.start()
	physics.setGravity( 0, 5 )

	Runtime:addEventListener ("enterFrame", onFrameUpdate)
	Runtime:addEventListener ("touch", sceneTouched)
	
	instructionsText.text = localization.getString("instructionsMathninja")
		
	local operatorFilenames = {
		["addition"] = "images/minigames/plusPurple.png",
		["subtraction"] = "images/minigames/minusPurple.png",
		["multiplication"] = "images/minigames/multiplyPurple.png",
		["division"] = "images/minigames/divisionPurple.png",
	}
	
	local chosenCategory = params.topic or "addition"
	local operation = params.operation or {operands = {0,0}, result = 0, }
	
	operand1 = operation.operands and operation.operands[1] or 0
	operand2 = operation.operands and operation.operands[2] or 0
	correctAnswer = operation.result or 0
	
	wrongAnswers = params.wrongAnswers
	operationResult = operation.operationString
	
	nameImageOperator = operatorFilenames[chosenCategory]

	requiredItemType = correctAnswer
end

local function startGame()
	gameStarted = true
	spawnItems = true
	updateTouch = true
end

local function finishGame()	
	Runtime:removeEventListener("enterFrame", onFrameUpdate)
	Runtime:removeEventListener("touch", sceneTouched)
	system.deactivate("multitouch")

	if startGameTimer then
		timer.cancel(startGameTimer)
	end
	for index = #itemArray,1,-1 do
		local item = itemArray[index]
		display.remove(item)
		table.remove(itemArray, index)
	end
	physics.stop()
		
	display.remove(dynamicElementsGroup)
	dynamicElementsGroup = nil
end
--------------------------------------------- Module functions
function game.getInfo()
	return {
		-- TODO Make answer appear when it is slashed
		available = false,
		correctDelay = 600,
		wrongDelay = 600,
		
		name = "Math ninja",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minOperand = 1},
			{id = "wrongAnswer", amount = 12, tolerance = 8, minNumber = 2},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) )
	sceneView:insert(background)
	
	fruitGroup = display.newGroup()
	sceneView:insert(fruitGroup)
	
	correctFruitGroup = display.newGroup()
	sceneView:insert(correctFruitGroup)
	
	local instructionOptions = {
		text = "",	 
		x = display.contentCenterX,
		y = display.contentCenterY * 0.85,
		width = 350,
		height = 140,
		font = FONT_NAME,   
		fontSize = 28,
		align = "center"
	}
	instructionsText = display.newText(instructionOptions)
	instructionsText:setFillColor(unpack(TUTORIAL_INSTRUCTIONS_FONT_COLOR))
	sceneView:insert(instructionsText)
	
	elementsGroup = display.newGroup()
	sceneView:insert(elementsGroup)
end

function game:show( event )
	local group = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		generateEquation()
	elseif phase == "did" then
		startGame()
	end
end

function game:destroy ( event )
	
end

function game:hide ( event )
	local phase = event.phase
	
	if phase == "will" then
		
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		finishGame()
	end
end

game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
