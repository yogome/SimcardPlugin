----------------------------------------------- Unit chooser
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local widget = require( "widget" )
local players = require( "models.players" )
local unitsData = require( "data.unitsData" )
local unitFactory = require( "units.unitFactory" )
local buttonList = require( "data.buttonlist")
local database = require( "libs.helpers.database" )
local sound = require( "libs.helpers.sound" )
local mixpanel = require( "libs.helpers.mixpanel" )
local unitsProxy = require( "data.unitsProxy" )
local localization = require( "libs.helpers.localization" )
local logger = require( "libs.helpers.logger" )

local scene = director.newScene() 
----------------------------------------------- Variables
local worldIndex, levelIndex, gamemodeData 
local canBuyUnits
local powercubes
local cubesText
local messageText, subject
local buttonRetry, buttonOK, buttonUpgrade
local unitGrid
local unitGridScrollView
local unitsSelected
local minigameIndexes
local backgroundGroup, background
local sectionsText = {}
local unitsFinalList
local iconList
local currentPlayer

local yogoCardBackground
local heroBaseCard, levelImage, heroImage
local heroBaseCardGroup, levelGroup, imageLevelGroup, insideImageLevelGroup
local textDesc, levelNum
local statsGroup, rectColor, textStats, staticRects
local titleCard, classCard

local unitIconGroup
local unitIconGroup2
local unitIcons
local lastParameters
----------------------------------------------- Constants
local PADDING = 20

local SIZE_CUBE_TEXT = 40
local SCALE_CUBE_INDICATOR_BACKGROUND = 0.7
local OFFSET_CUBES_TEXT = {x = 4, y = 47}
local SCALE_UNIT_LOCK = 0.5
local COLOR_LOCKED = {0.5}

local SCALE_UNIT_CHECKMARK = 0.35
local OFFSET_UNIT_CHECKMARK = {x = 25, y = 55}

local RATIO = 810 / display.viewableContentHeight
local SIZE_UNIT_GRID = {width = 860, height = 450 / RATIO}
local SIZE_UNIT_BACKGROUND = 160
local OFFSET_UNIT_ICON = {x = 0, y = -20}
local SCALE_UNIT_ICON = 0.38
local OFFSET_UNIT_GRID = {x = 30, y = 30}
local CORNER_RADIUS_UNIT_GRID = 15
local SIZE_FONT_COST = 25
local OFFSET_COST_TEXT = {x = 20, y = 51}
local COLUMN_SPACING = 5
local GRID_ROW = 9

local SIZE_MESSAGEBOX = {width = 540, height = 160, cornerRadius = 15}
local WIDTH_MESSAGE_TEXT = SIZE_MESSAGEBOX.width * 0.6
local POSITION_MESSAGE = {x = display.contentCenterX - 170, y = display.screenOriginY + 100}
local SIZE_FONT_MESSAGE = 30

local MESSAGES = {
	ok = "messageOKUnits",
	retry = "messageRetryUnits",
}

local LEVELIMAGES = {
	[1] = "images/yogodex/levels/level_01-04.png",
	[2] = "images/yogodex/levels/level_01-04.png",
	[3] = "images/yogodex/levels/level_01-04.png",
	[4] = "images/yogodex/levels/level_01-04.png",
	[5] = "images/yogodex/levels/level_05.png",
	[6] = "images/yogodex/levels/level_06-09.png",
	[7] = "images/yogodex/levels/level_06-09.png",
	[8] = "images/yogodex/levels/level_06-09.png",
	[9] = "images/yogodex/levels/level_06-09.png",
	[10] = "images/yogodex/levels/level_10.png",
	[11] = "images/yogodex/levels/level_11-14.png",
	[12] = "images/yogodex/levels/level_11-14.png",
	[13] = "images/yogodex/levels/level_11-14.png",
	[14] = "images/yogodex/levels/level_11-14.png",
	[15] = "images/yogodex/levels/level_15.png",
	[16] = "images/yogodex/levels/level_16-19.png",
	[17] = "images/yogodex/levels/level_16-19.png",
	[18] = "images/yogodex/levels/level_16-19.png",
	[19] = "images/yogodex/levels/level_16-19.png",
	[20] = "images/yogodex/levels/level_20.png"
	}
	
local CHAR_STATS_INDEX = {
		[1] = {name = "healthUnit",
				RGB = {255/255, 71/255, 138/255}},
		[2] = {name = "level",
				RGB = {0/255, 138/255, 238/255}},
		[3] = {name = "attack",
				RGB = {255/255, 174/255, 0}},
		[4] = {name = "special",
				RGB = {135/255, 193/255, 0}},
}

local GENDER = {
		[1] = "boy",
		[2] = "girl"
		}

local FOOD = "food"

local LOCKED = {
		imageCard = "images/yogodex/cards/soon.png",
		imageMenu = "images/yogodex/heroes/soon.png"
	}

