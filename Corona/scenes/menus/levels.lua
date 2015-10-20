----------------------------------------------- Levels
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local sound = require( "libs.helpers.sound" )
local players = require( "models.players" )
local robot = require( "libs.helpers.robot" )
local database = require( "libs.helpers.database" )
local settings = require("settings")
local worldsData = require( "data.worldsdata" )
local extramath = require( "libs.helpers.extramath" )
local music = require( "libs.helpers.music" )
local spine = require( "spine_temp.spine" )
local herolist = require( "data.herolist" )
local hatlist = require( "data.hatlist" )
local sceneList = require( "data.scenelist" )
local eventCounter = require( "libs.helpers.eventcounter" )
local unitFactory = require( "units.unitFactory" )
local textbox = require("libs.helpers.textbox")
local localization = require( "libs.helpers.localization" )
local worldslist = require( "data.worldslist" )
local extratable = require("libs.helpers.extratable")
local rewardsService = require( "services.rewards" )
local unitsData = require( "data.unitsData" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonBack, menu
local spaceObjects, objectDespawnX, objectSpawnX
local spawnZoneWidth, halfSpawnZoneWidth
local levelsGroup, worldIcon, worldIconGroup, staticBgGroup, dynamicBgGroup
local nameLabel, playerLevelText, originalLabelPosition
local energyText, coinsText, starsText
local timeToRemove, currentTimeToRecharge
local nameFadeRect, buttonGroup
local currentPlayer, worldIndex, backgroundFile
local buttonsEnabled
local lastUnlockedLevel, prevLastUnlockedLevel
local hero
local flagSheet
local nameTextField
local iconUnitList
local messageFull
local buttonYogodex
local category
----------------------------------------------- Constants
local SIZE_BACKGROUND = 1024
local TAG_TRANSITION_NAMECHANGE = "nameFadeRect"
local BACKGROUND_TRANSITION_TAG = "spaceObjects"
local MARGIN = 20
local SCALE_NAME_BACKGROUND = 0.56
local OFFSET_NAME_TEXT = {x = 35, y = -20}
local OFFSET_LEVEL_TEXT = {x = -90, y = 35}
local OFFSET_CLEAR = {x = 20, y = 140}

local OFFSET_Y_HERO = -20
local COST_ENERGY_PLAY = 5

local DATA_NAMELABEL_ONFOCUS = {x = display.contentCenterX, y = display.contentCenterY - 200, scale = 1.5}

local OFFSET_Y_NAMELABEL = 17
local SCALE_CLEAR = 0.6
local SCALE_BACK = 0.75
local SCALE_EDITNAME = 0.56
local OFFSET_EDITNAME = {x = 190, y = 23}

local COLOR_LOCKED_LEVEL = {0.5}
local OFFSET_LEVEL_LOCK = {x = 0, y = 0}
local MAX_LEVEL_STARS = 3
local OFFSET_LEVEL_STARS = {x = 0, y = 0}

local MAX_NAME_CHARS = 12
local SCALE_LEVEL_LOCK = 0.45

local DATA_DECORATIONS = {x = 0, y = 24, scale = 0.8}
local DATA_DECORATIONS_BOSS = {x = 0, y = -140, scale = 0.8}
local OFFSET_WORLD_ICON = {x = 0, y = 50}
local SCALE_LOWER_BUTTONS = 0.5
local STARS_LAYERS = 5
local STARS_LAYER_DEPTH_RATIO = 0.08
local STARS_PER_LAYER = 10

local SECONDS_IN_HOUR = 60 * 60
local SECONDS_IN_MINUTE = 60

local WALK_DELAY = 1000
local WALK_TIME = 1500

local SIZE_TIMER_FONT = 20
local SIZE_STATUS_FONT = 30
local SCALE_STATUS_BACKGROUNDS = 0.38
local WIDTH_STATUS_TEXTS = 100
local WIDTH_TIMER_TEXT = 200

local X_POSITION_NAME = 0.24
local X_POSITION_ENERGY = 0.89
local X_POSITION_COINS = 0.71
local X_POSITION_STARS = 0.34

local OFFSET_ENERGY_TEXT = {x = -30, y = -1}
local OFFSET_COINS_TEXT = {x = -30, y = -1}
local OFFSET_STARS_TEXT = {x = -25, y = 0}

local OFFSET_BASE_NUMBER = {x = 0, y = 100}
local SCALE_BASE_NUMBER = 0.8

local SIZE_FONT_LEVEL = 40
	
local SCALE_PATH = {xScale = 1, yScale = 0.75}
local ASTEROID_LAYERS = 3
local ASTEROID_LAYER_BASE_DEPTH_RATIO = 0.3
local ASTEROID_LAYER_DEPTH_RATIO = 0.3
local ASTEROIDS_PER_LAYER = 2

local OBJECTS_TOLERANCE_X = 100
local TAG_TRANSITION_LOCK = "lockTransition"

local SIZE_FONT_NAMEFIELD = 36

----------------------------------------------- Functions
local function scrollTransition()
	local currentPosition = -lastUnlockedLevel.x + (display.viewableContentWidth * 0.5)
	menu:scrollToPosition({time = 0, x = currentPosition - 1000, onComplete = function()
		menu:scrollToPosition({time = 600, x = currentPosition})
	end})
end

local function onReleasedBack()
	director.gotoScene( "scenes.menus.worlds", { effect = "zoomInOutFade", time = 600, } )
end

local function textboxOnComplete(value)
	transition.cancel(TAG_TRANSITION_NAMECHANGE)
	
	transition.to(nameLabel, {time = 400, tag = TAG_TRANSITION_NAMECHANGE ,xScale = 1, yScale = 1, x = originalLabelPosition.x, y = originalLabelPosition.y, transition = easing.outQuad})
	transition.to(nameFadeRect, {time = 400, tag = TAG_TRANSITION_NAMECHANGE ,alpha = 0, transition = easing.outQuad})
	currentPlayer.characterName = value
	players.save(currentPlayer)
	scene.enableButtons()
	
end

local function nameListener( event )
	local text = event.target.value
	textboxOnComplete(text)
	native.setKeyboardFocus( nil )
end

local function textboxFocus()
	sound.play("pop")
	transition.cancel(TAG_TRANSITION_NAMECHANGE)
	transition.to(nameLabel, {time = 400, tag = TAG_TRANSITION_NAMECHANGE ,
		x = DATA_NAMELABEL_ONFOCUS.x,
		y = DATA_NAMELABEL_ONFOCUS.y,
		xScale = DATA_NAMELABEL_ONFOCUS.scale,
		yScale = DATA_NAMELABEL_ONFOCUS.scale,
		transition = easing.outQuad,
		onComplete = function()
			native.setKeyboardFocus(nameTextField)
		end,
	})
	
	transition.to(nameFadeRect, {time = 400, tag = TAG_TRANSITION_NAMECHANGE ,alpha = 0.8, transition = easing.outQuad})
	scene.disableButtons()
end

local function nameLabelTapped()
	textboxFocus()
end

local function levelAction(event, levelIcon)
	if buttonsEnabled and not levelIcon.locked then
		local timesPressed = eventCounter.updateEventCount("buttonWorld"..worldIndex, "pressedLevel"..levelIcon.index)
		buttonsEnabled = false
		sound.play("pop")
		
		if currentPlayer.energy >= COST_ENERGY_PLAY  then
			music.fade(400)
			scene.disableButtons()
			
			local manager = require( "scenes.minigames.manager" )
			manager.setNextScene(nil, nil)
			
			local totalCubeCost = 0
			for index = 1, levelIcon.index do
				local levelData = worldsData[worldIndex][index].gamemodeData.minigameRewards
				if levelData then
					local unitDataWorldIndex = worldIndex > #unitsData and #unitsData or worldIndex
					for levelDataIndex = 1, #levelData do
						totalCubeCost = totalCubeCost + unitsData[unitDataWorldIndex][1][levelData[levelDataIndex].unitIndex].stats.cubeCost
					end
				end
			end
			
			if levelIcon.index <= 3 then
				totalCubeCost = totalCubeCost + 10
			end
			
			local levelIcon = event.target
			local gamemodeData = extratable.deepcopy(levelIcon.data.gamemodeData)
			
			manager.setOnComplete(function(event)
				if gamemodeData and gamemodeData.minigameRewards then
					local rewardDelay =	rewardsService.check(gamemodeData.minigameRewards, currentPlayer)
					timer.performWithDelay(rewardDelay, function()
						event.complete()
					end)
				else
					event.complete()
				end
			end)
			
			local nextSceneParameters = { -- This are next scene params after loading screen
				nextScene = "scenes.game.units",
				maxPowerCubes = totalCubeCost,
				nextSceneParameters = { -- This are next scene params after manager (units scene)
					worldIndex = worldIndex,
					levelIndex = levelIcon.index,
					gamemodeData = gamemodeData,
					subject = category or "math",
				},
				subject = category or "math",
			}
			
			nextSceneParameters.nextSceneParameters.retryParameters = nextSceneParameters
			
			local loadingParams = {
				removeEnergy = COST_ENERGY_PLAY,
				sceneList = sceneList.game,
				nextScene = "scenes.minigames.manager",
				nextSceneParameters = nextSceneParameters,
			}
			
			director.gotoScene("scenes.menus.loading", { effect = "zoomInOutFade", time = 600, params = loadingParams,})
		else 
			buttonsEnabled = false
			director.showOverlay( "scenes.menus.noenergy", { isModal = true, effect = "slideDown", time = 400 } )
		end
	else
		sound.play("enemyRouletteTickOp02")
	end
end

local function levelIconTapped(event)
	local levelIcon = event.target
	levelAction(event, levelIcon)
	
end

local function createBackground(parentGroup)
	local dynamicScale = display.viewableContentWidth / SIZE_BACKGROUND
    local backgroundContainer = display.newContainer(display.viewableContentWidth + 2, display.viewableContentHeight + 2)
    backgroundContainer.x = display.contentCenterX
    backgroundContainer.y = display.contentCenterY
    parentGroup:insert(backgroundContainer)
	
    local background = display.newImage(worldslist[worldIndex].backgroundLevels, true)
    background.xScale = dynamicScale
    background.yScale = dynamicScale
	backgroundContainer:insert(background)
	
	local containerHalfWidth = backgroundContainer.width * 0.5
	local containerHalfHeight = backgroundContainer.height * 0.5
	
	spaceObjects = {}
	
	objectDespawnX = containerHalfWidth + OBJECTS_TOLERANCE_X
	objectSpawnX = -containerHalfWidth - OBJECTS_TOLERANCE_X
	spawnZoneWidth = -objectSpawnX + objectDespawnX
	halfSpawnZoneWidth = spawnZoneWidth * 0.5
	
	for layerIndex = 1, STARS_LAYERS do
		local starLayer = display.newGroup()
		backgroundContainer:insert(starLayer)
		for starsIndex = 1, STARS_PER_LAYER do
			local scale =  0.05 + layerIndex * 0.05
			
			local star = display.newImage("images/menus/star_"..math.random(1,2)..".png")
			star.xOffset = math.random(objectSpawnX, objectDespawnX)
			star.y = math.random(-containerHalfHeight, containerHalfHeight)
			star.xScale = scale
			star.yScale = scale
			star.xVelocity = STARS_LAYER_DEPTH_RATIO * layerIndex
			starLayer:insert(star)
			
			spaceObjects[#spaceObjects + 1] = star
		end
	end
	
	worldIconGroup = display.newGroup()
	backgroundContainer:insert(worldIconGroup)
	
	local asteroids = worldsData[worldIndex].asteroids
	local numAsteroids = #asteroids
	
--	for layerIndex = 1, ASTEROID_LAYERS do
--		local asteroidLayer = display.newGroup()
--		backgroundContainer:insert(asteroidLayer)
--		for asteroidIndex = 1, ASTEROIDS_PER_LAYER do
--			local scale =  0.4 + layerIndex * 0.1
--			local asteroid = display.newImage(asteroids[math.random(1,numAsteroids)])
--			asteroid.xOffset = math.random(objectSpawnX, objectDespawnX)
--			asteroid.animate = true
--			asteroid.y = math.random(-containerHalfHeight, containerHalfHeight)
--			asteroid.xScale = scale
--			asteroid.yScale = scale
--			asteroid.xVelocity = ASTEROID_LAYER_BASE_DEPTH_RATIO + ASTEROID_LAYER_DEPTH_RATIO * layerIndex
--			asteroidLayer:insert(asteroid)
--			
--			spaceObjects[#spaceObjects + 1] = asteroid
--		end
--	end
end

local function updateSpaceObjects()
	pcall(function()
		if spaceObjects then
			local scrollX, scrollY = menu:getContentPosition()
			for index = 1, #spaceObjects do
				local object = spaceObjects[index]
				object.x = (object.xOffset + scrollX * object.xVelocity) % spawnZoneWidth - halfSpawnZoneWidth
			end
		end
	end)
end

local function disableSpaceObjects()
	transition.cancel(BACKGROUND_TRANSITION_TAG)
	Runtime:removeEventListener("enterFrame", updateSpaceObjects)
end

local function prepareSpaceObjects()
	disableSpaceObjects()
	for index = 1, #spaceObjects do
		local object = spaceObjects[index]
		if object.animate then
			local function animateObject(animatedObject, upperY, lowerY)
				transition.to(animatedObject, {tag = BACKGROUND_TRANSITION_TAG, time = 1200, y = upperY, transition = easing.inOutSine})
				transition.to(animatedObject, {tag = BACKGROUND_TRANSITION_TAG,delay = 1200, time = 1200, y = lowerY, transition = easing.inOutSine , onComplete = function()
					animateObject(animatedObject, upperY, lowerY)
				end})
			end
			transition.to(object, {tag = BACKGROUND_TRANSITION_TAG, delay = math.random(50,900), time = 1, onComplete = function()
				animateObject(object, object.y - 20, object.y + 20)
			end})
		end
	end
	Runtime:addEventListener("enterFrame", updateSpaceObjects)
end

local function removeLevels()
	display.remove(levelsGroup)
	levelsGroup = nil
end

local function removeWorldIcon()
	display.remove(worldIcon)
	worldIcon = nil
end

local function createLevels()
	local worldData = worldsData[worldIndex]
	lastUnlockedLevel = nil
	prevLastUnlockedLevel = nil
	removeWorldIcon()
	
	if worldData then
		
		levelsGroup = display.newGroup()
		local decorationGroup = display.newGroup()
		levelsGroup:insert(decorationGroup)
		local pathGroup = display.newGroup()
		levelsGroup:insert(pathGroup)
		
		local filler = display.newRect(0,0,20,20)
		filler.isVisible = false
		filler.anchorX = 0
		
		local squareRoot = math.sqrt
		local playerWorldData = currentPlayer.unlockedWorlds[worldIndex]
		
		iconUnitList = {}
		local iconCounter = 0

		for index = 1, #worldData do
			local levelData = worldData[index]
			local level = display.newGroup()
			level.x = levelData.x
			level.y = menu.height * 0.5 + levelData.y
			levelsGroup:insert(level)
			
			level.index = index
			level.data = levelData
			level:addEventListener("tap", levelIconTapped)
			
			local levelImage = display.newImage("images/levels/base.png")
			level:insert(levelImage)
			
			local levelNumberBase = display.newImage("images/levels/baseNumero.png")
			levelNumberBase.x = OFFSET_BASE_NUMBER.x
			levelNumberBase.y = OFFSET_BASE_NUMBER.y
			levelNumberBase:scale(SCALE_BASE_NUMBER, SCALE_BASE_NUMBER)
			level:insert(levelNumberBase)
			
			local levelNumber = display.newText(string.format("%02d", index),  levelNumberBase.x, levelNumberBase.y, settings.fontName, SIZE_FONT_LEVEL)
			level:insert(levelNumber)
			local starNumber
			
			if playerWorldData and playerWorldData.levels then
				
				if playerWorldData.levels[index] and playerWorldData.levels[index].unlocked then
					starNumber = playerWorldData.levels[index].stars or 0
					level.stars = starNumber
					if "number" == type(starNumber) then
						if starNumber < 0 then
							starNumber = 0
						elseif starNumber > MAX_LEVEL_STARS then
							starNumber = MAX_LEVEL_STARS
						end
											
						if starNumber > 0 then
							local starsImage = display.newImage(string.format("images/levels/star_%02d.png", starNumber))
							starsImage.x = OFFSET_LEVEL_STARS.x
							starsImage.y = OFFSET_LEVEL_STARS.y
							level:insert(starsImage)
							
							local sequenceData = {
								{ name = "flaging", sheet = flagSheet, start = 1, count = 8, time = 1000, loopCount = 0},
							}

							local flagSprite = display.newSprite( flagSheet, sequenceData )
							flagSprite.xScale = 0.5
							flagSprite.yScale = 0.5
							flagSprite.x = -5
							flagSprite.y = -95
							flagSprite:play()

							level:insert(flagSprite)
						end
					end
					prevLastUnlockedLevel = lastUnlockedLevel
					lastUnlockedLevel = level
				else
					level.locked = true
					local lockImage = display.newImage("images/general/lock.png")
					lockImage.x = OFFSET_LEVEL_LOCK.x
					lockImage.y = OFFSET_LEVEL_LOCK.y
					lockImage.xScale = SCALE_LEVEL_LOCK
					lockImage.yScale = SCALE_LEVEL_LOCK
					level:insert(lockImage)
					
					levelImage:setFillColor(unpack(COLOR_LOCKED_LEVEL))
				end
			end
	
			local gameMode = levelData.gamemodeData
			starNumber = starNumber or 0
			if gameMode.endRewards and starNumber < 1 then
				for rewardIndex = 1, #gameMode.endRewards do
					local reward = gameMode.endRewards[rewardIndex] 
					if reward.type == "unlockYogotar" then
						local iconGroup = display.newGroup()
						local iconContainer = display.newImage("images/levels/cardsMap.png")
						iconGroup:insert(iconContainer)
						local iconUnit = display.newImage(unitFactory.getUnitIconPath(reward.worldIndex, reward.unitIndex))
						iconUnit.xScale = 0.70
						iconUnit.yScale = 0.70
						iconUnit.y = -10
						iconGroup:insert(iconUnit)
						iconGroup.x = 0
						iconGroup.y = -115
						iconGroup.originalY = iconGroup.y
						iconGroup.motionLoop = 0
						iconGroup.xScale = 0.4
						iconGroup.yScale = 0.4
						level:insert(iconGroup)
						iconCounter = iconCounter + 1
						iconGroup.index = level.index
						iconUnitList[iconCounter] = iconGroup
					end
				end
			end
			
			local decoration
			if not levelData.miniBossLevel then
				decoration = display.newImage(string.format("images/levels/base_%02d.png",math.random(1,4)))
				decoration.x = level.x + DATA_DECORATIONS.x
				decoration.y = level.y + DATA_DECORATIONS.y
				decoration.xScale = DATA_DECORATIONS.scale
				decoration.yScale = DATA_DECORATIONS.scale
			else
				local levelSheetData = { width = 512, height = 512, numFrames = 16, sheetContentWidth = 2048, sheetContentHeight = 2048 }
				local levelSheet = graphics.newImageSheet("images/levels/world_01.png", levelSheetData )
				local sequenceData = {
					{ name = "bosslevel", sheet = levelSheet, start = 1, count = 16, time = 1100, loopCount = 0},
				}
				decoration = display.newSprite( levelSheet, sequenceData )
				decoration.x = level.x + DATA_DECORATIONS_BOSS.x
				decoration.y = level.y + DATA_DECORATIONS_BOSS.y
				level.isVisible = false
				level.isHitTestable = true
				level.xScale = 2
				level.yScale = 2
				pathGroup:toBack()
				decoration:play()
			end
			
			decorationGroup:insert(decoration)
			
			filler.width = levelData.x
			
			if index > 0 and index < #worldData then
				local p2 = worldData[index + 1]
				local p1 = worldData[index]
				
				local distanceX = p2.x - p1.x
				local distanceY = p2.y - p1.y
				local distance = squareRoot((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))
				
				local iterations = math.ceil(distance / 16)
				local lastPathImage
				for index = 1, iterations do
					local pathImage = display.newImage("images/levels/camino.png")
					pathImage.x = worldData.path.easingX(index, iterations, p1.x, distanceX)
					pathImage.y = menu.height * 0.5 + worldData.path.easingY(index, iterations, p1.y, distanceY)
					pathImage.fill.blendMode = {srcColor = "srcColor", srcAlpha = "srcAlpha", dstColor = "one", dstAlpha = "one"}
					pathImage.xScale = SCALE_PATH.xScale
					pathImage.yScale = SCALE_PATH.yScale
					pathGroup:insert(pathImage)
					
					if lastPathImage then
						lastPathImage.rotation = extramath.getFullAngle(pathImage.x - lastPathImage.x, pathImage.y - lastPathImage.y) + 90
					end
					lastPathImage = pathImage
				end
			end
		end
		
		if worldData[1] then
			filler.width = filler.width + worldData[1].x
		end
		levelsGroup:insert(filler)
		
		menu:insert(levelsGroup)
	end
end

local function updateMotion(object)
	object.motionLoop = object.motionLoop + 2

	local radians = object.motionLoop / 57.2957795131 -- Converting to radians

	local offset = math.sin(radians) * 15;   
	object.y = object.originalY + offset

	if object.motionLoop >= 360 then
		object.motionLoop = object.motionLoop - 360
	end
end

local function updateHero()
	pcall(function()
		hero:update()
		for iconIndex = 1, #iconUnitList do
			updateMotion(iconUnitList[iconIndex])
		end
	end)
end

local function removeHero()
	Runtime:removeEventListener("enterFrame", updateHero)
	transition.cancel(hero.group)
	display.remove(hero.group)
	hero = nil
end

local function addBreakLock(levelIcon)
	local lockData = { width = 128, height = 128, numFrames = 16 }
	local lockSheet = graphics.newImageSheet( "images/general/locksprite.png", lockData )

	local flagSequenceData = {
		{name = "idle", sheet = lockSheet, time = 1000, start = 1, count = 1, loopCount = 1  },
		{name = "break", sheet = lockSheet, time = 600, start = 1, count = 16, loopCount = 1 },
	}

	local lock = display.newSprite( lockSheet, flagSequenceData )
	lock.x = OFFSET_LEVEL_LOCK.x
	lock.y = OFFSET_LEVEL_LOCK.y
	lock.xScale = 1
	lock.yScale = 1
	lock:setSequence("idle")
	lock:play()
	
	transition.to(lock, {tag = TAG_TRANSITION_LOCK, delay = 1500, time = 300, xScale = 1.5, yScale = 1.5, transition = easing.outQuad, onComplete = function()
		lock:setSequence("break")
		lock:play()
	end})
	
	function lock:sprite(event)
		if "ended" == event.phase then
			if event.target.sequence == "break" then
				display.remove(lock)
				lock = nil
			end
		end
	end
	lock:addEventListener("sprite")
	
	levelIcon:insert(lock)
	
	return lock
end

local function createHero()
	local json = spine.SkeletonJson.new()

	json.scale = 0.4
	local skinName = herolist[currentPlayer.heroIndex].skinName
	
	local skeletonPath = "units/hero/skeleton.json"
	local skeletonData = json:readSkeletonDataFile(skeletonPath)
	hero = spine.Skeleton.new(skeletonData)

	hero.flipX = false
	hero.flipY = false

	function hero:createImage(attachment)
		if string.find(attachment.name, "hat") then
			return display.newImage("units/hero/hats/"..attachment.name..".png")
		else
			return display.newImage("units/hero/"..skinName.."/"..attachment.name..".png")
		end
	end

	hero:setToSetupPose()
	hero:setSkin(skinName)

	local animationStateData = spine.AnimationStateData.new(skeletonData)
	animationStateData:setMix("IDLE", "WALK", 0.05)
	animationStateData:setMix("WALK", "IDLE", 0.05)
	local animationState = spine.AnimationState.new(animationStateData)

	local walkAnimSpeed = 0.03
	local idleSpeed = 0.005
	function hero:update()
		local animSpeed = hero.isWalking and walkAnimSpeed or idleSpeed
		animationState:update(animSpeed)
		animationState:apply(self)
		self:updateWorldTransform()
	end

	function hero:setAnimation(animation)
		animationState:setAnimationByName(1, animation, true)
	end
	
	hero:setAnimation("IDLE")
	if prevLastUnlockedLevel then
		hero.group.x = prevLastUnlockedLevel.x
		hero.group.y = prevLastUnlockedLevel.y + OFFSET_Y_HERO
		
		transition.to(hero.group, {delay = WALK_DELAY, time = WALK_TIME,x = lastUnlockedLevel.x, onStart = function()
			hero.isWalking = true
			hero:setAnimation("WALK")
			sound.play("running")
			timer.performWithDelay(1100, function()
				sound.play("breakSound")
			end)
			
		end})
		transition.to(hero.group, {delay = WALK_DELAY, time = WALK_TIME, y = lastUnlockedLevel.y + OFFSET_Y_HERO, transition = easing.inOutCubic, onComplete = function()
			hero.isWalking = false
			hero:setAnimation("IDLE")
		end})
		
		for iconIndex = 1, #iconUnitList do
			local iconUnit = iconUnitList[iconIndex]
			if iconUnit.index == lastUnlockedLevel.index then
				transition.to(iconUnit, {delay = WALK_DELAY, time = WALK_TIME, alpha = 0})
			end
		end
		
		if lastUnlockedLevel.stars <= 0 then
			addBreakLock(lastUnlockedLevel)
		end
	else
		hero.group.x = lastUnlockedLevel.x
		hero.group.y = lastUnlockedLevel.y + OFFSET_Y_HERO
	end
	
	local function heroTap()
		levelIconTapped({target = lastUnlockedLevel})
	end
	
	hero.group:addEventListener("tap", heroTap)
	
	local attachHat = hero:getAttachment ("hat", "hat")
	attachHat.name = hatlist[currentPlayer.hatIndex].name
	hero:setSlotAttachment("hat", attachHat)
	
	menu:insert(hero.group)
	Runtime:addEventListener("enterFrame", updateHero)
end

local function populateProfileElements()
	playerLevelText.text = 1
	
	scene.updatePlayerStatus()
	starsText.text = 0
end

local function createNameLabel(sceneGroup)
	nameLabel = display.newGroup()
	nameLabel.x = display.screenOriginX + (X_POSITION_NAME * display.viewableContentWidth)
	nameLabel.y = display.screenOriginY + MARGIN + OFFSET_Y_NAMELABEL
	
	originalLabelPosition = {x = nameLabel.x, y = nameLabel.y}
	
	local nameEditSign = display.newImage("images/levels/edit.png")
	nameEditSign.x = nameLabel.x + OFFSET_EDITNAME.x
	nameEditSign.y = nameLabel.y + OFFSET_EDITNAME.y
	nameEditSign.xScale = SCALE_EDITNAME + 0.05
	nameEditSign.yScale = SCALE_EDITNAME + 0.05
	nameEditSign:addEventListener("tap", nameLabelTapped)
	sceneGroup:insert(nameEditSign)
	
	nameFadeRect = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	nameFadeRect:setFillColor(0)
	nameFadeRect.alpha = 0
	sceneGroup:insert(nameFadeRect)
	
	local texboxOptions = {
		backgroundImage = "images/levels/nameLevel.png",
		backgroundScale = SCALE_NAME_BACKGROUND + 0.05,
		fontSize = 32,
		font = settings.fontName,
		inputType = "email",
		color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
		placeholder = currentPlayer.characterName,
		offsetText = {x = 30, y = -20},
	}
	
	texboxOptions.onComplete = nameListener
	texboxOptions.onFocus = nameLabelTapped
	nameTextField = textbox.new(texboxOptions)
	nameTextField.x = 15
	nameTextField.y = 43
	nameLabel:insert(nameTextField)

	local levelTextOptions = {
		x = OFFSET_LEVEL_TEXT.x,
		y = OFFSET_LEVEL_TEXT.y,
		align = "center",
		font = settings.fontName,
		text = "0",
		fontSize = 48,
	}

	playerLevelText = display.newText(levelTextOptions)
	nameLabel:insert(playerLevelText)
	
	sceneGroup:insert(nameLabel)
end

local function onReleasedYogodex()
	director.gotoScene( "scenes.menus.selecthero", { effect = "zoomInOutFade", time = 600, params = {worldIndex = worldIndex}} )
end

local function createStaticButtons(sceneGroup)
	buttonGroup = display.newGroup()
	sceneGroup:insert(buttonGroup)
	
	buttonlist.back.onRelease = onReleasedBack
	buttonBack = widget.newButton(buttonlist.back)
	buttonBack.x = display.screenOriginX + 64 * SCALE_BACK + MARGIN
	buttonBack.y = display.screenOriginY + 64 * SCALE_BACK + MARGIN
	buttonBack.xScale = SCALE_BACK
	buttonBack.yScale = SCALE_BACK
	buttonGroup:insert(buttonBack)
	
	buttonlist.yogodex.onRelease = onReleasedYogodex
	buttonYogodex = widget.newButton(buttonlist.yogodex)
	buttonYogodex.xScale = SCALE_LOWER_BUTTONS
	buttonYogodex.yScale = SCALE_LOWER_BUTTONS
	buttonYogodex.x = display.screenOriginX + display.viewableContentWidth - buttonYogodex.width * SCALE_LOWER_BUTTONS * 0.5 - MARGIN
	buttonYogodex.y = display.screenOriginY + display.viewableContentHeight - buttonYogodex.height * SCALE_LOWER_BUTTONS * 0.5 - MARGIN
	buttonGroup:insert(buttonYogodex)
	
--	buttonlist.rankings.onRelease = onReleasedRankings
--	buttonRankings = widget.newButton(buttonlist.rankings)
--	buttonRankings.xScale = SCALE_LOWER_BUTTONS
--	buttonRankings.yScale = SCALE_LOWER_BUTTONS
--	buttonRankings.x = buttonRankings.x + (buttonRankings.width + buttonBadges.width) * SCALE_LOWER_BUTTONS * 0.5 + MARGIN
--	buttonRankings.y = display.screenOriginY + display.viewableContentHeight - buttonRankings.height * SCALE_LOWER_BUTTONS * 0.5 - MARGIN
--	buttonGroup:insert(buttonRankings)
end

local function createScrollView(sceneGroup)
	local scrollViewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		verticalScrollDisabled = true,
		hideBackground = true,
	}
	menu = widget.newScrollView(scrollViewOptions)
	sceneGroup:insert(menu)
end

local function createCoinsPanel()
	local coinsPanel = display.newGroup()
	coinsPanel.anchorChildren = true
	
	local coinsBackground = display.newImage("images/levels/coins.png")
	coinsBackground.xScale = SCALE_STATUS_BACKGROUNDS
	coinsBackground.yScale = SCALE_STATUS_BACKGROUNDS
	coinsPanel:insert(coinsBackground)
	local coinsTextOptions = {
		x = OFFSET_COINS_TEXT.x,
		y = OFFSET_COINS_TEXT.y,
		width = WIDTH_STATUS_TEXTS,
		align = "right",
		font = settings.fontName,
		text = "9000",
		fontSize = SIZE_STATUS_FONT,
	}
	coinsText = display.newText(coinsTextOptions)
	coinsPanel:insert(coinsText)
	
	return coinsPanel
end

local function createStarsPanel()
	local starsPanel = display.newGroup()
	starsPanel.anchorChildren = true
	
	local starsBackground = display.newImage("images/levels/star.png")
	starsBackground.xScale = SCALE_STATUS_BACKGROUNDS
	starsBackground.yScale = SCALE_STATUS_BACKGROUNDS
	starsPanel:insert(starsBackground)
	local starsTextOptions = {
		x = OFFSET_STARS_TEXT.x,
		y = OFFSET_STARS_TEXT.y,
		width = WIDTH_STATUS_TEXTS,
		align = "right",
		font = settings.fontName,
		text = "15",
		fontSize = SIZE_STATUS_FONT,
	}
	starsText = display.newText(starsTextOptions)
	starsPanel:insert(starsText)
	
	return starsPanel
end

local function createStatusElements(sceneGroup)
	local yPosition = display.screenOriginY + MARGIN

	
	local starsPanel = createStarsPanel()
	starsPanel.anchorY = 0
	starsPanel.y = yPosition + 55
	starsPanel.x = display.screenOriginX + (X_POSITION_STARS * display.viewableContentWidth)
	sceneGroup:insert(starsPanel)
	
	local coinsPanel = createCoinsPanel()
	coinsPanel.anchorY = 0
	coinsPanel.y = yPosition
	coinsPanel.x = display.screenOriginX + (X_POSITION_COINS * display.viewableContentWidth)
	sceneGroup:insert(coinsPanel)

end

local function startCountdown()
	timeToRemove = system.getTimer()
end

local function checkCompletion()
	local lastLevelIndex = #worldsData[worldIndex]
	if currentPlayer.unlockedWorlds[worldIndex].levels[lastLevelIndex] then
		if currentPlayer.unlockedWorlds[worldIndex].levels[lastLevelIndex].stars > 0 then
			if currentPlayer.unlockedWorlds[worldIndex + 1] then
				if not currentPlayer.unlockedWorlds[worldIndex + 1].unlocked then
					currentPlayer.unlockedWorlds[worldIndex + 1] = {
						unlocked = true,
						watchedEnd = false,
						watchedStart = false,
						levels = {
							[1] = {unlocked = true, stars = 0},
						},
					}	
				end
			else
				currentPlayer.unlockedWorlds[worldIndex + 1] = {
					unlocked = true,
					watchedEnd = false,
					watchedStart = false,
					levels = {
						[1] = {unlocked = true, stars = 0},
					},
				}	
			end
			if not currentPlayer.unlockedWorlds[worldIndex].watchedEnd then
				--currentPlayer.unlockedWorlds[worldIndex].watchedEnd = true
				--players.save(currentPlayer)
				--director.gotoScene("scenes.menus.endworld", {effect = "fade", time = 600, params = {worldIndex = worldIndex}})
			end
		end
	end
end

local function animate(displayObject)
	transition.cancel(displayObject)
	displayObject.xScale = 1.5
	displayObject.yScale = 1.5
	transition.to(displayObject, {xScale = 1, yScale = 1, transition = easing.outElastic})
end

local function checkAndUpdate(textObject, text)
	if textObject.text ~= tostring(text) then
		animate(textObject)
	end
	textObject.text = text
end
----------------------------------------------- Class functions
function scene.updatePlayerStatus()
	currentPlayer = players.getCurrent()
	
	coinsText.text = currentPlayer.coins or 0
end 

function scene.enableButtons()
	buttonBack:setEnabled(true)
	buttonYogodex:setEnabled(true)
--	buttonRankings:setEnabled(true)
	
	--nameTextbox:setEnabled(true)
	buttonsEnabled = true
end

function scene.disableButtons()
	buttonBack:setEnabled(false)
	buttonYogodex:setEnabled(false)
--	buttonRankings:setEnabled(false)
	
	--nameTextbox:setEnabled(false)
	buttonsEnabled = false
end

function scene.backAction()
	robot.press(buttonBack)
	return true
end 

function scene:create(event)
	local sceneGroup = self.view

	currentPlayer = players:getCurrent()
	
	staticBgGroup = display.newGroup()
	sceneGroup:insert(staticBgGroup)
	
	createScrollView(sceneGroup)
	createStaticButtons(sceneGroup)
	createStatusElements(sceneGroup)
	createNameLabel(sceneGroup)
	
	local flagSheetData1 = { width = 128, height = 256, numFrames = 8, sheetContentWidth = 512, sheetContentHeight = 512 }
	flagSheet = graphics.newImageSheet( "images/worlds/flag.png", flagSheetData1 )
	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
    local phase = event.phase
	
	local params = event.params or {}
	worldIndex = params.worldIndex or 1
	category = params.category or "math"
	
    if ( phase == "will" ) then
		dynamicBgGroup = display.newGroup()
		staticBgGroup:insert(dynamicBgGroup)

		messageFull = localization.getString("full")
		currentPlayer = players:getCurrent()
		createBackground(dynamicBgGroup)
		populateProfileElements()
		createLevels()
		createHero()
		prepareSpaceObjects()
		self.disableButtons()
		scrollTransition()
		startCountdown()
		checkCompletion()
		if not currentPlayer.firstMenu then
			--showShopIntro()
		end
	elseif ( phase == "did" ) then
		self.enableButtons()
		music.playTrack(1,400)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeHero()
		disableSpaceObjects()
		removeLevels()
		removeWorldIcon()
		transition.cancel(TAG_TRANSITION_LOCK)
		display.remove(dynamicBgGroup)
		dynamicBgGroup = nil
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene
