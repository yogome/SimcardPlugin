------------------------------------------------ Test Menu
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")  
local localization = require( folder.."localization" )
local offlinequeue = require( folder.."offlinequeue")
local performance = require( folder.."performance" )
local extrafile = require( folder.."extrafile")
local internet = require( folder.."internet" )
local database = require( folder.."database" )
local director = require( folder.."director" )
local logger = require( folder.."logger" )
local colors = require( folder.."colors")
local sound = require( folder.."sound" )
local music = require( folder.."music" )

local settings = require( "settings" )
local widget = require( "widget" )
local json = require( "json" )

local scene = director.newScene("testMenu")
----------------------------------------------- Variables
local fpsCounter
local backButton
local buttonList
local menuView
local addedButtons
local languages, currentLanguageIndex
----------------------------------------------- Constants
local KEY_DATABASE_POSITION = "testMenuSavedData" 

local BUTTON_SHOW_WIDTH = 100
local BUTTON_SHOW_HEIGHT = 35
local BUTTON_SHOW_ALPHA = 0.15
local BUTTON_SHOW_SIZE_TEXT = 25
local BUTTON_WIDTH = 400 
local BUTTON_HEIGHT = 90
local BUTTON_MARGIN = 5
local SIZE_TEXT = 45
local SIZE_FONT_MIN = 16
local COLOR_DEFAULT = {0.3,0.3,0.8}
----------------------------------------------- Functions
local function clearQueue()
	offlinequeue.clear()
end

local function toggleFPS()
	if fpsCounter.alpha <= 0 then fpsCounter.alpha = 0.7 else fpsCounter.alpha = 0 end
end

local function testInternet(event)
	event.target.text.text = "Internet:"..tostring(internet.isConnected())
end

local function toggleSound(event)
	sound.setEnabled(not sound.isEnabled())
	event.target.text.text = "Sound:"..tostring(sound.isEnabled())
end

local function toggleMusic(event)
	music.setEnabled(not music.isEnabled())
	event.target.text.text = "Music:"..tostring(music.isEnabled())
end

local function showGitVersion()
	extrafile.showGitVersion()
end

local function toggleLanguage(event)
	currentLanguageIndex = currentLanguageIndex + 1
	if currentLanguageIndex > #languages then currentLanguageIndex = 1 end
	if languages[currentLanguageIndex] then
		localization.setLanguage(languages[currentLanguageIndex])
		event.target.text.text = "Language:"..localization.getLanguage()
	end
end

local function createBackButton()
	local backButton = display.newGroup()
	backButton.anchorChildren = true
	backButton.alpha = BUTTON_SHOW_ALPHA
	
	local buttonBG = display.newRect(0,0,BUTTON_SHOW_WIDTH, BUTTON_SHOW_HEIGHT)
	buttonBG:setFillColor(0.5)
	backButton:insert(buttonBG)
	
	local buttonText = display.newText("BACK", 0, 0, native.systemFont, BUTTON_SHOW_SIZE_TEXT)
	backButton:insert(buttonText)
		
	buttonBG:addEventListener("tap", function()
		director.gotoScene( "testMenu", { effect = "fade", time = 400} )
		return true
	end)
	
	return backButton
end

local function createMenuView()
	local viewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		scrollWidth = 100,
		scrollHeight = 100,
		hideBackground = true,
	}
	
	local targetX, targetY = 0, 0
	local data = database.config(KEY_DATABASE_POSITION)
	if data then
		local luaData = json.decode(data)
		if luaData and luaData.lastScrollX and luaData.lastScrollY then
			targetX, targetY = luaData.lastScrollX, luaData.lastScrollY
		end
	end
	
	local menuView = widget.newScrollView(viewOptions)
	menuView:scrollToPosition({x = -800, y = -800, time = 0, onComplete = function()
		menuView:scrollToPosition({x = targetX, y = targetY, time = 600})
	end})
	return menuView
end

local function initialize()
	if settings and settings.testActions and "string" == type(settings.testActions) and not addedButtons then
		local testActions = require(settings.testActions)
		for index = 1, #testActions do
			scene.addButton(unpack(testActions[index]))
		end
		addedButtons = true
	end
end

local function savePosition()
	local lastScrollX, lastScrollY = menuView:getContentPosition()
	local data = json.encode({lastScrollX = lastScrollX, lastScrollY = lastScrollY})
	database.config(KEY_DATABASE_POSITION, data)