local COLOR_BACKGROUND = {253/255,208/255,89/255}
local COLOR_BOXES = {0.2,0.2,0.2,0.5}
local ANCHOR_CUBE_INDICATOR = {x = 1, y = 0}
local POSITION_CUBE_INDICATOR = {x = display.screenOriginX + display.viewableContentWidth - 100, y = display.screenOriginY + PADDING}
----------------------------------------------- Functions

local function updateTextDes(info)
	textDesc["Name1"].text = info.name or "????"
	textDesc["Name2"].text = info.name or "????"
	textDesc["Type"].text = info.type and localization.getString(info.type) or "????"
	textDesc["Class"].text = info.class or "????"
end

local function updateStats(levelStats)
	
	local rango = 60 --this is static
	local width = 100 --this is static
	
	for indexStats = 1, #staticRects do
		local rectStat = staticRects[indexStats]
		local widthToFill = levelStats[indexStats]
		display.remove(rectColor[indexStats])
		rectColor[indexStats] = display.newRect(rectStat.x, rectStat.y, widthToFill, 20)
		rectColor[indexStats].anchorX = 0
		rectColor[indexStats].anchorY = 0
		rectColor[indexStats]:setFillColor(unpack(CHAR_STATS_INDEX[indexStats].RGB))
		statsGroup:insert(rectColor[indexStats])
	end
	
	local MAX_LEVEL = 20
	
end

local function getUnitStats(unitData, currentLvl)
	local tableStats = {}
	
	local health = unitData.health
	local healthMultiplier = unitData.healthMultiplier
	health = health + (health * healthMultiplier * currentLvl)
	local statHealth = math.round((health / 595) * 120) --healthmax = 595 --width / rango = 120
	
	local speed = unitData.speed
	local speedMultiplier = unitData.speedMultiplier
	speed = speed + (speed * speedMultiplier * currentLvl)
	local statSpeed = math.round((currentLvl / 40) * 120) --levelmax = 20 --width / rango = 120
	
	local statAttack = 0
	if unitData.attack then
		if unitData.summoner then
			local summonData = unitsData[1][1][unitData.attack.unitSummon].stats
			local attack = summonData.attack.damage
			local attackMultiplier = summonData.attack.multiplier
			attack = attack + (attack * attackMultiplier * currentLvl)
			statAttack = math.round((attack / 487) * 120) --attackMax = 507 --width / rango = 120
		else
			local attack = unitData.attack.damage
			local attackMultiplier = unitData.attack.multiplier
			attack = attack + (attack * attackMultiplier * currentLvl)
			statAttack = math.round((attack / 487) * 120) --attackMax = 487 --width / rango = 120 
		end
	end
	
	local statSpecial = 0
	if unitData.special then
		if unitData.summoner then
			local summonData = unitsData[1][1][unitData.attack.unitSummon].stats
			local special = summonData.attack.damage
			local specialMultiplier = summonData.attack.multiplier
			special = special + (special * specialMultiplier * currentLvl)
			statSpecial = math.round((special / 507) * 120) --attackMax = 507 --width / rango = 120
		else
			local special = unitData.special.damage
			local specialMultiplier = unitData.special.multiplier
			special = special + (special * specialMultiplier * currentLvl)
			statSpecial = math.round((special / 507) * 120) --attackMax = 507 --width / rango = 120
		end
	end
	
	tableStats = {statHealth, statSpeed, statAttack, statSpecial}
	
	return tableStats
	
end

local function updateLvl(currentLevel)
	local positionX = levelImage.x
	local positionY = levelImage.y
	display.remove(insideImageLevelGroup)
	insideImageLevelGroup = display.newGroup()
	levelImage = display.newImage(LEVELIMAGES[currentLevel])
	levelImage.x = positionX
	levelImage.y = positionY
	levelImage.xScale = 0.42
	levelImage.yScale = 0.42
	insideImageLevelGroup:insert(levelImage)
	local positionStarX = levelImage.x - 42
	local positionStarY = levelImage.y - 63
	local numStars = currentLevel % 5 == 0 and 5 or currentLevel % 5
	for indexStars = 1, numStars, 1 do
		local star = display.newImage("images/yogodex/levels/star.png")
		star.xScale = 0.35
		star.yScale = 0.35
		star.x = positionStarX + ((indexStars - 1) * 21)
		star.y = positionStarY
		insideImageLevelGroup:insert(star)
	end
	imageLevelGroup:insert(insideImageLevelGroup)
end

local function updateImageCard(fileName)
	display.remove(heroImage)
	heroImage = display.newImage(fileName)
	heroImage.xScale = 0.6
	heroImage.yScale = 0.6
	heroImage.x = heroBaseCard.x + 10
	heroImage.y = heroBaseCard.y - 20
	heroBaseCardGroup:insert(heroImage)
end

