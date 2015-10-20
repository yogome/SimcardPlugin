----------------------------------------------- Home
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local buttonList = require( "data.buttonlist" )
local database = require( "libs.helpers.database" )
local parentgate = require( "libs.helpers.parentgate" )
local logger = require( "libs.helpers.logger" )
local music = require( "libs.helpers.music" )
local players = require( "models.players" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonPlay, buttonSettings, logo
local bgAsteroids, bgAsteroids
local currentPlayer
local gyroX, gyroY
local deltaYUp, deltaXUp
local upHeroes
----------------------------------------------- Constants 
local SIZE_BACKGROUND = 1024
local MARGIN_BUTTON = 20
local SCALE_LOGO = 0.7
local OFFSET_LOGO = {x = 0, y = 0}
----------------------------------------------- Functions
local function onReleasedPlay()
	if currentPlayer.gender == "none" then
		director.gotoScene( "scenes.menus.selecthero", { effect = "fade", time = 600, })
	else
		director.gotoScene( "scenes.menus.worlds", { effect = "fade", time = 600, })
	end
end

local function onReleasedSettings()
	director.showOverlay( "scenes.menus.settings", { isModal = true, effect = "zoomInOutFade", time = 400 } )
end

local function cancelPlayTransition()
	if buttonPlay.timer then
		timer.cancel(buttonPlay.timer)
	end
	transition.cancel(buttonPlay)
end

local function startTransitions()
	cancelPlayTransition()
	transition.cancel(logo)
	
	buttonPlay.xScale = 1
	buttonPlay.yScale = 1
	
	local smallScale = 0.75
	local bigScale = 0.85
	
	transition.to(buttonPlay, {time = 900, xScale = smallScale, yScale = smallScale, transition = easing.inOutSine})
	transition.to(buttonPlay, {delay = 900, time = 900, xScale = bigScale, yScale = bigScale, transition = easing.inOutSine})
	buttonPlay.timer = timer.performWithDelay(1800, function()
		transition.to(buttonPlay, {time = 900, xScale = smallScale, yScale = smallScale, transition = easing.inOutSine})
		transition.to(buttonPlay, {delay = 900, time = 900, xScale = bigScale, yScale = bigScale, transition = easing.inOutSine})
	end, -1)
	
	logo.xScale = 0.5
	logo.yScale = 0.5
	logo.alpha = 0
	
	transition.to(logo, {time = 600, alpha = 1, xScale = SCALE_LOGO, yScale = SCALE_LOGO, transition = easing.outQuad})
end

local function createBackground(sceneGroup)
	local dynamicScale = display.viewableContentWidth / SIZE_BACKGROUND
    local backgroundContainer = display.newContainer(display.viewableContentWidth + 2, display.viewableContentHeight + 2)
    backgroundContainer.x = display.contentCenterX
    backgroundContainer.y = display.contentCenterY
    sceneGroup:insert(backgroundContainer)
    
    local background = display.newImage("images/home/screen_home.png", true)
    background.xScale = dynamicScale
    background.yScale = dynamicScale
    backgroundContainer:insert(background)
	
	upHeroes = display.newImage("images/home/personajesyapp.png")
	upHeroes.xScale = dynamicScale
    upHeroes.yScale = dynamicScale
	backgroundContainer:insert(upHeroes)
end

local function onGyroscope(event)
	gyroX = gyroX + event.xRotation * 0.3
	gyroY = gyroY + event.yRotation * 0.3
	
	if gyroX > 5 or gyroX < -5 then
		gyroX = gyroX - event.xRotation * 0.3
	end
	
	if gyroY > 5 or gyroY < -5 then
		gyroY = gyroY - event.yRotation * 0.3
	end
	
	upHeroes.x = deltaXUp + gyroX * 5
	upHeroes.y = deltaYUp - gyroY * 5
end
----------------------------------------------- Class functions 
function scene.enableButtons()
	buttonPlay:setEnabled(true)
	buttonSettings:setEnabled(true)
end

function scene.disableButtons()
	buttonPlay:setEnabled(false)
	buttonSettings:setEnabled(false)
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
	
	deltaYUp = upHeroes.y
	deltaXUp = upHeroes.x
	
	logo = display.newImage("images/home/logo_yappkids.png", true)
	logo.x = display.contentCenterX + OFFSET_LOGO.x
	logo.y = display.contentCenterY + OFFSET_LOGO.y
	sceneGroup:insert(logo)
	
	buttonList.play.onRelease = onReleasedPlay
	buttonPlay = widget.newButton(buttonList.play)
	buttonPlay.x = display.contentCenterX
	buttonPlay.y = display.screenOriginY + display.viewableContentHeight - 128 - MARGIN_BUTTON
	sceneGroup:insert(buttonPlay)
	
	buttonList.settings.onRelease = onReleasedSettings
	buttonSettings = widget.newButton(buttonList.settings)
	buttonSettings.x = display.screenOriginX + buttonSettings.width * 0.5 + MARGIN_BUTTON
	buttonSettings.y = display.screenOriginY + display.viewableContentHeight - buttonSettings.height * 0.5 - MARGIN_BUTTON
	sceneGroup:insert(buttonSettings)
	
	buttonSettings.isVisible = false
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		currentPlayer = players.getCurrent()
		self.disableButtons()
		startTransitions()
		gyroX = 0
		gyroY = 0
		Runtime:addEventListener("gyroscope", onGyroscope)
	elseif ( phase == "did" ) then
		self.enableButtons()
		music.playTrack(1,400)
	end
end

function scene:hide( event )
	local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
		Runtime:removeEventListener("gyroscope", onGyroscope)
		self.disableButtons()
	elseif ( phase == "did" ) then
		cancelPlayTransition()
	end
end

scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene

