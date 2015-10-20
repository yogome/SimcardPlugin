--------------------------------------------- Badges
local worldsData = require( "data.worldsdata" )
local database = require( "libs.helpers.database" )
local settings = require( "settings" )
local unitsData = require( "data.unitsData" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )

local rewards = {}
--------------------------------------------- Variables
local timeToShow
local rewardQueue
local fadeRect
local initialized
local radialEffect
--------------------------------------------- Constants
local OFFSET_X_SPAWN = 1000
local OFFSET_X_DESPAWN = 1000

local TIME_REWARD_IN = 250
local TIME_REWARD_SHOW = 4000
local TIME_REWARD_OUT = 250
local TIME_PER_REWARD = TIME_REWARD_IN + TIME_REWARD_SHOW + TIME_REWARD_OUT
local TIME_FADE_IN = 400
local TIME_FADE_OUT = 400

local OFFSET_YOGOTAR_NAME1 = {x = -205, y = -115}
local OFFSET_YOGOTAR_NAME2 = {x = -205, y = -125}
local COLOR_UNIT_NAME1 = {0,0,0}
local COLOR_UNIT_NAME2 = {32/255,70/255,178/255}
local OFFSET_YOGOTAR_LABEL_TITLE = {x = -50, y = 210}
local OFFSET_YOGOTAR_TEXT_TITLE = {x  = 140, y = 0}
local OFFSET_YOGOTAR_LABEL_DESC = {x = -50, y = 250}
local OFFSET_YOGOTAR_TEXT_DESC = {x  = 140, y = 0}

local OFFSET_IGNARUS_NAME1 = {x = 165, y = -115}
local OFFSET_IGNARUS_NAME2 = {x = 165, y = -105}
local OFFSET_IGNARUS_LABEL_TITLE = {x = -50, y = 210}
local OFFSET_IGNARUS_LABEL_DESC = {x = -50, y = 250}
local OFFSET_IGNARUS_TEXT_TITLE = {x  = 140, y = 0}
local OFFSET_IGNARUS_TEXT_DESC = {x  = 140, y = 0}

local SIZE_FONT_UNIT_NAME = 70
local SIZE_FONT_LABELS = 35

local OFFSET_REWARD_UNLOCKED = {x = 0, y = -330}

local OFFSET_UNIT_IMAGE = {x = 30, y = -50}
local OFFSET_UNIT_IMAGE_IGNARUS = {x = -10, y = -50}

local TEXT_LABEL_TITLE = "title"
local TEXT_LABEL_CLASS = "class"
local IMAGE_CARD_UNIT ={
	[1] = "images/yogodex/buenos.png",
	[2] = "images/yogodex/malos.png",
}
local NAME_TEAM = {
	[1] = "Yogotars",
	[2] = "Ignarus",
}
local TEXT_REWARD_UNLOCKED = "newUnit"

local TEXT_REWARD_ENEMY_UNLOCKED = "newEnemy"
local SIZE_FONT_REWARD_UNLOCKED = 60
local SCALE_REWARD_TO = 0.8
local SCALE_REWARD_FROM = 0.5

local NUMBER_STARS = 15
local NUMBER_FIREWORKS = 5
local RANGE_FIREWORKS = {x = 300, y = 200}
local TIME_FIREWORK_SHOW = 400
local TIME_FIREWORK = 400
--------------------------------------------- Functions
local function isRewardUnlocked(reward, player)
	if reward.type == "unlockYogotar" then
		local unitData = unitsData[reward.worldIndex][1][reward.unitIndex]

		if not player.units[unitData.unitProxy] then
			player.units[unitData.unitProxy] = {bought = true, unlocked = true, upgradeLevel = 1}
		else
			player.units[unitData.unitProxy].bought = true
			player.units[unitData.unitProxy].unlocked = true
		end
		
		local rewardGroup = display.newGroup()
		rewardGroup.x = display.screenOriginX + display.viewableContentWidth + OFFSET_X_SPAWN
		rewardGroup.y = display.contentCenterY
		
		local background = display.newImage(IMAGE_CARD_UNIT[1])
		background.xScale = 1.2
		background.yScale = 1.2
		rewardGroup:insert(background)
		
		local cardStrip = display.newImage("images/yogodex/buenosstrip.png")
		cardStrip.xScale = 0.9
		cardStrip.yScale = 0.9
		cardStrip.x = background.x - 165
		cardStrip.y = background.y - 75
		rewardGroup:insert(cardStrip)
		
		local nameTextOptions = {
			x = cardStrip.x,
			y = OFFSET_YOGOTAR_NAME1.y,
			width = 300,
			align = "right",
			font = settings.fontName,
			text = unitData.info.name,
			fontSize = SIZE_FONT_UNIT_NAME,
		}

		local nameText1 = display.newText(nameTextOptions)
		nameText1.rotation = -90
		nameText1:setFillColor(unpack(COLOR_UNIT_NAME1), 0.2)
		rewardGroup:insert(nameText1)

		nameTextOptions.x = cardStrip.x
		nameTextOptions.y = OFFSET_YOGOTAR_NAME2.y

		local nameText2 = display.newText(nameTextOptions)
		nameText2.rotation = -90
		nameText2:setFillColor(unpack(COLOR_UNIT_NAME2))
		rewardGroup:insert(nameText2)

		local titleLabel = display.newText(localization.getString(TEXT_LABEL_TITLE), OFFSET_YOGOTAR_LABEL_TITLE.x, OFFSET_YOGOTAR_LABEL_TITLE.y, settings.fontName, SIZE_FONT_LABELS)
		titleLabel:setFillColor(32/255,162/255,230/255)
		rewardGroup:insert(titleLabel)
		
		local titleTextOptions = {
			x = titleLabel.x + OFFSET_YOGOTAR_TEXT_TITLE.x,
			y = titleLabel.y + OFFSET_YOGOTAR_TEXT_TITLE.y,
			width = 160,
			align = "left",
			font = settings.fontName,
			text = localization.getString(unitData.info.type),
			fontSize = SIZE_FONT_LABELS,
		}
		local titleText = display.newText(titleTextOptions)
		titleText:setFillColor(32/255,70/255,178/255)
		rewardGroup:insert(titleText)

		local classLabel = display.newText(localization.getString(TEXT_LABEL_CLASS), OFFSET_YOGOTAR_LABEL_DESC.x, OFFSET_YOGOTAR_LABEL_DESC.y, settings.fontName, SIZE_FONT_LABELS)
		classLabel:setFillColor(32/255,162/255,230/255)
		rewardGroup:insert(classLabel)
		local descTextOptions = {
			x = classLabel.x + OFFSET_YOGOTAR_TEXT_DESC.x,
			y = classLabel.y + OFFSET_YOGOTAR_TEXT_DESC.y,
			width = 160,
			align = "left",
			font = settings.fontName,
			text = NAME_TEAM[1],
			fontSize = SIZE_FONT_LABELS,
		}
		local classText = display.newText(descTextOptions)
		classText:setFillColor(32/255,70/255,178/255)
		rewardGroup:insert(classText)
		
		local characterImage = display.newImage(unitData.info.imageCard)
		characterImage.x = OFFSET_UNIT_IMAGE.x
		characterImage.y = OFFSET_UNIT_IMAGE.y
		rewardGroup:insert(characterImage)
		
		local rewardUnlockedOptions = {
			x = OFFSET_REWARD_UNLOCKED.x,
			y = OFFSET_REWARD_UNLOCKED.y,
			font = settings.fontName,
			text = localization.getString(TEXT_REWARD_UNLOCKED),
			fontSize = SIZE_FONT_REWARD_UNLOCKED,
		}
		local rewardUnlockedText = display.newText(rewardUnlockedOptions)
		rewardGroup:insert(rewardUnlockedText)
		
		rewardGroup.xScale = SCALE_REWARD_FROM
		rewardGroup.yScale = SCALE_REWARD_FROM
		
		rewardQueue[#rewardQueue + 1] = rewardGroup
		timeToShow = timeToShow + TIME_PER_REWARD
		
	elseif reward.type == "unlockIgnarus" then
		local unitData = unitsData[reward.worldIndex][2][reward.unitIndex]

		if not player.units[unitData.unitProxy] then
			player.units[unitData.unitProxy] = {bought = true, unlocked = true, upgradeLevel = 1}
		else
			player.units[unitData.unitProxy].bought = true
			player.units[unitData.unitProxy].unlocked = true
		end
		
		local rewardGroup = display.newGroup()
		rewardGroup.x = display.screenOriginX + display.viewableContentWidth + OFFSET_X_SPAWN
		rewardGroup.y = display.contentCenterY
		
		local background = display.newImage(IMAGE_CARD_UNIT[2])
		background.xScale = 1.2
		background.yScale = 1.2
		rewardGroup:insert(background)
		
		local cardStrip = display.newImage("images/yogodex/malosstrip.png")
		cardStrip.xScale = 0.9
		cardStrip.yScale = 0.9
		cardStrip.x = background.x + 165
		cardStrip.y = background.y - 77
		rewardGroup:insert(cardStrip)
		
		local characterImage = display.newImage(unitData.info.imageCard)
		characterImage.x = OFFSET_UNIT_IMAGE_IGNARUS.x
		characterImage.y = OFFSET_UNIT_IMAGE_IGNARUS.y
		rewardGroup:insert(characterImage)
		
		local nameTextOptions = {
			x = OFFSET_IGNARUS_NAME1.x,
			y = OFFSET_IGNARUS_NAME1.y,
			width = 300,
			align = "right",
			font = settings.fontName,
			text = unitData.info.name,
			fontSize = SIZE_FONT_UNIT_NAME,
		}

		local nameText1 = display.newText(nameTextOptions)
		nameText1.rotation = -90
		nameText1:setFillColor(unpack(COLOR_UNIT_NAME1))
		rewardGroup:insert(nameText1)

		nameTextOptions.x = OFFSET_IGNARUS_NAME2.x
		nameTextOptions.y = OFFSET_IGNARUS_NAME2.y

		local nameText2 = display.newText(nameTextOptions)
		nameText2.rotation = -90
		--nameText2:setFillColor(unpack(COLOR_UNIT_NAME2))
		rewardGroup:insert(nameText2)

		local titleLabel = display.newText(localization.getString(TEXT_LABEL_TITLE), OFFSET_IGNARUS_LABEL_TITLE.x, OFFSET_IGNARUS_LABEL_TITLE.y, settings.fontName, SIZE_FONT_LABELS)
		titleLabel:setFillColor(255/255,162/255,	0/255)
		rewardGroup:insert(titleLabel)
		
		local titleTextOptions = {
			x = titleLabel.x + OFFSET_IGNARUS_TEXT_TITLE.x,
			y = titleLabel.y + OFFSET_IGNARUS_TEXT_TITLE.y,
			width = 160,
			align = "left",
			font = settings.fontName,
			text = localization.getString(unitData.info.type),
			fontSize = SIZE_FONT_LABELS,
		}
		local titleText = display.newText(titleTextOptions)
		rewardGroup:insert(titleText)

		local classLabel = display.newText(localization.getString(TEXT_LABEL_CLASS), OFFSET_IGNARUS_LABEL_DESC.x, OFFSET_IGNARUS_LABEL_DESC.y, settings.fontName, SIZE_FONT_LABELS)
		classLabel:setFillColor(255/255,162/255,	0/255)
		rewardGroup:insert(classLabel)
		local descTextOptions = {
			x = classLabel.x + OFFSET_IGNARUS_TEXT_DESC.x,
			y = classLabel.y + OFFSET_IGNARUS_TEXT_DESC.y,
			width = 160,
			align = "left",
			font = settings.fontName,
			text = NAME_TEAM[2],
			fontSize = SIZE_FONT_LABELS,
		}
		local classText = display.newText(descTextOptions)
		rewardGroup:insert(classText)
		
		
		local rewardUnlockedOptions = {
			x = OFFSET_REWARD_UNLOCKED.x,
			y = OFFSET_REWARD_UNLOCKED.y,
			font = settings.fontName,
			text = localization.getString(TEXT_REWARD_ENEMY_UNLOCKED),
			fontSize = SIZE_FONT_REWARD_UNLOCKED,
		}
		local rewardUnlockedText = display.newText(rewardUnlockedOptions)
		rewardGroup:insert(rewardUnlockedText)
		
		rewardGroup.xScale = SCALE_REWARD_FROM
		rewardGroup.yScale = SCALE_REWARD_FROM
		
		rewardQueue[#rewardQueue + 1] = rewardGroup
		timeToShow = timeToShow + TIME_PER_REWARD
	end
end

local function initialize()
	if not initialized then
		initialized = true
		
		fadeRect = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
		fadeRect.alpha = 0
		fadeRect:setFillColor(0)
		
		radialEffect = display.newImage("images/rewards/radial.png")
		radialEffect.x = display.contentCenterX
		radialEffect.y = display.contentCenterY
		radialEffect.xScale = 2
		radialEffect.yScale = 2
		radialEffect.alpha = 0
		
	end
end

local function showFireworks(delay, duration)
	for index = 1, NUMBER_STARS do
		local star = display.newImage("images/rewards/lone_star.png")
		star.x = display.contentCenterX + math.random(-RANGE_FIREWORKS.x, RANGE_FIREWORKS.x)
		star.y = display.contentCenterY + math.random(-RANGE_FIREWORKS.y, RANGE_FIREWORKS.y)
		star.alpha = 0
		
		local randomDelay = math.random(1, duration * 0.5)
		local randomScale = 1 + (math.random(0,100) * 0.01)
		
		transition.to(star, {delay = delay + randomDelay, time = TIME_FIREWORK_SHOW, xScale = randomScale, yScale = randomScale, alpha = 1, transition = easing.outQuad, onComplete = function()
			transition.to(star, {delay = 400, time = TIME_FIREWORK_SHOW, alpha = 0, transition = easing.inQuad, onComplete = function()
				display.remove(star)
				star = nil
			end})
		end})
	end
	
	for index = 1, NUMBER_FIREWORKS do
		local fireworkSheet = { width = 256, height = 256, numFrames = 8 }
		local fireworkSheet = graphics.newImageSheet( "images/rewards/firework1.png", fireworkSheet )

		local sequenceData = {
			{name = "explode", sheet = fireworkSheet, start = 1, count = 8, time = TIME_FIREWORK },
		}
		
		local randomDelay = math.random(1, duration * 0.5)

		local firework = display.newSprite( fireworkSheet, sequenceData )
		firework.x = display.contentCenterX + math.random(-RANGE_FIREWORKS.x, RANGE_FIREWORKS.x)
		firework.y = display.contentCenterY + math.random(-RANGE_FIREWORKS.y, RANGE_FIREWORKS.y)
		firework.alpha = 0
		
		transition.to(firework, {time = TIME_FIREWORK, delay = delay + randomDelay, onStart = function()
			firework.alpha = 1
			firework:setSequence("explode")
			firework:play()
		end, onComplete = function()
			display.remove(firework)
			firework = nil
		end})
	end
end
--------------------------------------------- Module functions
function rewards.check(rewards, player)
	rewards = rewards or {}

	rewardQueue = {}
	timeToShow = 0
	
	for index = 1, #rewards do
		local reward = rewards[index]
		if reward then
			isRewardUnlocked(reward, player)
		end
	end
	
	if timeToShow > 0 then
		timeToShow = timeToShow + TIME_FADE_IN + TIME_FADE_OUT
		
		fadeRect.alpha = 0
		fadeRect.isVisible = true
		transition.to(fadeRect, {delay = 0, time = TIME_FADE_IN, alpha = 0.8})
		
		transition.cancel(radialEffect)
		radialEffect.rotation = 0
		radialEffect.alpha = 0
		transition.to(radialEffect, {time = timeToShow, rotation = 360 * (timeToShow * 0.0001)})
		
		for rewardIndex = 1, #rewardQueue do
			local rewardGroup = rewardQueue[rewardIndex]
			local delay = TIME_FADE_IN + (TIME_PER_REWARD * (rewardIndex - 1))
			
			timer.performWithDelay(delay+TIME_REWARD_IN * 0.5, function()
				sound.play("unlock")
			end)
			
			showFireworks(delay + TIME_REWARD_IN, TIME_REWARD_SHOW)
			
			transition.to(radialEffect, {delay = delay + TIME_REWARD_IN, time = TIME_REWARD_SHOW * 0.2, alpha = 1, transition = easing.outQuad})
			transition.to(radialEffect, {delay = delay + TIME_REWARD_IN + TIME_REWARD_SHOW * 0.8, time = TIME_REWARD_SHOW * 0.2, alpha = 0, transition = easing.outQuad})
			
			transition.to(rewardGroup, {delay = delay, time = TIME_REWARD_IN, x = display.contentCenterX, xScale = SCALE_REWARD_TO, yScale = SCALE_REWARD_TO, transition = easing.outQuad})
			transition.to(rewardGroup, {delay = delay + TIME_REWARD_IN + TIME_REWARD_SHOW, time = TIME_REWARD_OUT,xScale = SCALE_REWARD_FROM, yScale = SCALE_REWARD_FROM, x = display.screenOriginX - OFFSET_X_DESPAWN, transition = easing.inQuad, onComplete = function()
				display.remove(rewardGroup)
				rewardGroup = nil
			end})
		end
		transition.to(fadeRect, {delay = timeToShow - TIME_FADE_OUT, time = TIME_FADE_OUT, alpha = 0, onComplete = function()
			fadeRect.isVisible = false
			fadeRect.alpha = 0
		end})
	end

	return timeToShow
end

initialize()

return rewards
