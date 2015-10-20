----------------------------------------------- Select player
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonList = require( "data.buttonlist" )
local database = require( "libs.helpers.database" )
local music = require( "libs.helpers.music" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )
local players = require( "models.players" )
local herolist = require( "data.herolist" )
local scene = director.newScene() 
----------------------------------------------- Variables
local spaceObjects, objectDespawnX, objectSpawnX
local elementsGroup, dynamicGroup
local language
local nameText, emailText
local email, buttonOK
local playerList
local buttonsEnabled
local selectedProfileIndex
local checkmark
local chosenAge, chosenGrade
local newPlayer
local profileView
----------------------------------------------- Constants 
local COLOR_BACKGROUND = {148/255,75/255,199/255}
local SIZE_BACKGROUND = 1024
local MARGIN_BUTTON = 20

local OFFSET_PROFILEVIEW = {x = 0, y = 0}
local SIZE_PROFILEVIEW = {width = 600, height = 400}
local DEFAULT_EMAIL = "something@somewhere.com"

local STARS_LAYERS = 5
local STARS_LAYER_DEPTH_RATIO = 0.08
local STARS_PER_LAYER = 10

local ASTEROID_LAYERS = 2
local ASTEROID_LAYER_DEPTH_RATIO = 0.8
local ASTEROIDS_PER_LAYER = 2

local OBJECTS_TOLERANCE_X = 100
local OFFSET_YOGOTAR = {x = -200, y = -170}
local SCALE_YOGOTAR = 0.8

local SIZE_FONT_MESSAGE_LARGE = 60
local SIZE_FONT_MESSAGE_NORMAL = 35

local TEXT_TITLE = {
	en = "Please choose your child.",
	es = "Por favor escoge a tu hijo.",
}
local COLOR_EMAIL = {0,177/255,254/255}
local OFFSET_TITLE = {x = 0, y = 50}
local OFFSET_EMAIL = {x = 0, y = 100}

local OFFSET_OK = {x = 0, y = -75}
local SCALE_OK = 0.5
local DEFAULT_PLAYERLIST = {
--	{characterName = "Test player1", coins = 50, heroIndex = 1},
--	{characterName = "Test player2", coins = 150, heroIndex = 2}
}

local OFFSET_LEVEL = {x = -235, y = -10}
local OFFSET_NAME = {x = -34, y = -27}
local OFFSET_STARS = {x = -190, y = 28}
local OFFSET_COINS = {x = -20, y = 28}

local SIZE_FONT_LEVEL = 50
local SIZE_FONT_NAME = 45
local SIZE_FONT_STARS = 30
local SIZE_FONT_COINS = 30

local WIDTH_STATUS_TEXT = 200

local OFFSET_SHIELD = {x = -236, y = -5}
local OFFSET_SHIELD_STARS = {x = 1, y = -151}
local SCALE_CHECKMARK = 0.45
local OFFSET_CHECKMARK = {x = 225, y = 0}

