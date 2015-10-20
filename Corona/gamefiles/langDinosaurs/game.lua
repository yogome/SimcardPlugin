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
local answersLayer, questionTime
local backgroundLayer
local textLayer, instructions, answerRects, correctText
local manager, audioBtn, tableToCheck,pressedDinosaur
local tapsEnabled, dinosaursGroup, pressedAudio
local isFirstTime, rightRect, wrongRect,languageToUse
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
local DINOSAURPOSITIONS = {
	[1] = { x = centerX - 300, y =  centerY + 150} ,
	[2] = { x = centerX , y =  centerY } ,
	[3] = { x = centerX + 300, y =  centerY + 150} ,
}
----------------------------------------------- Functions - Local functions ONLY.
--
local function sayColor(colorToSay)
	sound.play(languageToUse .. colorToSay)
end
local function createAnimation(name)
	
    local sheetData = { width = 256, height = 256, numFrames = 4, sheetContentWidth = 512, sheetContentHeight = 512 }
	local masterSheet1 = graphics.newImageSheet( assetPath .. name .. ".png", sheetData )

	local sequenceData = {
		{ name = "idle", sheet = masterSheet1, start = 1, count = 4, time = 550, loopCount = 0, loopDirection = "bounce"},
	}
	local sprite = display.newSprite( masterSheet1, sequenceData )
	sprite:play()
	return  sprite
end

local function checkColor(event)
	if pressedDinosaur then
		return
	end
	pressedDinosaur = true
	local colorCheck = event.target.color
	if colorCheck == tableToCheck[questionTime] then
		correctAnswers =  correctAnswers + 1
		rightRect.alpha = 1
		wrongRect.alpha = 0
		correctText.text = localization.getString("langDinosaursCorrect", languageToUse)
		sound.play("rightChoice")
	else
		sound.play("wrongChoice")
		wrongAnswers = wrongAnswers + 1
		rightRect.alpha = 0
		wrongRect.alpha = 1
		correctText.text = localization.getString("langDinosaursIncorrect", languageToUse) .. " " .. localization.getString("common" .. colorCheck, languageToUse)
	end
	questionTime = questionTime + 1
	if questionTime < 4 then
		instructions.text = localization.getString("langDinosaurs", languageToUse) .. " " .. localization.getString("common" .. tableToCheck[questionTime], languageToUse)
		timer.performWithDelay(500,function()
		sayColor(tableToCheck[questionTime])
	end)
	end
	transition.to(answerRects,{alpha = 1, onComplete = function()
		transition.to(answerRects,{alpha = 0,delay = 600,onComplete = function() pressedDinosaur = false end})
	end})
	if questionTime >= 4 then
		if correctAnswers > wrongAnswers then
			manager.correct()
		else
			
			local answerTable = {}
			for counter = 1, #tableToCheck do
				answerTable[counter] = localization.getString("common" .. tableToCheck[counter],languageToUse)
			end
			local answerString = table.concat(answerTable, ", ")
			manager.wrong({id = "text", text = answerString, fontSize = 70})
		end
	end
end
local function createAnswers()
	dinosaursGroup = display.newGroup()
	backgroundLayer:insert(dinosaursGroup)
	
	local colorsToUse = {"red","pink","green","black","orange","purple","blue","white","brown","yellow"}
	for counter = 1, #DINOSAURPOSITIONS do
		local indexToUse = mRandom(#colorsToUse)
		local dinosaur = createAnimation(colorsToUse[indexToUse])
		dinosaur.x, dinosaur.y = DINOSAURPOSITIONS[counter].x, DINOSAURPOSITIONS[counter].y
		dinosaur.color = colorsToUse[indexToUse]
		dinosaur.index = counter
		dinosaur:addEventListener("tap",checkColor)
		dinosaursGroup:insert(dinosaur)
		table.remove(colorsToUse,indexToUse)
	end
	colorsToUse = {1,2,3}
	for counter = 1, NUMBEROFANSWERS do
		local indexToUse = mRandom(#colorsToUse)
		tableToCheck[counter] = dinosaursGroup[colorsToUse[indexToUse]].color
		table.remove(colorsToUse,indexToUse)
	end
end

local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	tableToCheck = {}
	createAnswers()
	pressedAudio = false
	pressedDinosaur = false
	questionTime = 1
	correctAnswers = 0
	wrongAnswers = 0
	answerRects.alpha = 0
	answersLayer.alpha = 1
	timer.performWithDelay(500,function()
		sayColor(tableToCheck[1])
	end)
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("langDinosaurs", languageToUse) .. " " .. localization.getString("common" .. tableToCheck[questionTime], languageToUse)
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
		local objToMark
		for counter = 1, #tableToCheck do
			if tableToCheck[1] == dinosaursGroup[counter].color then
				objToMark = dinosaursGroup[counter]
			end
		end
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 500, time = 3000, x = objToMark.x, y = objToMark.y - 70},
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
	sayColor(tableToCheck[questionTime])
	pressedAudio = true
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
		y = screenTop + 28,
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
	
	correctText = display.newText("Correct",300,- 5,settings.fontName,35)
	answerRects:insert(correctText)
end
local function removeAnswers()
	display.remove(dinosaursGroup)
	dinosaursGroup = nil
end
local function checkLanguage()
	languageToUse = "en"
	if localization.getLanguage() == "en" then
		languageToUse = "es"
	end
end
function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
		checkLanguage()
		initialize(event)
--		tutorial() -- We always call the tutorial. Whether or not it is drawn depends on the function inside, not outside
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
