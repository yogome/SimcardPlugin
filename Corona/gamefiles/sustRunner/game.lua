--------------------------------------------------- Runner
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )
local physics = require( "physics" )
local extratable = require("libs.helpers.extratable")
local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
-------------------------------------
local backgroundGroup, characterGroup, layerGroups, effectsGroup, topItemsGroup, descriptionText, scoreGroup
local backgroundA1, backgroundA2, backgroundB1, backgroundB2
local player, playerBody
local enemyArray, channelFree, explosionArray
local gameStarted, gameEnded
local currentLoop, checkCollisions
local touchFirstY, currentChannel
local requiredItemType
local correctItemsCollected
local informationText, recycleItems
local animatedRecycled
local gameTimer, gameTimerUpdate
local textTotalScore
local timerRunnerGroup, itemsGroup
local gameTutorial
local isFirstTime
local correctAnswers
local manager
-------------------------------------
local channels = 3
local halfViewX = display.viewableContentWidth * 0.5
local halfViewY = display.viewableContentHeight * 0.5
local centerX = display.contentWidth * 0.5
local centerY = display.contentHeight * 0.5
local leftX = centerX - halfViewX
local rightX = centerX + halfViewX
local bottomY = centerY + halfViewY
local topY = centerY - halfViewY
local backgroundSize = 1024
local backgroundScale = (halfViewX * 2) / backgroundSize
local playHeightStart = centerY + 5 * backgroundScale
local totalPlayHeight = bottomY - playHeightStart - 20
local channels = 3
local channelSpace = totalPlayHeight/channels

local startingX =  display.screenOriginX + 100

local scene = director.newScene()

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = scene.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2000, x = startingX, y = centerY, toX = startingX, toY = playHeightStart + (channelSpace*0.5 + (channelSpace * 1) * backgroundScale)},
				[2] = {id = "drag", delay = 1000, time = 2000, x = startingX, y = centerY, toX = startingX, toY = playHeightStart + (channelSpace*0.5 + (channelSpace * 2) * backgroundScale)},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function createGameTimer( time ) -- Returns a timer set to the time. NOTE: update must be called on a loop for it to work!
	time = time or 30
	
	display.remove(timerRunnerGroup)
	timerRunnerGroup = display.newGroup()
	timerRunnerGroup.xScale = 1
	timerRunnerGroup.yScale = 1
	timerRunnerGroup.currentTime = time or 1

	local timerRunnerText = display.newText(timerRunnerGroup.currentTime, 0, 0, settings.fontName, 40)
	timerRunnerText:setTextColor(255, 255, 255)
	timerRunnerText.x = 0
	timerRunnerText.y = 0
	timerRunnerGroup:insert(timerRunnerText)
	
	local currentFrame = 0
	timerRunnerGroup.timerEnded = false
	
	function timerRunnerGroup:reset( newTime )
		timerRunnerGroup.currentTime = newTime or 1
		timerRunnerText.text = timerRunnerGroup.currentTime
		timerRunnerGroup.timerEnded = false
	end
	
	function timerRunnerGroup:update()
		if timerRunnerGroup.timerEnded == false then
			currentFrame = currentFrame + 1
			if currentFrame % 60 == 0 then
				timerRunnerGroup.currentTime = timerRunnerGroup.currentTime - 1
				if timerRunnerGroup.currentTime>-1 then
					timerRunnerText.text = timerRunnerGroup.currentTime
				else
					timerRunnerGroup.timerEnded = true
				end
			end
		end
	end

	return timerRunnerGroup
end

