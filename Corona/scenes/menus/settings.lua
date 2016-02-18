----------------------------------------------- Main game logic
local path = ...
local localization = require("libs.helpers.localization")
local director = require( "libs.helpers.director")
local buttonList = require("data.buttonlist")
local sound = require("libs.helpers.sound")
local music = require("libs.helpers.music")
local uifx = require("libs.helpers.uifx")
local widget = require( "widget" )

local game = director.newScene() 
----------------------------------------------- Variables
local buttonSound, buttonMusic, buttonOK
local buttonsLayer, backgroundLayer
local languageButtons
local parent
----------------------------------------------- Constants
local OFFSET_X_BUTTONS_LANGUAGE = 100
local OFFSET_Y_BUTTONS_LANGUAGE = -20
local BUTTON_LANGUAGE_SPACING = 136
local DATA_LANGUAGE_BUTTONS = {
	--[1] = {language = "en"},
	[1] = {language = "es"},
	[2] = {language = "pt"},
} 
local ALPHA_DISABLED = 0.5

local OFFSET_BUTTON_MUSIC = {x = -210, y = -90}
local OFFSET_BUTTON_SOUND = {x = -210, y = 70}
local OFFSET_BUTTON_OK = {x = 0, y = 270}
local SCALE_BACKGROUND = 1.1
----------------------------------------------- Functions
local function toggleSound()
	sound.setEnabled(not sound.isEnabled())
	buttonSound.alpha = sound.isEnabled() and 1 or ALPHA_DISABLED
	if sound.isEnabled() then sound.play("pop") end
end

local function toggleMusic()
	music.setEnabled(not music.isEnabled())
	buttonMusic.alpha = music.isEnabled() and 1 or ALPHA_DISABLED
end

local function closeWindow()
	director.hideOverlay("fade", 500)
	if parent and parent.reloadLanguage then
		parent.reloadLanguage()
	end
end

local function chooseLanguage(event)
	sound.play("pop")
	localization.setLanguage(event.target.language)
end

local function initialize(event)
	event = event or {}
	
	parent = event.parent
	
	buttonMusic.alpha = music.isEnabled() and 1 or ALPHA_DISABLED
	buttonSound.alpha = sound.isEnabled() and 1 or ALPHA_DISABLED
	
	languageButtons[localization.getLanguage()]:setState({isOn = true})
	
	uifx.applyBounceTransition(buttonOK, {
		smallScale = 0.95,
		largeScale = 1.1,
	})
end
----------------------------------------------- Module functions 
function game:create(event)
	local sceneView = self.view
	
	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)
	
	local fadeRect = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	fadeRect:setFillColor(0, 0.8)
	backgroundLayer:insert(fadeRect)
	
	local background = display.newImage("images/settings/background.png")
	background.x, background.y = display.contentCenterX, display.contentCenterY
	background:scale(SCALE_BACKGROUND, SCALE_BACKGROUND)
	backgroundLayer:insert(background)
	
	buttonsLayer = display.newGroup()
	sceneView:insert(buttonsLayer)
	
	languageButtons = {}
	
	local startY = display.contentCenterY - (BUTTON_LANGUAGE_SPACING * (#DATA_LANGUAGE_BUTTONS - 1)) * 0.5
	for index = 1, #DATA_LANGUAGE_BUTTONS do
		local options = {width = 410, height = 128, numFrames = 2}
		local radioButtonSheet = graphics.newImageSheet("images/settings/"..tostring(DATA_LANGUAGE_BUTTONS[index].language)..".png", options)
	
		local languageSwitch = widget.newSwitch({
			x = display.contentCenterX + OFFSET_X_BUTTONS_LANGUAGE,
			y = startY + ((index - 1) * BUTTON_LANGUAGE_SPACING) + OFFSET_Y_BUTTONS_LANGUAGE,
			width = 410,
			height = 128,
			style = "radio",
			sheet = radioButtonSheet,
			onRelease = chooseLanguage,
			frameOff = 1,
			frameOn = 2
		})
		languageSwitch.language = DATA_LANGUAGE_BUTTONS[index].language
		
		languageButtons[DATA_LANGUAGE_BUTTONS[index].language] = languageSwitch
		buttonsLayer:insert(languageSwitch)
	end
	
	buttonList.sound.onRelease = toggleSound
	buttonSound = widget.newButton(buttonList.sound)
	buttonSound.x = display.contentCenterX + OFFSET_BUTTON_SOUND.x
	buttonSound.y = display.contentCenterY + OFFSET_BUTTON_SOUND.y
	buttonsLayer:insert(buttonSound)
	
	buttonList.music.onRelease = toggleMusic
	buttonMusic = widget.newButton(buttonList.music)
	buttonMusic.x = display.contentCenterX + OFFSET_BUTTON_MUSIC.x
	buttonMusic.y = display.contentCenterY + OFFSET_BUTTON_MUSIC.y
	buttonsLayer:insert(buttonMusic)
	
	buttonList.ok.onRelease = closeWindow
	buttonOK = widget.newButton(buttonList.ok)
	buttonOK.x = display.contentCenterX + OFFSET_BUTTON_OK.x
	buttonOK.y = display.contentCenterY + OFFSET_BUTTON_OK.y
	buttonsLayer:insert(buttonOK)
end

function game:show( event )	
	local phase = event.phase
	
	if phase == "will" then
		initialize(event)
	end
end
----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "show", game )

return game
