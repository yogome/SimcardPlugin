----------------------------------------------- Real time line strategy game
local scenePath = ...
local libraries = {
	director = require( "libs.helpers.director" ),
	widget = require( "widget" ),
	unitsData = require( "data.unitsData" ),
	buttonlist = require( "data.buttonlist" ),
	unitFactory = require( "units.unitFactory" ),
	colors = require( "libs.helpers.colors" ),
	settings = require( "settings" ),
	pauseScene = require( "scenes.game.pause" ),
	loseScene = require( "scenes.game.lose" ),
	music = require( "libs.helpers.music" ),
	winScene = require( "scenes.game.win" ),
	database = require( "libs.helpers.database" ),
	worldsData = require( "data.worldsdata" ),
	gamemodes = require( "data.gamemodes" ),
	extratable = require( "libs.helpers.extratable" ),
	screenfocus = require( "libs.helpers.screenfocus" ),
	sound = require( "libs.helpers.sound" ),
	goalsScene = require("scenes.game.goals"),
	indicator = require( "libs.helpers.indicator" ),
	gameHelper = require( "scenes.game.helper" ),
	levelsService = require( "services.levels" ),
	rewardsService = require( "services.rewards" ),
	players = require( "models.players" ),
	sceneList = require( "data.scenelist" ),
	robot = require( "libs.helpers.robot" ),
	herolist = require("data.herolist"),
	mixpanel = require( "libs.helpers.mixpanel" ),
	logger = require( "libs.helpers.logger" ),
	eventCounter = require( "libs.helpers.eventcounter" ),
	backgroundList = require( "data.backgroundlist" ),
	localization = require( "libs.helpers.localization" )
}
local game = libraries.director.newScene() 
----------------------------------------------- Caches
local stringFormat = string.format 
----------------------------------------------- Variables
local unitScrollView, unitScrollViewHeight, warzoneScrollViewHeight
local warzoneScrollView
local background, bgComponentList, parallaxRightLimit

local unitIcons
local foodText, energyText
local foodBarFill--, energyBarFill
local leftHealthBarFill, rightHealthBarFill

local currentLoop
local pauseButton, paused, overridePaused, eventIndex

local gameGoals
local newEnemyUnits
local currentFood, currentEnergy, currentItemRecharge
local laneList
local coinsFreezed
local unpickedCoins
local heroUnitIcon
local currentEvent, nextEvent
local retryParameters
local warzoneScrollDelay
local gamemodeData
local worldID, levelID
local debugText
local activeGoals
local lostUnits, lostBuildings, totalBuildings, playerHealths
local unitAvailability
local activeUnits, unitsSpawned
local currentGamemode
local unitCounts
local currentCoins, coinsText
local coinsCollected, coinsDespawn
local tutorialElements, removeHandEvent
local extraUnitData
local tutorialHand, tutorialFocus
local endBanner
local removeHandEvent, removeFocusEvent

local isGameOver
local savedSubject

local gameConditions = {
	winOnUnitDespawn = false,
	winOnBuildingsKilled = false,
	loseOnEnemyDespawn = false,
	loseOnBuildingsLost = false,
}

local pauseFoodRecharge, pauseEnergyRecharge
local currentPlayer
local foodTutorial, energyTutorial
local scheduleEnergyPause
local rightPlayerIconRect, leftPlayerIconRect
local unitSpawnFreezed
local eventTimesPlayed
local itemIcon

local backgroundID
----------------------------------------------- Constants
local ELEMENTS_TUTORIAL_TAGS = {
	FIRST_ITEM_UNITBAR = "firstUnitOnBar",
	HERO_ITEM_UNITBAR = "heroUnitOnBar",
	FIRST_LANE = "firstLane",
	LAST_COIN = "lastCoin",
	LAST_ENEMY = "lastEnemy",
	LAST_PLAYER_UNIT = "lastPlayerUnit",
	FOOD_BAR = "foodBar",
	ENERGY_BAR = "energyBar",
}

local WORLDS_PATH = {
	[1] = "world01",
	[2] = "world02",
	[3] = "world03"
}

local SKIN_WORLD = {
	[1] = "world1",
	[2] = "world2",
	[3] = "world3"
}

local GOAL_TYPES = {
	COLLECT_COINS = "collectCoins",
	KILL_BUILDINGS = "killBuildings",
	KILL_UNITS = "killUnits",
}

local GOAL_TEXTS = {
	[GOAL_TYPES.KILL_UNITS] = {
		string = "eliminateUnits",
		time = "eliminateTime",
	},
	[GOAL_TYPES.KILL_BUILDINGS] = {
		string = "destroyBuildings",
		time = "eliminateTime"
	},
	[GOAL_TYPES.COLLECT_COINS] = {
		string = "collectCoins",
		time = "eliminateTime"
	},
}
local COLOR_AFFORDABLE_FOOD = libraries.colors.green
local COLOR_AFFORDABLE_ENERGY = libraries.colors.blue
local COLOR_EXPENSIVE = libraries.colors.orangeRed

local SIZE_PLAYER_ICON_RECT = 64
local SIZE_HEALTHBAR = {width = 256, height = 32}
local OFFSETS = {
	PLAYER_ICON_RECT_LEFT = {x = -124, y = 0},
	PLAYER_ICON_RECT_RIGHT = {x = -124, y = 0},
	TEXT_COINS = {x = -35, y = 20},
	X_DESPAWN = 100,
	HERO_TEXT = {x = -105, y = -193},
	FOOD_TEXT = {x = 175, y = -193},
	UNIT_ICON = {y = 10},
	PRICETAG_UNIT_ICON = {x = 25, y = 87},
	PORTRAIT_UNIT_ICON = {x = 0, y = -30},
	FOOD_BAR = {x = 90, y = -166},
	HERO_BAR = {x = -375, y = -166},
	HEALTH_BAR = {x = -88, y = -23},
}

local SCALE_UNIT_ICON_PORTRAIT = 1.5
local WIDTH_COINS_TEXT = 150
local SIZE_FONT_COINS_TEXT = 25

local padding = 8
local TEAM_INDEX_COMPUTER = 2
local TEAM_INDEX_PLAYER = 1

local DEFAULT_LEVEL_ID = 1
local DEFAULT_WORLD_ID = 2
local DEFAULT_GAMEMODE_ID = "test"
local DEFAULT_GOAL_TEXT = {en = "Defeat the enemy team.", es = "Derrota al equipo enemigo."}
local HEIGHT_EXTRA_WARZONE = 10

local AMOUNT_SLANT = 40
local WIDTH_COLUMN_FORTRESSLANE = 128
local X_SPAWN_NO_FORTRESS = 50

local RATIO_PARALLAX_BACKGROUND = 0.00005
local SIZE_QUADS = 76

local SCALE_COINS = 0.75
local DELAY_COIN_DESPAWN = 4000
local INTERVAL_UPDATE_GAME = 2

local foodRechargePerUpdate
local energyRechargePerUpdate

local DRAG_START_Y_UNITBAR = 5
local TOLERANCE_DRAG_UNITBAR = 10

local SIZE_FILL_UNITBAR = {width = 285, height = 20}
local PATH_FILL_UNITBAR = "images/game/fill.png"
local PATH_BACKGROUND_LEFT_UNITBAR = "images/game/leftBarBackground.png"
local PATH_BACKGROUND_RIGHT_UNITBAR = "images/game/rightBarBackground.png"
local PATH_FOREGROUND_LEFT_UNITBAR = "images/game/leftBar.png"
local PATH_FOREGROUND_RIGHT_UNITBAR = "images/game/rightBar.png"
local PATH_FOREGROUND_MIDDLE_UNITBAR = "images/game/middleBar.png"
local WIDTH_FONT_UNITBAR = 130
local SIZE_FONT_UNITBAR = 18
local COLOR_FOOD_BAR = {full = libraries.colors.lime, empty = libraries.colors.red}
local COLOR_HERO_BAR = {full = libraries.colors.cyan, empty = libraries.colors.red}

local SIZE_FONT_PRICE_UNIT = 45
local SIZE_ICON_UNIT = 128

local SCALE_UNITLOCK = 0.8

local PATH_FOREGROUND_HEALTHBAR = "images/game/healthbar_foreground.png"
local PATH_BACKGROUND_HEALTHBAR = "images/game/healthbar_background.png"

local NAME_EVENT_LAST_UNIT_SPECIAL = "lastPlayerUnitSpecial"
local NAME_EVENT_TUTORIAL_TRANSITION_ENDED = "transitionEnded"
local NAME_EVENT_COIN_PICKED = "coinPicked"
local NAME_EVENT_UNIT_SPAWNED = "unitSpawned"

local TEXT_TUTORIAL = {
	FOOD = "tutorialFood",
	ENERGY = "tutorialEnergy"
}

local TAG_FOCUS_EVENT = "tagTutorialFocus"
local TAG_HAND_EVENT = "tagTutorialHand"
local ICON_BACKGROUND = {
	locked = "images/game/unitnoprice.png",
	unit = "images/game/unit.png",
	item = "images/game/poder_1.png",
	hero = "images/game/hero.png"
}
----------------------------------------------- Functions
local function retryGame()
	local retryIndex = libraries.eventCounter.updateEventCount("gamePlayedWorld"..worldID, "levelRetry"..levelID)
	libraries.mixpanel.logEvent("mainGameRetry", {worldIndex = worldID, levelIndex = levelID, retryIndex = retryIndex})
	
	local nextSceneParameters = {
		worldIndex = worldID,
		levelIndex = levelID,
		gamemodeData = gamemodeData,
		subject = savedSubject,
	}
	local loadingParams = {
		sceneList = libraries.sceneList.game,
		nextScene = "scenes.minigames.manager",
		nextSceneParameters = nextSceneParameters,
	}
	libraries.gameHelper.loader("scenes.menus.loading", loadingParams)
end

