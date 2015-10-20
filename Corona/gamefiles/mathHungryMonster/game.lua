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
local answersLayer, firstNumber
local backgroundLayer, answerContainer, tutorialContainer,answerNumber
local textLayer, instructions, tables, counterNumber, foodCounter
local manager,monsterGroup, foodGroup
local tapsEnabled,initialTouchPos,indexImage
local isFirstTime, miniGameAnswer
local gameTutorial,lockButtons,pieceBackScale
local readyText
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
local SUSHIPOSITIONS = {
	[1] = {x = centerX - 345, y = centerY + 60},
	[2] = {x = centerX - 225, y = centerY + 140},
	[3] = {x = centerX - 75 , y = centerY + 190},
	[4] = {x = centerX + 75, y = centerY + 190},
	[5] = {x = centerX + 225, y = centerY + 140},
	[6] = {x = centerX + 345, y = centerY + 60}
}
local NUMBEROFANSWERS = 9
local buttonOk = { width = 171, height = 128, defaultFile = assetPath .. "listo.png", overFile = assetPath .. "listo2.png", onPress = function()sound.play("pop")end}
----------------------------------------------- Functions - Local functions ONLY.
local function changeMonsterFace(normal,happy,angry,sad,bad)
	monsterGroup[1].alpha = normal
	monsterGroup[2].alpha = happy
	monsterGroup[3].alpha = angry
	monsterGroup[4].alpha = sad
	monsterGroup[5].alpha = bad
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
				changeMonsterFace(0,1,0,0,0)
				sound.play("minigamesNom")
				transition.to(label,{alpha = 0})
				foodCounter = foodCounter + 1
				counterNumber.text = foodCounter
				timer.performWithDelay(500,function()changeMonsterFace(1,0,0,0,0)end)
			else
				transition.to(label,{x = label.xPos, y = label.yPos, onComplete = function()
					label.isActive = false
				end})
			end
		end
	end		
	return true
end
local function createDynamicAnswers()
	foodGroup = display.newGroup()
	answersLayer:insert(foodGroup)
	indexImage = mRandom(4)
	local firstPosX, firstPosY =  tables.x - 200, tables.y - 110
	for counter = 1, NUMBEROFANSWERS do
		local cookie = display.newImage(assetPath .. "bocado" .. indexImage .. ".png")
		firstPosX = firstPosX + 100
		cookie.x, cookie.y = firstPosX, firstPosY
		cookie.xScale, cookie.yScale = 0.7, 0.7
		if counter % 3 == 0 then
			firstPosX = tables.x - 200
			firstPosY = firstPosY + 100
		end
		cookie:addEventListener("touch",onTouch)
		cookie.xPos, cookie.yPos = cookie.x, cookie.y
		foodGroup:insert(cookie)
	end
end
local function initializeSushis()

end
local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	changeMonsterFace(1,0,0,0,0)
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	foodCounter = 0
	counterNumber.text = ""
	pieceBackScale = 0.7
	initialTouchPos = 0
	miniGameAnswer = operation.result
	answerNumber.text = miniGameAnswer
	firstNumber.text = ""
	initializeSushis()
	createDynamicAnswers()
	instructions.text = localization.getString("mathHungryMonster")
	readyText.text = localization.getString("commonOk")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end
local function createAnswerGroup()
	local group = display.newGroup()
	local firstPosX, firstPosY =  - 200, -50
	local numberText = display.newText(miniGameAnswer .. " = ",firstPosX - 10, firstPosY + 100, settings.fontName,60)
	group:insert(numberText)
	for counter = 1, miniGameAnswer do
		local cookie = display.newImage(assetPath .. "bocado" .. indexImage .. ".png")
		firstPosX = firstPosX + 100
		cookie.x, cookie.y = firstPosX, firstPosY
		cookie.xScale, cookie.yScale = 0.7, 0.7
		if counter % 3 == 0 then
			firstPosX = -200
			firstPosY = firstPosY + 100
		end
		cookie:addEventListener("touch",onTouch)
		cookie.xPos, cookie.yPos = cookie.x, cookie.y
		group:insert(cookie)
	end
	group.alpha = 0
	return group
