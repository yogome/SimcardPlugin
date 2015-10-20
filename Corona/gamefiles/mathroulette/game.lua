 ----------------------------------------------- Test minigame - comentless file in same folder - template.lua
local scenePath = ... -- we receive the require scenePath in the 3 dots "gamefiles.testminigame.game"
local folder = scenePath:match("(.-)[^%.]+$") -- We strip the lua filename "gamefiles.testminigame."
local assetPath = string.gsub(folder,"[%.]","/") -- We convert dots to slashes "gamefiles/testminigame/" so we can load files in our directory
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" ) -- This is the only module that is not a library that can be included in minigames.
local sound = require( "libs.helpers.sound" )
local uifx = require( "libs.helpers.uifx" )
local widget = require( "widget" )
local physics = require "physics"
local game = director.newScene() 
----------------------------------------------- Variables - Variables are declared BUT not initialized
local answersLayer, firstNumber, secondNumber
local backgroundLayer,operatorSign,checkCounter
local textLayer, instructions, positions, pin	
local manager,roulette,bubbleNumbers, startGameSound
local tapsEnabled,tapOrder,initialTouchPos
local isFirstTime, miniGameAnswer,backRoulette
local gameTutorial,orderTable,lockButtons
local answersSettedTable, posToSound
local operationResult
----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -200}
local ASSETPATH = assetPath
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenLeft = display.screenOriginX
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenRight = screenLeft + screenWidth
local screenTop = display.screenOriginY
local screenHeight = display.viewableContentHeight - screenTop * 2
local screenBottom = screenTop + screenHeight 
local mRandom = math.random
local mAbs = math.abs
local mRound = math.round
local buttonOk = { width = 128, height = 128, defaultFile = ASSETPATH .. "ok.png", overFile = ASSETPATH .. "ok2.png", onPress = function()sound.play("pop")end}

local NUMBEROFANSWERS = 10
----------------------------------------------- Functions - Local functions ONLY.

local function onTouch( event )
	local t = event.target
	if event.phase == "began" then
		sound.play("flipCard")
		tutorials.cancel(gameTutorial,300)
		initialTouchPos = event.x
		display.getCurrentStage():setFocus(t);
		t.touchJoint = physics.newJoint("touch", roulette, event.x, event.y);
		t.isFocus = true;
	elseif event.phase == "moved" and t.isFocus then
		t.touchJoint:setTarget(event.x, event.y);
	elseif event.phase == "ended" and t.isFocus then
		display.getCurrentStage():setFocus(nil);
		t.touchJoint:removeSelf();
		t.touchJoint = nil;
		t.isFocus = nil;
--		sound.stopAll(300)
	end
--	return true
end
local function createDynamicAnswers()
	
end
local function createNumbers(wrongTable)
	local winnerIndex = mRandom(NUMBEROFANSWERS)
	local number
	
	for counter = 1, NUMBEROFANSWERS do
		if winnerIndex ==  counter then
			number = miniGameAnswer
		else
			number = wrongTable[counter]
		end
		local numberText =  display.newText( number, positions[counter].x, positions[counter].y, settings.fontName, 45)
		numberText.answer = number
		numberText:setFillColor(0)
		bubbleNumbers:insert(numberText)
	end
end
local function update()
	local lastPos,x
	for counter = 1, NUMBEROFANSWERS do
		bubbleNumbers[counter].rotation = -roulette.rotation
		x,lastPos = bubbleNumbers[counter]:localToContent(0,0)
		lastPos = mRound(lastPos)
		if lastPos > posToSound and counter ~= checkCounter and startGameSound then
			checkCounter = counter
			sound.play("minigamesClick")
		end
	end
