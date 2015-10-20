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
local answersLayer, questionTime,correctAnswer, departureText, planesGroup,indexLine,departureGroup,instructionsGroup
local backgroundLayer, languageUsing,tableToCheck, lineGroup, countryArrived,colorToUse
local textLayer, instructions, antartic, countriesGroup, planeNumber, flyBoard
local manager, audioBtn, tableToCheck, bodyPartTapped, planeToUse
local tapsEnabled, pressedAudio, departureBoard, activePlanes
local isFirstTime, tableToCheck, wrongAnswer, lastPos
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
local CONTINENTS = {"america","asia","europa","africa"}
local POSCOUNTRIES = {
	[1] = { x = centerX - 195, y = centerY + 50},
	[2] = { x = centerX - 350, y = centerY - 180},
	[3] = { x = centerX - 270, y = centerY +10},
	[4] = { x = centerX - 10, y = centerY - 130},
	[5] = { x = centerX + 400, y = centerY - 80},
	[6] = { x = centerX - 350, y = centerY - 50},
	[7] = { x = centerX + 380, y = centerY},
	[8] = { x = centerX + 200, y = centerY - 190},
	[9] = { x = centerX - 85, y = centerY - 110},
	[10] = { x = centerX - 90, y = centerY - 170},
	[11] = { x = centerX - 340, y = centerY - 110},
	[12] = { x = centerX - 210, y = centerY + 130},
}
----------------------------------------------- Functions - Local functions ONLY.
local function checkForCountry(countryName)
--	for counter = 1, countriesGroup.numChildren do
--		if countryName == countriesGroup[counter].name then
--			return countriesGroup[counter]
--		end
--	end
end
local function createWrongGroup()

end
local function flyPlane(counter)
	if counter < lineGroup.numChildren then
		if lastPos.x ~= 0 then
			if mAbs(lastPos.x - lineGroup[counter].x) < 1 and mAbs(lastPos.y - lineGroup[counter].y) < 1 then
				counter = counter + 1
			end
		end
		if planeToUse.isLeft then
			if planeToUse.x < lineGroup[counter].x then
				planeToUse.xScale = mAbs(planeToUse.xScale)
				planeToUse.isLeft = false
			end
		else
			if planeToUse.x > lineGroup[counter].x then
				planeToUse.xScale = mAbs(planeToUse.xScale) * -1
				planeToUse.isLeft = true
			end
		end
		transition.to(planeToUse,{x = lineGroup[counter].x, y = lineGroup[counter].y,time = 5, transition = easing.inOutSine, onComplete = function()
			flyPlane(counter + 1)
			lastPos.x = lineGroup[counter].x
			lastPos.y = lineGroup[counter].y
		end})
	else
		local objectToShow
		local countryToShow = nil
		local timeToWait = 0
		display.remove(lineGroup)
		if countryArrived == tableToCheck[planeNumber] then
			transition.to(planeToUse,{alpha = 0, xScale = 0.1, yScale = 0.1})
			correctAnswers = correctAnswers + 1
			sound.play("correctAnswer")
			objectToShow = correctAnswer
		else
			transition.to(planeToUse,{alpha = 0, rotation = 180})
			wrongAnswers = wrongAnswers + 1
			sound.play("wrongAnswer")
			objectToShow = wrongAnswer
--			countryToShow = checkForCountry(tableToCheck[planeNumber])
			timeToWait = 1000
		end
		objectToShow.xScale, objectToShow.yScale = 0.1, 0.1
		objectToShow.x, objectToShow.y = planeToUse.x, planeToUse.y
		transition.to(objectToShow, {alpha = 1, xScale = 1, yScale = 1, onComplete = function()
			activePlanes = true
			transition.to(objectToShow,{delay = 300, alpha = 0, xScale = 0.5, yScale = 0.5, onComplete = function()
				sound.stopAll(1000)
			end})
		end})
		planeNumber = planeNumber + 1
		if countryToShow ~= nil then
			transition.to(countryToShow,{xScale = 1.4, yScale = 1.4, onComplete = function()
				transition.to(countryToShow,{xScale = 1, yScale = 1})
			end})
		end
		timer.performWithDelay(timeToWait,function()
			if planeNumber < 7 then
				departureText.text = localization.getString("country" .. tableToCheck[planeNumber])
			else
				if correctAnswers > wrongAnswers then
					manager.correct()
				else
					local groupAnswer = createWrongGroup()
					manager.wrong({id = "group", group = groupAnswer})
				end
			end
		end)
	end
end
local function onTouched(event)
	local label = event.target
	if label.index ~= planeNumber or  not activePlanes then
		return
	end
	local phase = event.phase
	local parent = label.parent
	if "began" == phase then
		colorToUse.r = mRandom(255)/255
		colorToUse.g = mRandom(255)/255
		colorToUse.b = mRandom(255)/255
		sound.play("dragtrash")
		parent:insert( label )
		display.getCurrentStage():setFocus( label )

		label.isFocus = true
		label.isCorrect = false
		
		label.x0 = event.x - label.x
		label.y0 = event.y - label.y
		lineGroup = display.newGroup()
		backgroundLayer:insert(lineGroup)
		indexLine = 1
		planeToUse = label
		countryArrived = "none"
	elseif label.isFocus then
		if "moved" == phase then
			local line = display.newCircle(event.x, event.y, 5, 5);
			line:setFillColor( colorToUse.r,colorToUse.g, colorToUse.b );
			lineGroup:insert(line)
		elseif "ended" == phase or "cancelled" == phase then
			sound.play("pop")
			display.getCurrentStage():setFocus( nil )
			label.isFocus = false
			activePlanes = false
			local objPosX, objPosY = event.x, event.y