end
local function pressButton(event)
	if tapsEnabled then
		disableButtons()
		sound.play("minigameslion")
		if foodCounter == miniGameAnswer then
			changeMonsterFace(0,0,1,0,0)
			manager.correct()
		else
			if foodCounter < miniGameAnswer then
				changeMonsterFace(0,0,0,1,0)
			else
				changeMonsterFace(0,0,0,0,1)
			end
			local groupAnswer = createAnswerGroup()
			manager.wrong({id = "group", group = groupAnswer})
	--		manager.wrong({id = "text", text = miniGameAnswer, fontSize = 70})
		end
	end
end
local function removeAnswers()
	if foodGroup and type(foodGroup.numChildren) == "number" then
		for counter = 1, foodGroup.numChildren do
			foodGroup[counter]:removeEventListener("touch",onTouch)
		end
		display.remove(foodGroup)
	end
end
local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 2000, x = foodGroup[5].x, y = foodGroup[5].y, toX = monsterGroup.x, toY = monsterGroup.y},
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
			{id = "operation", operands = 2, maxAnswer = 9, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 6},
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
	background.x, background.y = centerX, centerY
	background.width, background.height = screenWidth, screenHeight
	backgroundLayer:insert(background)
	
	local textData = {
		text = "",
		font = "VAGRounded",   
		fontSize = 25,
		align = "center",
	}
	tutorialContainer = display.newGroup()
	
	instructions = display.newText(textData)
	instructions:setFillColor(222/255,89/255,39/255)
	tutorialContainer:insert(instructions)
	
	local textContainer = display.newImage(assetPath .. "instruccion.png")
	tutorialContainer:insert(textContainer)
	
	textLayer:insert(tutorialContainer)
	textLayer.x, textLayer.y = centerX, screenTop + 60 
	
	answerContainer = display.newGroup()

	backgroundLayer:insert(answerContainer)
	
	firstNumber =  display.newText("1", answerContainer.x - 150, answerContainer.y + 10, settings.fontName, 55)
	firstNumber:setFillColor(63/255,0,49/255)
	answerContainer:insert(firstNumber)
	
	local backTables = display.newImage(assetPath .. "mesa.png")
	backTables.x, backTables.y = centerX - 270, screenBottom - 240
	backTables.xScale, backTables.yScale = 1, 1.3
	backgroundLayer:insert(backTables)
	
	if screenWidth / screenHeight >= 1.5 then
		backTables.x = centerX - 350
	end
	tables = display.newImage(assetPath .. "charola.png")
	tables.x, tables.y = backTables.x , backTables.y
	tables.xScale, tables.yScale = 1.2, 1.2
	backgroundLayer:insert(tables)
	
	local answerHolder = display.newImage(assetPath .. "numero.png")
	answerHolder.x, answerHolder.y = centerX, screenTop + 200
	answerHolder.xScale, answerHolder.yScale = 0.8, 0.8
	backgroundLayer:insert(answerHolder)
	
	answerNumber = display.newText("",answerHolder.x, answerHolder.y, settings.fontName,40)
	backgroundLayer:insert(answerNumber)
	
	buttonOk.onRelease = pressButton
    local oksBtn = widget.newButton(buttonOk)
    oksBtn.x,oksBtn.y = screenRight - 200, screenBottom - 100
    oksBtn.tag = "readyBtn"
	answersLayer:insert(oksBtn)
	
	readyText =  display.newText("", oksBtn.x, oksBtn.y, settings.fontName, 30)
	answersLayer:insert(readyText)
	
	local counterHolder = display.newImage(assetPath .. "counterholder.png")
	counterHolder.x, counterHolder.y = oksBtn.x, centerY + 40
	backgroundLayer:insert(counterHolder)
	
	if screenWidth / screenHeight >= 1.5 then
		counterHolder.y = centerY + 50
	end
	
	counterNumber = display.newText("",counterHolder.x,counterHolder.y + 60, settings.fontName,40)
	counterNumber:setFillColor( 16/255, 112/255, 155/255)
	backgroundLayer:insert(counterNumber)
	
	monsterGroup = display.newGroup()
	monsterGroup.x,monsterGroup.y = centerX + 100, centerY + 70
	monsterGroup.xScale, monsterGroup.yScale = 1, 1
	for counter = 1, 5 do
		local monster = display.newImage(assetPath .. "m" .. counter .. ".png")
		monsterGroup:insert(monster)
		if counter ~= 1 then
			monster.alpha = 0
		end
	end
	backgroundLayer:insert(monsterGroup)
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