local function createPlayer()
	
	local playerData = { width=256, height=256, numFrames=4 }
	local playerSheet = graphics.newImageSheet( assetPath .. "player.png", playerData )
	local playerSequenceData = {
		{ name="walk", sheet = playerSheet, start=1, count=4, time=500, loopCount=0 },
	}

	player = display.newSprite( playerSheet, playerSequenceData )
	player.x = startingX
	player.y = centerY
	player.xScale = 0.6
	player.yScale = 0.6
	player:setSequence( "walk" )
	player:play()
	effectsGroup:insert(player)
	player.targetX = player.x
	player.targetY = player.y
	player.targetChannelIndex = 1
	characterGroup:insert(player)
	player.coolDown = 0
	
	playerBody = display.newGroup()
	playerBody.x = player.x
	playerBody.y = player.y
	playerBody.name = "player"

	Runtime:addEventListener("enterFrame", player)
end

local function createBackgrounds()
	
	backgroundA1 = display.newImageRect( assetPath .. "background1.png", backgroundSize, 512)
	backgroundA1.x = centerX
	backgroundA1.y = centerY - 128 * backgroundScale
	backgroundA1.xScale = backgroundScale
	backgroundA1.yScale = backgroundScale
	backgroundGroup:insert(backgroundA1)	

	backgroundA2 = display.newImageRect( assetPath .. "background2.png", backgroundSize, 512)
	backgroundA2.x = rightX + halfViewX
	backgroundA2.y = centerY - 128 * backgroundScale
	backgroundA2.xScale = -backgroundScale
	backgroundA2.yScale = backgroundScale
	backgroundGroup:insert(backgroundA2)	
	
	backgroundB1 = display.newImageRect( assetPath .. "frontground.png", backgroundSize, backgroundSize)
	backgroundB1.x = centerX
	backgroundB1.y = centerY
	backgroundB1.xScale = backgroundScale
	backgroundB1.yScale = backgroundScale
	backgroundGroup:insert(backgroundB1)
	
	backgroundB2 = display.newImageRect( assetPath .. "frontground.png", backgroundSize, backgroundSize)
	backgroundB2.x = rightX + halfViewX
	backgroundB2.y = centerY
	backgroundB2.xScale = backgroundScale
	backgroundB2.yScale = backgroundScale
	backgroundGroup:insert(backgroundB2)	

end

local function createCharacterLayers()
	layerGroups = {}
	for index = 1, channels do
		local groupLayer = display.newGroup()
		groupLayer.x = 0
		groupLayer.y = 0
		layerGroups[index] = groupLayer
		characterGroup:insert(groupLayer)
	end
end

local function scoreText(initialScore)
	display.remove(textTotalScore)
	textTotalScore = display.newText(initialScore, centerX, centerY * 0.55, settings.fontName, 30)
	return textTotalScore
end

function scene:create( event )
	local mainScene = self.view
	
	backgroundGroup = display.newGroup()
	mainScene:insert(backgroundGroup)
	
	characterGroup = display.newGroup()
	mainScene:insert(characterGroup)
	
	effectsGroup = display.newGroup()
	mainScene:insert(effectsGroup)
	
	topItemsGroup = display.newGroup()
	mainScene:insert(topItemsGroup)
	
	descriptionText = display.newGroup()
	mainScene:insert(descriptionText)
	
	createCharacterLayers()
	createBackgrounds()
	createPlayer()
end

local function updateMovement()
	local distanceX = player.targetX - player.x
	local distanceY = player.targetY - player.y
	
	player.x = player.x + (distanceX * 0.2)
	player.y = player.y + (distanceY * 0.2)
	
	if math.abs(distanceY) < 10 then
		player.parent:remove(player)
		layerGroups[player.targetChannelIndex]:insert(player)
	end
	local targetRotation = 0 + (distanceY * 0.2)
	local distanceRotation = targetRotation - player.rotation
	player.rotation = player.rotation + (distanceRotation * 0.1)
	
	playerBody.x = player.x
	playerBody.y = player.y
	
end

local function createItem(owner, itemType)
	
	local itemNumber = math.random(1,5)
	local item = display.newImage( assetPath .. "items/item"..itemType.."_"..itemNumber..".png" )
	item.x = 5
	item.y = -40
	item.xScale = 0.3
	item.yScale = 0.3
	item.type = itemType
	owner:insert(item)
	owner.item = item
	owner.itemNumber = itemNumber
	owner.hasItem = true
end

local function createEnemy( channel)
	local itemType = math.random (1,50)
	if itemType < 20 then
		itemType = requiredItemType
	else
		itemType = math.random (1,5)
	end
	
	local enemy = display.newGroup()
	enemy.x = rightX + 50
	enemy.y = playHeightStart + (channelSpace*0.5 + (channelSpace * (channel - 1)) * backgroundScale)
	enemy.collided = false
	layerGroups[channel]:insert(enemy)
	
	local enemyData = { width=256, height=256, numFrames=4 }
	local enemySheet1 = graphics.newImageSheet( assetPath .. "enemyAnim.png", enemyData )
	local enemySequenceData = {
		{ name="walk", sheet=enemySheet1, start=1, count=4, time=300, loopCount=0 },
	}

	local enemySprite = display.newSprite( enemySheet1, enemySequenceData )
	enemySprite.x = 0
	enemySprite.y = 0
	enemySprite.xScale = 0.4
	enemySprite.yScale = 0.4
	enemySprite:setSequence( "walk" )
	enemySprite:play()
	enemy.name = 'enemy'
	enemy:insert(enemySprite)
	physics.addBody( enemy, "dynamic", { density = 1, bounce = 0.5, friction = 0.5, radius = 25} )
	
	director.to(scenePath, enemy, {time = 5000, x = leftX - 100, onComplete = function()
		enemy.remove = true
	end})
	enemy.itemType = itemType
	createItem(enemy, itemType)
	table.insert(enemyArray, enemy)
end

local function scrollBackground()
	
	backgroundA1.x = backgroundA1.x - 2
	backgroundA2.x = backgroundA2.x - 2
	
	local leftBoundary = leftX - halfViewX
	if backgroundA1.x < leftBoundary then
		local remaining = backgroundA1.x - leftBoundary
		backgroundA1.x = rightX + halfViewX + remaining
	end
	
	if backgroundA2.x < leftBoundary then
		local remaining = backgroundA2.x - leftBoundary
		backgroundA2.x = rightX + halfViewX + remaining
	end
	
	backgroundB1.x = backgroundB1.x - 4
	backgroundB2.x = backgroundB2.x - 4
	
	if backgroundB1.x < leftBoundary then
		local remaining = backgroundB1.x - leftBoundary
		backgroundB1.x = rightX + halfViewX + remaining
	end
	
	if backgroundB2.x < leftBoundary then
		local remaining = backgroundB2.x - leftBoundary
		backgroundB2.x = rightX + halfViewX + remaining
	end
end

local function endGame()
	if correctItemsCollected < 5 then
		manager.wrong({id = "group", group = correctAnswers})
	else
		manager.correct()
	end
end

local function onFrameUpdate(event)
	scrollBackground()
	updateMovement()
	if gameEnded ~= true and gameStarted == true then
		currentLoop = currentLoop + 1
		
		--Extras timer handling
		if gameTimerUpdate == true then
			gameTimer:update()
			if gameTimer.timerEnded == true then
				gameEnded = true
				endGame()
			end
		end
	
		for index = 1, #channelFree do
			if channelFree[index] > 0 then
				channelFree[index] = channelFree[index] - 1
			end
		end
		
		-- Dynamic enemy creation
		if currentLoop % 60 == 0 then
			local randomChannel
			local isChannelFree = false
			local currentTries = 0
			repeat
				currentTries = currentTries + 1
				randomChannel = math.random(1, channels)
			until channelFree[randomChannel] <= 0 or currentTries > 15
			
			if currentTries <= 15 then
				channelFree[randomChannel] = 60
				createEnemy(randomChannel)
			end
		end

		if currentLoop % 2 == 0 then
			for index = #enemyArray,1,-1 do -- Inverse for loop to avoid nil objects
				local enemy = enemyArray[index]
				if enemy.remove == true then
					physics.removeBody(enemy)
					display.remove(enemy)
					table.remove(enemyArray, index)
				end
			end
		end	
	end
