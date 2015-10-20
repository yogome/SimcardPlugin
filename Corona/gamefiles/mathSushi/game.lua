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
local backgroundLayer,operatorSign
local textLayer, instructions, positions
local manager,monsterGroup,sushiGroup,sushi1,sushi2,sushi3
local tapsEnabled,initialTouchPos,textAnswers
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
local function changeMonsterFace(normal,happy,angry)
	monsterGroup[1].alpha = normal
	monsterGroup[2].alpha = happy
	monsterGroup[3].alpha = angry
end

local function checkAnswer(obj)
	transition.to(obj,{alpha = 0})
	sound.play("minigamesNom")
	timer.performWithDelay(400,function()sound.play("minigameslion")end)
	if miniGameAnswer == obj.answer then
		changeMonsterFace(0,1,0)
		manager.correct()
	else
		changeMonsterFace(0,0,1)
		manager.wrong({id = "text", text = firstNumber.text .. " " .. operatorSign.text .. " " .. secondNumber.text .. " = " .. miniGameAnswer, fontSize = 70})
	end
end
local function onTouch(event)
	if event.target.isActive then
		return
	end
	local label = event.target
	local phase = event.phase
	local parent = label.parent
	
	if "began" == phase then
		sound.play("dragtrash")
		parent:insert( label )
		display.getCurrentStage():setFocus( label )

		label.isFocus = true
		label.isCorrect = false
		
		if label.scaledUp then
			label:scale(pieceBackScale, pieceBackScale)
			label.scaledUp = false
		end
		
		label.x0 = event.x - label.x
		label.y0 = event.y - label.y

	elseif label.isFocus then
		if "moved" == phase then
			label.x = event.x - label.x0
			label.y = event.y - label.y0
		elseif "ended" == phase or "cancelled" == phase then
			sound.play("pop")
			event.target.isActive = true
			display.getCurrentStage():setFocus( nil )
			label.isFocus = false
			
			local objPosX, objPosY = label:localToContent(0, 0)
			local monsterPosX, monsterPosY = monsterGroup[1]:localToContent(0, 0)
			
		    local distanceToPointX, distanceToPointY = mAbs(objPosX - monsterPosX), mAbs(objPosY - monsterPosY)
			if distanceToPointX < 100 and distanceToPointY < 120 then
				checkAnswer(label)
			else
				transition.to(label,{x = SUSHIPOSITIONS[label.index], y = screenBottom - 100,onComplete = function()
					label.isActive = false
				end})
			end
		end
	end		
	return true
end
local function createDynamicAnswers(wrongTable)
	local winnerIndex = mRandom(NUMBEROFANSWERS)
	local number
	for counter = 1, NUMBEROFANSWERS do
		if winnerIndex == counter then
			number = miniGameAnswer
		else
			number = wrongTable[counter]
		end
		local answerText = display.newText(number,0, 0, settings.fontName, 45)
		sushiGroup[counter]:insert(answerText)
		answerText.y = answerText.y - 35
		sushiGroup[counter].textAnswer = answerText
		sushiGroup[counter].answer = number
	end
end
local function initializeSushis()
	for counter = 1, NUMBEROFANSWERS do
		local sushi = sushiGroup[counter]
		sushi.isActive = false
		sushi.x, sushi.y = SUSHIPOSITIONS[sushi.index], screenBottom - 100
		if sushi.textAnswer ~= nil then
			display.remove(sushi.textAnswer)
			sushi.answer = nil
		end
		if sushi.alpha == 0 then
			sushi.alpha = 1
		end
	end
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
	initializeSushis()
	createDynamicAnswers(params.wrongAnswers)
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("mathSushi")
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

end
local function tutorial()
	local correctAnswer
	for counter = 1, NUMBEROFANSWERS do
		if sushiGroup[counter].answer == miniGameAnswer then
			correctAnswer = sushiGroup[counter]
		end
	end
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 3000, x = correctAnswer.x, y = correctAnswer.y, toX = monsterGroup.x, toY = monsterGroup.y},
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
			{id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 3},
		},
	}
end   
local function createSushi(group,counter,pos)
	group = display.newGroup()
	local sushi = display.newImage(assetPath .. "opcion" .. counter .. ".png" )
	group.x,group.y = pos, screenBottom - 100
	sushi.xScale,sushi.yScale = 0.7,0.7
	group.posX,group.posY = group.x,group.y
	group.index = counter
	group:addEventListener("touch",onTouch)
	group:insert(sushi)
	sushiGroup:insert(group)
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
		y = screenTop + 60 ,
	}
	instructions = display.newText(textData)
	instructions:setFillColor(222/255,89/255,39/255)
	textLayer:insert(instructions)
	
	local bubbleX = display.newImage(assetPath .. "casilla.png")
	bubbleX.xScale, bubbleX.yScale = 0.7, 0.7
	bubbleX.x, bubbleX.y = centerX - 400, screenTop + 280
	backgroundLayer:insert(bubbleX)
	
	firstNumber =  display.newText("1", bubbleX.x, bubbleX.y, settings.fontName, 50)
	firstNumber:setFillColor(1)
	backgroundLayer:insert(firstNumber)
	
	local bubble = display.newImage(assetPath .. "casilla.png")
	bubble.xScale, bubble.yScale = 0.7, 0.7
	bubble.x, bubble.y = centerX - 50, bubbleX.y
	backgroundLayer:insert(bubble)
	
	secondNumber =  display.newText("2", bubble.x, bubble.y, settings.fontName, 50)
	secondNumber:setFillColor(1)
	backgroundLayer:insert(secondNumber)
	
	operatorSign =  display.newText("", bubble.x - 170, bubble.y - 10, settings.fontName, 150)
	operatorSign:setFillColor(5/255,124/255,109/255)
	backgroundLayer:insert(operatorSign)
	
	local equalsIcon = display.newImage(assetPath .. "igual.png")
	equalsIcon.x, equalsIcon.y = centerX + 170, bubbleX.y
	backgroundLayer:insert(equalsIcon)
	
	monsterGroup = display.newGroup()
	monsterGroup.x,monsterGroup.y = centerX + 380, screenTop + 280
	for counter = 1, 3 do
		local monster = display.newImage(assetPath .. "monstruo" .. counter .. ".png")
		monsterGroup:insert(monster)
		if counter ~= 1 then
			monster.alpha = 0
		end
	end
	backgroundLayer:insert(monsterGroup)
	
	sushiGroup = display.newGroup()
	createSushi(sushi1,1,centerX - 300)
	createSushi(sushi2,2,centerX)
	createSushi(sushi3,3,centerX + 300)
	answersLayer:insert(sushiGroup)
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