local function createYogoCard(sceneGroup)
	
	yogoCardBackground = display.newRoundedRect(0, 0, display.contentCenterX - 50, SIZE_UNIT_GRID.height , 15)
	yogoCardBackground.anchorX = 0
	yogoCardBackground.anchorY = 0
	yogoCardBackground.x = display.viewableContentWidth - display.contentCenterX - 30 + 50
	yogoCardBackground.y = display.contentCenterY - display.contentCenterY * 0.5 + 10
	yogoCardBackground:setFillColor(0, 0.4)
	
	sceneGroup:insert(yogoCardBackground)
	
	local CENTER_REFERENCE_X = yogoCardBackground.x + (yogoCardBackground.width * 0.5)
	local CENTER_REFERENCE_Y = yogoCardBackground.y + (yogoCardBackground.height * 0.5)
	
	heroBaseCardGroup = display.newGroup()
	heroBaseCard = display.newImage("images/yogodex/buenos.png")
	heroBaseCard.xScale = 0.7
	heroBaseCard.yScale = 0.7
	heroBaseCard.x = CENTER_REFERENCE_X - 100
	heroBaseCard.y = CENTER_REFERENCE_Y
	heroBaseCardGroup:insert(heroBaseCard)
	
	local cardStrip = display.newImage("images/yogodex/buenosstrip.png")
	cardStrip.xScale = 0.5
	cardStrip.yScale = 0.5
	cardStrip.x = heroBaseCard.x - 100
	cardStrip.y = heroBaseCard.y - 50
	heroBaseCardGroup:insert(cardStrip)
	
	textDesc = {}
	
	local textHeroOptions = {
		x = cardStrip.x,
		y = heroBaseCard.y - 15,
		width = 300,
		align = "right",
		font = settings.fontName,
		text = "",
		fontSize = 46,
	}
	
	local textHero = display.newText(textHeroOptions)
	textHero.rotation = -90
	textHero:setFillColor(0, 0.2)
	heroBaseCardGroup:insert(textHero)
	
	textDesc["Name1"] = textHero
	
	textHeroOptions = {
		x = cardStrip.x,
		y = textHero.y - 5,
		width = 300,
		align = "right",
		font = settings.fontName,
		text = "",
		fontSize = 46,
	}
	
	local textHeroBg = display.newText(textHeroOptions)
	textHeroBg.rotation = -90
	textHeroBg:setFillColor(32/255,70/255,178/255)
	heroBaseCardGroup:insert(textHeroBg)
	
	textDesc["Name2"] = textHeroBg 
	
	classCard = display.newText("", heroBaseCard.x - 30, heroBaseCard.y + 123, settings.fontName, 22)
	classCard:setFillColor(32/255,162/255,230/255)
	heroBaseCardGroup:insert(classCard)
	local classOptions = {
		x = heroBaseCard.x + 70,
		y = classCard.y,
		width = 130,
		align = "left",
		font = settings.fontName,
		text = "",
		fontSize = 18,
	}

	local classDescCard = display.newText(classOptions)
	classDescCard:setFillColor(32/255,70/255,178/255)
	heroBaseCardGroup:insert(classDescCard)
	sceneGroup:insert(heroBaseCardGroup)
	
	textDesc["Class"] = classDescCard
	
	titleCard = display.newText("", classCard.x, classCard.y + 25, settings.fontName, 22)
	titleCard:setFillColor(32/255,162/255,230/255)
	heroBaseCardGroup:insert(titleCard)
	local descOptions = {
		x = classDescCard.x,
		y = titleCard.y,
		width = 130,
		align = "left",
		font = settings.fontName,
		text = "",
		fontSize = 18,
	}
	local titleDescCard = display.newText(descOptions)
	titleDescCard:setFillColor(32/255,70/255,178/255)
	heroBaseCardGroup:insert(titleDescCard)
	
	textDesc["Type"] = titleDescCard 
	
	levelGroup = display.newGroup()
	imageLevelGroup = display.newGroup()
	insideImageLevelGroup = display.newGroup()
	levelImage = display.newImage("images/yogodex/level.png")
	levelImage.xScale = 0.65
	levelImage.yScale = 0.65
	levelImage.x = heroBaseCard.x + (heroBaseCard.width * 0.55)
	levelImage.y = CENTER_REFERENCE_Y - 105
	insideImageLevelGroup:insert(levelImage)
	imageLevelGroup:insert(insideImageLevelGroup)
	levelGroup:insert(imageLevelGroup)
	local levelText = display.newText("LVL", levelImage.x, levelImage.y - 27, settings.fontName, 35)
	levelNum = display.newText("", levelImage.x, levelImage.y + 12, settings.fontName, 50)
	levelGroup:insert(levelNum)
	levelGroup:insert(levelText)
	sceneGroup:insert(levelGroup)
	
	statsGroup = display.newGroup()
	
	textStats = {}
	staticRects = {}
	
	local CHAR_POSITION = {x = levelImage.x - 20, y = levelImage.y + 80, width = 120, height = 180 }
	
	for indexInfo = 1, 4 do
		local charDescOptions = {
			x = CHAR_POSITION.x,
			y = CHAR_POSITION.y + ((CHAR_POSITION.height ) * ((indexInfo + 1)/6)) - 30, 
			width = CHAR_POSITION.width,
			align = "left",
			font = settings.fontName,
			text = "to ini",
			fontSize = 18,
		}
		local charDescText = display.newText(charDescOptions)
		statsGroup:insert(charDescText)
		
		textStats[indexInfo] = charDescText
		
		local rectStats = display.newRect(charDescText.x + 20, charDescText.y - 10, 100, 20)
		rectStats.anchorX = 0
		rectStats.anchorY = 0
		rectStats:setFillColor(0, 0.6)
		statsGroup:insert(rectStats)
		
		staticRects[indexInfo] = rectStats
	end
	
	sceneGroup:insert(statsGroup)
	
	heroBaseCardGroup.xScale = 0.9
	heroBaseCardGroup.yScale = 0.9
	heroBaseCardGroup.x = heroBaseCardGroup.x + 80
	
	--buttonlist.selectGreen.onRelease = selectThis
--	local upgradeGroup = display.newGroup()
--	buttonUpgrade = widget.newButton(buttonList.selectBlue)
--	buttonUpgrade.xScale = 0.5
--	buttonUpgrade.yScale = 0.33
--	buttonUpgrade.x = yogoCardBackground.x + (yogoCardBackground.width * 0.5)
--	buttonUpgrade.y = (yogoCardBackground.y + yogoCardBackground.height) * 0.92
--	
--	local descBuyText = display.newText("UPGRADE", buttonUpgrade.x, buttonUpgrade.y - 5, settings.fontName, 30)
--	upgradeGroup:insert(buttonUpgrade)
--	upgradeGroup:insert(descBuyText)
--	sceneGroup:insert(upgradeGroup)
	
end

local function updateUnit(unitData)
	local info = unitData.info
	local proxyIndex = unitData.unitProxy
	if not currentPlayer.units[proxyIndex] then
		currentPlayer.units[proxyIndex] = {bought = true, unlocked = false, upgradeLevel = 1}
	end
	local currentLvl = currentPlayer.units[proxyIndex].upgradeLevel
	local levelStats
	
	if not currentPlayer.units[proxyIndex].unlocked then
		yogoCardBackground:toFront(heroBaseCardGroup)
		info = LOCKED
--		info.faction = "????"
--		info.location = "????"
		levelStats = {0, 0, 0, 0}
	else
		local myMoney = currentPlayer.coins
		heroBaseCardGroup:toFront(yogoCardBackground)
		levelStats = getUnitStats(unitData.stats, currentLvl)
		
	end
	
	updateImageCard(info.imageCard)
	updateTextDes(info)
	
	updateStats(levelStats)
	updateLvl(currentLvl)
	levelNum.text = currentLvl
	levelGroup.isVisible = true
	
end