end

local function changeChannel(channelIndex)
	currentChannel = channelIndex
	if currentChannel < 1 then currentChannel = 1 end
	if currentChannel > channels then currentChannel = channels end
	sound.play("cut")
	player.targetChannelIndex = currentChannel

	player.targetY = playHeightStart + (channelSpace*0.5 + (channelSpace * (currentChannel - 1)) * backgroundScale)
end

local function swipe(event)
	if gameStarted == true and gameEnded ~= true then
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			touchFirstY = event.y
		elseif event.phase == "ended" then
			if event.y > touchFirstY then
				changeChannel(currentChannel+1)
			elseif event.y < touchFirstY then
				changeChannel(currentChannel-1)
			end
		end
	end
end

local function getExplosion(positionX, positionY)
	local explosionAvailable = false
	local availableIndex = #explosionArray + 1
	for index = 1, #explosionArray do
		if explosionArray[index].isVisible == false then
			explosionAvailable = true
			availableIndex = index
		end
	end
	
	if explosionAvailable == false then
		local explosionData = { width = 128, height = 128, numFrames = 16 }
		local explosionSheet = graphics.newImageSheet( assetPath .. "explosion.png", explosionData )
			
		local explosionSequenceData = {
			{ name="explosion", sheet = explosionSheet, start = 1, count = 16, time = 400, loopCount = 1 },
		}
		
		local explosion = display.newSprite( explosionSheet, explosionSequenceData )
		explosion.x = positionX
		explosion.y = positionY
		explosion.xScale = 1
		explosion.yScale = 1
		
		explosion:setSequence("explosion")
		explosion:play()
		
		effectsGroup:insert(explosion)
		explosionArray[availableIndex] = explosion
	else
		local explosion = explosionArray[availableIndex]
		explosion.x = positionX
		explosion.y = positionY
		explosion.isVisible = true
		
		explosion:setSequence("explosion")
		explosion:play()
		
		director.performWithDelay(scenePath,  400, function()
			explosion.isVisible = false
		end)
	end
	sound.play("wrongAnswer")
end

local function checkPlayerCollision(assumedPlayer, object)
	if assumedPlayer.name == "player" then
		if object.name == "enemy" then
			if object.collided ~= true then
				object.collided = true
				display.remove(object.item)
				if object.itemType == requiredItemType then
					correctItemsCollected = correctItemsCollected + 1
					sound.play("correctAnswer")
					director.to(scenePath, animatedRecycled[object.itemNumber], { alpha = 1, time = 200, xScale = 0.5, yScale = 0.5, onComplete = function()
							animatedRecycled[object.itemNumber].alpha = 0
							animatedRecycled[object.itemNumber]:scale(2,2)
					end})
				else
					getExplosion(object.x, object.y)
					if correctItemsCollected > 0 then
						correctItemsCollected = correctItemsCollected - 1
					end
				end
				scoreGroup.text = correctItemsCollected
			end
		end
	end
end


local function onCollision( event )
	if checkCollisions == true then
		local object1 = event.object1
		local object2 = event.object2

		checkPlayerCollision(object1, object2)
		checkPlayerCollision(object1, object2)
	end
end

local function getRecycleString(number)
	local translatorText
	if number == 1 then
		translatorText = localization.getString("instructionsRunnerRecyclePlastic")
	elseif number == 2 then
		translatorText = localization.getString("instructionsRunnerRecycleGlass")
	elseif number == 3 then
		translatorText = localization.getString("instructionsRunnerRecyclePaper")
	elseif number == 4 then
		translatorText = localization.getString("instructionsRunnerRecycleMetal")
	elseif number == 5 then
		translatorText = localization.getString("instructionsRunnerRecycleOrganic")
	end
	return translatorText

end