end
local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	roulette:addEventListener( "touch", onTouch )
	Runtime:addEventListener("enterFrame",update)
	posToSound = 1095
	if screenWidth / screenHeight >= 1.5 then
		posToSound = 1008
	end
	roulette.rotation = 0
	bubbleNumbers = display.newGroup()
	roulette:insert(bubbleNumbers)
	initialTouchPos = 0
		
	firstNumber.text = operation.operands[1]
	secondNumber.text = operation.operands[2]
	operatorSign.text = operation.operator
	miniGameAnswer = operation.result
	operationResult = operation.operationString
	createNumbers(params.wrongAnswers)
	answersSettedTable = {0, miniGameAnswer}
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("mathRoulette")
	physics.start()
	physics.addBody(roulette, "dynamic", {friction = 0, bounce = 0, density = 1, radius = 25});
	roulette.angularDamping = 1;

	physics.addBody(pin, "static", {friction = 0, bounce = 0, density = 1, radius = 2.5, isSensor = true});

	physics.newJoint("pivot", pin, roulette, pin.x, pin.y);
	physics.setGravity( 0, 0 )
	startGameSound = false
	timer.performWithDelay(1200,function() startGameSound = true end)
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end
local function pressButton(event)
	local tag = event.target.tag
	if tag == "okBtn" then
		if lockButtons then
			return
		end
		lockButtons = true
		local x,lastPos,posY,index
		for counter = 1, NUMBEROFANSWERS do
			x,lastPos = bubbleNumbers[counter]:localToContent(0,0)
			if counter == 1 then
				posY = lastPos
				index = counter
			else
				if posY > lastPos then
					posY = lastPos
					index = counter
				end
			end
		end
		if bubbleNumbers[index].answer == miniGameAnswer then
			manager.correct()
		else
			manager.wrong({id = "text", text = operationResult, fontSize = 70})
		end
	end
end
local function removeAnswers()
	roulette:removeEventListener("touch",onTouch)
	display.remove(bubbleNumbers)
	bubbleNumbers = nil
end
local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 3000, x = screenLeft + 300, y = screenBottom - 200, toX = centerX - 100, toY = screenBottom - 200},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) -- Use the tutorial library, it is simple, fast and efficient, see how it works.
	end
end
----------------------------------------------- Module functions 
function game.getInfo() -- This is the minigame header. The manager will ask the minigame what it does and what it needs
	return {
		available = false, -- If false, manager will not choose it, only manually
		correctDelay = 500, -- Delay given to complete animation or actions after the player has answered correctly
		wrongDelay = 500, -- Delay given to complete animation or actions after the player has failed to answer
		-- NOTE: These delays exist so the animation after the player has answered can complete and for us to only count the time it takes to answer
		name = "Minigame tester", -- Reference name, server purposes
		category = "math", -- Category/Subject
		subcategories = {"addition", "subtraction", "multiplication"}, -- available subcategories
		age = {min = 0, max = 99}, -- Minimum and max age for this game
		grade = {min = 0, max = 99}, -- Min and max grade for this game
		gamemode = "findAnswer", -- Gamemode (How the game is played)
		requires = { -- What the game needs from the manager. We will ask for an operation and some wrong answers
			{id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 15, minNumber = 3, tolerance = 20, unique = true},
		},
	}
