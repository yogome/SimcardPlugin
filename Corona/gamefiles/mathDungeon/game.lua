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
local game = director.newScene() 
----------------------------------------------- Variables - Variables are declared BUT not initialized
local answersLayer, firstNumber, secondNumber
local backgroundLayer,operatorSign, yogotarGroup
local textLayer, instructions,shield
local manager,monsterGroup
local tapsEnabled,initialTouchPos, patternRecognizer
local isFirstTime, miniGameAnswer
local gameTutorial,lockButtons,pieceBackScale
----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -200}
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
local mathSqrt = math.sqrt 
local SUSHIPOSITIONS = {centerX - 300, centerX, centerX + 300}
local NUMBEROFANSWERS = 3
----------------------------------------------- Functions - Local functions ONLY.
local function changeMonsterFace(normal,happy,angry,defeated)
	monsterGroup[1].alpha = normal
	monsterGroup[3].alpha = angry
	monsterGroup[4].alpha = defeated
	
	yogotarGroup[1].alpha = normal
	yogotarGroup[2].alpha = defeated
	yogotarGroup[3].alpha = angry
end

local function checkAnswer(event)
	local answer = event
	transition.to(answersLayer,{alpha = 0})
	if answer == miniGameAnswer then
		manager.correct()
		changeMonsterFace(0,0,0,1)
	else
		manager.wrong({id = "text", text = miniGameAnswer, fontSize = 70})
		changeMonsterFace(0,0,1,0)
	end
end

local function insertPatterns()
	
	local patterns = require("libs.helpers.patterns")
	
	patternRecognizer = patterns.newRecognizer({
	width = 200,
	height = 200,
	onComplete = function(event)
		checkAnswer(event.value)
	end,})
	patternRecognizer.x = screenRight - 190
	patternRecognizer.y = screenBottom - 200
	answersLayer:insert(patternRecognizer)
end
local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	changeMonsterFace(1,0,0)
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	pieceBackScale = 0.7
	initialTouchPos = 0
	firstNumber.text = operation.operands[1]
	secondNumber.text = operation.operands[2]
	operatorSign.text = operation.operator
	miniGameAnswer = operation.result
	insertPatterns()
	answersLayer.alpha = 1
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("mathDungeon")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end
local function pressButton(event)
	
end
local function removeAnswers()
	display.remove(patternRecognizer)
end
local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		firstNumber.text = 2
		secondNumber.text = 1
		operatorSign.text = "-"
		miniGameAnswer = 1
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 3000, x = shield.x, y = shield.y - 70, toX = shield.x, toY = shield.y + 70},
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
		subcategories = {"addition", "subtraction"}, -- available subcategories
		age = {min = 0, max = 99}, -- Minimum and max age for this game
		grade = {min = 0, max = 99}, -- Min and max grade for this game
		gamemode = "findAnswer", -- Gamemode (How the game is played)
		requires = { -- What the game needs from the manager. We will ask for an operation and some wrong answers
			{id = "operation", operands = 2, maxAnswer = 9, minAnswer = 0, maxOperand = 9, minOperand = 1},
			{id = "wrongAnswer", amount = 3},
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
	
	local background = display.newImage(assetPath .. "fondo.png")
	background.x = centerX
	background.y = centerY
	background.width = screenWidth
	background.height = screenHeight
	backgroundLayer:insert(background)
	
	local textData = {
		text = "",
		font = "VAGRounded",   
		fontSize = 30,
		align = "center",
		x = centerX,
		y = screenTop + 25 ,
	}
	local rectText = display.newRect(screenLeft,screenTop,screenWidth,55)
	rectText.anchorX = 0
	rectText.anchorY = 0
	rectText:setFillColor(0)
	rectText.alpha = 0.6
	backgroundLayer:insert(rectText)
	
	instructions = display.newText(textData)
	instructions:setFillColor(1)
	textLayer:insert(instructions)
	
	monsterGroup = display.newGroup()
	monsterGroup.x,monsterGroup.y = screenLeft + 200, centerY + 20
	for counter = 1, 4 do
		local monster = display.newImage(assetPath .. "dragon" .. counter .. ".png")
		monsterGroup:insert(monster)
		if counter ~= 1 then
			monster.alpha = 0
		end
	end
	monsterGroup.xScale, monsterGroup.yScale = 0.85,0.85
	backgroundLayer:insert(monsterGroup)
	
	yogotarGroup = display.newGroup()
	yogotarGroup.x,yogotarGroup.y = screenRight - 400, screenBottom - 200
	for counter = 1, 3 do
		local yogotar = display.newImage(assetPath .. "yogotar" .. counter .. ".png")
		yogotarGroup:insert(yogotar)
		if counter ~= 1 then
			yogotar.alpha = 0
		end
	end
	yogotarGroup.xScale, yogotarGroup.yScale = 1.2, 1.2
	backgroundLayer:insert(yogotarGroup)
	
	shield = display.newImage(assetPath .. "escudo.png")
	shield.x, shield.y = yogotarGroup.x + 200, yogotarGroup.y
	shield.xScale, shield.yScale =  1.1, 1.1
	answersLayer:insert(shield)
	
	local bubble = display.newImage(assetPath .. "operacion.png")
	bubble.xScale, bubble.yScale = 0.7, 0.7
	bubble.x, bubble.y = monsterGroup.x + 150, monsterGroup.y + 110
	answersLayer:insert(bubble)
	
	firstNumber =  display.newText("1", bubble.x - 50, bubble.y, settings.fontName, 60)
	firstNumber:setFillColor(0.7,0.7,0.7)
	answersLayer:insert(firstNumber)
	
	secondNumber =  display.newText("2", bubble.x + 50, bubble.y, settings.fontName, 60)
	secondNumber:setFillColor(0.7,0.7,0.7)
	answersLayer:insert(secondNumber)
	
	operatorSign =  display.newText("", bubble.x , bubble.y - 10, settings.fontName, 80)
	operatorSign:setFillColor(0.7,0.7,0.7)
	answersLayer:insert(operatorSign)
end

function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
		initialize(event)
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
		-- We did not include the transition made with director, director cancels it automatically once we leave the scene.
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