local function createRequiredItem(item)
	
	display.remove(itemsGroup)
	itemsGroup = display.newGroup()
	
	local textString = getRecycleString(item)
	display.remove(informationText)
	informationText = display.newText(localization.getString("instructionsRunnerRecycle") .. " " .. textString,  display.contentCenterX, display.viewableContentHeight * 0.10, settings.fontName, 50)
	informationText:setFillColor(46/255, 37/255, 135/255)
	descriptionText:insert(informationText)

	local distanceX = 0
	local distanceStep = 10
	for indexAssets = 1, 5 do
		local item = display.newImage( assetPath .. "items/item" ..item.."_"..indexAssets..".png" )
		item:scale(0.5, 0.5)
		item.x = distanceX
		itemsGroup:insert(item)
		distanceX = distanceX + (item.width * 0.5) + distanceStep
		recycleItems[indexAssets] = item
	end
	
	correctAnswers = itemsGroup
	
	local distanceX = 0
	local distanceStep = 10
	for indexAssets = 1, 5 do
		local item = display.newImage( assetPath .. "items/item" ..item.."_"..indexAssets..".png" )
		item:scale(1, 1)
		item.x = distanceX
		itemsGroup:insert(item)
		distanceX = distanceX + (item.width * 0.5) + distanceStep
		item.alpha = 0
		animatedRecycled[indexAssets] = item
	end
	
	itemsGroup.anchorChildren = true
	itemsGroup.anchorX = 0.5
	itemsGroup.alpha = 0.75
	itemsGroup.y = display.viewableContentHeight * 0.20
	itemsGroup.x = centerX
	
	return itemsGroup
	
end

local function initialize(parameters )
	parameters = parameters or {}
	isFirstTime = parameters.isFirstTime
end

function scene.getInfo()
	return {
		available = true,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Trash runner",
		category = "sustainability",
		subcategories = {"recycle"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "classify",
		requires = {
			{id = "trash", amount = 30, groups = 4},
		},
	}
end 

function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		touchFirstY = 0
		enemyArray = {}
		recycleItems = {}
		animatedRecycled = {}
		channelFree = {}
		explosionArray = { }
		for index = 1, channels do
			channelFree[index] = 0 -- 0 means it is free
		end
		
		manager = event.parent

		-- Variable reseting
		checkCollisions = false
		gameTimerUpdate = false
		gameStarted = false
		gameEnded = false
		currentLoop = 0
		correctItemsCollected = 0
		changeChannel(1)

		scoreGroup = scoreText(0)
		sceneGroup:insert(scoreGroup)
		
		gameTimer = createGameTimer(0)
		sceneGroup:insert(gameTimer)
		
		requiredItemType = math.random(1,5)
		local items = createRequiredItem(requiredItemType)
		
		sceneGroup:insert(items)
		
		gameTimer:reset(30) -- Resets timer with 30 seconds.
		
		physics.start()
		physics.setGravity( 0, 0 )

		player.x = startingX
		player.y = centerY
		player.coolDown = 0
		physics.addBody( playerBody, "dynamic", {density = 1, bounce = 0.5, friction = 0.5, radius = 20, isSensor = true} )
		
		gameTimer.x = centerX
		gameTimer.y = display.viewableContentHeight * 0.04
		gameTimerUpdate = true
		gameStarted = true
		checkCollisions = true
		
		Runtime:addEventListener ("enterFrame", onFrameUpdate)
		Runtime:addEventListener ("touch", swipe)
		Runtime:addEventListener( "collision", onCollision )
		initialize(event.params )
		showTutorial()
	elseif ( phase == "did" ) then

	end
end

function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		Runtime:removeEventListener ("enterFrame", onFrameUpdate)
		Runtime:removeEventListener ("touch", swipe)
		Runtime:removeEventListener( "collision", onCollision )
		physics.removeBody(playerBody)
		for index = #enemyArray,1,-1 do
			local enemy = enemyArray[index]
			display.remove(enemy)
			table.remove(enemyArray, index)
		end	
		
		physics.stop()

	end
end

function scene:destroy( event )

	local sceneGroup = self.view

end


-- -------------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -------------------------------------------------------------------------------

return scene