local function winGame()
	game.pause()
	isGameOver = true
	
	for unitIndex = #activeUnits, 1, -1 do
		local unit = activeUnits[unitIndex]
		unit.paused = false 
		if unit.team == TEAM_INDEX_PLAYER then
			unit:setAnimation("WIN")
		else
			unit:setAnimation("LOSE")
		end
	end
	
	local currentStars = (playerHealths[TEAM_INDEX_PLAYER] >= 1 and 3) or (playerHealths[TEAM_INDEX_PLAYER] >= 0.5 and 2) or (playerHealths[TEAM_INDEX_PLAYER] > 0 and 1) or 0
	
	for index = 1, #unpickedCoins do
		local coin = unpickedCoins[index]
		if coin then
			libraries.robot.press(coin)
		end
	end
	
	libraries.levelsService.check(currentPlayer, worldID, levelID, currentStars)
	libraries.mixpanel.logEvent("mainGameEnded", {gameWon = true, coinsWon = currentCoins, starsWon = currentStars, worldIndex = worldID, levelIndex = levelID, timesPlayed = eventTimesPlayed})

	local nextSceneParameters = {
		worldIndex = worldID,
		levelIndex = levelID,
		gamemodeData = gamemodeData,
		subject = savedSubject,
	}
	
	libraries.director.performWithDelay(scenePath, 1000, function()
		local function onBackReleased()
			libraries.winScene.disableButtons()
			libraries.gameHelper.loader("scenes.menus.loading", {nextScene = "scenes.menus.levels", sceneList = libraries.sceneList.menus, nextSceneParameters = nextSceneParameters})
		end
		local function onRetryReleased()
			libraries.winScene.disableButtons()
			retryGame()
		end
		local function onPlayReleased()
			libraries.winScene.disableButtons()
			libraries.gameHelper.loader("scenes.game.bonus", {stars = currentStars, levelIndex = levelID, worldIndex = worldID})
		end

		local scale = display.viewableContentWidth / 1024
		libraries.music.fade(200)
		libraries.sound.play("finish")
		
		display.remove(endBanner)
		local pathEndBanner = libraries.localization.format("images/game/complete_%s.png")
		endBanner = display.newImage(pathEndBanner, true)
		endBanner.x = display.contentCenterX
		endBanner.y = display.screenOriginY - endBanner.contentHeight
		endBanner.xScale = scale
		endBanner.yScale = scale
		game.hudGroup:insert(endBanner)

		transition.to(endBanner, {delay = 500, time = 500, y = display.contentCenterY, transition = easing.outQuad})
		transition.to(endBanner, {delay = 1500, time = 500, y = display.screenOriginY + display.viewableContentHeight + endBanner.height, transition = easing.outQuad, onComplete = function()
			local rewardDelay =	libraries.rewardsService.check(gamemodeData.endRewards, currentPlayer)
			libraries.director.performWithDelay(scenePath, rewardDelay, function()
				currentPlayer.coins = currentPlayer.coins + currentCoins
				libraries.winScene.show(currentStars, currentCoins, onBackReleased, onRetryReleased, onPlayReleased)
				if currentPlayer.energy < 5 then
					libraries.winScene.retrySetEnabled(false)
				end
			end)
		end})
	end)
end

local function loseGame()
	libraries.mixpanel.logEvent("mainGameEnded", {gameWon = false, coinsWon = 0, starsWon = 0, worldIndex = worldID, levelIndex = levelID, timesPlayed = eventTimesPlayed})
	game.pause()
	isGameOver = true
	
	for unitIndex = #activeUnits, 1, -1 do
		local unit = activeUnits[unitIndex]
		if unit.team == TEAM_INDEX_PLAYER then
			unit:setAnimation("LOSE")
		else
			unit:setAnimation("WIN")
		end
	end
	
	local function onBackReleased()
		libraries.loseScene.disableButtons()
		libraries.gameHelper.loader("scenes.menus.loading", {nextScene = "scenes.menus.levels", sceneList = libraries.sceneList.menus})
	end
	local function onRetryReleased()
		libraries.loseScene.disableButtons()
		retryGame()
	end
	
	libraries.music.fade(200)
	libraries.loseScene.show(onBackReleased, onRetryReleased)
	if currentPlayer.energy < 5 then
		libraries.loseScene.retrySetEnabled(false)
	end
end

local function checkOverridePause(eventName)
	if overridePaused then
		if currentEvent then
			if currentEvent.pauseUntil == eventName then
				transition.cancel(TAG_FOCUS_EVENT)
				if removeHandEvent and removeHandEvent == eventName then
					transition.cancel(TAG_HAND_EVENT)
					transition.to(tutorialHand, {time = 400, alpha = 0})
				end
				if removeFocusEvent and removeFocusEvent == eventName then
					transition.cancel(TAG_HAND_EVENT)
					transition.to(tutorialFocus, {time = 400, alpha = 0})
				end
				overridePaused = false
				currentEvent = nextEvent
			end
		end
	end
end 

local function screenFocusTransition(parameters)
	local x, y = parameters.x, parameters.y
	if parameters.position and "string" == type(parameters.position) then
		local tutorialElement = tutorialElements[parameters.position]
		if tutorialElement and tutorialElement.localToContent then
			x, y = tutorialElement:localToContent(0,0)
		else
			x, y = 0, 0
			libraries.logger.error("[GAME] "..tostring(parameters.position).." Does not have a valid position.")
		end
	end
	
	local offsetX = parameters.offsetX or 0
	local offsetY = parameters.offsetY or 0
	
	removeFocusEvent = parameters.removeEvent
	
	local transitionParameters = {
		x = x + offsetX,
		y = y + offsetY,
		width = parameters.width,
		height = parameters.height,
		time = parameters.time,
		delay = parameters.delay,
		onComplete = function()
			checkOverridePause(NAME_EVENT_TUTORIAL_TRANSITION_ENDED)
		end,
		alpha = parameters.alpha,
		tag = TAG_FOCUS_EVENT,
	}
	transition.to(tutorialFocus, transitionParameters)
end

local function handDragTransition(parameters)
	local fromX, fromY = parameters.fromX, parameters.fromY
	local toX, toY = parameters.toX, parameters.toY
	if parameters.from and "string" == type(parameters.from) then
		fromX, fromY = tutorialElements[parameters.from]:localToContent(0,0)
	end
	if parameters.to and "string" == type(parameters.to) then
		toX, toY = tutorialElements[parameters.to]:localToContent(0,0)
	end
	
	local offsetToX = parameters.offsetToX or 0
	local offsetToY = parameters.offsetToY or 0
	local offsetFromX = parameters.offsetFromX or 0
	local offsetFromY = parameters.offsetFromY or 0
	
	removeHandEvent = parameters.removeEvent
	
	fromX = fromX or 0
	fromY = fromY or 0
	toX = toX or 0
	toY = toY or 0
	
	fromX = fromX + offsetFromX
	fromY = fromY + offsetFromY
	toX = toX + offsetToX
	toY = toY + offsetToY
	
	transition.cancel(TAG_HAND_EVENT)
	
	local function handTransition(firstDelay)
		tutorialHand:playSequence("normal")
		tutorialHand.alpha = 0
		tutorialHand.x = fromX
		tutorialHand.y = fromY
		transition.to(tutorialHand, {tag = TAG_HAND_EVENT, delay = firstDelay, time = 500, alpha = 1, onComplete = function()
			tutorialHand:playSequence("press")
			transition.to(tutorialHand, {tag = TAG_HAND_EVENT, delay = 400, time = 800, y = toY, transition = easing.outSine})
			transition.to(tutorialHand, {tag = TAG_HAND_EVENT, delay = 400, time = 800, x = toX, onComplete = function()
				tutorialHand:playSequence("unpress")
				transition.to(tutorialHand, {tag = TAG_HAND_EVENT, delay = 200, time = 400, alpha = 0, onComplete = function()
					handTransition(0)
				end})
			end})
		end})
	end
	handTransition(0)
end

local function handTapAnimation(parameters)
	local x, y = parameters.x, parameters.y
	if parameters.position and "string" == type(parameters.position) then
		local tutorialElement = tutorialElements[parameters.position]
		if tutorialElement and tutorialElement.localToContent then
			x, y = tutorialElement:localToContent(0,0)
		else
			x, y = 0, 0
			libraries.logger.error("[GAME] "..tostring(parameters.position).." Does not have a valid position.")
		end
	end
	
	transition.cancel(TAG_HAND_EVENT)
	removeHandEvent = parameters.removeEvent
	
	tutorialHand.x = x + 20
	tutorialHand.y = y + 20
	tutorialHand:playSequence("tap")
	transition.to(tutorialHand, {tag = TAG_HAND_EVENT, delay = 0, time = 500, alpha = 1})
end

local function removeScrollViews()
	display.remove(unitScrollView)
	unitScrollView = nil
	
	display.remove(warzoneScrollView)
	warzoneScrollView = nil
end

local function createDragIcon(positionX, positionY, unitIndex, worldIndex)
	local dragIcon
	libraries.sound.play("dragUnit")
	if "hero" == unitIndex then
		dragIcon = display.newImage("units/hero/"..libraries.herolist[currentPlayer.heroIndex].skinName.."/head_a.png")
	elseif unitIndex == "item" then
		dragIcon = display.newImage("images/game/poder_2.png")
	else
		dragIcon = display.newImage(libraries.unitFactory.getUnitIconPath(worldIndex, unitIndex))
	end
	local scale = SIZE_ICON_UNIT / dragIcon.width
	dragIcon.xScale = scale
	dragIcon.yScale = scale
	dragIcon.anchorY = 1
	dragIcon.x = positionX
	dragIcon.y = positionY
	game.dragGroup:insert(dragIcon)
	transition.from(dragIcon, {time = 300, alpha = 0, xScale = 0.1, yScale = 0.1, transition = easing.outQuad})
	return dragIcon
end