local function createBackground()
	display.remove(background)
	local scale = (display.viewableContentWidth / 1024)
	local bgIndex = worldIndex <= 4 and worldIndex or 4
	background = display.newImage("images/general/background_"..bgIndex..".png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = scale
	background.yScale = scale
	backgroundGroup:insert(background)
end

local function onReleasedRetry()
	local retryParameters = lastParameters and lastParameters.retryParameters or {
		worldIndex = worldIndex,
		levelIndex = levelIndex,
		gamemodeData = gamemodeData,
		subject = subject,
	}
	director.gotoScene("scenes.minigames.manager", {effect = "fade", time = 600, params = retryParameters})
end

local function onReleasedOK()
	mixpanel.logEvent("unitsChosen")
	local parameters = {
		levelID = levelIndex,
		worldID = worldIndex,
		gamemodeData = gamemodeData,
		subject = subject,
		unitAvailability = {}
	}
	local num = 9
	local counterUnit = 1
	for index = 1, num do
		if unitsFinalList[index] then
			parameters.unitAvailability[counterUnit] = {
				unitIndex = unitsFinalList[index].unitIndex, 
				world = unitsFinalList[index].worldIndex,
				unitProxy = unitsFinalList[index].unitProxy
			}
			counterUnit = counterUnit + 1
		end
	end
	director.gotoScene("scenes.game.game", {effect = "fade", time = 600, params = parameters})
end

local function updateIcons()
	for unitIndex = 1, #unitGrid.frames do
		local unitFrame = unitGrid.frames[unitIndex]
		if not unitFrame.isSelected and not unitFrame.locked then
			unitFrame:setAvailable(powercubes >= unitFrame.cost)
		end
	end
end

local function createCubeIndicator(sceneGroup)
	local indicator = display.newGroup()
	indicator.anchorChildren = true
	indicator.x = POSITION_CUBE_INDICATOR.x
	indicator.y = POSITION_CUBE_INDICATOR.y
	indicator.anchorX = ANCHOR_CUBE_INDICATOR.x
	indicator.anchorY = ANCHOR_CUBE_INDICATOR.y
	
	local indicatorBackground = display.newImage("images/units/marcador.png")
	indicatorBackground.xScale = SCALE_CUBE_INDICATOR_BACKGROUND
	indicatorBackground.yScale = SCALE_CUBE_INDICATOR_BACKGROUND
	indicator:insert(indicatorBackground)
	
	local cubesTextOptions = {
		x = OFFSET_CUBES_TEXT.x,
		y = OFFSET_CUBES_TEXT.y,
		font = settings.fontName,
		text = 0,
		fontSize = SIZE_CUBE_TEXT,
	}
	cubesText = display.newText(cubesTextOptions)
	indicator:insert(cubesText)
	
	sceneGroup:insert(indicator)
end

local function createMessageText(sceneGroup)
	
	local messageTextRect = display.newRoundedRect(POSITION_MESSAGE.x, POSITION_MESSAGE.y, SIZE_MESSAGEBOX.width, SIZE_MESSAGEBOX.height, SIZE_MESSAGEBOX.cornerRadius)
	messageTextRect:setFillColor(unpack(COLOR_BOXES))
	sceneGroup:insert(messageTextRect)
	
	local messageTextOptions = {
		x = 0,
		y = POSITION_MESSAGE.y,
		font = settings.fontName,
		align = "left",
		width = WIDTH_MESSAGE_TEXT,
		text = "Message text",
		fontSize = SIZE_FONT_MESSAGE,
	}
	messageText = display.newText(messageTextOptions)
	messageText.anchorX = 0
	messageText.x = POSITION_MESSAGE.x - SIZE_MESSAGEBOX.width * 0.5 + PADDING
	sceneGroup:insert(messageText)
end

local function initialize(parameters)
	parameters = parameters or {}
	
	lastParameters = parameters
	
	unitsSelected = 0
	rectColor = {}
	
	local managerEvent = parameters.event or {}
	
	minigameIndexes = parameters.minigameIndexes or {1}
	worldIndex = parameters.worldIndex or 1
	levelIndex = parameters.levelIndex or 1
	gamemodeData = parameters.gamemodeData
	subject = parameters.subject
	
	powercubes = managerEvent.powerCubes or 0
	cubesText.text = powercubes
	
	canBuyUnits = false
	local player = players.getCurrent()
	if player.units then
		for index = 1, #player.units do
			local playerUnit = player.units[index]
			if playerUnit then
				local unitProxy = unitsProxy[index]
				local unit = unitProxy.unitIndex and unitsData[unitProxy.worldIndex][unitProxy.teamIndex][unitProxy.unitIndex].stats or {}
				if playerUnit.bought and playerUnit.unlocked and unit.available then
					if unit.cubeCost <= powercubes then
						canBuyUnits = true
						break
					end
				end
			end
		end
	end
	
	unitsFinalList = {}
	
	for indexText = 1, #textStats do
		local textBox = textStats[indexText]
		textBox.text = localization.getString(CHAR_STATS_INDEX[indexText].name)
	end
	
	messageText.text = canBuyUnits and localization.getString(MESSAGES.ok) or localization.getString(MESSAGES.retry)
	buttonRetry.isVisible = not canBuyUnits
	buttonOK.isVisible = canBuyUnits
	buttonOK:setFillColor(0.5)
	buttonOK:setEnabled(false)
	
	classCard.text = localization.getString("class")
	titleCard.text = localization.getString("title")
	
	levelGroup.isVisible = false
	textDesc["Name1"].text = ""
	textDesc["Name2"].text = ""
	textDesc["Type"].text = ""
	textDesc["Class"].text = ""
	updateStats({0,0,0,0})
	display.remove(heroImage)
end

--local function isTableEmpty(tab)
--	local hasIndices = #tab
--	local hasKeys = 0
--	for key, value in pairs(tab) do
--		hasKeys = hasKeys + 1
--	end
--	
--	return hasIndices == 0 and hasKeys == 0
--end


local function updateListIcon(index, info)
	if iconList[index].image then
		display.remove(iconList[index].image)
	end
	local unitHeroImage = display.newRoundedRect(0,0,100,100,15)
	unitHeroImage.x = iconList[index].positionX
	unitHeroImage.y = iconList[index].positionY 
	unitHeroImage.fill = { type = "image", filename = info.imageMenu }
	iconList[index].image = unitHeroImage
	unitIconGroup:insert(unitHeroImage)	
end

local function addUnitFrame(unitFrame)
	local unitFinalIndex = unitFrame.frameIndex % 9 == 0 and 9 or unitFrame.frameIndex % 9
	if unitsFinalList[unitFinalIndex] then
		local prevUnitFrame = unitsFinalList[unitFinalIndex]
		transition.to(prevUnitFrame.checkmark, {time = 400, alpha = 0, xScale = 0.005, yScale = 0.005, transition = easing.outQuad})
		unitsSelected = unitsSelected - 1
		powercubes = powercubes + unitFrame.cost
		prevUnitFrame.isSelected = false
	end
	unitsFinalList[unitFinalIndex] = unitFrame
	transition.to(unitFrame.checkmark, {time = 400, alpha = 1, xScale = SCALE_UNIT_CHECKMARK, yScale = SCALE_UNIT_CHECKMARK, transition = easing.outQuad})
	unitsSelected = unitsSelected + 1
	powercubes = powercubes - unitFrame.cost
	updateListIcon(unitFinalIndex, unitFrame.unitDex.info)
end

local function unitFrameTapped(event)
	local unitFrame = event.target
	if not unitFrame.locked and powercubes >= unitFrame.cost then
		sound.play("pop")
		unitFrame.isSelected = not unitFrame.isSelected
		transition.cancel(unitFrame.checkmark)
		updateUnit(unitFrame.unitDex)
		if unitFrame.isSelected then
			addUnitFrame(unitFrame)
		else
			unitsSelected = unitsSelected - 1
			powercubes = powercubes + unitFrame.cost
			transition.to(unitFrame.checkmark, {time = 400, alpha = 0, xScale = 0.005, yScale = 0.005, transition = easing.outQuad})
			local unitFinalIndex = unitFrame.frameIndex % 9 == 0 and 9 or unitFrame.frameIndex % 9
			unitsFinalList[unitFinalIndex] = nil
			if iconList[unitFinalIndex].image then
				display.remove(iconList[unitFinalIndex].image)
			end
			iconList[unitFinalIndex].image = nil
		end
		if unitsSelected > 0 then
			buttonOK:setFillColor(1)
			buttonOK:setEnabled(true)
		else
			buttonOK:setFillColor(0.5)
			buttonOK:setEnabled(false)
		end
		transition.cancel(cubesText)
		cubesText.text = powercubes
		cubesText.xScale = 2
		cubesText.yScale = 2
		transition.to(cubesText, {time = 500, xScale = 1, yScale = 1, transition = easing.outElastic})
		updateIcons()
	else
		if unitFrame.isSelected then
			sound.play("pop")
			unitFrame.isSelected = false
			unitsSelected = unitsSelected - 1
			powercubes = powercubes + unitFrame.cost
			
			local unitFinalIndex = unitFrame.frameIndex % 9 == 0 and 9 or unitFrame.frameIndex % 9
			unitsFinalList[unitFinalIndex] = nil
			
			transition.to(unitFrame.checkmark, {time = 400, alpha = 0, xScale = 0.005, yScale = 0.005, transition = easing.outQuad})
			
			if unitsSelected > 0 then
				buttonOK:setFillColor(1)
				buttonOK:setEnabled(true)
			else
				buttonOK:setFillColor(0.5)
				buttonOK:setEnabled(false)
			end
		
			transition.cancel(cubesText)
			cubesText.text = powercubes
			cubesText.xScale = 2
			cubesText.yScale = 2
			transition.to(cubesText, {time = 500, xScale = 1, yScale = 1, transition = easing.outElastic})
			updateIcons()
		else
			sound.play("enemyRouletteTickOp02") 
		end
	end
end

local function createUnitFrame(unitIndex, worldIndex)
	local unitFrame = display.newGroup()
	unitFrame.anchorChildren = true
	
	local unitData = unitsData[worldIndex][1][unitIndex].stats
	
	local unitBackground = display.newImageRect("images/units/unit.png", SIZE_UNIT_BACKGROUND, SIZE_UNIT_BACKGROUND)
	unitFrame:insert(unitBackground)
	
	local unitIcon = display.newImage(unitFactory.getUnitIconPath(worldIndex, unitIndex))
	unitIcon.width = unitIcon.width * SCALE_UNIT_ICON
	unitIcon.height = unitIcon.height * SCALE_UNIT_ICON
	unitIcon.x = OFFSET_UNIT_ICON.x
	unitIcon.y = OFFSET_UNIT_ICON.y
	unitFrame:insert(unitIcon)
	
	unitFrame.cost = unitData.cubeCost
	local costTextOptions = {
		x = OFFSET_COST_TEXT.x,
		y = OFFSET_COST_TEXT.y,
		font = settings.fontName,
		text = unitFrame.cost,
		fontSize = SIZE_FONT_COST,
	}
	local costText = display.newText(costTextOptions)
	costText:setFillColor(0)
	unitFrame:insert(costText)
	
	local lockImage = display.newImage("images/general/lock.png")
	lockImage.xScale = SCALE_UNIT_LOCK
	lockImage.yScale = SCALE_UNIT_LOCK
	unitFrame.lock = lockImage
	unitFrame:insert(lockImage)
	lockImage.isVisible = false
	
	local checkmark = display.newImage("images/units/checkmark.png")
	checkmark.xScale = SCALE_UNIT_CHECKMARK
	checkmark.yScale = SCALE_UNIT_CHECKMARK
	checkmark.x = OFFSET_UNIT_CHECKMARK.x
	checkmark.y = OFFSET_UNIT_CHECKMARK.y
	checkmark.alpha = 0
	unitFrame.checkmark = checkmark
	unitFrame:insert(checkmark)
	
	function unitFrame:setLocked(locked)
		unitFrame.locked = locked
		self.lock.isVisible = locked
		
		local color = locked and COLOR_LOCKED or {1}
		self.background:setFillColor(unpack(color))
		self.icon:setFillColor(unpack(color))
	end
	
	function unitFrame:setAvailable(available)
		local color = available and {1} or COLOR_LOCKED
		self.background:setFillColor(unpack(color))
		self.icon:setFillColor(unpack(color))
	end
	
	unitFrame.isSelected = false
	unitFrame:addEventListener("tap", unitFrameTapped)
	
	unitFrame.locked = false
	unitFrame.background = unitBackground
	unitFrame.icon = unitIcon
	
	return unitFrame
end

local function removeUnitGrid()
	display.remove(unitGrid)
	unitGrid = nil
	
	for iconIndex = 1, #iconList do
		display.remove(iconList[iconIndex].image)
	end
end

local function createUnitBanner(x, y, index)
	local bannerGroup = display.newGroup()
	
	local unitsTextBg = display.newRoundedRect(0, 0, 65, 130, 15)
	unitsTextBg.x = x - (70 * 0.5)
	unitsTextBg.y = y - 12
	unitsTextBg:setFillColor(0, 0.4)
	bannerGroup:insert(unitsTextBg)
	
	local sectionText = display.newText(localization.getString(unitsData[1][1][index].info.type), unitsTextBg.x, unitsTextBg.y, settings.fontName, 25)
	sectionText.rotation = -90
	bannerGroup:insert(sectionText)
	
	return bannerGroup
end

local function createUnitGrid(sceneGroup)
	unitGrid = display.newGroup()
	unitGrid.x = display.screenOriginX + (SIZE_UNIT_GRID.width - 340) * 0.5 + OFFSET_UNIT_GRID.x
	unitGrid.y = display.contentCenterY + OFFSET_UNIT_GRID.y
	sceneGroup:insert(unitGrid)
	
	local background = display.newRoundedRect(0, 0, SIZE_UNIT_GRID.width - 340, SIZE_UNIT_GRID.height, CORNER_RADIUS_UNIT_GRID)
	background:setFillColor(unpack(COLOR_BOXES))
	unitGrid:insert(background)
	
	local unitGridScrollviewOptions = {
		x = 0,
		y = 0,
		width = SIZE_UNIT_GRID.width - 340,
		height = SIZE_UNIT_GRID.height,
		hideBackground = true,
	}
	
	unitGridScrollView = widget.newScrollView(unitGridScrollviewOptions)
	unitGrid:insert(unitGridScrollView)
	unitGrid.scrollView = unitGridScrollView
	
	function unitGrid:animate()
		self.scrollView:scrollToPosition({y = -1000, time = 0, onComplete = function()
			self.scrollView:scrollToPosition({y = 0, time = 1000})
		end})
	end
	
	local unitCount = 0
	for worldIndex = 1, #unitsData do
		local unitlist = unitsData[worldIndex][1]
		for unitIndex = 1, #unitlist do
			if unitlist[unitIndex].available then
				unitCount = unitCount + 1
			end
		end
	end
	
	local spacing = SIZE_UNIT_GRID.width / COLUMN_SPACING
	local fillerRect = display.newRect(0, 0, SIZE_UNIT_GRID.width, math.floor((unitCount - 1) / COLUMN_SPACING) * spacing)
	fillerRect.anchorX = 0
	fillerRect.anchorY = 0
	fillerRect.isVisible = false
	unitGridScrollView:insert(fillerRect)
	
	for rowIndex = 1, 9 do
		local posY = 0 + ((rowIndex - 1) % GRID_ROW) * spacing + spacing * 0.5
			local posX = 0 + spacing * 0.5
			local banner = createUnitBanner(posX, posY, rowIndex)
			unitGridScrollView:insert(banner)
	end
	
	unitGrid.frames = {}
	local unitCount = 0
--	local unitData = {}
	
--	local unitCounter = 0
--	for indexWorld = 1, #unitsdex, 1 do
--		for indexInfo = 1, #unitsdex[indexWorld][1] do
--			unitCounter = unitCounter + 1
--			table.insert(unitData, unitCounter, unitsdex[indexWorld][1][indexInfo])
--		end
--	end
	
	for worldIndex = 1, 3 do -- limit to world 3 units
		local unitlist = unitsData[worldIndex][1]
		for unitIndex = 1, #unitlist do
			if unitlist[unitIndex].stats.available then
				unitCount = unitCount + 1
				local colnum = math.floor((unitCount - 1) / GRID_ROW) + 0.5
				local unitFrame = createUnitFrame(unitIndex, worldIndex)
				unitFrame.y = 0 + ((unitCount - 1) % GRID_ROW) * spacing + spacing * 0.5
				unitFrame.x = colnum * spacing + spacing * 0.5
				unitGridScrollView:insert(unitFrame)
				unitFrame.unitIndex = unitIndex
				unitFrame.worldIndex = worldIndex
				unitFrame.frameIndex = unitIndex
				unitFrame.unitProxy = unitlist[unitIndex].unitProxy
				unitFrame.unitDex = unitlist[unitIndex]
				unitGrid.frames[unitCount] = unitFrame
			end
		end
	end
	
	unitGrid:animate()
end

local function setupUnitGrid()
	local player = players.getCurrent()
	for index = 1, #unitGrid.frames do
		local unitIndex = unitGrid.frames[index].unitDex.unitProxy
		local unitUnlocked = player.units and player.units[unitIndex] and player.units[unitIndex].bought and player.units[unitIndex].unlocked
		local unitUnlocked = canBuyUnits and unitUnlocked
		unitGrid.frames[index]:setLocked(not unitUnlocked)
	end
end

local function setUnitIcons(sceneGroup)
	iconList = {}
	unitIconGroup = display.newGroup()
	sceneGroup:insert(unitIconGroup)
	for index = 1, 9 do
		local alphaRect = display.newRoundedRect(0,0,100,100,15)
		alphaRect.x = ((display.viewableContentWidth - 150) * ((index - 1)/8)) + 75
		alphaRect.y = display.viewableContentHeight - 70
		alphaRect:setFillColor(0, 0.4)
		iconList[index] = {positionX = alphaRect.x, positionY = alphaRect.y}
		unitIconGroup:insert(alphaRect)
	end
end

--local function updateListIcons()
--	display.remove(unitIconGroup2)
--	unitIconGroup2 = display.newGroup()
--	unitIconGroup:insert(unitIconGroup2)
--	for index = 1, 9 do
--		local unitHeroImage = display.newRoundedRect(0,0,100,100,15)
--		unitHeroImage.x = iconList[index].positionX
--		unitHeroImage.y = iconList[index].positionY 
--		unitHeroImage.fill = { type = "image", filename = unitsdex[1][1][index].imageMenu }
--		unitIconGroup:insert(unitHeroImage)
--	end
--end


local function playSound()
	if powercubes > 0 then 
		sound.play("finish") 
	else 
		sound.play("defeat") 
	end		
end
----------------------------------------------- Module functions
function scene.disableButtons()
	buttonOK:setEnabled(false)
	buttonRetry:setEnabled(false)
end

function scene.enableButtons()
	buttonOK:setEnabled(true)
	buttonRetry:setEnabled(true)
end

function scene:create(event)
	local sceneGroup = self.view
	
	backgroundGroup = display.newGroup()
	sceneGroup:insert(backgroundGroup)
	
	local scale = display.viewableContentWidth / 1024
	local backgroundFloor = display.newImage("images/general/floor.png")
	backgroundFloor.x = display.contentCenterX
	backgroundFloor.y = display.screenOriginY + display.viewableContentHeight
	backgroundFloor.anchorY = 0.8
	backgroundFloor.xScale = scale
	backgroundFloor.yScale = scale
	sceneGroup:insert(backgroundFloor)
	
	createCubeIndicator(sceneGroup)
	createMessageText(sceneGroup)
	createYogoCard(sceneGroup)
	setUnitIcons(sceneGroup)
	
	buttonList.retry.onRelease = onReleasedRetry
	buttonRetry = widget.newButton(buttonList.retry)
	buttonRetry.anchorX = 1
	buttonRetry.x = POSITION_MESSAGE.x + SIZE_MESSAGEBOX.width * 0.5 - PADDING
	buttonRetry.y = POSITION_MESSAGE.y
	sceneGroup:insert(buttonRetry)
	
	buttonList.ok.onRelease = onReleasedOK
	buttonOK = widget.newButton(buttonList.ok)
	buttonOK.width = buttonRetry.width
	buttonOK.height = buttonRetry.height
	buttonOK.anchorX = 1
	buttonOK.x = POSITION_MESSAGE.x + SIZE_MESSAGEBOX.width * 0.5 - PADDING
	buttonOK.y = POSITION_MESSAGE.y
	sceneGroup:insert(buttonOK)
	
	buttonRetry.isVisible = false
	buttonOK.isVisible = false
	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		self.disableButtons()
		currentPlayer = players.getCurrent()
		initialize(event.params)
		--updateListIcons()
		createBackground(sceneGroup)
		removeUnitGrid()
		createUnitGrid(sceneGroup)
		setupUnitGrid()
		playSound()
	elseif ( phase == "did" ) then
		self.enableButtons()
		
		buttonOK:setFillColor(0.5)
		buttonOK:setEnabled(false)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeUnitGrid()
		for indexStats = 1, #rectColor do
			display.remove(rectColor[indexStats])
		end
	end
end

----------------------------------------------- Execution
scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene

