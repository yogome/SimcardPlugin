----------------------------------------------- Bonus Roulette
local director = require( "libs.helpers.director" )
local settings = require("settings")
local players = require( "models.players" )
local sound = require ("libs.helpers.sound")
local gameHelper = require( "scenes.game.helper" )
local scenelist = require( "data.scenelist" )
local eventCounter = require( "libs.helpers.eventcounter" )
local music = require( "libs.helpers.music" )
local game = director.newScene() 
----------------------------------------------- Variables

local worldBackgroundGroup
local background, roulette
local rouletteGroup, starsGroup, starExplosionGroup, coinsPanel, energyPanel
local tutorialGroup
local hand, arrow
local isRotated
local promedioY = 0
local prevRotation = 0
local timeCounter = 0
local prevTime = 0
--local timerBonus
local xChanged
local energyText, coinsText
local currentPlayer
local numStars
local explosionSheet, trailSheet
local newEnergy, newCoins
local isTapped
local endBonusTimer
local levelIndex, worldIndex
----------------------------------------------- Constants
local SIDE_MASTER = 1
local SCALE_MASTER = 0.9
local OFFSET_MASTER = {x = 250, y = 140}
local DEFAULT_WOLRD = 1
local WORLDS = {
		[1] = "images/BonusTime/fondo1.png",
		[2] = "images/BonusTime/fondo2.png"
}

local COLOR_BACKGROUND = {123/255,205/255,187/255}
local SCALE = (display.viewableContentHeight/512)
local ROULETTE_POSITION_X = display.screenOriginX + 300
local ROULETTE_POSITION_Y = display.contentCenterY + 120

local STARSLETTER_POSITION_X = ROULETTE_POSITION_X + 5
local STARSLETTER_POSITION_Y = ROULETTE_POSITION_Y - 250

local itemRoulette = {
		[1] = {name = "coins", number = "50", image = "images/shop/coin-01.png", x = 0, y = 0 - 190, rotate = 0  },
		[2] = {name = "coins", number = "25", image = "images/shop/coin-01.png", x = 135, y = 0 - 135, rotate = 45  },
		[3] = {name = "coins", number = "100", image = "images/shop/coin-01.png", x = 190, y = 0, rotate = 90  },
		[4] = {name = "coins", number = "150", image = "images/shop/coin-01.png", x = 135, y = 135, rotate = 135  },
		[5] = {name = "coins", number = "75", image = "images/shop/coin-01.png", x = 0, y = 190, rotate = 180  },
		[6] = {name = "coins", number = "200", image = "images/shop/coin-01.png", x = - 135, y = 0 + 135, rotate = 225  },
		[7] = {name = "coins", number = "250", image = "images/shop/coin-01.png", x = - 190, y = 0, rotate = 270  },
		[8] = {name = "coins", number = "300", image = "images/shop/coin-01.png", x = - 135, y = - 135, rotate = 315  }
}

local STARSPOSITION = {
		[1] = {positionX = STARSLETTER_POSITION_X-4 - 187, positionY = STARSLETTER_POSITION_Y + 10, image = "images/BonusTime/star-03.png", rotate = 28},
		[2] = {positionX = STARSLETTER_POSITION_X-4, positionY = STARSLETTER_POSITION_Y - 64, image = "images/BonusTime/star-02.png", rotate = 0},
		[3] = {positionX = STARSLETTER_POSITION_X-4 + 195, positionY = STARSLETTER_POSITION_Y + 20, image = "images/BonusTime/star-01.png", rotate = -28}
}

local EXPLOSION_POSITIONS = {
		[1] = {x = STARSPOSITION[1].positionX, y = STARSPOSITION[1].positionY + 50 },
		[2] = {x = STARSPOSITION[2].positionX, y = STARSPOSITION[2].positionY + 50 },
		[3] = {x = STARSPOSITION[3].positionX, y = STARSPOSITION[3].positionY + 50 },
}

local OFFSET_ENERGY_TEXT = {x = -20, y = -2}
local OFFSET_COINS_TEXT = {x = -35, y = -2}

local WIDTH_STATUS_TEXTS = 120

local TAG_TRANSITION_TUTORIAL = "tagTutorial"


----------------------------------------------- Functions
local function spawnExplosion(positionX, positionY)
	sound.play("confetti_explosion_op1")
	local sequenceData = {
		{ name = "explode", sheet = explosionSheet, start = 1, count = 16, time = 800, loopCount = 1},
	}
	
	local masterSprite = display.newSprite( explosionSheet, sequenceData )
	masterSprite.x = positionX 
	masterSprite.y = positionY
	masterSprite:play()
	
	function masterSprite:sprite(event)
		if event.phase == "ended" then
			display.remove(self)
		end
	end
	
	starExplosionGroup:insert(masterSprite)