local LABEL_NEWCHILD = {
	en = "New child",
	es = "Nuevo hijo",
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

local OFFSET_HERO = {x = 225, y = 0}
local SCALE_HERO = 0.37
----------------------------------------------- Functions
local function onReleasedOk()
	scene.disableButtons()
	players.deleteAll()
	playerList[selectedProfileIndex].id = nil
	players.save(playerList[selectedProfileIndex], true)
	timer.performWithDelay(500, function()
		director.gotoScene("scenes.menus.home", {effect = "crossFade", time = 600})
	end)
end

local function newKidReleased()
	if buttonsEnabled then
		players.deleteAll()
		newPlayer = players.getCurrent()
		newPlayer.age = chosenAge
		newPlayer.grade = chosenGrade
		director.gotoScene("scenes.menus.home", {effect = "crossFade", time = 600})
	end
end

local function createBackground(sceneGroup)
	local dynamicScale = display.viewableContentWidth / SIZE_BACKGROUND
    local backgroundContainer = display.newContainer(display.viewableContentWidth + 2, display.viewableContentHeight + 2)
    backgroundContainer.x = display.contentCenterX
    backgroundContainer.y = display.contentCenterY
    sceneGroup:insert(backgroundContainer)
    
    local background = display.newImage("images/menus/background.png", true)
    background.xScale = dynamicScale
    background.yScale = dynamicScale
	background.fill.effect = "filter.monotone"
	background.fill.effect.r, background.fill.effect.g, background.fill.effect.b = unpack(COLOR_BACKGROUND)
    backgroundContainer:insert(background)
	
	local containerHalfWidth = backgroundContainer.width * 0.5
	local containerHalfHeight = backgroundContainer.height * 0.5
	
	spaceObjects = {}
	
	objectDespawnX = containerHalfWidth + OBJECTS_TOLERANCE_X
	objectSpawnX = -containerHalfWidth - OBJECTS_TOLERANCE_X
	
	for layerIndex = 1, STARS_LAYERS do
		local starLayer = display.newGroup()
		backgroundContainer:insert(starLayer)
		for starsIndex = 1, STARS_PER_LAYER do
			local scale =  0.05 + layerIndex * 0.05
			
			local star = display.newImage("images/menus/star_"..math.random(1,2)..".png")
			star.x = math.random(objectSpawnX, objectDespawnX)
			star.y = math.random(-containerHalfHeight, containerHalfHeight)
			star.xScale = scale
			star.yScale = scale
			star.xVelocity = STARS_LAYER_DEPTH_RATIO * layerIndex
			starLayer:insert(star)
			
			spaceObjects[#spaceObjects + 1] = star
		end
	end
	
	for layerIndex = 1, ASTEROID_LAYERS do
		local asteroidLayer = display.newGroup()
		backgroundContainer:insert(asteroidLayer)
		for asteroidIndex = 1, ASTEROIDS_PER_LAYER do
			local scale =  0.5 + layerIndex * 0.2
			
			local asteroid = display.newImage("images/menus/asteroid_0"..math.random(1,2)..".png")
			asteroid.x = math.random(objectSpawnX, objectDespawnX)
			asteroid.y = math.random(-containerHalfHeight, containerHalfHeight)
			asteroid.xScale = scale
			asteroid.yScale = scale
			asteroid.xVelocity = ASTEROID_LAYER_DEPTH_RATIO * layerIndex
			asteroidLayer:insert(asteroid)
			
			spaceObjects[#spaceObjects + 1] = asteroid
		end
	end
end

local function updateSpaceObjects()
	if spaceObjects then
		for index = 1, #spaceObjects do
			local object = spaceObjects[index]
			
			object.x = object.x + object.xVelocity
			if object.x > objectDespawnX then
				object.x = objectSpawnX
			end
		end
	end
end

local function createShield(level)
	local shield = display.newGroup()
	level = level or 1
	if level > #LEVELIMAGES then
		level = #LEVELIMAGES
	end
	
	local shieldBackground = display.newImage(LEVELIMAGES[level])
	shield:insert(shieldBackground)
	
	local starNumber = level % 6
	local starsImage = display.newImage("images/yogodex/levels/star_0"..starNumber..".png")
	starsImage.x = OFFSET_SHIELD_STARS.x
	starsImage.y = OFFSET_SHIELD_STARS.y
	shield:insert(starsImage)
	
	return shield
end

local function profileTapped(event)
	local profileGroup = event.target
	if buttonsEnabled then
		sound.play("pop")
		if not selectedProfileIndex then
			transition.to(buttonOK, {time = 600, alpha = 1, xScale = SCALE_OK, yScale = SCALE_OK, transition = easing.outQuad})
		end
		
		if selectedProfileIndex ~= profileGroup.index then
			selectedProfileIndex = profileGroup.index

			transition.cancel(checkmark)
			profileGroup:insert(checkmark)
			checkmark.xScale = 0.1
			checkmark.yScale = 0.1
			checkmark.alpha = 0
			checkmark.x = OFFSET_CHECKMARK.x
			checkmark.y = OFFSET_CHECKMARK.y
			transition.to(checkmark,{time = 400,alpha = 1, xScale = SCALE_CHECKMARK, yScale = SCALE_CHECKMARK, transition = easing.outQuad})
		end
	end
end

local function createDynamicElements()
	scene.view:insert(checkmark)
	checkmark.alpha = 0
	
	display.remove(dynamicGroup)
	dynamicGroup = display.newGroup()
	elementsGroup:insert(dynamicGroup)
	
	local profileViewOptions = {
		x = display.contentCenterX + OFFSET_PROFILEVIEW.x,
		y = display.contentCenterY + OFFSET_PROFILEVIEW.y,
		width = SIZE_PROFILEVIEW.width,
		height = SIZE_PROFILEVIEW.height,
		scrollWidth = 0,
		scrollHeight = 0,
		hideScrollBar = true,
		hideBackground = true,
		verticalScrollDisabled = false,
		horizontalScrollDisabled = true,
	}
	profileView = widget.newScrollView(profileViewOptions)
	dynamicGroup:insert(profileView)
	
	local profileWidth = SIZE_PROFILEVIEW.width
	local profileHeight = profileWidth * 0.25
	
	local fillerHeight = profileHeight * #playerList + 2
	local filler = display.newRect(0, fillerHeight * 0.5, 20, fillerHeight)
	filler.isVisible = false
	profileView:insert(filler)
	
	for profileIndex = 1, #playerList do
		local profileGroup = display.newGroup()
		local profileBackground = display.newImageRect("images/register/childbackground.png", profileWidth, profileHeight)
		profileGroup:insert(profileBackground)
		
		profileGroup.x = SIZE_PROFILEVIEW.width * 0.5
		profileGroup.y = profileHeight * 0.5 + (profileHeight * (profileIndex - 1))
		
		local playerLevel = players.getRankLevel(playerList[profileIndex])
		local shield = createShield(playerLevel)
		shield.x = OFFSET_SHIELD.x
		shield.y = OFFSET_SHIELD.y
		shield.xScale = 0.28
		shield.yScale = 0.28
		profileGroup:insert(shield)
		
		local levelOptions = {
			x = OFFSET_LEVEL.x,
			y = OFFSET_LEVEL.y,
			font = settings.fontName,
			text = playerLevel,
			fontSize = SIZE_FONT_LEVEL,
			align = "center"
		}
		local levelText = display.newText(levelOptions)
		profileGroup:insert(levelText)
		
		local nameOptions = {
			x = OFFSET_NAME.x,
			y = OFFSET_NAME.y,
			font = settings.fontName,
			text = playerList[profileIndex].characterName,
			fontSize = SIZE_FONT_NAME,
			align = "center"
		}
		nameText = display.newText(nameOptions)
		profileGroup:insert(nameText)
		
		local starsOptions = {
			x = OFFSET_STARS.x,
			y = OFFSET_STARS.y,
			font = settings.fontName,
			text = players.getStars(playerList[profileIndex]),
			width = WIDTH_STATUS_TEXT,
			fontSize = SIZE_FONT_STARS,
			align = "right"
		}
		local starsText = display.newText(starsOptions)
		profileGroup:insert(starsText)
		
		local coinsOptions = {
			x = OFFSET_COINS.x,
			y = OFFSET_COINS.y,
			font = settings.fontName,
			text = playerList[profileIndex].coins,
			width = WIDTH_STATUS_TEXT,
			fontSize = SIZE_FONT_COINS,
			align = "right"
		}
		local coinsText = display.newText(coinsOptions)
		profileGroup:insert(coinsText)
		
		local heroIcon = display.newImage("units/hero/"..herolist[playerList[profileIndex].heroIndex].skinName.."/head_a.png")
		heroIcon.x = OFFSET_HERO.x
		heroIcon.y = OFFSET_HERO.y
		heroIcon.xScale = SCALE_HERO
		heroIcon.yScale = SCALE_HERO
		profileGroup:insert(heroIcon)
		
		profileView:insert(profileGroup)
		
		profileGroup.index = profileIndex
		profileGroup:addEventListener("tap", profileTapped)
	end
	
	local newChildButton = display.newGroup()
	newChildButton.x = SIZE_PROFILEVIEW.width * 0.5
	newChildButton.y = profileHeight * 0.5 + (profileHeight * (#playerList))
	
	local newChildBackground = display.newImageRect("images/register/newchild.png", profileWidth, profileHeight)
	newChildButton:insert(newChildBackground)
	
	local newChildOptions = {
		x = 0,
		y = 0,
		font = settings.fontName,
		text = LABEL_NEWCHILD[language],
		fontSize = 40,
		align = "center"
	}
	local newChildText = display.newText(newChildOptions)
	newChildButton:insert(newChildText)
	newChildButton:addEventListener("tap", newKidReleased)

	profileView:insert(newChildButton)
	
end

local function initialize(parameters)
	parameters = parameters or {}
	email = parameters.email or DEFAULT_EMAIL
	
	playerList = parameters.playerList or DEFAULT_PLAYERLIST
	
	chosenAge = parameters.age or 1
	chosenGrade = parameters.grade or 1
	
	nameText.text = TEXT_TITLE[language]
	emailText.text = email
	
	buttonOK.alpha = 0
	buttonOK.xScale = 0.1
	buttonOK.yScale = 0.1
	selectedProfileIndex = nil
	
	newPlayer = nil
end
----------------------------------------------- Class functions 
function scene.enableButtons()
	buttonOK:setEnabled(true)
	buttonsEnabled = true
end

function scene.disableButtons()
	buttonOK:setEnabled(false)
	buttonsEnabled = false
end

function scene:create(event)
	local sceneGroup = self.view
	
	local testMenuRect = display.newRect(display.screenOriginX + 50, display.screenOriginY + 50, 100, 100)
	testMenuRect.isHitTestable = true
	testMenuRect.isVisible = false
	sceneGroup:insert(testMenuRect)
	local testTapCount = 0
	testMenuRect:addEventListener("tap", function()
		testTapCount = testTapCount + 1
		if testTapCount == 10 then
			testTapCount = 0
			director.gotoScene( "scenes.menus.test" )
		end
	end)
	
	createBackground(sceneGroup)
	
	local titleOptions = {
		x = display.contentCenterX + OFFSET_TITLE.x,
		y = display.screenOriginY + OFFSET_TITLE.y,
		font = settings.fontName,
		text = "",
		fontSize = SIZE_FONT_MESSAGE_LARGE,
		align = "center"
	}
	nameText = display.newText(titleOptions)
	sceneGroup:insert(nameText)
	
	local emailOptions = {
		x = display.contentCenterX + OFFSET_EMAIL.x,
		y = display.screenOriginY + OFFSET_EMAIL.y,
		font = settings.fontName,
		text = "",
		fontSize = SIZE_FONT_MESSAGE_NORMAL,
		align = "center"
	}
	emailText = display.newText(emailOptions)
	emailText:setFillColor(unpack(COLOR_EMAIL))
	sceneGroup:insert(emailText)
	
	buttonList.ok.onRelease = onReleasedOk
	buttonOK = widget.newButton(buttonList.ok)
	buttonOK.x = display.contentCenterX + OFFSET_OK.x
	buttonOK.y = display.screenOriginY + display.viewableContentHeight + OFFSET_OK.y
	buttonOK.xScale = SCALE_OK
	buttonOK.yScale = SCALE_OK
	sceneGroup:insert(buttonOK)
	
	local window = display.newImageRect("images/register/window.png", SIZE_PROFILEVIEW.width + 38, SIZE_PROFILEVIEW.height + 40)
	window.x = display.contentCenterX
	window.y = display.contentCenterY + 10
	sceneGroup:insert(window)
	
	elementsGroup = display.newGroup()
	sceneGroup:insert(elementsGroup)
	
	checkmark = display.newImage("images/general/checkmark.png")
	checkmark.alpha = 0
	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		Runtime:addEventListener("enterFrame", updateSpaceObjects)
		language = database.config("language") or "en"
		initialize(event.params)
		createDynamicElements()
		self.disableButtons()
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
		Runtime:removeEventListener("enterFrame", updateSpaceObjects)
		if newPlayer then players.save(newPlayer) end
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene

