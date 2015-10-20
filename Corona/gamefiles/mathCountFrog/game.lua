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

local game = director.newScene() 
----------------------------------------------- Variables - Variables are declared BUT not initialized
local answersLayer, wrongAnswersGroup,gameIsOver
local backgroundLayer, lastLeaf, lineGroup
local textLayer, instructions,leafsTapped
local manager,frogGroup,frogStanding,frogJumping,frogSplash,leafsGroup
local tapsEnabled,tapOrder
local isFirstTime,leafPositionsToUse
local gameTutorial,orderTable
----------------------------------------------- Constants
local OFFSET_TEXT = {x = 0, y = -200}
local SIZE_FONT = 40

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

local NUMBEROFANSWERS = 9
local POSITIONOPTIONS = {
	[1] = {1,2,3,4,5,6,7,8,9},
	[2] = {1,4,3,5,2,9,8,6,7},
	[3] = {1,3,2,5,9,8,7,4,6},
	[4] = {1,2,9,4,8,7,6,3,5},
	[5] = {1,5,4,9,2,3,8,6,7},
	[6] = {1,6,5,4,2,3,9,7,8},
	[7] = {1,4,3,8,2,9,7,5,6},
	[8] = {1,3,2,5,6,7,8,4,9},
	[9] = {1,7,8,9,2,3,4,6,5},
}

local LEAFPOSITIONS = {
	[1] = {x = screenLeft + 200, y = screenBottom - 150},
	[2] = {x = centerX + 100, y = screenBottom - 100},
	[3] = {x = centerX - 120, y = screenBottom - 200},
	[4] = {x = centerX + 50, y = centerY + 60},
	[5] = {x = screenLeft + 200, y = centerY},
	[6] = {x = centerX - 100, y = centerY - 50},
	[7] = {x = centerX + 200, y = centerY - 40},
	[8] = {x = screenRight - 220, y = centerY + 200},
	[9] = {x = screenRight - 180, y = centerY + 50},
}
----------------------------------------------- Functions - Local functions ONLY.
--
local function changeFrogState(standing,jumping,splash)
	frogStanding.alpha = standing
	frogJumping.alpha = jumping
	frogSplash.alpha = splash
end
local function checkOrder(counter)
	gameIsOver = true
	if counter > 1 then
		timer.performWithDelay(300,function()
			sound.play("dragtrash")
		end)
	end
	local checkingNumber = counter + 1
	changeFrogState(1,0,0)
	timer.performWithDelay(300, function()
		sound.play("dragUnit")
		changeFrogState(0,1,0)
		transition.to(frogGroup,{y = leafsTapped[checkingNumber].y - 300, time = 500, transition=easing.outQuad})
		transition.to(frogGroup,{y = leafsTapped[checkingNumber].y - 70, time = 500, delay = 500, transition=easing.inQuad})
		transition.to(frogGroup,{x = leafsTapped[checkingNumber].x, transition=easing.outSine, time = 800, onComplete = function()
			if (checkingNumber) == tonumber(orderTable[counter]) then
				counter = counter + 1
				if counter < NUMBEROFANSWERS then
					changeFrogState(1,0,0)
					timer.performWithDelay(400,checkOrder(counter))
				else
					changeFrogState(1,0,0)
					manager.correct()
				end
			else
				sound.play("waterBigImpact")
				changeFrogState(0,0,1)
				local answerString = table.concat(POSITIONOPTIONS[1], ", ")
				manager.wrong({id = "text", text = answerString, fontSize = 40})
			end
		end})
	end)
end
local function leafTapped(event)
	if gameIsOver then
		return
	end
	local phase = event.phase
	local posX,posY = event.x, event.y
	local objTapped = event.target
	if objTapped.isTapped then
		if objTapped.tapOrder == (tapOrder-2) then
			transition.to(leafsTapped[tapOrder],{r = 1, g = 1, b = 1})
			leafsTapped[tapOrder].isTapped = false
			display.remove(lineGroup[tapOrder-1])
			lastLeaf = { x = leafsTapped[tapOrder-1].x, y = leafsTapped[tapOrder-1].y}
			tapOrder = tapOrder - 1
			table.remove(orderTable)
			table.remove(leafsTapped)
		end
		return
	end
	objTapped.tapOrder = tapOrder
	tapOrder = tapOrder + 1
	leafsTapped[tapOrder] = objTapped
	colors.addColorTransition(objTapped)
	objTapped.isTapped = true
	transition.to(objTapped,{r = 0.6, g = 0.6, b = 0.5})
	local line = display.newLine( lastLeaf.x, lastLeaf.y, objTapped.x, objTapped.y)
	lineGroup:insert(line)
	lastLeaf = { x = objTapped.x, y = objTapped.y}
	line:setStrokeColor( mRandom(255)/255, mRandom(255)/255, mRandom(255)/255, 1 )
	line.strokeWidth = 15
	local numTap = objTapped.index
	table.insert(orderTable,numTap)
	sound.play("pop")
	if tapOrder ==  NUMBEROFANSWERS then
		checkOrder(1)
	end
	if phase == "began" then
		
	elseif phase == "moved" then
			
	elseif phase == "ended" or phase == "cancelled" then
		if objTapped.isReady then
			
		end
	end
end
local function createDynamicAnswers()
	
	leafsTapped = {}
	
	lineGroup = display.newGroup()
	backgroundLayer:insert(lineGroup)
	
	display.remove(leafsGroup)
	leafsGroup = nil
	leafsGroup = display.newGroup()
	local indexx = mRandom(#POSITIONOPTIONS)
	for counter = 1, NUMBEROFANSWERS do
		local leaf = display.newImage(assetPath .. "hoja.png")
		leaf.xScale = 0.8
		leaf.yScale = 0.8
		if counter == 1 then
			leaf.x = LEAFPOSITIONS[1].x
			leaf.y = LEAFPOSITIONS[1].y
			leaf.index = 1
			leaf.isTapped = true
			leaf.tapOrder = 0
			leafsTapped[1] = leaf
		else
			leaf.index = POSITIONOPTIONS[indexx][counter]
			leaf.counter = counter
			leaf.x = LEAFPOSITIONS[counter].x
			leaf.y = LEAFPOSITIONS[counter].y
			leafPositionsToUse[leaf.index] = LEAFPOSITIONS[counter]
		end
		leaf:addEventListener("touch",leafTapped)
		local leafText = display.newText(leaf.index,leaf.x, leaf.y, settings.fontName, 34)
		leafsGroup:insert(leaf)
		leafsGroup:insert(leafText)
	end
	backgroundLayer:insert(leafsGroup)
end

local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	gameIsOver = false
	isFirstTime = params.isFirstTime
	manager = event.parent
	tapOrder = 1
	orderTable = {}
	changeFrogState(1,0,0)
	frogGroup.x = screenLeft + 200
	frogGroup.y = screenBottom - 200
	leafPositionsToUse = {}
	createDynamicAnswers() 
	lastLeaf = { x = LEAFPOSITIONS[1].x, y = LEAFPOSITIONS[1].y}
	instructions.text = localization.getString("mathCountFrogMinigame")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 1500, x = LEAFPOSITIONS[1].x, y = LEAFPOSITIONS[1].y, toX = leafPositionsToUse[2].x, toY = leafPositionsToUse[2].y},
				[2] = {id = "drag", delay = 500, time = 1500, x = leafPositionsToUse[2].x, y = leafPositionsToUse[2].y, toX = leafPositionsToUse[3].x, toY = leafPositionsToUse[3].y},
				[3] = {id = "drag", delay = 500, time = 1500, x = leafPositionsToUse[3].x, y = leafPositionsToUse[3].y, toX = leafPositionsToUse[4].x, toY = leafPositionsToUse[4].y},
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
		
		name = "Math Count Frog", -- Reference name, server purposes
		category = "math", -- Category/Subject
		subcategories = {"counting"}, -- available subcategories
		age = {min = 0, max = 99}, -- Minimum and max age for this game
		grade = {min = 0, max = 99}, -- Min and max grade for this game
		gamemode = "findAnswer", -- Gamemode (How the game is played)
		requires = { -- What the game needs from the manager. We dont need anything here for this minigame
			
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
	
	local background = display.newImage( assetPath .. "fondo.png")
	background.x = centerX
	background.y = centerY
	background.width = screenWidth
	background.height = screenHeight
	backgroundLayer:insert(background)
	
	frogGroup = display.newGroup()
	sceneView:insert(frogGroup)
	
	frogStanding = display.newImage(assetPath .. "rana.png")
	frogGroup:insert(frogStanding)
	
	frogJumping = display.newImage(assetPath .. "rana2.png")
	frogGroup:insert(frogJumping)
	
	frogSplash = display.newImage(assetPath .. "rana3.png")
	frogGroup:insert(frogSplash)
	
	-- Instructions are text. Will always be present
	-- We dont need text here, we will set it depending on language.
	local textData = {
		text = "",
		width = 550,
		font = "VAGRounded",   
		fontSize = 26,
		align = "center",
		x = centerX,
		y = screenTop + 70,
	}
	instructions = display.newText(textData)
	instructions:setFillColor(15/255,73/255,130/255)
	textLayer:insert(instructions)
	
end
local function removeDynamicAnswers()
	display.remove(lineGroup)
	for counter = 1, #leafsGroup do
		leafsGroup[counter]:removeEventListener("touch",leafTapped)
	end
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
		removeDynamicAnswers()
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