--			for counter = 1, countriesGroup.numChildren do
--				local posX, posY = countriesGroup[counter]:localToContent(0, 0)
--				local distanceToPointX, distanceToPointY = mAbs(objPosX - posX), mAbs(objPosY - posY)
--				if distanceToPointX < 30 and distanceToPointY < 30 then
--					countryArrived = countriesGroup[counter].name
--				end
--			end
--			print("you arrived to " .. countryArrived .. " number of points " .. lineGroup.numChildren)
			if lineGroup.numChildren > 1000 then
				countryArrived = "none"
			end
		    if countryArrived ~= "none" then
				if planeToUse.x < lineGroup[lineGroup.numChildren].x then
					planeToUse.xScale = mAbs(planeToUse.xScale)
					planeToUse.isLeft = true
				else
					planeToUse.isLeft = false
				end
				sound.play("airplane")
				flyPlane(1)
			else
				activePlanes = true
				display.remove(lineGroup)
			end
		end
	end		
	return true
end
local function createAnswers()
	tableToCheck = {}
	planesGroup = display.newGroup()
	answersLayer:insert(planesGroup)
	local pivot = 100
	local tempParts = extraTable.deepcopy(CONTINENTS)
	for counter = 1, NUMBEROFANSWERS do
		local plane = display.newImage(assetPath .. "nave.png")
		plane.index = counter
		plane.x, plane.y = flyBoard.x + pivot, flyBoard.y - 50
		plane.xScale, plane.yScale = -0.9, 0.9
		plane:addEventListener("touch",onTouched)
		pivot = pivot + 120
		planesGroup:insert(plane)
		local ind = mRandom(#tempParts)
		tableToCheck[counter] = tempParts[ind]
		table.remove(tempParts,ind)
	end
end
local function animateInstructions()
	departureGroup.alpha = 0
	instructionsGroup.alpha = 1
	transition.to(instructionsGroup, {alpha = 0, delay = 3000, onComplete = function()
		transition.to(departureGroup,{alpha = 1})
		activePlanes = true
	end})
end
local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	local operation = params.operation
	colorToUse = {r = 0, g = 0, b = 0}
	planeNumber = 1
	activePlanes = false
	lastPos = {x = 0, y = 0}
	isFirstTime = params.isFirstTime
	languageUsing = localization.getLanguage()
	manager = event.parent
	lockButtons = false
	correctAnswers = 0
	wrongAnswers = 0
	questionTime = 1
	bodyPartTapped = false
	createAnswers()
	animateInstructions()
	departureText.text = localization.getString("country" .. tableToCheck[planeNumber])
	instructions.text = localization.getString("geoAirport")
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
		local countryToShow = checkForCountry(tableToCheck[planeNumber])
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 3000, x = planesGroup[1].x, y = planesGroup[1].y, toX = countryToShow.x, toY = countryToShow.y },
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
	
	local backSea = display.newImage(assetPath .. "fondo.png")
	backSea.x, backSea.y = centerX, centerY
	backSea.width, backSea.height = screenWidth, screenHeight
	backgroundLayer:insert(backSea)
	
	local backMap = display.newImage(assetPath .. "mapamundi.png")
	backMap.x, backMap.y = centerX, centerY
	backgroundLayer:insert(backMap)
	
	flyBoard = display.newImage(assetPath .. "pista.png")
	flyBoard.anchorY, flyBoard.anchorX = 1 , 0
	flyBoard.x, flyBoard.y = screenRight - flyBoard.width, screenBottom
	backgroundLayer:insert(flyBoard)
	
	instructionsGroup = display.newGroup()
	backgroundLayer:insert(instructionsGroup)
	
	local instructionsBoard = display.newImage(assetPath .. "instruccion.png")
	instructionsBoard.anchorY = 0
	instructionsBoard.x, instructionsBoard.y = centerX, screenTop
	instructionsBoard.width = screenWidth
	instructionsGroup:insert(instructionsBoard)
	
	instructions = display.newText("", centerX, screenTop + 45,settings.fontName,30)
	instructions.anchorY = 1
	instructionsGroup:insert(instructions)
	
	departureGroup = display.newGroup()
	backgroundLayer:insert(departureGroup)
	
	departureBoard = display.newImage(assetPath .. "vuelos.png")
	departureBoard.anchorX = 0
	departureBoard.anchorY = 0
	departureBoard.x, departureBoard.y = screenRight - (departureBoard.width + 10), screenTop + 10
	departureGroup:insert(departureBoard)
	
	departureText = display.newText("Location",departureBoard.x + 130, departureBoard.y + 50, settings.fontName, 35)
	departureText.anchorX = 0
	departureGroup:insert(departureText)
	
	correctAnswer = display.newImage(assetPath .. "good.png")
	correctAnswer.alpha = 0
	answersLayer:insert(correctAnswer)
	
	wrongAnswer = display.newImage(assetPath .. "wrong.png")
	wrongAnswer.alpha = 0
	answersLayer:insert(wrongAnswer)
end
local function removeAnswers()
	display.remove(planesGroup)
end
function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
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
