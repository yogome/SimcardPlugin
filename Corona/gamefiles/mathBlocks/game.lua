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
local answersLayer, canonGun, canonBullet,answersCorrect, gameEnded
local backgroundLayer,gameGroup, operations, timerReference
local textLayer, instructions,shield, widthToUse, rectText
local manager,answers, questionGroup,questionIndex
local tapsEnabled,initialTouchPos, patternRecognizer
local isFirstTime, positionToLose
local gameTutorial,lockButtons,pieceBackScale
----------------------------------------------- Constants 

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
local NUMBEROFCOLUMNS = 6
local TIMEDOWN = 4000
----------------------------------------------- Functions - Local functions ONLY.
local function shootToTarget(objToShoot)
	local objX,objY = objToShoot:localToContent(0, 0)
	local hipotenusa= math.sqrt((math.pow((objX - canonGun.x),2)) + (math.pow((objY - canonGun.y),2)))
	local catetoAdyacente =  objX - canonGun.x
	local grados = math.acos(catetoAdyacente/hipotenusa)
	director.to(scenePath, canonGun, {rotation = -(math.deg(grados) - 90), time = 100, transition = easing.inOutCubic, onComplete = function()
		transition.to(canonGun,{xScale = 1.2, yScale = 1.2, time = 200})
		transition.to(canonGun,{xScale = 1, yScale = 1, time = 400, delay = 200})
		sound.play("shootBall")
		canonBullet.alpha = 1
		transition.to(canonBullet,{x = objX, y = objY, onComplete = function()
			sound.play("ballImpact")
			canonBullet.alpha = 0
			canonBullet.x,canonBullet.y = canonGun.x,canonGun.y
		end})
		transition.to(gameGroup[#answers],{delay = 500, alpha = 0})
		table.remove(answers)
	end})
end
local function gameDown()
	if gameEnded then
		return
	end
	transition.to(gameGroup, { y = gameGroup.y + (widthToUse - 4), tag = "gameDown"})
	timerReference = timer.performWithDelay(TIMEDOWN,gameDown)
--	print(gameGroup.y .. " position group" .. positionToLose)
	if gameGroup.y >= positionToLose then
		local answerString
		answerString = table.concat(answers, ", ")
		manager.wrong({id = "text", text = answerString, fontSize = 70})
		gameEnded = true
	end
end

local function checkFormAnswer(value)
--	print( value .. " valor " .. answers[#answers] .. " respuesta")
	if value == answers[#answers] then
		shootToTarget(questionGroup[questionIndex])
		questionIndex =  questionIndex - 1
		answersCorrect = answersCorrect + 1
		positionToLose = positionToLose + (widthToUse + 30)
	else
		transition.cancel("gameDown")
		sound.play("wrongChoice")
		timer.cancel(timerReference)
		gameDown()
	end
	if answersCorrect >= 3 then
		gameEnded = true
		manager.correct()
	end
end
local function insertPatterns()
	
	local patterns = require("libs.helpers.patterns")
	
	patternRecognizer = patterns.newRecognizer({
	width = 300,
	height = 300,
	onComplete = function(event)
		checkFormAnswer(event.value)
	end,})
	patternRecognizer.x = centerX
	patternRecognizer.y = centerY
	patternRecognizer.alpha = 0.5
	answersLayer:insert(patternRecognizer)
end
local function checkAnswer(count,randIndex,value)
	if count == randIndex then
		table.insert(answers,value)
	end
end
local function createDynamicAnswers()
	questionGroup = {}
	for counter = 1, NUMBEROFCOLUMNS do
		local questionIndex = 4
		while questionIndex == 4 or questionIndex == 2 do
			questionIndex = mRandom(5)
		end
		if gameGroup[counter].alpha == 0 then
			gameGroup[counter].alpha = 1
		end
		for count = 1, 5 do
			if count == questionIndex then
				local questionBox = display.newImage(assetPath .. "b2.png")
				gameGroup[counter][count]:insert(questionBox)
				table.insert(questionGroup,questionBox)
			end
			if count == 1 then
				gameGroup[counter][count][2].text = operations[counter].operands[1]
				checkAnswer(count,questionIndex,operations[counter].operands[1])
			elseif count == 2 then
				gameGroup[counter][count][2].text = operations[counter].operator
				checkAnswer(count,questionIndex,operations[counter].operator)
			elseif count == 3 then
				gameGroup[counter][count][2].text = operations[counter].operands[2]
				checkAnswer(count,questionIndex, operations[counter].operands[2])
			elseif count == 4 then
				gameGroup[counter][count][2].text = "="
			elseif count == 5 then
				gameGroup[counter][count][2].text = operations[counter].result
				checkAnswer(count,questionIndex, operations[counter].result)
			end
		end
	end
end

local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	operations = params.operations
	isFirstTime = params.isFirstTime
	manager = event.parent
	lockButtons = false
	pieceBackScale = 0.7
	textLayer.alpha = 1
	canonBullet.alpha = 0
	initialTouchPos = 0
	canonGun.rotation = 0
	insertPatterns()
	gameEnded = false
	answersLayer.alpha = 1
	answersCorrect = 0
	answers = {}
	positionToLose = -190
	createDynamicAnswers()
	local screenSize = screenWidth / screenHeight
	if screenSize >= 1.5 then
		gameGroup.y = - screenHeight * .947
	else
		gameGroup.y = - screenHeight * .845
	end
	questionIndex = #questionGroup
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("mathBlocks")
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
	for counter = 1, #questionGroup do
		display.remove(questionGroup[counter])
	end
end
local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		gameGroup[6][1][2].text = 3
		gameGroup[6][2][2].text = "-"
		gameGroup[6][3][2].text = 2
		gameGroup[6][5][2].text = 1
		answers[#answers] = 1
		display.remove(questionGroup[#questionGroup])
		local questionBox = display.newImage(assetPath .. "b2.png")
		gameGroup[6][5]:insert(questionBox)
		questionGroup[#questionGroup] = questionBox
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 500, time = 3000, x = centerX, y = centerY - 100, toX = centerX, toY = centerY + 100},
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
			{id = "operation", operands = 2, maxAnswer = 9, minAnswer = 0, maxOperand = 9, minOperand = 1, amount = 6},
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
	
	local background = display.newRect(centerX,centerY,screenWidth,screenHeight)
	background:setFillColor(39/255,204/255,204/255)
	backgroundLayer:insert(background)
	
	local backCity = display.newImage(assetPath .. "ciudad.png")
	backCity.x, backCity.y = centerX, screenBottom
	backCity.width = screenWidth * 0.7
	backCity.anchorY = 1
	backgroundLayer:insert(backCity)
	
	gameGroup = display.newGroup()
	local dummieRect = display.newImage(assetPath .. "b1.png")
	widthToUse = dummieRect.width
	display.remove(dummieRect)
	gameGroup.x, gameGroup.y = centerX - (widthToUse * 2), screenTop + 30
	local offsetY = - (widthToUse - 4)
	for counter = 1, NUMBEROFCOLUMNS do
		local group = display.newGroup()
		local offsetX = 0
		offsetY = offsetY + 124
		group.x, group.y= group.x, offsetY
		for count = 1, 5 do
			local index = 1
			if count == 4 then
				index = 3
			end
			local rectGroup = display.newGroup()
			rectGroup.x = rectGroup.x + offsetX
			local rect = display.newImage(assetPath .. "b".. index .. ".png")
			local recText = display.newText("1",0,0,settings.fontName, 40)
			rectGroup:insert(rect)
			rectGroup:insert(recText)
			offsetX = offsetX + (widthToUse - 4)
			group:insert(rectGroup)
		end
		gameGroup:insert(group)
	end
	backgroundLayer:insert(gameGroup)
	
	local wallLeft = display.newImage(assetPath .. "muros.png")
	wallLeft.x, wallLeft.y = centerX - 317, centerY
	wallLeft.anchorX = 1
	wallLeft.width = screenWidth * 0.27
	wallLeft.height = screenHeight + 30
	backgroundLayer:insert(wallLeft)
	
	local wallRight = display.newImage(assetPath .. "muros.png")
	wallRight.x, wallRight.y = centerX + 303, centerY
	wallRight.anchorX = 0
	wallRight.width = screenWidth * 0.27
	wallRight.height = screenHeight + 30
	backgroundLayer:insert(wallRight)
	
	local textData = {
		text = "",
		width = 300,
		font = "VAGRounded",   
		fontSize = 30,
		align = "center",
		x = centerX,
		y = centerY ,
	}
	
	rectText = display.newRoundedRect(centerX, centerY, 400, 230,30)
	rectText:setFillColor(0)
	rectText.alpha = 0.3
	textLayer:insert(rectText)
	
	instructions = display.newText(textData)
	instructions:setFillColor(1)
	textLayer:insert(instructions)
	
	local canon = display.newImage(assetPath .. "basecanon.png")
	canon.x, canon.y = centerX, screenBottom
	canon.anchorY = 1
	backgroundLayer:insert(canon)
	
	canonGun = display.newImage(assetPath .. "disparador.png")
	canonGun.x, canonGun.y = canon.x, canon.y + 10
	canonGun.anchorY = 1
	backgroundLayer:insert(canonGun)

	canonBullet = display.newImage(assetPath .. "bola.png")
	canonBullet.x, canonBullet.y = canon.x , canon.y
	canonBullet.xScale, canonBullet.yScale = 0.3, 0.3
	backgroundLayer:insert(canonBullet)

end

function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
		initialize(event)
		timer.performWithDelay(3000,tutorial) -- We always call the tutorial. Whether or not it is drawn depends on the function inside, not outside
	elseif phase == "did" then -- Start music, start game, enable control
		enableButtons()
		transition.to(textLayer,{alpha = 0, delay = 3000, onComplete = function()
			gameDown()
		end})
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