end

local function updateNumber(textObject, number)
	number = tonumber(number)
	local actualNumber = tonumber(textObject.text)
	if actualNumber and number then
		if actualNumber < number then
			actualNumber = actualNumber + 10
			textObject.text = actualNumber > number and number or actualNumber
		end
	end
end

local function createBackground(sceneGroup)
	local backgroundColor = display.newRect(display.screenOriginX - 1, display.screenOriginY - 1, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	backgroundColor.anchorX = 0
	backgroundColor.anchorY = 0
	backgroundColor:setFillColor(unpack(COLOR_BACKGROUND))
	sceneGroup:insert(backgroundColor)
	worldBackgroundGroup = display.newGroup()
	sceneGroup:insert(worldBackgroundGroup)
	local ground = display.newImage("images/BonusTime/piso.png")
	ground.xScale = SCALE
	ground.yScale = SCALE
	ground.x = display.contentCenterX
	ground.y = display.contentCenterY + 200
	sceneGroup:insert(ground)
	local signal = display.newImage("images/BonusTime/letrero.png")
	signal.x = display.viewableContentWidth - 260
	signal.y = display.screenOriginY + 10
	sceneGroup:insert(signal)
	local stand = display.newImage("images/BonusTime/base.png")
	stand.x = ROULETTE_POSITION_X
	stand.y = ROULETTE_POSITION_Y + 50
	sceneGroup:insert(stand)
	local starsLetter = display.newImage("images/BonusTime/stars.png")
	starsLetter.x = ROULETTE_POSITION_X + 5
	starsLetter.y = ROULETTE_POSITION_Y - 250
	sceneGroup:insert(starsLetter)
end

local function createStatusElements(sceneGroup)
	energyPanel = display.newGroup()
	energyPanel.anchorChildren = true
	--energyPanel:addEventListener("tap", energyPanelTapped)
	sceneGroup:insert(energyPanel)
	
	local energyBackground = display.newImage("images/BonusTime/energy.png")
	energyBackground.xScale = 0.5
	energyBackground.yScale = 0.5
	energyPanel:insert(energyBackground)
	
	
	local energyTextOptions = {
		x = OFFSET_ENERGY_TEXT.x,
		y = OFFSET_ENERGY_TEXT.y,
		width = WIDTH_STATUS_TEXTS,
		align = "right",
		font = settings.fontName,
		text = "500",
		fontSize = 40,
	}
	energyText = display.newText(energyTextOptions)
	energyPanel:insert(energyText)
	
	coinsPanel = display.newGroup()
	coinsPanel.anchorChildren = true
	sceneGroup:insert(coinsPanel)
	
	local coinsBackground = display.newImage("images/BonusTime/coin.png")
	coinsBackground.xScale = 0.5
	coinsBackground.yScale = 0.5
	coinsPanel:insert(coinsBackground)
	local coinsTextOptions = {
		x = OFFSET_COINS_TEXT.x,
		y = OFFSET_COINS_TEXT.y,
		width = WIDTH_STATUS_TEXTS,
		align = "right",
		font = settings.fontName,
		text = "9000",
		fontSize = 40,
	}
	coinsText = display.newText(coinsTextOptions)
	coinsPanel:insert(coinsText)
	
	energyPanel.anchorY = 0
	coinsPanel.anchorY = 0
	
	local yPosition = display.screenOriginY + 20
	local positionXPanel = display.screenOriginX + 200
	
	coinsPanel.y = yPosition
	coinsPanel.x = positionXPanel 
	
	energyPanel.anchorX = 0
	energyPanel.y = yPosition
	energyPanel.x = positionXPanel + (positionXPanel * 0.6)
	
	
end

local function createWorldBackground(worldIndex)
	display.remove(background)
	worldIndex = worldIndex and worldIndex or DEFAULT_WOLRD
	background = display.newImage(WORLDS[worldIndex])
	background.xScale = SCALE
	background.yScale = SCALE
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	worldBackgroundGroup:insert(background)
end

local function grabEffect(positionX, positionY)
	local sequenceData = {
		{ name = "travel", sheet = trailSheet, start = 1, count = 24, time = 1200, loopCount = 1},
	}
	
	local masterSprite = display.newSprite( trailSheet, sequenceData )
	masterSprite.x = positionX
	masterSprite.y = positionY
	masterSprite:play()
	
	starExplosionGroup:insert(masterSprite)
	
	function masterSprite:sprite(event)
		if event.phase == "ended" then
			display.remove(self)
		end
	end
	
	masterSprite:addEventListener("sprite", masterSprite)
	
end

local function saveGift(gift)
	if gift.name == "coins" then
		currentPlayer.coins = currentPlayer.coins + gift.number
		newCoins = currentPlayer.coins
		grabEffect(coinsPanel.x, coinsPanel.y)
	else
		currentPlayer.energy = currentPlayer.energy + gift.number
		newEnergy = currentPlayer.energy
		grabEffect(energyPanel.x + 150, energyPanel.y)
	end
end

local function girar(ruleta)
	local final = math.random(1, 8)
	local toRotate = ((360/8) * (final)) + (360 * 10)
	
	sound.play("roulette")
	transition.to( ruleta, { rotation= toRotate , time= 3000, transition=easing.outExpo, onComplete = function()
		local indexRouletteFinal = 8 - ((ruleta.rotation % 360)/45)
		indexRouletteFinal = indexRouletteFinal <= 0 and 8 or indexRouletteFinal
		for indexGift = 1, numStars do
			transition.to(ruleta, {time = ((indexGift - 1) * 700) + 100, onComplete = function()
				spawnExplosion(EXPLOSION_POSITIONS[indexGift].x, EXPLOSION_POSITIONS[indexGift].y )
				saveGift(itemRoulette[indexRouletteFinal])
				indexRouletteFinal = indexRouletteFinal + 1
				indexRouletteFinal = indexRouletteFinal > 8 and 1 or indexRouletteFinal
				if indexGift == numStars then
					endBonusTimer = timer.performWithDelay(1500, function()
						local timesPlayed = eventCounter.updateEventCount("bonusWorld"..worldIndex, "bonusLevel"..levelIndex)
						gameHelper.loader("scenes.menus.loading", {nextSceneParameters = {worldIndex = worldIndex}, nextScene = "scenes.menus.selecthero", sceneList = scenelist.menus})
					end)
				end
			end})
		end	
	end} )		
end

local function manageTime(event)
	timeCounter = event.time - prevTime + timeCounter
	prevTime = event.time
	
end

local function dragUpdate(event)

	if isRotated then
		return
	end
	prevRotation = 0

	local self = event.target
     if event.phase == "began" and event.x > self.x and not isRotated then
		--self.deltaX = event.x > self.x and event.x - self.x or self.x - event.x
        self.deltaY = event.y
		self.deltaX = event.x
		isTapped = true
        display.getCurrentStage():setFocus( self )
        self.isFocus = true
    elseif self.isFocus then
        if event.phase == "moved" then
			promedioY = event.x > self.x and event.y - self.deltaY or promedioY
			self.rotation = (prevRotation + promedioY) % 360
        elseif event.phase == "ended" or event.phase == "cancelled" then    		
            display.getCurrentStage():setFocus( nil )
            self.isFocus = false  
			prevRotation = self.rotation
			local distance = event.y - self.deltaY
			--self.speed = (math.round((distance * 0.1) / (timeCounter * 0.001)))
			timeCounter = 0
            if(distance > 0 ) then
            	girar(self)
				isRotated = true
            end
			--self.speed = 0
        end
    end
    return true
end

local function createRoulette()
	display.remove(roulette)
	roulette = display.newImage("images/BonusTime/ruleta_2.png")
	rouletteGroup.rotation = 0
	rouletteGroup:insert(roulette)
	
	for indexRoulette = 1, 8 do
		local item = display.newImage(itemRoulette[indexRoulette].image)
		item.x = itemRoulette[indexRoulette].x
		item.y = itemRoulette[indexRoulette].y
		item.rotation = itemRoulette[indexRoulette].rotate
		rouletteGroup:insert(item)
		
		local number = display.newText(itemRoulette[indexRoulette].number, itemRoulette[indexRoulette].x - itemRoulette[indexRoulette].x * 0.3 , itemRoulette[indexRoulette].y - itemRoulette[indexRoulette].y * 0.3, settings.fontName , 30)
		number.rotation = itemRoulette[indexRoulette].rotate
		rouletteGroup:insert(number)
	end
	isRotated = false
	rouletteGroup:addEventListener("touch", dragUpdate)
end

local function createMaster(sceneGroup)
	
	local masterSheetData1 = { width = 430, height = 512, numFrames = 8, sheetContentWidth = 860, sheetContentHeight = 2048 }
	local masterSheet1 = graphics.newImageSheet( "images/win/master_win.png", masterSheetData1 )

	local sequenceData = {
		{ name = "win", sheet = masterSheet1, start = 1, count = 8, time = 500, loopCount = 0 },
	}

	local masterSprite = display.newSprite( masterSheet1, sequenceData )
	masterSprite.x = display.contentCenterX + OFFSET_MASTER.x
	masterSprite.y = display.contentCenterY + OFFSET_MASTER.y
	masterSprite.xScale = SCALE_MASTER * SIDE_MASTER
	masterSprite.yScale = SCALE_MASTER
	masterSprite:play()
	
	sceneGroup:insert(masterSprite)
end

local function createSheetEffects(sceneGroup)
	starExplosionGroup = display.newGroup()
	sceneGroup:insert(starExplosionGroup)
	local explosionSheetData1 = { width = 256, height = 256, numFrames = 16, sheetContentWidth = 1024, sheetContentHeight = 1024 }
	explosionSheet = graphics.newImageSheet( "images/BonusTime/fx_star_xplosion.png", explosionSheetData1 )
	
	local trailEffectSheetData = {width = 128, height = 256, numFrames = 32, sheetContentWidth = 1024, sheetContentHeight = 1024 }
	trailSheet = graphics.newImageSheet( "images/BonusTime/fx_trail.png", trailEffectSheetData )
	
end

local function transitionTutorial()
	hand.x = display.contentCenterX
	hand.y = display.contentCenterY
	arrow.x = hand.x -50
	arrow.y = hand.y - 100
	transition.to(arrow, {tag = TAG_TRANSITION_TUTORIAL, alpha = 1})
	transition.to(hand, {tag = TAG_TRANSITION_TUTORIAL, alpha = 1, onComplete = function()
		transition.to(hand, {tag = TAG_TRANSITION_TUTORIAL, delay = 500, time = 1000, y = hand.y + 250, onComplete = function()
			transition.to(hand, {tag = TAG_TRANSITION_TUTORIAL, alpha = 0})
			transition.to(arrow, {tag = TAG_TRANSITION_TUTORIAL, alpha = 0, onComplete = function()
				if not isTapped then
					transitionTutorial()
				end
			end})
		end})
	end})
end

local function showTutorial()
	hand = display.newImage("images/BonusTime/flecha-02.png")
	hand.anchorX = 0.95
	hand.anchorY = 0
	hand.xScale = 0.3
	hand.yScale = 0.3
	
	arrow = display.newImage("images/BonusTime/flecha-01.png")
	arrow.xScale = 0.3
	arrow.yScale = 0.3
	tutorialGroup:insert(hand)
	tutorialGroup:insert(arrow)
	
	arrow.alpha = 0
	hand.alpha = 0
	
	transitionTutorial()
end

local function initialize(parameters)
	parameters = parameters or {}
	numStars = parameters.stars or 3
	isTapped = false
	for indexStars = 1, numStars do
		local star = display.newImage("images/win/star.png")
		star.x = STARSPOSITION[indexStars].positionX
		star.y = STARSPOSITION[indexStars].positionY
		star.rotation = STARSPOSITION[indexStars].rotate
		star:scale(0.33, 0.33)
		starsGroup:insert(star)
	end
	levelIndex = parameters.levelIndex or 1
	worldIndex = parameters.worldIndex or 1
	
	coinsText.text = tonumber(currentPlayer.coins or 0)
	energyText.text = tonumber(currentPlayer.energy or 0)
	newCoins = tonumber(coinsText.text)
	newEnergy = tonumber(energyText.text)
	
	music.playTrack(1,400)
end

local function enterFrame()
	if isTapped then
		transition.cancel(TAG_TRANSITION_TUTORIAL)
		display.remove(hand)
		display.remove(arrow)
	end
	updateNumber(coinsText, newCoins)
	updateNumber(energyText, newEnergy)
end

----------------------------------------------- Module functions 
function game:create(event)
	local sceneGroup = self.view
	
	createBackground(sceneGroup)
	rouletteGroup = display.newGroup()
	rouletteGroup.x = ROULETTE_POSITION_X
	rouletteGroup.y = ROULETTE_POSITION_Y
	sceneGroup:insert(rouletteGroup)
	
	starsGroup = display.newGroup()
	sceneGroup:insert(starsGroup)
	
	createStatusElements(sceneGroup)
	createMaster(sceneGroup)
	createSheetEffects(sceneGroup)
	
	tutorialGroup = display.newGroup()
	sceneGroup:insert(tutorialGroup)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		currentPlayer = players.getCurrent()
		createWorldBackground()
		createRoulette()
		xChanged = false
		initialize(event.params)
		showTutorial()
		Runtime:addEventListener("enterFrame", enterFrame)
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		isTapped = false
		if endBonusTimer then
			timer.cancel(endBonusTimer)
		end
		transition.cancel(TAG_TRANSITION_TUTORIAL)
		display.remove(hand)
		display.remove(arrow)
		Runtime:removeEventListener("enterFrame", enterFrame)
		players.save(currentPlayer)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
