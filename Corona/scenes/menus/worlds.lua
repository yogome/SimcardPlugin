----------------------------------------------- Worlds
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonlist = require( "data.buttonlist" )
local sound = require( "libs.helpers.sound" )
local players = require( "models.players" )
local robot = require( "libs.helpers.robot" )
local database = require( "libs.helpers.database" )
local worldsList = require( "data.worldslist" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonBack
local titleGroup, title, language
local buttonsEnabled
local currentPlayer
local scrollView
local scrollViewButtonGroup
local cardList
----------------------------------------------- Constants
local SCALE_TITLE = 0.8
local COLOR_BACKGROUND = {47/255,190/255,196/255}
local WIDTH_BACKGROUND = 1024
local HEIGHT_BACKGROUND = 768
local MARGIN = 20
local OFFSET_COMPLETION_BACKGROUND = {x = 0, y = 257}
local OFFSET_COMPLETION_TEXT = {x = 0, y = 255}
local NUM_BACKGROUNDS = 5
local PADDING_CARDS_SIDES = 400
local SCALE_CARDS = 1.1
local COLOR_CARD_DISABLED = {0.2}
----------------------------------------------- Functions
local function onReleasedBack()
	director.gotoScene( "scenes.menus.home", { effect = "zoomInOutFade", time = 600, } )
end

local function cardTapped(event)
	if buttonsEnabled then
		local worldSelected = worldsList[event.target.index]
		if worldSelected.isAvailable then
			if not currentPlayer.unlockedWorlds[event.target.index] then
				currentPlayer.unlockedWorlds[event.target.index] = {
					unlocked = true,
					watchedEnd = false,
					watchedStart = false,
					levels = {
						[1] = {unlocked = true, stars = 0},
					},
				}
			end
			buttonsEnabled = false
			sound.play("pop")
			director.gotoScene( "scenes.menus.levels", { effect = "zoomInOutFade", time = 600, params = {worldIndex = event.target.index, category = event.target.name }} )
		else
			sound.play("wrongAnswer")
		end
	end
end

local function createTitle()
	display.remove(title)
	
	title = display.newImage("images/worlds/title_central.png")
	title.x = display.contentCenterX
	title.y = buttonBack.y
	title.xScale = SCALE_TITLE
	title.yScale = SCALE_TITLE
	titleGroup:insert(title)
end

local function createCards()
	
	local totalWidth = (display.viewableContentHeight / HEIGHT_BACKGROUND) * WIDTH_BACKGROUND * NUM_BACKGROUNDS
	local paddingCards = (totalWidth - (PADDING_CARDS_SIDES * 2))/(#worldsList - 1)
	
	
	for index = 1, #worldsList do
		display.remove(cardList[index])
		cardList[index] = nil
		
		local card = display.newGroup()
		card.index = index
		card.y = scrollView.height * 0.5
		card.x = PADDING_CARDS_SIDES + (index - 1) * paddingCards
		scrollViewButtonGroup:insert(card)
		card.xScale = SCALE_CARDS
		card.yScale = SCALE_CARDS
		
		card.name = worldsList[index].name or ""
		
		local cardImage = display.newImage(worldsList[index].cardName)
		card:insert(cardImage)
		
		if not worldsList[index].isAvailable then
			cardImage:setFillColor(unpack(COLOR_CARD_DISABLED))
		end
		
		card:addEventListener("tap", cardTapped)
		
		cardList[index] = card
	end
	
end
----------------------------------------------- Class functions 
function scene.enableButtons()
	buttonBack:setEnabled(true)
	buttonsEnabled = true
end

function scene.disableButtons()
	buttonBack:setEnabled(false)
	buttonsEnabled = false
end

function scene.backAction()
	robot.press(buttonBack)
	return true
end 

function scene:create(event)
	local sceneGroup = self.view
	
	cardList = {}
	
	local scrollViewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		hideBackground = false,
		verticalScrollDisabled = true,
		isBounceEnabled = false,
	}
	
	scrollView = widget.newScrollView(scrollViewOptions)
	sceneGroup:insert(scrollView)

	local backgroundScale = display.viewableContentHeight / HEIGHT_BACKGROUND
	
	for index = 1, NUM_BACKGROUNDS do
		local background = display.newImage("images/worlds/fondo"..index..".png")
		background.anchorX = 0
		background.x = ((index - 1) * WIDTH_BACKGROUND) * backgroundScale
		background.y = scrollView.height * 0.5
		background.xScale = backgroundScale
		background.yScale = backgroundScale
		scrollView:insert(background)
	end
	
	scrollViewButtonGroup = display.newGroup()
	scrollView:insert(scrollViewButtonGroup)
	
	titleGroup = display.newGroup()
	sceneGroup:insert(titleGroup)
	
	buttonlist.back.onRelease = onReleasedBack
	buttonBack = widget.newButton(buttonlist.back)
	buttonBack.x = display.screenOriginX + buttonBack.width * 0.5 + MARGIN
	buttonBack.y = display.screenOriginY + buttonBack.height * 0.5 + MARGIN
	sceneGroup:insert(buttonBack)
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		language = database.config("language") or "en"
		currentPlayer = players.getCurrent()
		createTitle()
		createCards()
		self.disableButtons()
	elseif ( phase == "did" ) then
		self.enableButtons()
	end
end

function scene:hide( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene
