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
local extraTable = require("libs.helpers.extratable")
local game = director.newScene() 
----------------------------------------------- Variables - Variables are declared BUT not initialized
local answersLayer, questionTime,monsterGroup
local backgroundLayer, languageUsing,tableToCheck, objTapped
local textLayer, instructions, answerRects, correctText
local manager, audioBtn, tableToCheck, bodyPartTapped
local tapsEnabled, pressedAudio
local isFirstTime, rightRect, wrongRect
local gameTutorial,lockButtons, correctAnswers, wrongAnswers
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
local NUMBEROFANSWERS = 3
local MONSTERBODYPARTS = {"rarm","larm","rhand","lhand","rfoot","lfoot","rleg","lleg","torso","head"}
local MONSTER1POSITIONS = {
	[1] = {x = 150, y = 20},
	[2] = {x = -150, y = 20},
	[3] = {x = 160, y = 153},
	[4] = {x = -160, y = 153},
	[5] = {x = 60, y = 190},
	[6] = {x = -50, y = 190},
	[7] = {x = 50, y = 130},
	[8] = {x = -40, y = 130},
	[9] =  {x = 0, y = 0},
	[10] = {x = 0, y = -120},
}
local MONSTER2POSITIONS = {
	[1] = {x = 160, y = -10},
	[2] = {x = -160, y = -10},
	[3] = {x = 175, y = 60},
	[4] = {x = -175, y = 65},
	[5] = {x = 75, y = 190},
	[6] = {x = -77, y = 181},
	[7] = {x = 70, y = 130},
	[8] = {x = -70, y = 130},
	[9] =  {x = 0, y = 0},
	[10] = {x = 0, y = -120},
}
----------------------------------------------- Functions - Local functions ONLY.
 
local function changePart()
	timer.performWithDelay(500,function()
		sound.play(languageUsing .. tableToCheck[questionTime])
	end)
	instructions.text = localization.getString("langGiants") .. localization.getString("monster" .. tableToCheck[questionTime]) .. localization.getString("langGiants2")
end

local function checkPart(event)
	if bodyPartTapped then
		return
	end
	bodyPartTapped = true
	local tag = event.target.tag
	objTapped = event.target
	colors.addColorTransition(objTapped)
	transition.to(objTapped,{r = 0.5, g = 0.5, b = 0.5})
	if objTapped.tag == tableToCheck[questionTime] then
		sound.play("rightChoice")
		rightRect.alpha = 1
		wrongRect.alpha = 0
		correctText.text = localization.getString("langGiantsCorrect")
		correctAnswers = correctAnswers + 1
	else
		local addText = ""
		if languageUsing == "es" then
			if objTapped.tag == "torso" or objTapped.tag == "rarm" or objTapped.tag == "larm" or objTapped.tag == "rfoot" or objTapped.tag == "lfoot" then
				addText = "el "
			else
				addText = "la "
			end
		end
		sound.play("wrongChoice")
		rightRect.alpha = 0
		wrongRect.alpha = 1
		correctText.text = localization.getString("langGiantsWrong") .. addText .. localization.getString("monster" .. objTapped.tag)
		wrongAnswers = wrongAnswers + 1
	end
	transition.to(answerRects,{ alpha = 1, onComplete = function()
		transition.to(objTapped,{r = 1, g = 1, b = 1, delay = 700})
		transition.to(answerRects,{ delay = 700, alpha = 0, onComplete = function()
			bodyPartTapped = false
		end})
	end})
	questionTime = questionTime + 1
	if questionTime < 4 then
		changePart()
	end
	if questionTime > 3 then
		if correctAnswers > wrongAnswers then
			manager.correct()
		else
			local answerTable = {}
			for counter = 1, #tableToCheck do
				answerTable[counter] = localization.getString("monster" .. tableToCheck[counter])
			end
			local answerString = table.concat(answerTable, ", ")
			manager.wrong({id = "text", text = answerString, fontSize = 70})
		end		
	end
end
local function createAnswers()
	monsterGroup = display.newGroup()
	answersLayer:insert(monsterGroup)
	local monsterType =  "g1"
	local offsets = MONSTER1POSITIONS
	if mRandom(2) > 1 then
		monsterType = "g2"
		offsets = MONSTER2POSITIONS
	end
	local parts = MONSTERBODYPARTS
	tableToCheck = {}
	local tempParts = extraTable.deepcopy(parts)
	for counter = 1, NUMBEROFANSWERS do
		local ind = mRandom(#tempParts)
		tableToCheck[counter] = tempParts[ind]
		table.remove(tempParts,ind)
	end
	monsterGroup.x,monsterGroup.y = centerX, centerY
	for counter = 1, #parts do
		local monsterPart = display.newImage(assetPath .. monsterType .. parts[counter] .. ".png")
		monsterPart.tag = parts[counter]
		if monsterType == "g2" then
			if monsterPart.tag == "piernad" then
				monsterPart.yScale = 1.2
			elseif monsterPart.tag == "piernai" then
				monsterPart.yScale = 1.2
			end
		end
		monsterPart:addEventListener("tap",checkPart)
		monsterPart.x, monsterPart.y = offsets[counter].x, offsets[counter].y
		monsterGroup:insert(monsterPart)
	end
end

local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	isFirstTime = params.isFirstTime
	languageUsing = localization.getLanguage()
	manager = event.parent
	lockButtons = false
	correctAnswers = 0
	wrongAnswers = 0
	answerRects.alpha = 0
	questionTime = 1
	bodyPartTapped = false
	createAnswers()
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end
local function pressButton(event)
	
end

local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local posX, posY
		tableToCheck[1] = "head"
		tableToCheck[2] = "torso"
		tableToCheck[3] = "rhand"
		for counter = 1, monsterGroup.numChildren do
			if tableToCheck[1] == monsterGroup[counter].tag then
				posX,posY = monsterGroup[counter]:localToContent(0, 0)
			end
		end
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 500, time = 3000, x = posX, y = posY + 80},
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
local function audioPressed(event)
	if pressedAudio then
		return
	end
	pressedAudio = true
	sound.play(languageUsing .. tableToCheck[questionTime])
	transition.to(audioBtn,{ xScale = 0.5, yScale = 0.5,time = 100})
	transition.to(audioBtn,{ xScale = .75, yScale = .75, delay = 100, time = 100})
	timer.performWithDelay(2000, function()
		pressedAudio = false
	end)
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
	local rectText = display.newImage(assetPath .. "instruccion.png")
	rectText.anchorY = 0
	rectText.width = screenWidth
	rectText.x, rectText.y = centerX, screenTop
	textLayer:insert(rectText)
	
	instructions = display.newText(textData)
	instructions:setFillColor(1)
	textLayer:insert(instructions)
	
	audioBtn = display.newImage( assetPath .. "audio.png")
	audioBtn.x, audioBtn.y = screenLeft + screenWidth * 0.08, screenTop + 60
	audioBtn.xScale, audioBtn.yScale = 0.75, 0.75
	audioBtn:addEventListener("tap",audioPressed)
	textLayer:insert(audioBtn)
	
	answerRects = display.newGroup()
	answerRects.x, answerRects.y = screenLeft, screenBottom - 100
	answersLayer:insert(answerRects)
	
	rightRect = display.newImage(assetPath .. "incorrecto.png")
	rightRect.anchorX = 0
	rightRect.alpha = 0
	answerRects:insert(rightRect)
	
	wrongRect = display.newImage(assetPath .. "correcto.png")
	wrongRect.anchorX = 0
	answerRects:insert(wrongRect)
	
	correctText = display.newText("Correct",350,- 5,settings.fontName,35)
	answerRects:insert(correctText)
end
local function removeAnswers()
	display.remove(monsterGroup)
	monsterGroup = nil
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
		changePart()
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
		tutorials.cancel(gameTutorial)
		removeAnswers()
		-- We did not include the transition made with director, director cancels it automatically once we leave the scene.
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