end   
function game:create(event) -- This will be fired the first time you load the scene. If you deload the scene this can get called again. The best practice is to make your scenes without memory leaks.
	local sceneView = self.view
	
	-- These groups make up a layered scene, this way dynamic objects can always appear behind any text. These layers will NEVER be removed
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	local background = display.newImage("gamefiles/mathRoulette/fondo.png")
	background.x = centerX
	background.y = centerY
	background.width = screenWidth
	background.height = screenHeight
	backgroundLayer:insert(background)
	
	roulette = display.newGroup()
	roulette.x,roulette.y = screenLeft + 400, screenBottom
	backRoulette = display.newImage(ASSETPATH .. "rueda1.png")
	roulette:insert(backRoulette)
	
	pin = display.newCircle(roulette.x, roulette.y, 5);
	pin:setFillColor(1);
	backgroundLayer:insert(pin)
	
	positions = {
		[1] = {x = backRoulette.x, y = backRoulette.y - 290},
		[2] = {x = backRoulette.x + 170, y = backRoulette.y - 240},
		[3] = {x = backRoulette.x + 280, y = backRoulette.y - 90},
		[4] = {x = backRoulette.x + 280, y = backRoulette.y + 90},
		[5] = {x = backRoulette.x + 170, y = backRoulette.y + 240},
		[6] = {x = backRoulette.x , y = backRoulette.y + 290},
		[7] = {x = backRoulette.x - 170, y = backRoulette.y + 240},
		[8] = {x = backRoulette.x - 280, y = backRoulette.y + 90},
		[9] = {x = backRoulette.x - 280, y = backRoulette.y - 90},
		[10] = {x = backRoulette.x - 170, y = backRoulette.y - 240},
	}
	
	answersLayer:insert(roulette)
	
	buttonOk.onRelease = pressButton
    local oksBtn = widget.newButton(buttonOk)
    oksBtn.x,oksBtn.y = screenRight - 200, screenBottom - 150
	oksBtn.xScale, oksBtn.yScale = 1.5 , 1.5
    oksBtn.tag = "okBtn"
	answersLayer:insert(oksBtn)
	
	local textData = {
		text = "",
		width = 550,
		font = "VAGRounded",   
		fontSize = 30,
		align = "center",
		x = centerX + 250,
		y = centerY + 30 ,
	}
	instructions = display.newText(textData)
	instructions:setFillColor(15/255,73/255,130/255)
	textLayer:insert(instructions)
	
	local bubbleX = display.newImage(ASSETPATH .. "numero.png")
	bubbleX.xScale, bubbleX.yScale = 0.7, 0.7
	bubbleX.x, bubbleX.y = centerX - 400, screenTop + 150
	backgroundLayer:insert(bubbleX)
	
	firstNumber =  display.newText("1", bubbleX.x, bubbleX.y, settings.fontName, 50)
	firstNumber:setFillColor(1)
	backgroundLayer:insert(firstNumber)
	
	local bubble = display.newImage(ASSETPATH .. "numero.png")
	bubble.xScale, bubble.yScale = 0.7, 0.7
	bubble.x, bubble.y = centerX - 50, bubbleX.y
	backgroundLayer:insert(bubble)
	
	secondNumber =  display.newText("2", bubble.x, bubble.y, settings.fontName, 50)
	secondNumber:setFillColor(1)
	backgroundLayer:insert(secondNumber)
	
	operatorSign =  display.newText("", bubble.x - 170, bubble.y, settings.fontName, 90)
	operatorSign:setFillColor(1)
	backgroundLayer:insert(operatorSign)
	
	bubble = display.newImage(ASSETPATH .. "respuesta.png")
	bubble.xScale, bubble.yScale = 0.7, 0.7
	bubble.x, bubble.y = centerX + 400, bubbleX.y
	backgroundLayer:insert(bubble)
	
	local equalsIcon = display.newImage(ASSETPATH .. "igual.png")
	equalsIcon.x, equalsIcon.y = centerX + 170, bubbleX.y
	backgroundLayer:insert(equalsIcon)
	
	local arrowIcon = display.newImage(ASSETPATH .. "flecha.png")
	arrowIcon.x, arrowIcon.y = roulette.x, roulette.y - 400
	arrowIcon.xScale, arrowIcon.yScale = 0.4, 0.4
	textLayer:insert(arrowIcon)
end

function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
		initialize(event)
		createDynamicAnswers() -- Just an example to create dynamic stuff
		tutorial() -- We always call the tutorial. Whether or not it is drawn depends on the function inside, not outside
	elseif phase == "did" then -- Start music, start game, enable control
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- We dont usually use this part now, but you can disable game stuff here
		
	elseif phase == "did" then -- Remove all dynamic stuff, remove Runtime event listeners, disable physics, multitouch.
		-- Remove transitions, cancel timers, etc.
		disableButtons()
		removeAnswers()
		tutorials.cancel(gameTutorial)
		Runtime:removeEventListener("enterFrame",update)
		physics.removeBody(roulette)
		physics.stop()
		-- We did not include the transition made with director, director cancels it automatically once we leave the scene.
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