local function spawnUnit(unitIndex, worldIndex, lane, teamIndex, spawnX)
	
	if spawnX then
		extraUnitData.spawnX = spawnX
	else
		extraUnitData.spawnX = nil
	end
	
	if teamIndex == TEAM_INDEX_PLAYER then
		extraUnitData.upgradeLevel = currentPlayer.units[unitIndex] and currentPlayer.units[unitIndex].upgradeLevel or 1
	else
		extraUnitData.upgradeLevel = 1
	end
	local unit = libraries.unitFactory.newUnit(unitIndex, worldIndex, lane, teamIndex, extraUnitData)
	if unit.canSummon then
		unit.spawnUnit = spawnUnit
	end
	activeUnits[#activeUnits + 1] = unit
	unitCounts[teamIndex] = unitCounts[teamIndex] + 1
	unitsSpawned[teamIndex] = unitsSpawned[teamIndex] + 1
	transition.from(unit.group, {time = 400, alpha = 0, transition = easing.outQuad})
	if unit.isHero then
		scheduleEnergyPause = true
	end
	return unit
end

local function spawnItem(itemIndex, lane)
	local itemSheetData = { width = 128, height = 512, numFrames = 16, sheetContentWidth = 1024, sheetContentHeight = 1024 }
	local itemSheet = graphics.newImageSheet( "images/game/thunder.png", itemSheetData )
	local sequenceData = {
		{ name = "thunder", sheet = itemSheet, start = 1, count = 16, time = 800, loopCount = 1},
	}
	local function itemOnUnit(unitIndex)
		if lane.unitList[unitIndex] then
			local unit = lane.unitList[unitIndex]
			if unit.unitData.name ~= "building" and unit.team == 2 and not unit.dead then
				local itemSprite = display.newSprite( itemSheet, sequenceData )
				itemSprite.x = unit.group.x
				itemSprite.y = unit.group.y
				itemSprite.anchorY = 1
				itemSprite:play()
				libraries.sound.play("bolt")
				lane:insert(itemSprite)
				unit.paused = true
				
				function itemSprite:sprite(event)
					if event.phase == "ended" then
						display.remove(self)
						unit.currentHealth = 0.005
						unit.dead = true
						unit.paused = false
						unit:setAnimation("DEAD")
						itemOnUnit(unitIndex - 1)
					end
				end

				itemSprite:addEventListener("sprite", itemSprite)
			else
				itemOnUnit(unitIndex + 1)
			end
		end
	end
	itemOnUnit(1)
end

local function addEnemyUnit(unitIndex)
	local chosenLane
	local currentAttempt = 0
	repeat
		currentAttempt = currentAttempt + 1
		chosenLane = laneList[math.random(1, #laneList)]
	until not chosenLane.disabled or currentAttempt >= 50
	
	--local enemyIdWorld = worldID == 2 and 1 or worldID
--	if worldID == 2 then
--		enemy.
--	end
	local unitOptions = {
		skin = SKIN_WORLD[worldID],
		spine = worldID == 2 and "skeleton2" or "skeleton"
	}

	local enemy = spawnUnit(unitIndex, worldID, chosenLane, TEAM_INDEX_COMPUTER)
	tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_ENEMY] = enemy.group
	if currentGamemode.enemyAttackMultiplier then
		enemy.attackMultiplier = currentGamemode.enemyAttackMultiplier
	end
end
		
local function iconTouched(event)
	local icon = event.target
	if event.phase == "began" and not unitSpawnFreezed then
        display.getCurrentStage():setFocus( icon )
        icon.isFocus = true
		icon.dragIcon = nil
    elseif icon.isFocus then
        if event.phase == "moved" then
			local x, y = event.x, event.y
			
			if y < event.yStart - DRAG_START_Y_UNITBAR then
				if not icon.isLocked then
					if not icon.dragIcon then
						local realX, realY = icon:localToContent(0,0)
						local worldIndex = icon.worldID or 1
						icon.dragIcon = createDragIcon(realX, realY, icon.unitIndex, worldIndex)
					end
				end
			elseif (x < event.xStart - TOLERANCE_DRAG_UNITBAR or x > event.xStart + TOLERANCE_DRAG_UNITBAR) and icon.isDragging ~= true then
				icon.isFocus = nil
				unitScrollView:takeFocus(event)
				return false
			end
			
            if icon.dragIcon then
				icon.isDragging = true
				icon.dragIcon.x = x
				icon.dragIcon.y = y
				
				local laneFound = false
				for index = 1, #laneList do
					local lane = laneList[index]
					
					local laneY = lane.y + SIZE_QUADS * 0.5
					
					if y < laneY and y > laneY - SIZE_QUADS or ((index == #laneList) and y < laneY) then
						icon.dragIcon.lane = lane
						laneFound = true
						if not lane.disabled then
							lane:setFillColor(unpack(libraries.colors.lime))
						else
							lane:setFillColor(unpack(libraries.colors.red))
						end
					else
						lane:setFillColor(unpack(libraries.colors.white))
						if not laneFound then
							icon.dragIcon.lane = nil
						end
					end
				end
			end
		elseif event.phase == "ended" or event.phase == "cancelled" then
			if icon.dragIcon then
				local function deleteDragIcon()
					local dragIcon = icon.dragIcon
					transition.cancel(dragIcon)
					icon.dragIcon = nil
					transition.to(dragIcon, {time = 500, alpha = 0, transition = easing.inQuad, onComplete = function()
						display.remove(dragIcon)
						dragIcon = nil
					end})
				end
				
				local lane = icon.dragIcon.lane
				if lane and not lane.disabled then
					lane:setFillColor(unpack(libraries.colors.white))
					
					if icon.foodConsumption <= currentFood and icon.energyConsumption <= currentEnergy and icon.itemConsumption <= currentItemRecharge then
						currentFood = currentFood - icon.foodConsumption
						currentEnergy = currentEnergy - icon.energyConsumption
						currentItemRecharge = currentItemRecharge - icon.itemConsumption
						
						libraries.sound.play("dropDraggedUnit")
					
						local dragIcon = icon.dragIcon
						icon.dragIcon = nil

						local scrollX, scrollY = warzoneScrollView:getContentPosition()
						dragIcon.x = dragIcon.x - scrollX
						dragIcon.y = dragIcon.y - scrollY - lane.y

						local toX = icon.unitIndex == "item" and dragIcon.x or lane.spawnX[TEAM_INDEX_PLAYER]
						transition.to(dragIcon, {time = 400, x = toX, y = 0, transition = easing.outQuad, onComplete = function()
							checkOverridePause(NAME_EVENT_UNIT_SPAWNED)
							if icon.unitIndex == "item" then
								spawnItem(icon.unitIndex, lane)
								icon.maskY = -itemIcon.height * 0.5
							else
								local unit =  spawnUnit(icon.unitIndex, icon.worldID, lane, TEAM_INDEX_PLAYER)
								--spawnItem(icon.unitIndex, lane)
								if tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_PLAYER_UNIT] then
									unit.group.onSpecialComplete = nil
								end

								unit.group.onSpecialComplete = function()
									checkOverridePause(NAME_EVENT_LAST_UNIT_SPECIAL)
									currentPlayer.badges.data.specialAttackCount = currentPlayer.badges.data.specialAttackCount + 1
								end
								tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_PLAYER_UNIT] = unit.group
								if currentGamemode.playerAttackMultiplier then
									unit.attackMultiplier = currentGamemode.playerAttackMultiplier
								end
								if icon.maskY then
									icon.maskY = -itemIcon.height * 0.5
								end
							end
							transition.to(dragIcon, {time = 400, alpha = 0, transition = easing.outQuad, onComplete = function()
								display.remove(dragIcon)
								dragIcon = nil
							end})
						end})
						lane:insert(dragIcon)
					else
						deleteDragIcon()
					end
				else
					if lane then
						lane:setFillColor(unpack(libraries.colors.white))
					end
					deleteDragIcon()
				end
			end
			
            display.getCurrentStage():setFocus( nil )
            icon.isFocus = nil
			icon.dragIcon = nil
			icon.isDragging = false
        end
    end
    return true
end

local function createBuilding(buildingIndex, worldData, lane, teamIndex)
	local imagelist = worldData.buildingList[buildingIndex].images
	local healthbarY = worldData.buildingList[buildingIndex].healthbarY
	local offsetY = worldData.buildingList[buildingIndex].offsetY
	local buildingPath = worldData.buildingList.path
	local building = {
		setAnimation = function(self, animationName)
		
		end,
		updateAnimation = function(self) end,
		setColor = function(self) end,
		update = function(self)
			if self.dead then
				if not self.deadCheck then
					self.deadCheck = true
					local unitTeam = self.team
					local side = 2 * unitTeam - 3
					self.lane.spawnX[unitTeam] = self.lane.spawnX[unitTeam] + (side * WIDTH_COLUMN_FORTRESSLANE)
					
					lostBuildings[unitTeam] = lostBuildings[unitTeam] + 1
					
					playerHealths[unitTeam] = (totalBuildings[unitTeam] - lostBuildings[unitTeam]) / totalBuildings[unitTeam]
					if unitTeam == TEAM_INDEX_PLAYER then
						leftHealthBarFill.width = SIZE_HEALTHBAR.width * playerHealths[unitTeam]
					else
						rightHealthBarFill.width = SIZE_HEALTHBAR.width * playerHealths[unitTeam]
					end
					
					if lostBuildings[unitTeam] == totalBuildings[unitTeam] then
						if TEAM_INDEX_PLAYER == unitTeam then
							if gameConditions.loseOnBuildingsLost then
								loseGame()
							end
						elseif TEAM_INDEX_COMPUTER == unitTeam then
							if gameConditions.winOnBuildingsKilled then
								winGame()
							end
						end
					end
					
					local function disableLane(lane)
						local flag = libraries.gameHelper.getFlag()
						flag.anchorY = 1
						flag.x = self.group.x
						flag.y = self.group.y - self.offsetY - SIZE_QUADS * 0.5
						self.group.parent:insert(flag)
						lane.disabled = true
					end
					self.lane.activeBuildings[unitTeam] = self.lane.activeBuildings[unitTeam] - 1
					if self.lane.activeBuildings[unitTeam] <= 0 then
						disableLane(self.lane)
					end
				end
			end
		end,
		lane = lane,
		team = teamIndex,
		noCoin = true,
	}
	
	building.group = display.newGroup()
	building.currentHealth = 500
	building.offsetY = offsetY
	building.unitData = {
		name = "building",
		health = 500,
		hitOffset = {x = 0, y = -60},
		coinsReward = 100,
		deathSound = "towerCollapse"..teamIndex,
	}
	
	building.health = worldData.buildingList[buildingIndex].health
	
	local conditionPerfect = display.newImage(buildingPath..imagelist.conditionPerfect)
	conditionPerfect.anchorY = 1
	building.group:insert(conditionPerfect)
	
	local conditionDamaged = display.newImage(buildingPath..imagelist.conditionDamaged)
	conditionDamaged.anchorY = 1
	building.group:insert(conditionDamaged)
	
	local conditionDestroyed = display.newImage(buildingPath..imagelist.conditionDestroyed)
	conditionDestroyed.anchorY = 1
	building.group:insert(conditionDestroyed)
	
	conditionDestroyed.isVisible = false
	conditionDamaged.isVisible = false
	
	local healthbarOptions = {
		width = 64,
		height = 8,
		barPadding = 2,
		barColors = {empty = {1,0.5,0}, full = {0,1,0}},
	}
	
	local healthbar = libraries.indicator.newBar(healthbarOptions)
	healthbar.x = 0
	healthbar.y = building.group.y + healthbarY
	building.group:insert(healthbar)
	building.healthbar = {
		setFillAmount = function(self, fillAmount)
			if fillAmount > 0.7 then
				conditionPerfect.isVisible = true
				conditionDamaged.isVisible = false
				conditionDestroyed.isVisible = false
			elseif fillAmount > 0.3 then
				conditionPerfect.isVisible = false
				conditionDamaged.isVisible = true
				conditionDestroyed.isVisible = false
			else
				conditionPerfect.isVisible = false
				conditionDamaged.isVisible = false
				conditionDestroyed.isVisible = true
			end
			healthbar:setFillAmount(fillAmount)
		end,
	}
	
	return building
end

local function createLanes()
	
	local worldData = libraries.worldsData[worldID]
	
	display.setDefault( "textureWrapX", "mirroredRepeat" )
	display.setDefault( "textureWrapY", "mirroredRepeat" )
	
	local warzoneHeight = 420
	local warzoneWidth = currentGamemode.warzoneWidth
	local warzoneBackground = display.newRect(warzoneWidth * 0.5, warzoneScrollViewHeight, warzoneWidth * 2, warzoneHeight)
	local warzoneData = libraries.backgroundList[backgroundID].warzone
	warzoneBackground.fill = { type = "image", filename = warzoneData.background.filePath }
	warzoneBackground.fill.scaleY = 1
	warzoneBackground.fill.scaleX = (warzoneData.background.width / 2) / warzoneWidth
	warzoneBackground.anchorY = 1
	warzoneScrollView:insert(warzoneBackground)
	
	laneList = {}
	local fortressData = currentGamemode.fortressData
	local totalLaneHeight = currentGamemode.lanes * SIZE_QUADS

	for laneIndex = 1, currentGamemode.lanes do
		local lane = display.newGroup()
		lane.y = warzoneScrollViewHeight - (warzoneHeight * 0.5) + (totalLaneHeight * 0.5) - ((laneIndex - 1) * SIZE_QUADS) - SIZE_QUADS * 0.5
		warzoneScrollView:insert(lane)
		
		lane.spawnX = {
			[TEAM_INDEX_PLAYER] = WIDTH_COLUMN_FORTRESSLANE * fortressData[TEAM_INDEX_PLAYER].columns + AMOUNT_SLANT * laneIndex,
			[TEAM_INDEX_COMPUTER] = warzoneWidth - (WIDTH_COLUMN_FORTRESSLANE * fortressData[TEAM_INDEX_COMPUTER].columns + AMOUNT_SLANT * laneIndex),
		}
		
		local laneTexture = display.newRect(0,0, warzoneWidth, SIZE_QUADS )
		laneTexture.y = warzoneScrollViewHeight - (warzoneHeight * 0.5) + (totalLaneHeight * 0.5) - ((laneIndex - 1) * SIZE_QUADS) - SIZE_QUADS * 0.5
		laneTexture.anchorX = 0
		laneTexture.fill = { type = "image", filename = warzoneData.laneTexture }
		laneTexture.fill.scaleY = 1
		laneTexture.fill.scaleX = SIZE_QUADS / warzoneWidth
		laneTexture.index = laneIndex
		warzoneScrollView:insert(laneTexture)
		lane.texture = laneTexture
		
		function lane:setFillColor(...)
			lane.texture:setFillColor(...)
		end

		if fortressData[TEAM_INDEX_PLAYER] and fortressData[TEAM_INDEX_PLAYER].enabled and fortressData[TEAM_INDEX_PLAYER].columns > 0 then
			laneTexture.path.x1 = AMOUNT_SLANT * laneIndex
			laneTexture.path.x2 = AMOUNT_SLANT * (laneIndex - 1)
		else
			lane.spawnX[TEAM_INDEX_PLAYER] = X_SPAWN_NO_FORTRESS
		end

		if fortressData[TEAM_INDEX_COMPUTER] and fortressData[TEAM_INDEX_COMPUTER].enabled and  fortressData[TEAM_INDEX_COMPUTER].columns > 0 then
			laneTexture.path.x4 = -AMOUNT_SLANT * laneIndex
			laneTexture.path.x3 = -AMOUNT_SLANT * (laneIndex - 1)
		else
			lane.spawnX[TEAM_INDEX_COMPUTER] = warzoneWidth - X_SPAWN_NO_FORTRESS
		end
		
		lane.activeBuildings = {
			[TEAM_INDEX_PLAYER] = 0,
			[TEAM_INDEX_COMPUTER] = 0,
		}
		
		lane.unitList = {}
		function lane:addUnit(unit)
			local assignedIndex = #self.unitList + 1
			self.unitList[assignedIndex] = unit
			unit.assignedLaneIndex = assignedIndex
			self:insert(unit.group)
		end
		
		laneList[laneIndex] = lane
		if laneIndex == 1 then
			tutorialElements[ELEMENTS_TUTORIAL_TAGS.FIRST_LANE] = lane
		end
	end

	for index = #laneList, 1 , -1 do
		warzoneScrollView:insert(laneList[index])
	end
	
	local floorOffsets = {
		[TEAM_INDEX_PLAYER] = ((fortressData[TEAM_INDEX_PLAYER].columns + 2) * SIZE_QUADS) * 0.5,
		[TEAM_INDEX_COMPUTER] = warzoneWidth - ((fortressData[TEAM_INDEX_COMPUTER].columns + 2) * SIZE_QUADS) * 0.5,
	}
	
	local reverseLanes = {}
	for index = 1, #laneList do
		reverseLanes[index] = laneList[#laneList + 1 - index]
	end
	
	local texturePath = libraries.backgroundList[backgroundID].path .. "textures/"
	for teamIndex = 1, 2 do
		local columns  = fortressData[teamIndex].columns
		if columns > 0 and fortressData[teamIndex].enabled then
			libraries.gameHelper.createFloor(columns, reverseLanes, (teamIndex * 2) - 3, worldID, floorOffsets[teamIndex], 0, texturePath)
		end
	end
	
	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	local leftEdgeTexture = display.newImage(libraries.backgroundList[backgroundID].path .."edge_1.png")
	leftEdgeTexture.x = -30
	leftEdgeTexture.y = -50
	laneList[1]:insert(leftEdgeTexture)
	
	local rightEdgeTexture = display.newImage(libraries.backgroundList[backgroundID].path .."edge_2.png")
	rightEdgeTexture.x = warzoneWidth + 30
	rightEdgeTexture.y = -50
	laneList[1]:insert(rightEdgeTexture)
	
	warzoneScrollView:setScrollWidth(warzoneWidth)
end

local function updateParallax()
	local scrollX, scrollY = warzoneScrollView:getContentPosition()
	if scrollX < 0 and scrollX > parallaxRightLimit then
		if bgComponentList then
			for index = 1, #bgComponentList do
				local backgroundComponent = bgComponentList[index]
				backgroundComponent.fill.x = -scrollX * backgroundComponent.parallaxRatio
			end
		end
	end
end

local function addBuildings()
	local worldData = libraries.worldsData[worldID]
	local fortressData = currentGamemode.fortressData
	local warzoneWidth = currentGamemode.warzoneWidth
	
	local buildings = currentGamemode.buildings or {}
	
	for laneIndex = 1, currentGamemode.lanes do
		local lane = laneList[laneIndex]
		for teamIndex = 1, 2 do
			if fortressData[teamIndex] and fortressData[teamIndex].enabled and fortressData[teamIndex].columns > 0 then
				local teamSide = (teamIndex * 2 - 3) * -1

				local fortressColumns = currentGamemode.fortressData[teamIndex].columns
				local fortressLaneWidth = WIDTH_COLUMN_FORTRESSLANE * fortressColumns
				local fortressLaneGroupX = warzoneWidth * 0.5 - (warzoneWidth * 0.5 * teamSide) + ((AMOUNT_SLANT * laneIndex) - AMOUNT_SLANT * 0.5 + fortressLaneWidth * 0.5) * teamSide

				display.setDefault( "textureWrapX", "clampToEdge" )
				display.setDefault( "textureWrapY", "clampToEdge" )
				for buildingIndex = 1, fortressColumns do
					local buildingType = buildings[teamIndex] and buildings[teamIndex][laneIndex] and buildings[teamIndex][laneIndex][buildingIndex] or 1

					local building = createBuilding(buildingType, worldData, lane, teamIndex)
					building.group.x = fortressLaneGroupX - (fortressLaneWidth * 0.5) + (WIDTH_COLUMN_FORTRESSLANE * (buildingIndex - 1)) + WIDTH_COLUMN_FORTRESSLANE * 0.5
					building.group.y = SIZE_QUADS * 0.5 + building.offsetY
					building.group.xScale = teamSide
					lane:insert(building.group)
					
					lane.activeBuildings[teamIndex] = lane.activeBuildings[teamIndex] + 1

					activeUnits[#activeUnits + 1] = building
					lane.unitList[#lane.unitList + 1] = building
					
					totalBuildings[teamIndex] = totalBuildings[teamIndex] + 1
				end
			end
		end
	end
end

local function populateUnitBar()
	local availableUnitCount = 0
	for index = 1, #unitAvailability do
		local unitIndex = unitAvailability[index].unitIndex
		local unitWorld = unitAvailability[index].world
		local currentUnit = libraries.unitsData[unitWorld][1][unitIndex].stats
		if currentUnit.available then
			availableUnitCount = availableUnitCount + 1
		end
	end
	if currentGamemode.heroAvailable then
		availableUnitCount = availableUnitCount + 1
	end
	if currentGamemode.itemsAvailable then
		availableUnitCount = availableUnitCount + 1
	end

	local fillerWidth = (availableUnitCount * SIZE_ICON_UNIT ) + (SIZE_ICON_UNIT * 0.7)
	--fillerWidth = 0
	
	local menuFiller = display.newRect(fillerWidth * 0.5, 0, fillerWidth, 5)
	menuFiller.isVisible = false
	unitScrollView:insert(menuFiller)
	
	local playerUnitData = currentPlayer.units
	
	unitIcons = {}
	local positionUnitIndex = 1

	local function createUnitIcon(iconPath, iconType, foodCost, energyCost, itemCost)
		local unitIcon = display.newGroup()
		unitIcon.anchorChildren = true

		local unitIconBackground = display.newImage(ICON_BACKGROUND[iconType])
		unitIcon:insert(unitIconBackground)
		unitIcon.background = unitIconBackground
		
		if iconType == "unit" then
			local unitIconPortrait = display.newImage(iconPath)
			local scale = SIZE_ICON_UNIT / unitIconPortrait.width
			unitIconPortrait.xScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.yScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.y = OFFSETS.PORTRAIT_UNIT_ICON.y
			unitIcon:insert(unitIconPortrait)
			unitIcon.portrait = unitIconPortrait
		elseif iconType == "locked" then
			local unitIconPortrait = display.newImage("images/game/unknown.png")
			local scale = 0.8
			unitIconPortrait.xScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.yScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.y = -20
			unitIcon:insert(unitIconPortrait)
			unitIcon.portrait = unitIconPortrait
		elseif iconType == "hero" then
			local unitIconPortrait = display.newImage(iconPath)
			local scale = SIZE_ICON_UNIT / unitIconPortrait.width
			unitIconPortrait.xScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.yScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.y = -20
			unitIcon:insert(unitIconPortrait)
			unitIcon.portrait = unitIconPortrait
		elseif iconType == "item" then
			local unitIconPortrait = display.newImage("images/game/poder_2.png")
			local scale = 0.9
			unitIconPortrait.xScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.yScale = scale * SCALE_UNIT_ICON_PORTRAIT
			unitIconPortrait.y = 0
			unitIcon:insert(unitIconPortrait)
			unitIcon.portrait = unitIconPortrait
		end

		unitIcon.foodConsumption = foodCost or 0
		unitIcon.energyConsumption = energyCost or 0
		unitIcon.itemConsumption = itemCost or 0
		local priceTagTextOptions = {
			x = OFFSETS.PRICETAG_UNIT_ICON.x,
			y = OFFSETS.PRICETAG_UNIT_ICON.y,
			align = "center",
			font = libraries.settings.fontName,
			text = foodCost > 0 and foodCost or energyCost > 0 and energyCost or "COST",
			fontSize = SIZE_FONT_PRICE_UNIT,
		}

		local priceText = display.newText(priceTagTextOptions)
		unitIcon.priceText = priceText
		unitIcon:insert(priceText)
		
		priceText.isVisible = iconType == "unit"
		unitIcon.isLocked = iconType == "locked"
		
		function unitIcon:setAvailable(available, affordableColor)
			local affordableColor = affordableColor or COLOR_AFFORDABLE_ENERGY
			if available then 
				self.priceText:setFillColor(unpack(affordableColor))
				self.portrait:setFillColor(1)
				self.background:setFillColor(1)
			else
				self.priceText:setFillColor(unpack(COLOR_EXPENSIVE))
				self.portrait:setFillColor(0.7)
				self.background:setFillColor(0.7)
			end
		end
		
		return unitIcon
	end
		
	if currentGamemode.itemsAvailable then
		local iconPath = "images/game/poder_1.png"
		
		itemIcon = createUnitIcon(iconPath, "item", 0, 0, currentGamemode.maxItemRecharge)
		itemIcon.x = padding + SIZE_ICON_UNIT * 0.5 + (SIZE_ICON_UNIT + padding) * (positionUnitIndex - 1)
		itemIcon.y = unitScrollView.height * 0.5 + OFFSETS.UNIT_ICON.y
		itemIcon.width = SIZE_ICON_UNIT
		itemIcon.height = SIZE_ICON_UNIT
		itemIcon.unitIndex = "item"
		unitScrollView:insert(itemIcon)
		local mask = graphics.newMask("images/game/mask.png")
		itemIcon:setMask(mask)
		itemIcon.maskY = -itemIcon.height * 0.5
		itemIcon.isHitTestMasked = false
		itemIcon:addEventListener("touch", iconTouched)
		
		positionUnitIndex = positionUnitIndex + 1
		
		--tutorialElements[ELEMENTS_TUTORIAL_TAGS.HERO_ITEM_UNITBAR] = heroUnitIcon
	end
	
	if currentGamemode.heroAvailable then
		local iconPath = "units/hero/"..libraries.herolist[currentPlayer.heroIndex].skinName.."/head_a.png"
		
		heroUnitIcon = createUnitIcon(iconPath, "hero", 0, currentGamemode.maxEnergy)
		heroUnitIcon.x = padding + SIZE_ICON_UNIT * 0.5 + (SIZE_ICON_UNIT + padding) * (positionUnitIndex - 1)
		heroUnitIcon.y = unitScrollView.height * 0.5 + OFFSETS.UNIT_ICON.y
		heroUnitIcon.width = SIZE_ICON_UNIT
		heroUnitIcon.height = SIZE_ICON_UNIT
		heroUnitIcon.unitIndex = "hero"
		unitScrollView:insert(heroUnitIcon)
		local mask = graphics.newMask("images/game/mask.png")
		heroUnitIcon:setMask(mask)
		heroUnitIcon.maskY = -itemIcon.height * 0.5
		heroUnitIcon.isHitTestMasked = false
		heroUnitIcon:addEventListener("touch", iconTouched)
		
		positionUnitIndex = positionUnitIndex + 1
		
		tutorialElements[ELEMENTS_TUTORIAL_TAGS.HERO_ITEM_UNITBAR] = heroUnitIcon
	end

	for unitBarIndex = 1, #unitAvailability do
		local unitIndex = unitAvailability[unitBarIndex].unitIndex
		local unitWorld = unitAvailability[unitBarIndex].world
		local unitProxy = unitAvailability[unitBarIndex].unitProxy
		local unitData = libraries.unitsData[unitWorld][1][unitIndex].stats
		if unitData.available then
			local playerCanUseUnit = playerUnitData[unitProxy] and playerUnitData[unitProxy].bought and playerUnitData[unitProxy].unlocked
			local iconPath = libraries.unitFactory.getUnitIconPath(unitWorld, unitIndex)
			local isLocked = (unitAvailability[unitBarIndex] and playerCanUseUnit) and "unit" or "locked"
			local unitIcon = createUnitIcon(iconPath, isLocked, unitData.foodConsumption)
			unitIcon.x = padding + SIZE_ICON_UNIT * 0.5 + (SIZE_ICON_UNIT + padding) * (positionUnitIndex - 1)
			unitIcon.y = unitScrollView.height * 0.5 + OFFSETS.UNIT_ICON.y
			unitIcon.width = SIZE_ICON_UNIT
			unitIcon.height = SIZE_ICON_UNIT
			unitIcon.unitIndex = unitIndex
			unitIcon.worldID = unitWorld
			unitScrollView:insert(unitIcon)
			unitIcon:addEventListener("touch", iconTouched)

			if unitIndex == 1 then
				tutorialElements[ELEMENTS_TUTORIAL_TAGS.FIRST_ITEM_UNITBAR] = unitIcon
			end

			unitIcons[unitBarIndex] = unitIcon
		
			positionUnitIndex = positionUnitIndex + 1
		end
	end
	
	if fillerWidth > display.screenOriginX + display.viewableContentWidth then
		unitScrollView:setScrollWidth(fillerWidth)
	end
end

local function addScrollViews()
	local unitScrollViewOptions = {
		x = display.contentCenterX,
		y = display.screenOriginY + display.viewableContentHeight - unitScrollViewHeight * 0.5,
		width = display.viewableContentWidth,
		height = unitScrollViewHeight,
		scrollWidth = 0,
		scrollHeight = 0,
		hideBackground = true,
		verticalScrollDisabled = true,
		isBounceEnabled = false,
	}
	unitScrollView = libraries.widget.newScrollView(unitScrollViewOptions)
	game.unitBarGroup:insert(unitScrollView)
	
	warzoneScrollViewHeight = display.viewableContentHeight - unitScrollViewHeight + HEIGHT_EXTRA_WARZONE
	local warzoneScrollViewOptions = {
		x = display.contentCenterX,
		y = display.screenOriginY + (warzoneScrollViewHeight + HEIGHT_EXTRA_WARZONE) * 0.5,
		width = display.viewableContentWidth + 2,
		height = warzoneScrollViewHeight,
		scrollWidth = 0,
		scrollHeight = 0,
		hideBackground = true,
		verticalScrollDisabled = true,
		isBounceEnabled = false,
	}
	warzoneScrollView = libraries.widget.newScrollView(warzoneScrollViewOptions)
	game.warzoneScrollGroup:insert(warzoneScrollView)
	
	local warzoneWidth = currentGamemode.warzoneWidth
	parallaxRightLimit = -(warzoneWidth - warzoneScrollView.width)
end

local function updateItemRecharge()
	if currentItemRecharge < currentGamemode.maxItemRecharge then
		currentItemRecharge = currentItemRecharge + (currentGamemode.itemRechargePerSecond / 60 * INTERVAL_UPDATE_GAME)
		if currentItemRecharge > currentGamemode.maxItemRecharge then currentItemRecharge = currentGamemode.maxItemRecharge end
--		local fillAmount = currentItemRecharge / currentGamemode.maxItemRecharge
--		energyBarFill.xScale = fillAmount
--		
--		if scheduleEnergyPause then
--			scheduleEnergyPause = false
--			pauseEnergyRecharge = true
--		end
--		
--		energyBarFill.fill.effect.r = (COLOR_HERO_BAR.full[1] * fillAmount) + (COLOR_HERO_BAR.empty[1] * (1 - fillAmount))
--		energyBarFill.fill.effect.g = (COLOR_HERO_BAR.full[2] * fillAmount) + (COLOR_HERO_BAR.empty[2] * (1 - fillAmount))
--		energyBarFill.fill.effect.b = (COLOR_HERO_BAR.full[3] * fillAmount) + (COLOR_HERO_BAR.empty[3] * (1 - fillAmount))
--		--heroUnitIcon:setAvailable(true, COLOR_AFFORDABLE_ENERGY)
--		
		if itemIcon then
			if itemIcon.itemConsumption > 0 then
				itemIcon.maskY = itemIcon.maskY + ( (currentGamemode.itemRechargePerSecond / 60 * INTERVAL_UPDATE_GAME) * (itemIcon.height / currentGamemode.maxItemRecharge ))
			end
		end
	end
	--energyText.text = stringFormat("%d/%d",currentEnergy, currentGamemode.maxEnergy)
end

local function updateEnergy()
	if currentEnergy < currentGamemode.maxEnergy then
		currentEnergy = currentEnergy + energyRechargePerUpdate
		if currentEnergy > currentGamemode.maxEnergy then currentEnergy = currentGamemode.maxEnergy end
--		local fillAmount = currentEnergy / currentGamemode.maxEnergy
--		energyBarFill.xScale = fillAmount
		
		if scheduleEnergyPause then
			scheduleEnergyPause = false
			pauseEnergyRecharge = true
		end
		
--		energyBarFill.fill.effect.r = (COLOR_HERO_BAR.full[1] * fillAmount) + (COLOR_HERO_BAR.empty[1] * (1 - fillAmount))
--		energyBarFill.fill.effect.g = (COLOR_HERO_BAR.full[2] * fillAmount) + (COLOR_HERO_BAR.empty[2] * (1 - fillAmount))
--		energyBarFill.fill.effect.b = (COLOR_HERO_BAR.full[3] * fillAmount) + (COLOR_HERO_BAR.empty[3] * (1 - fillAmount))
		--heroUnitIcon:setAvailable(true, COLOR_AFFORDABLE_ENERGY)
		
		if heroUnitIcon then
			if heroUnitIcon.energyConsumption > 0 then
				heroUnitIcon.maskY = heroUnitIcon.maskY + ( energyRechargePerUpdate * (heroUnitIcon.height / currentGamemode.maxEnergy ))
			end
		end
	end
	--energyText.text = stringFormat("%d/%d",currentEnergy, currentGamemode.maxEnergy)
end

local function updateFood()
	if currentFood < currentGamemode.maxFoodLevel then
		currentFood = currentFood + foodRechargePerUpdate
		if currentFood > currentGamemode.maxFoodLevel then currentFood = currentGamemode.maxFoodLevel end
		local fillAmount = currentFood / currentGamemode.maxFoodLevel
		foodBarFill.xScale = fillAmount
		
		foodBarFill.fill.effect.r = (COLOR_FOOD_BAR.full[1] * fillAmount) + (COLOR_FOOD_BAR.empty[1] * (1 - fillAmount))
		foodBarFill.fill.effect.g = (COLOR_FOOD_BAR.full[2] * fillAmount) + (COLOR_FOOD_BAR.empty[2] * (1 - fillAmount))
		foodBarFill.fill.effect.b = (COLOR_FOOD_BAR.full[3] * fillAmount) + (COLOR_FOOD_BAR.empty[3] * (1 - fillAmount))
		
		for index = 1, #unitIcons do
			if unitIcons[index].foodConsumption > 0 then
				if unitIcons[index].foodConsumption <= currentFood then
					if not unitIcons[index].isLocked then
						unitIcons[index]:setAvailable(true, COLOR_AFFORDABLE_FOOD)
					end
				else
					unitIcons[index]:setAvailable(false)
				end
			end
		end
	end
	foodText.text = stringFormat("%d/%d",currentFood, currentGamemode.maxFoodLevel)
end

local function setGoals(goalsIn)
	activeGoals = libraries.extratable.deepcopy(goalsIn)
	gameGoals = {}
	if goalsIn then
		for index = 1, #goalsIn do
			activeGoals[index].goalIndex = index
			
			local goalType = goalsIn[index].type
			local goalText = stringFormat(libraries.localization.getString(GOAL_TEXTS[goalType].string), goalsIn[index].amount)
			if goalsIn[index].time then
				goalText = goalText..stringFormat(libraries.localization.getString(GOAL_TEXTS[goalType].time), goalsIn[index].time)
			end
			gameGoals[index] = {complete = false, text = goalText, current = 0, goal = goalsIn[index].amount}
		end
	end
end

local function dropCoin(unit)
	local coin = display.newGroup()
	coin.xScale = 0.05
	coin.yScale = 0.05
	coin.x = unit.group.x
	coin.y = unit.group.y
	coin.canTap = true
	coin.value = unit.unitData.coinsReward
	unit.group.parent:insert(coin)
	
	local rect = display.newRect(0, 0, 150, 150)
	rect:setFillColor(0, 0)
	rect.isHitTestable = true
	coin:insert(rect)
	local coinImage = libraries.gameHelper.getCoin()
	coin:insert(coinImage)
	
	coin.unpickedIndex = #unpickedCoins + 1
	unpickedCoins[coin.unpickedIndex] = coin
	
	local targetX = coin.x + math.random(-110,110)
	local arcHeight = 80
	
	local TIME_AIR = 400
	local TIME_AIR_HALF = TIME_AIR * 0.5
	
	transition.to(coin, {time = TIME_AIR_HALF, xScale = SCALE_COINS, yScale = SCALE_COINS, y = coin.y - arcHeight, transition = easing.outQuad})
	transition.to(coin, {delay = TIME_AIR_HALF, time = TIME_AIR_HALF, y = coin.y, transition = easing.inQuad})
	transition.to(coin, {time = TIME_AIR, x = targetX})
	
--	if coinsDespawn then
--		transition.to(coin, {delay = DELAY_COIN_DESPAWN, time = 400, alpha = 0, onComplete = function()
--			unpickedCoins[coin.unpickedIndex] = nil
--			display.remove(coin)
--			coin = nil
--		end})
--	end
	
	tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_COIN] = coin
	
	function coin:touch(event)
		if self.canTap and not coinsFreezed then
			self.canTap = false
			unpickedCoins[coin.unpickedIndex] = nil
			
			libraries.sound.play("coins")
			transition.cancel(self)
			
			local contentX, contentY = self:localToContent(0,0)
			self.x = contentX
			self.y = contentY
			game.hudGroup:insert(self)

			coinsCollected = coinsCollected + 1
			currentCoins = currentCoins + self.value
			local toX, toY = coinsText:localToContent(0,0)
			transition.to(self, {time = 900, alpha = 0, x = toX, y = toY, transition = easing.outQuad, onComplete = function()
				coinsText.text = currentCoins
				coinsText.xScale = 2
				coinsText.yScale = 2
				transition.to(coinsText, {time = 400, xScale = 1, yScale = 1, transition = easing.outElastic})
				checkOverridePause(NAME_EVENT_COIN_PICKED)
				display.remove(self)
			end})
		end
	end
	coin:addEventListener("touch")
end

local function updateGoals()
	if activeGoals and #activeGoals > 0 then
		for index = #gameGoals, 1, -1 do
			local goalType = activeGoals[index] and activeGoals[index].type or nil
			if GOAL_TYPES.KILL_UNITS == goalType then
				if lostUnits[TEAM_INDEX_COMPUTER] >= activeGoals[index].amount then
					gameGoals[activeGoals[index].goalIndex].complete = true
					table.remove(activeGoals, index)
				end
			elseif GOAL_TYPES.KILL_BUILDINGS == goalType then
				if lostBuildings[TEAM_INDEX_COMPUTER] >= activeGoals[index].amount then
					gameGoals[activeGoals[index].goalIndex].complete = true
					table.remove(activeGoals, index)
				end
			elseif GOAL_TYPES.COLLECT_COINS == goalType then
				if coinsCollected >= activeGoals[index].amount then
					gameGoals[activeGoals[index].goalIndex].complete = true
					table.remove(activeGoals, index)
				end
			end
		end
	else
		winGame()
	end
end

local function updateAI(currentLoop)
	if currentLoop % currentGamemode.enemyUnitInterval == 0 then
		if unitCounts[TEAM_INDEX_COMPUTER] < currentGamemode.maxConcurrentEnemyUnits then
			if unitsSpawned[TEAM_INDEX_COMPUTER] < #currentGamemode.enemyUnits then
				addEnemyUnit(currentGamemode.enemyUnits[unitsSpawned[TEAM_INDEX_COMPUTER] + 1])
			else
				if not currentGamemode.afterMode then
					currentGamemode.afterMode = true
					currentGamemode.enemyUnitInterval = math.ceil(currentGamemode.enemyUnitInterval * 0.75)
					currentGamemode.maxConcurrentEnemyUnits = math.floor(currentGamemode.maxConcurrentEnemyUnits * 1.5)
								
					if currentGamemode.enemyUnitInterval < 50 then
						currentGamemode.enemyUnitInterval = 150
					end
				end
				addEnemyUnit(currentGamemode.enemyUnits[math.random(#currentGamemode.enemyUnits)])
			end
		end
	end
end

local function checkUnitBounds(unit)
	local unitX = unit.group.x
	if unitX > currentGamemode.warzoneWidth + OFFSETS.X_DESPAWN or unitX < -OFFSETS.X_DESPAWN then
		unit.despawn = true
		if TEAM_INDEX_PLAYER == unit.team then
			if gameConditions.winOnUnitDespawn then
				winGame()
			end
		elseif TEAM_INDEX_COMPUTER == unit.team then
			if gameConditions.loseOnEnemyDespawn then
				loseGame()
			end
		end
	end
end

local function updateUnits()
	for unitIndex = #activeUnits, 1, -1 do
		local unit = activeUnits[unitIndex]
		unit:update()
		unit:updateAnimation()
		checkUnitBounds(unit)
		
		local function prepareRemoval()
			if unit.isHero then
				pauseEnergyRecharge = false
			end
			if unit.unitData.deathSound then
				libraries.sound.play(unit.unitData.deathSound)
			end
			
			unit.isRemoving = true
			unitCounts[unit.team] = unitCounts[unit.team] - 1
			transition.to(unit.group, {alpha = 0, onComplete = function()
				unit.removeFlag = true
			end})
		end
		
		if not unit.isRemoving then
			if unit.dead then
				prepareRemoval()

				lostUnits[unit.team] = lostUnits[unit.team] + 1
				if unit.team == TEAM_INDEX_COMPUTER then
					if not unit.noCoin then
						dropCoin(unit)
					end
					currentPlayer.badges.data.killedUnits = currentPlayer.badges.data.killedUnits + 1
				end
			elseif unit.despawn then
				prepareRemoval()
			end
		end
		
		if unit.removeFlag then
			display.remove(unit.group)
			table.remove(activeUnits, unitIndex)
			unit = nil
		end
	end
end

local function showFoodTutorial()
	foodTutorial = display.newGroup()
	foodTutorial.alpha = 0
	
	local scale = 0.75
	local background = display.newImage("images/game/left.png")
	background.xScale = scale
	background.yScale = scale
	foodTutorial:insert(background)
	
	local foodTextOptions = {
		x = 50,
		y = -20,
		width = 280,
		align = "left",
		font = libraries.settings.fontName,
		text = libraries.localization.getString(TEXT_TUTORIAL.FOOD),
		fontSize = 20,
	}
	local tutorialText = display.newText(foodTextOptions)
	foodTutorial:insert(tutorialText)
	
	foodTutorial.x = foodBarFill.x + 140
	foodTutorial.y = foodBarFill.y - 120
	
	transition.to(foodTutorial, {time = 500, alpha = 1, transition = easing.outQuad})
	game.topHudGroup:insert(foodTutorial)
	
	transition.to(foodTutorial, {delay = 4000, time = 500, alpha = 0, transition = easing.inQuad, onComplete = function()
		display.remove(foodTutorial)
		foodTutorial = nil
	end})
end

local function showEnergyTutorial()
	energyTutorial = display.newGroup()
	energyTutorial.alpha = 0
	
	local scale = 0.75
	local background = display.newImage("images/game/left.png")
	background.xScale = scale
	background.yScale = scale
	energyTutorial:insert(background)
	
	local foodTextOptions = {
		x = 50,
		y = -20,
		width = 280,
		align = "left",
		font = libraries.settings.fontName,
		text = libraries.localization.getString(TEXT_TUTORIAL.ENERGY),
		fontSize = 20,
	}
	local tutorialText = display.newText(foodTextOptions)
	energyTutorial:insert(tutorialText)
	
	energyTutorial.x = heroUnitIcon.x + (heroUnitIcon.width * 0.5)
	energyTutorial.y = foodBarFill.y - 80
	
	transition.to(energyTutorial, {time = 500, alpha = 1, transition = easing.outQuad})
	game.topHudGroup:insert(energyTutorial)
	
	transition.to(energyTutorial, {delay = 4000, time = 500, alpha = 0, transition = easing.inQuad, onComplete = function()
		display.remove(energyTutorial)
		energyTutorial = nil
	end})
end

local function updateGamemodeEvents(currentLoop)
	if currentEvent then
		if currentLoop == currentEvent.frame then
			if currentEvent.focusTransition then
				screenFocusTransition(currentEvent.focusTransition)
			end
			if currentEvent.handDrag then
				handDragTransition(currentEvent.handDrag)
			end
			if currentEvent.handTap then
				handTapAnimation(currentEvent.handTap)
			end
			
			eventIndex = eventIndex + 1
			nextEvent = currentGamemode.events[eventIndex]
			
			local function checkSpecalEvent(specialEvent)
				if "showFoodTutorial" == specialEvent then
					showFoodTutorial()
				elseif "showEnergyTutorial" == specialEvent then
					showEnergyTutorial()
				elseif "fullSpecial" == specialEvent then
					local unit = tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_PLAYER_UNIT].unit
					unit.currentSpecialEnergy = unit.unitData.specialEnergy
				elseif "emptySpecial" == specialEvent then
					local unit = tutorialElements[ELEMENTS_TUTORIAL_TAGS.LAST_PLAYER_UNIT].unit
					unit.currentSpecialEnergy = 0
				elseif "allowRandomness" == specialEvent then
					extraUnitData.allowRandomness = true
				end
			end
			
			if currentEvent.specialEvent then
				if "table" == type(currentEvent.specialEvent) then
					for index = 1, #currentEvent.specialEvent do
						checkSpecalEvent(currentEvent.specialEvent[index])
					end
				else
					checkSpecalEvent(currentEvent.specialEvent)
				end
			end
			
			local function checkPauseEvent(pauseEvent)
				if "food" == pauseEvent then
					pauseFoodRecharge = true
				elseif "energy" == pauseEvent then
					pauseEnergyRecharge = true
				end
			end
			
			if currentEvent.pause then
				if "table" == type(currentEvent.pause) then
					for index = 1, #currentEvent.pause do
						checkPauseEvent(currentEvent.pause[index])
					end
				else
					checkPauseEvent(currentEvent.pause)
				end
			end
			
			local function checkUnpauseEvent(unpauseEvent)
				if "food" == unpauseEvent then
					pauseFoodRecharge = false
				elseif "energy" == unpauseEvent then
					pauseEnergyRecharge = false
				end
			end
			
			if currentEvent.unpause then
				if "table" == type(currentEvent.unpause) then
					for index = 1, #currentEvent.unpause do
						checkUnpauseEvent(currentEvent.unpause[index])
					end
				else
					checkUnpauseEvent(currentEvent.unpause)
				end
			end
			
			local function checkFreezeEvent(freezeEvent)
				if "warzoneScrollView" == freezeEvent then
					warzoneScrollView:setIsLocked(true)
				elseif "unitScrollView" == freezeEvent then
					unitScrollView:setIsLocked(true)
				elseif "pauseButton" == freezeEvent then
					pauseButton:setEnabled(false)
				elseif "coinPick" == freezeEvent then
					coinsFreezed = true
				elseif "unitSpawn" == freezeEvent then
					unitSpawnFreezed = true
				end
			end
			
			local function checkUnFreezeEvent(unFreezeEvent)
				if "warzoneScrollView" == unFreezeEvent then
					warzoneScrollView:setIsLocked(false)
				elseif "unitScrollView" == unFreezeEvent then
					unitScrollView:setIsLocked(false)
				elseif "pauseButton" == unFreezeEvent then
					pauseButton:setEnabled(true)
				elseif "coinPick" == unFreezeEvent then
					coinsFreezed = false
				elseif "unitSpawn" == unFreezeEvent then
					unitSpawnFreezed = false
				end
			end
			
			if currentEvent.freeze then
				if "table" == type(currentEvent.freeze) then
					for index = 1, #currentEvent.freeze do
						checkFreezeEvent(currentEvent.freeze[index])
					end
				else
					checkFreezeEvent(currentEvent.freeze)
				end
			end
			
			if currentEvent.unFreeze then
				if "table" == type(currentEvent.unFreeze) then
					for index = 1, #currentEvent.unFreeze do
						checkUnFreezeEvent(currentEvent.unFreeze[index])
					end
				else
					checkUnFreezeEvent(currentEvent.unFreeze)
				end
			end
			
			if currentEvent.pauseUntil then
				overridePaused = true
			else
				currentEvent = nextEvent
			end
		end
	end
end

local function enterFrame(event)
	updateParallax()
	
	if not paused and not overridePaused then
		currentLoop = currentLoop + 1
		if currentLoop % INTERVAL_UPDATE_GAME == 0 then
			if not pauseEnergyRecharge then
				updateEnergy()
			end
			if not pauseFoodRecharge then
				updateFood()
				updateItemRecharge()
			end
			updateGoals()
		end
		
		updateAI(currentLoop)
		updateUnits()
		updateGamemodeEvents(currentLoop)
		debugText.text = currentLoop.." - "..unitCounts[TEAM_INDEX_PLAYER].." - "..unitCounts[TEAM_INDEX_COMPUTER]
	end
	if paused and isGameOver then
		for unitIndex = #activeUnits, 1, -1 do
			local unit = activeUnits[unitIndex]
			unit:updateAnimation()
		end
	end
end

local function createUnitBarBackground()
--	local leftBackground = display.newImage(PATH_BACKGROUND_LEFT_UNITBAR)
--	leftBackground.anchorX = 0
--	leftBackground.anchorY = 1
--	leftBackground.x = display.screenOriginX
--	leftBackground.y = display.screenOriginY + display.viewableContentHeight
--	game.unitBarGroup:insert(leftBackground)
	
	local rightBackground = display.newImage(PATH_BACKGROUND_RIGHT_UNITBAR)
	rightBackground.anchorX = 1
	rightBackground.anchorY = 1
	rightBackground.x = display.screenOriginX + display.viewableContentWidth
	rightBackground.y = display.screenOriginY + display.viewableContentHeight
	game.unitBarGroup:insert(rightBackground)
	
	foodBarFill = display.newImageRect(PATH_FILL_UNITBAR, SIZE_FILL_UNITBAR.width, SIZE_FILL_UNITBAR.height)
	foodBarFill.anchorX = 0
	foodBarFill.x = rightBackground.x + OFFSETS.HERO_BAR.x - foodBarFill.width * 0,5
	foodBarFill.y = rightBackground.y + OFFSETS.HERO_BAR.y
	foodBarFill.fill.effect = "filter.monotone"
	game.unitBarGroup:insert(foodBarFill)
	
--	energyBarFill = display.newImageRect(PATH_FILL_UNITBAR, SIZE_FILL_UNITBAR.width, SIZE_FILL_UNITBAR.height)
--	energyBarFill.anchorX = 0
--	energyBarFill.x = rightBackground.x + OFFSETS.HERO_BAR.x - energyBarFill.width * 0,5
--	energyBarFill.y = rightBackground.y + OFFSETS.HERO_BAR.y
--	energyBarFill.fill.effect = "filter.monotone"
--	game.unitBarGroup:insert(energyBarFill)
	
--	local leftForeground = display.newImage(PATH_FOREGROUND_LEFT_UNITBAR)
--	leftForeground.anchorX = 0
--	leftForeground.anchorY = 1
--	leftForeground.x = display.screenOriginX
--	leftForeground.y = display.screenOriginY + display.viewableContentHeight
--	game.unitBarGroup:insert(leftForeground)
	
	local rightForeground = display.newImage(PATH_FOREGROUND_RIGHT_UNITBAR)
	rightForeground.anchorX = 1
	rightForeground.anchorY = 1
	rightForeground.x = display.screenOriginX + display.viewableContentWidth
	rightForeground.y = display.screenOriginY + display.viewableContentHeight
	game.unitBarGroup:insert(rightForeground)
	
	local middleWidth = display.viewableContentWidth - rightForeground.width
	
	local middleBackground = display.newImage(PATH_FOREGROUND_MIDDLE_UNITBAR)
	middleBackground.anchorX = 0
	middleBackground.anchorY = 1
	middleBackground.x = display.screenOriginX
	middleBackground.y = display.screenOriginY + display.viewableContentHeight
	middleBackground.width = middleWidth + 2
	game.unitBarGroup:insert(middleBackground)
	
	unitScrollViewHeight = middleBackground.height
	
	local foodTextOptions = {
		x = display.screenOriginX + display.viewableContentWidth + OFFSETS.HERO_TEXT.x,
		y = display.screenOriginY + display.viewableContentHeight + OFFSETS.HERO_TEXT.y,
		width = WIDTH_FONT_UNITBAR,
		align = "right",
		font = libraries.settings.fontName,
		text = "0/0",
		fontSize = SIZE_FONT_UNITBAR,
	}
	
	foodText = display.newText(foodTextOptions)
	foodText.anchorX = 1
	game.unitBarGroup:insert(foodText)

--	local energyTextOptions = {
--		x = display.screenOriginX + display.viewableContentWidth + OFFSETS.HERO_TEXT.x,
--		y = display.screenOriginY + display.viewableContentHeight + OFFSETS.HERO_TEXT.y,
--		width = WIDTH_FONT_UNITBAR,
--		align = "right",
--		font = libraries.settings.fontName,
--		text = "0/0",
--		fontSize = SIZE_FONT_UNITBAR,
--	}
--	
--	energyText = display.newText(energyTextOptions)
--	energyText.anchorX = 1
--	game.unitBarGroup:insert(energyText)
end

local function initialize(parameters)
	parameters = parameters or {}
	
	if retryParameters then
		parameters = retryParameters
	end
	
	levelID = parameters.levelID or DEFAULT_LEVEL_ID
	worldID = parameters.worldID or DEFAULT_WORLD_ID
	
	savedSubject = parameters.subject
	--unitsSelected = parameters.unitsSelected or DEFAULT_WORLD_ID
	
	eventTimesPlayed = libraries.eventCounter.updateEventCount("gamePlayedWorld"..worldID, "level"..levelID)
	libraries.mixpanel.logEvent("mainGameStarted", {worldIndex = worldID, levelIndex = levelID, timesPlayed = eventTimesPlayed})
	
	gamemodeData = parameters.gamemodeData or {endRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 1},
				}}
	local gamemodeID = gamemodeData.mode or DEFAULT_GAMEMODE_ID

	local defaultAvailability = {}
	for index = 1, 9 do
		defaultAvailability[index] = {world = 1, unitIndex = index}
	end
	
	unitAvailability = parameters.unitAvailability or defaultAvailability
	currentGamemode = libraries.extratable.deepcopy(libraries.gamemodes[gamemodeID])
	warzoneScrollDelay = currentGamemode.warzoneScrollDelay or 0

	if gamemodeData.overrideData then
		for key, value in pairs(gamemodeData.overrideData) do
			currentGamemode[key] = value
		end
	end
	
	newEnemyUnits = {}
	local function addEnemyAmount(amount, ofIndex)
		for index = 1, amount do
			newEnemyUnits[#newEnemyUnits + 1] = ofIndex
		end
	end
	
	local maxEnemyIndex = 1
	for index = 1, #currentGamemode.enemyUnits do
		local enemyType = currentGamemode.enemyUnits[index]
		if "table" == type(enemyType) then
			addEnemyAmount(enemyType.amount, enemyType.index)
			if enemyType.index > maxEnemyIndex then maxEnemyIndex = enemyType.index end
		else
			newEnemyUnits[#newEnemyUnits + 1] = enemyType
			if enemyType > maxEnemyIndex then maxEnemyIndex = enemyType end
		end
	end
	if not currentGamemode.spawnInOrder then
		newEnemyUnits = libraries.extratable.shuffle(newEnemyUnits)
	end
	currentGamemode.enemyUnits = newEnemyUnits
	
	leftPlayerIconRect.fill = {type = "image", filename = libraries.herolist[currentPlayer.heroIndex].iconPath}
	rightPlayerIconRect.fill = {type = "image", filename = "images/yogodex/unidades/oni.png"}
	-- TODO this must be the biggest enemy
	
	local gamemodeConditions = currentGamemode.conditions or {win = {}, lose = {}}
	gameConditions.winOnUnitDespawn = gamemodeConditions.win.unitDespawn
	gameConditions.winOnBuildingsKilled = gamemodeConditions.win.unitDespawn
	gameConditions.loseOnEnemyDespawn = gamemodeConditions.lose.enemyDespawn
	gameConditions.loseOnBuildingsLost = gamemodeConditions.lose.buildingsLost
	
	coinsDespawn = currentGamemode.coinsDespawn
	if coinsDespawn == nil then
		coinsDespawn = true
	end
	
	setGoals(currentGamemode.goals)
	
	extraUnitData = {
		unitsCanSpecial = currentGamemode.unitsCanSpecial,
		allowRandomness = currentGamemode.allowRandomness
	}
	
	lostBuildings = {
		[TEAM_INDEX_PLAYER] = 0,
		[TEAM_INDEX_COMPUTER] = 0,
	}
	
	lostUnits = {
		[TEAM_INDEX_PLAYER] = 0,
		[TEAM_INDEX_COMPUTER] = 0,
	}
	
	totalBuildings = {
		[TEAM_INDEX_PLAYER] = 0,
		[TEAM_INDEX_COMPUTER] = 0,
	}
	
	playerHealths = {
		[TEAM_INDEX_PLAYER] = 1,
		[TEAM_INDEX_COMPUTER] = 1,
	}
	
	eventIndex = 1
	currentEvent = currentGamemode.events and currentGamemode.events[eventIndex] or nil
	nextEvent = nil
	
	tutorialElements = {}
	tutorialElements[ELEMENTS_TUTORIAL_TAGS.FOOD_BAR] = foodBarFill
	--tutorialElements[ELEMENTS_TUTORIAL_TAGS.ENERGY_BAR] = energyBarFill
end

local function resetVariables()
	currentCoins = 0
	coinsText.text = currentCoins
	coinsCollected = 0
	
	currentLoop = 0
	coinsFreezed = false
	unitSpawnFreezed = false
	currentFood = 0
	currentEnergy = 0
	currentItemRecharge = 0
	paused = false
	overridePaused = false
	pauseFoodRecharge = false
	pauseEnergyRecharge = false
	isGameOver = false
	
	local foodRechargePerSecond = currentGamemode.foodRechargePerSecond or 15
	local energyRechargePerSecond = currentGamemode.energyRechargePerSecond or 1

	foodRechargePerUpdate = foodRechargePerSecond / 60 * INTERVAL_UPDATE_GAME
	energyRechargePerUpdate = energyRechargePerSecond / 60 * INTERVAL_UPDATE_GAME
	
	
	unpickedCoins = {}
	activeUnits = {}
	unitsSpawned = {}
	unitCounts = {[TEAM_INDEX_PLAYER] = 0, [TEAM_INDEX_COMPUTER] = 0}
	unitsSpawned = {[TEAM_INDEX_PLAYER] = 0, [TEAM_INDEX_COMPUTER] = 0}
	
	tutorialFocus.alpha = 0
	tutorialHand.alpha = 0
	retryParameters = nil
end

local function createHealthBars()
	
	local leftHealthBar = display.newGroup()
	leftHealthBar.anchorChildren = true
	
	local leftHealthBarBackground = display.newImage("images/game/healthbar_background_coins.png")
	leftHealthBar:insert(leftHealthBarBackground)
	
	leftHealthBarFill = display.newContainer(SIZE_HEALTHBAR.width, SIZE_HEALTHBAR.height)
	leftHealthBarFill.anchorChildren = false
	leftHealthBarFill.anchorX = 0
	leftHealthBarFill.x = OFFSETS.HEALTH_BAR.x
	leftHealthBarFill.y = OFFSETS.HEALTH_BAR.y
	leftHealthBar:insert(leftHealthBarFill)

	local fillImage = display.newImage("images/game/fill_2.png")
	fillImage.x = 0
	fillImage.anchorX = 0
	leftHealthBarFill:insert(fillImage)
	
	local leftHealthBarForeground = display.newImage("images/game/healthbar_foreground_coins.png")
	leftHealthBar:insert(leftHealthBarForeground)
	
	local coinsTextOptions = {
		x = OFFSETS.TEXT_COINS.x,
		y = OFFSETS.TEXT_COINS.y,
		width = WIDTH_COINS_TEXT,
		align = "left",
		font = libraries.settings.fontName,
		text = "0",
		fontSize = SIZE_FONT_COINS_TEXT,
	}
	
	coinsText = display.newText(coinsTextOptions)
	coinsText.anchorX = 0
	leftHealthBar:insert(coinsText)
	
	leftPlayerIconRect = display.newRoundedRect(OFFSETS.PLAYER_ICON_RECT_LEFT.x, OFFSETS.PLAYER_ICON_RECT_LEFT.y, SIZE_PLAYER_ICON_RECT, SIZE_PLAYER_ICON_RECT, 15)
	leftPlayerIconRect:setStrokeColor(unpack(libraries.colors.gray))
	leftPlayerIconRect.strokeWidth = 4
	leftHealthBar:insert(leftPlayerIconRect)
	
	local rightHealthBar = display.newGroup()
	rightHealthBar.anchorChildren = true
	
	local rightHealthBarBackground = display.newImage(PATH_BACKGROUND_HEALTHBAR)
	rightHealthBar:insert(rightHealthBarBackground)
	
	rightHealthBarFill = display.newContainer(SIZE_HEALTHBAR.width, SIZE_HEALTHBAR.height)
	rightHealthBarFill.anchorChildren = false
	rightHealthBarFill.anchorX = 0
	rightHealthBarFill.x = OFFSETS.HEALTH_BAR.x
	rightHealthBarFill.y = OFFSETS.HEALTH_BAR.y
	rightHealthBar:insert(rightHealthBarFill)

	local fillImage = display.newImage("images/game/fill_2.png")
	fillImage.x = 0
	fillImage.anchorX = 0
	rightHealthBarFill:insert(fillImage)
	
	local rightHealthBarForeground = display.newImage(PATH_FOREGROUND_HEALTHBAR)
	rightHealthBar:insert(rightHealthBarForeground)
	
	rightPlayerIconRect = display.newRoundedRect(OFFSETS.PLAYER_ICON_RECT_RIGHT.x, OFFSETS.PLAYER_ICON_RECT_RIGHT.y, SIZE_PLAYER_ICON_RECT, SIZE_PLAYER_ICON_RECT, 15)
	rightPlayerIconRect:setStrokeColor(unpack(libraries.colors.gray))
	rightPlayerIconRect.strokeWidth = 4
	rightHealthBar:insert(rightPlayerIconRect)
	
	leftHealthBar.anchorX = 0
	leftHealthBar.anchorY = 0
	leftHealthBar.x = display.screenOriginX
	leftHealthBar.y = display.screenOriginY
	
	rightHealthBar.anchorX = 0
	rightHealthBar.anchorY = 0
	rightHealthBar.xScale = -1
	rightHealthBar.x = display.screenOriginX + display.viewableContentWidth
	rightHealthBar.y = display.screenOriginY
	
	game.topHudGroup:insert(leftHealthBar)
	game.topHudGroup:insert(rightHealthBar)
end

local function pauseReleased(event)
	libraries.mixpanel.logEvent("mainGamePaused")
	game.pause()
	
	transition.pause(TAG_FOCUS_EVENT)
	transition.pause(TAG_HAND_EVENT)
	transition.pause(libraries.unitFactory.TAG_PROJECTILE_TRANSITIONS)
	
	local function onBackReleased()
		libraries.pauseScene.disableButtons()
		libraries.gameHelper.loader("scenes.menus.loading", {nextScene = "scenes.menus.levels", sceneList = libraries.sceneList.menus})
	end
	local function onRetryReleased()
		libraries.pauseScene.disableButtons()
		retryGame()
	end
	local function onResumeReleased()
		local timeToUnpause = 800
		libraries.director.performWithDelay(scenePath, timeToUnpause, function()
			game.unpause()
			transition.resume(TAG_FOCUS_EVENT)
			transition.resume(TAG_HAND_EVENT)
			transition.resume(libraries.unitFactory.TAG_PROJECTILE_TRANSITIONS)
		end)
		libraries.director:hideOverlay(true, "fade", timeToUnpause)
	end
	
	libraries.pauseScene.show(gameGoals, onBackReleased, onRetryReleased, onResumeReleased)
	if currentPlayer.energy < 5 then
		libraries.pauseScene.retrySetEnabled(false)
	end
end

local function removeBackground()
	display.remove(background)
	background = nil
end

local function createBackground()
	removeBackground()
	
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "mirroredRepeat" )
	
	background = display.newGroup()
	
	backgroundID = libraries.worldsData[worldID][levelID].backgroundID or libraries.worldsData[worldID].defaultBackgroundID
	local backgroundData = libraries.backgroundList[backgroundID]
	local parallaxData = backgroundData.parallax
	
	bgComponentList = {}
	for index = 1, #parallaxData do
		local backgroundComponent = display.newRect(display.contentCenterX, display.contentCenterY + parallaxData[index].y, display.viewableContentWidth, parallaxData[index].height )
		background:insert(backgroundComponent)
		backgroundComponent.fill = { type = "image", filename = parallaxData[index].filename }
		backgroundComponent.fill.scaleY = 1
		backgroundComponent.fill.scaleX = parallaxData[index].width / display.viewableContentWidth
		backgroundComponent.parallaxRatio = RATIO_PARALLAX_BACKGROUND * index
		
		bgComponentList[index] = backgroundComponent
	end
	
	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	game.backgroundGroup:insert(background)
end

local function createTutorialElements()
	local screenfocusParameters = {
		x = display.screenOriginX + 200,
		y = display.screenOriginY + 200,
		width = 800,
		height = 400,
		color = {0,0,0,1},
	}
	tutorialFocus = libraries.screenfocus.new(screenfocusParameters)
	tutorialFocus.alpha = 0
	game.tutorialGroup:insert(tutorialFocus)
	
	tutorialHand = libraries.gameHelper.getTutorialHand()
	tutorialHand.alpha = 0
	game.tutorialGroup:insert(tutorialHand)
end

local function showGoals()
	overridePaused = true
	warzoneScrollView:setIsLocked(false)
	libraries.goalsScene.show(gameGoals, function()
		libraries.mixpanel.logEvent("goalsAccepted", {worldIndex = worldID, levelIndex = levelID, timesPlayed = eventTimesPlayed})
		libraries.director.hideOverlay(false, "zoomInOutFade", 600)
		
		local rewardDelay =	libraries.rewardsService.check(gamemodeData.startRewards, currentPlayer)
		libraries.director.performWithDelay(scenePath, rewardDelay, function()
			overridePaused = false
			libraries.director.performWithDelay(scenePath, warzoneScrollDelay, function()
				local position = (display.viewableContentWidth - currentGamemode.warzoneWidth) * 0.5
				if position < 0 then
					position = 0
				else
					warzoneScrollView:setIsLocked(true)
				end
				warzoneScrollView:scrollToPosition({x = position, time = 800})
			end)
			libraries.director.performWithDelay(scenePath, 500, function()
				libraries.music.playTrack(3,400)
			end)
		end)
	end)
end

----------------------------------------------- Class functions 
function game.pause()
	game.disableButtons()
	paused = true
end

function game.unpause()
	game.enableButtons()
	paused = false
end

function game.enableButtons()
	pauseButton:setEnabled(true)
end

function game.disableButtons()
	pauseButton:setEnabled(false)
end

function game:create(event)
	local sceneView = self.view
	
	game.backgroundGroup = display.newGroup()
	sceneView:insert(game.backgroundGroup)
	
	game.warzoneScrollGroup = display.newGroup()
	sceneView:insert(game.warzoneScrollGroup)
	
	game.unitBarGroup = display.newGroup()
	sceneView:insert(game.unitBarGroup)
	
	game.dragGroup = display.newGroup()
	sceneView:insert(game.dragGroup)
		
	game.hudGroup = display.newGroup()
	sceneView:insert(game.hudGroup)
	
	game.tutorialGroup = display.newGroup()
	sceneView:insert(game.tutorialGroup)
	
	game.topHudGroup = display.newGroup()
	sceneView:insert(game.topHudGroup)
	
	local debugTextOptions = {
		x = display.contentCenterX,
		y = display.screenOriginY + 200,
		text = "DEBUG",
		fontSize = 25,
	}
	debugText = display.newText(debugTextOptions)
	debugText.isVisible = false
	game.hudGroup:insert(debugText)
	
	createUnitBarBackground()
	createHealthBars()
	
	local pauseScale = 0.7
	libraries.buttonlist.pause.onRelease = pauseReleased
	pauseButton = libraries.widget.newButton(libraries.buttonlist.pause)
	pauseButton.x = display.contentCenterX
	pauseButton.y = display.screenOriginY + pauseButton.height * pauseScale * 0.5 + padding
	pauseButton.xScale = pauseScale
	pauseButton.yScale = pauseScale
	game.topHudGroup:insert(pauseButton)
	
	createTutorialElements()
	
end

function game:destroy()
	
end

function game:show( event )
    local phase = event.phase

    if ( phase == "will" ) then
		currentPlayer = libraries.players.getCurrent()
		self.disableButtons()
		initialize(event.params)
		resetVariables()
		createBackground()
		removeScrollViews()
		addScrollViews()
		populateUnitBar()
		createLanes()
		addBuildings()
		showGoals()
		Runtime:addEventListener("enterFrame", enterFrame)
		warzoneScrollView:scrollToPosition({x = -currentGamemode.warzoneWidth + display.viewableContentWidth, time = 1000})
	elseif ( phase == "did" ) then
		self.enableButtons()
	end
end

function game:hide( event )
    local phase = event.phase

    if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		Runtime:removeEventListener("enterFrame", enterFrame)
		removeBackground()
		removeScrollViews()
		
		if foodTutorial then
			transition.cancel(foodTutorial)
			display.remove(foodTutorial)
			foodTutorial = nil
		end
		libraries.players.save(currentPlayer)
	end
end

game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