end
----------------------------------------------- Class functions
function scene.addButton(textString, listener, rectColor, column, strokeColor)
	if textString and listener then
		rectColor = rectColor or {0.1,0.1,0.1}
		column = column or 1
		strokeColor = strokeColor or colors.black
		
		local button = display.newGroup()
		button.listener = listener
		button.defaultColor = rectColor
		menuView:insert(button)
		
		local background = display.newRect(0,0,BUTTON_WIDTH,BUTTON_HEIGHT)
		background.strokeWidth = BUTTON_MARGIN
		background.stroke = strokeColor
		colors.addColorTransition(background)
		button:insert(background)
		background:setFillColor(unpack(rectColor))
		
		local textOptions = {
			x = 0,
			y = 0,
			fontSize = SIZE_TEXT,
			font = native.systemFont,
			align = "center",
			text = textString,
		}
		
		local text = nil
		local currentSize = SIZE_TEXT
		local textWasAdjusted = false
		repeat
			textOptions.fontSize = currentSize
			display.remove(text)
			text = display.newText(textOptions)
			button:insert(text)
			if text.width < BUTTON_WIDTH then
				if textWasAdjusted then
					textOptions.width = text.width
				end
				display.remove(text)
				text = display.newText(textOptions)
				button:insert(text)
			else
				textWasAdjusted = true
				currentSize = currentSize - 2
			end
		until currentSize <= SIZE_FONT_MIN or text.width < BUTTON_WIDTH
		
		button.text = text
		button.background = background
		
		button:addEventListener("tap", function()
			savePosition()
			background:setFillColor(1)
			transition.cancel(background)
			transition.to(background, {time = 200, r = rectColor[1], g = rectColor[2], b = rectColor[3], a = rectColor[4] or 1})
			button.listener({target = button})
			return true
		end)
		buttonList[column] = buttonList[column] or {}
		local row = #buttonList[column]
		button.x = display.screenOriginX + (BUTTON_WIDTH + BUTTON_MARGIN) * 0.5 + ((BUTTON_WIDTH + BUTTON_MARGIN) * (column - 1))
		button.y = display.screenOriginY + (BUTTON_HEIGHT + BUTTON_MARGIN) * 0.5 + ((BUTTON_HEIGHT + BUTTON_MARGIN) * row)
		
		buttonList[column][#buttonList[column] + 1] = button
		
		return button
	end
end

function scene:create(event)
	logger.log("[Test menu] initializing")
	buttonList = {}

	backButton = createBackButton()
	backButton.anchorX = 0
	backButton.anchorY = 0
	backButton.x = display.screenOriginX
	backButton.y = display.screenOriginY
	display.getCurrentStage():insert(backButton)
	backButton.isVisible = false
	
	scene.backButton = backButton
	addedButtons = false
	
	menuView = createMenuView()
	self.view:insert(menuView)
	
	fpsCounter = performance.getGroup()
	fpsCounter.x = display.screenOriginX + display.viewableContentWidth - 130
	fpsCounter.y = display.screenOriginY + display.viewableContentHeight - 40
	fpsCounter.alpha = 0
	display.getCurrentStage():insert(fpsCounter)
	
	languages, currentLanguageIndex = localization.getAvailableLanguages()
	
	self.addButton("Toggle FPS", toggleFPS, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Show version", showGitVersion, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Clear queue", clearQueue, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Delete DB", database.delete, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Internet:"..tostring(internet.isConnected()), testInternet, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Sound:"..tostring(sound.isEnabled()), toggleSound, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Music:"..tostring(music.isEnabled()), toggleMusic, COLOR_DEFAULT, 1, colors.white)
	self.addButton("Language:"..localization.getLanguage(), toggleLanguage, COLOR_DEFAULT, 1, colors.white)
	
	initialize()
end

function scene:destroy()
	addedButtons = false
end

function scene:show( event )
	if "will" == event.phase then
		display.setDefault("background",0,0,0)
	elseif "did" == event.phase then
		backButton.isVisible = true
	end
end

function scene:hide( event )
	if "did" == event.phase then

	end
end

scene:addEventListener( "create" )
scene:addEventListener( "destroy" )
scene:addEventListener( "hide" )
scene:addEventListener( "show" )

director.loadScene( "testMenu" )

return scene
