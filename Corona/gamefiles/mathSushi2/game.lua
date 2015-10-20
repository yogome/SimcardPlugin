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
local answersLayer, firstNumber, secondNumber, answerNumber, firstOperand, secondOperand, firstOperandRight, secondOperandRight
local backgroundLayer,operatorSign, answerContainer, tutorialContainer, monsterText
local textLayer, instructions, positions, cleanDishes
local manager,monsterGroup,sushiGroup,sushi1,sushi2,sushi3,sushi4,sushi5,sushi6
local tapsEnabled,initialTouchPos,textAnswers
local isFirstTime, miniGameAnswer
local gameTutorial,lockButtons,pieceBackScale
local canAnswer
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
local NUMBEROFANSWERS = 6
----------------------------------------------- Functions - Local functions ONLY.
local function changeMonsterFace(normal,happy,angry)
	
	monsterGroup[1].alpha = normal
	monsterGroup[2].alpha = happy
	monsterGroup[3].alpha = angry
	
	answerContainer[1].alpha = normal
	answerContainer[2].alpha = happy
	answerContainer[3].alpha = angry
	
end

local function addAnswer(obj,check)
	transition.to(obj,{alpha = 0})
	sound.play("minigamesNom")
	if not check then
		firstOperand = obj.answer
		firstNumber.text = firstOperand
		transition.to(cleanDishes[1],{alpha = 1})
	else
		canAnswer = false
		transition.to(cleanDishes[2],{alpha = 1})
		secondOperand = obj.answer
		secondNumber.text = secondOperand
		local result
		if operatorSign.text == "-" then
			result = firstOperand - secondOperand
		else
			result = firstOperand + secondOperand
		end
		timer.performWithDelay(400,function()sound.play("minigameslion")end)
		if result == miniGameAnswer then
			changeMonsterFace(0,1,0)
			manager.correct()
		else
			changeMonsterFace(0,0,1)
			manager.wrong({id = "text", text = firstOperandRight .. " " .. operatorSign.text .. " " .. secondOperandRight .. " = " .. miniGameAnswer, fontSize = 70})
		end
	end
end
local function checkAnswer(obj)
	transition.to(obj,{alpha = 0})
	sound.play("minigameslion")
	if miniGameAnswer == obj.answer then
		changeMonsterFace(0,1,0)
		manager.correct()
	else
		changeMonsterFace(0,0,1)
		manager.wrong({id = "text", text = miniGameAnswer, fontSize = 70})
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
			if distanceToPointX < 100 and distanceToPointY < 120 and canAnswer then
				if firstOperand == nil then
					addAnswer(label,false)
				else
					addAnswer(label,true)
				end
			else
				transition.to(label,{x = SUSHIPOSITIONS[label.index].x, y = SUSHIPOSITIONS[label.index].y,onComplete = function()
					label.isActive = false
				end})
			end
		end
	end		
	return true
end
local function createDynamicAnswers(wrongTable)
	local winnerIndex = mRandom(NUMBEROFANSWERS)
	local winnerIndex2 = winnerIndex
	while winnerIndex2 == winnerIndex do
		winnerIndex2 = mRandom(NUMBEROFANSWERS)
	end
	local number = 1
	for counter = 1, NUMBEROFANSWERS do
		if winnerIndex == counter then
			number = firstOperandRight
		end
		if  winnerIndex2 == counter then
			number = secondOperandRight
		end
		if counter ~= winnerIndex and counter ~= winnerIndex2 then
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
	answerContainer.alpha = 0
	tutorialContainer.alpha = 1
	transition.to(answerContainer,{delay = 2000, alpha = 1})
	transition.to(tutorialContainer,{delay = 2000, alpha = 0})
	for counter = 1, NUMBEROFANSWERS do
		local sushi = sushiGroup[counter]
		sushi.isActive = false
		sushi.x, sushi.y = SUSHIPOSITIONS[sushi.index].x, SUSHIPOSITIONS[sushi.index].y
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
	canAnswer = true
	changeMonsterFace(1,0,0)
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	cleanDishes[1].alpha = 0
	cleanDishes[2].alpha = 0
	firstOperand =  nil
	secondOperand = nil
	pieceBackScale = 0.7
	initialTouchPos = 0
	operatorSign.text = operation.operator
	miniGameAnswer = operation.result
	firstOperandRight = operation.operands[1]
	secondOperandRight = operation.operands[2]
	firstNumber.text = ""
	secondNumber.text = ""
	answerNumber.text = miniGameAnswer
	monsterText.text = miniGameAnswer
	initializeSushis()
	createDynamicAnswers(params.wrongAnswers)
	instructions.text = localization.getString("mathSushi2")
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
		if sushiGroup[counter].answer == firstOperandRight then
			correctAnswer = sushiGroup[counter]
		end
	end
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 1500, x = correctAnswer.x, y = correctAnswer.y, toX = monsterGroup.x, toY = monsterGroup.y},
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
			{id = "wrongAnswer", amount = 6, minNumber = 1},
		},
	}
end   
local function createSushi(group,counter)
	group = display.newGroup()
	local sushi = display.newImage(assetPath .. "opcion" .. counter .. ".png" )
	sushi.xScale,sushi.yScale = 0.55,0.55
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
	
	local background = display.newRect(centerX,centerY,screenWidth,screenHeight)
	background:setFillColor(243/255, 236/255, 185/255)
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
	for counter = 1, 3 do
		local answer = display.newImage(assetPath .. "contenedor" .. counter .. ".png")
		if counter ~= 1 then
			answer.alpha = 0
		end
		answerContainer:insert(answer)
	end 
	
	answerContainer.xScale, answerContainer.yScale = 0.9, 0.9
	backgroundLayer:insert(answerContainer)
	
	firstNumber =  display.newText("1", answerContainer.x - 150, answerContainer.y + 10, settings.fontName, 55)
	firstNumber:setFillColor(63/255,0,49/255)
	answerContainer:insert(firstNumber)
	
	secondNumber =  display.newText("2", answerContainer.x , answerContainer.y + 10, settings.fontName, 55)
	secondNumber:setFillColor(63/255,0,49/255)
	answerContainer:insert(secondNumber)
	
	answerNumber = display.newText("", answerContainer.x + 150, answerContainer.y + 10, settings.fontName, 55)
	answerNumber:setFillColor(63/255,0,49/255)
	answerContainer:insert(answerNumber)
	
	operatorSign =  display.newText("", answerContainer.x - 75, answerContainer.y, settings.fontName, 100)
	operatorSign:setFillColor(63/255,0,49/255)
	answerContainer:insert(operatorSign)
	
	local equalsIcon = display.newImage(assetPath .. "igual.png")
	equalsIcon.x, equalsIcon.y = answerContainer.x + 75, answerContainer.y + 10
	equalsIcon.xScale, equalsIcon.yScale = 0.4, 0.4
	answerContainer:insert(equalsIcon)
	
	local tables = display.newImage(assetPath .. "mesas.png")
	tables.x, tables.y = centerX, centerY + 30
	tables.xScale, tables.yScale = 0.9, 0.9
	backgroundLayer:insert(tables)
	
	answerContainer.x, answerContainer.y = centerX, screenTop + 45
	
	monsterGroup = display.newGroup()
	monsterGroup.x,monsterGroup.y = centerX , centerY - 85
	monsterGroup.xScale, monsterGroup.yScale = 0.8, 0.8
	for counter = 1, 3 do
		local monster = display.newImage(assetPath .. "m" .. counter .. ".png")
		monsterGroup:insert(monster)
		if counter ~= 1 then
			monster.alpha = 0
		end
	end
	
	monsterText = display.newText("11",5,105,settings.fontName, 45)
	monsterGroup:insert(monsterText)
	monsterText:setFillColor(63/255,0,49/255)
	backgroundLayer:insert(monsterGroup)
	
	sushiGroup = display.newGroup()
	createSushi(sushi1,1)
	createSushi(sushi2,2)
	createSushi(sushi3,3)
	createSushi(sushi4,4)
	createSushi(sushi5,5)
	createSushi(sushi6,6)
	answersLayer:insert(sushiGroup)
	
	cleanDishes = display.newGroup()
	local xpositions = { -70 , 70}
	for counter = 1, 2 do
		local cleanDish = display.newImage(assetPath .. "vacio.png")
		cleanDish.x, cleanDish.y = cleanDishes.x + xpositions[counter], cleanDishes.y + 90
		cleanDish.xScale, cleanDish.yScale = 0.4, 0.4
		cleanDish.alpha = 0
		cleanDishes:insert(cleanDish)
	end
	cleanDishes.x,cleanDishes.y = centerX,centerY
	backgroundLayer:insert(cleanDishes)
	
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
