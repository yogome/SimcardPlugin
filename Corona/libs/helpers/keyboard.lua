----------------------------------------------- Keyboard
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local colors = require( folder.."colors" ) 
local director = require( folder.."director" ) 
local widget = require( "widget")

local keyboard = {}
---------------------------------------------- Constants
local CHARACTERS_STRING_KEYS = {
	{"q","w","e","r","t","y","u","i","o","p",},
	{"a","s","d","f","g","h","j","k","l","@"},
	{"z","x","c","v","b","n","m","."},
}

local CHARACTERS_STRING_NUMBER_KEYS = {
	{"1","2","3","4","5","6","7","8","9","0",},
	{"-","/",":",";","(",")","$","&","@","#",},
	{"!",",","+","_","\\","=",".","%"},
}

local CHARACTERS_NUMBER_KEYS = {
	{"1","2","3"},
	{"4","5","6"},
	{"7","8","9"},
	{"0"},
}

local FRAMES_BACKSPACE_REPEAT = 10
local FRAMES_BACKSPACE_START = 20

local stringRowKeys =  10

local stringKeyWidthPart = 9
local stringKeyWidthMarginPart = 1

local stringTotalWidthParts = stringRowKeys * stringKeyWidthPart + (stringRowKeys + 1) * stringKeyWidthMarginPart
local stringPartWidth = display.viewableContentWidth / stringTotalWidthParts

local stringKeyWidth = stringPartWidth * stringKeyWidthPart
local stringMarginWidth = stringPartWidth * stringKeyWidthMarginPart

local rows = 4
local keyboardHeightRatio = 0.45
local totalHeight = display.viewableContentHeight * keyboardHeightRatio

local keyHeightPart = 5
local keyHeightMarginPart = 1

local totalHeightParts = rows * keyHeightPart + (rows + 1) * keyHeightMarginPart
local partHeight = totalHeight / totalHeightParts

local keyHeight = partHeight * keyHeightPart
local marginHeight = partHeight * keyHeightMarginPart

local halfKeyHeight = keyHeight * 0.5
local stringHalfKeyWidth = stringKeyWidth * 0.5

local numberKeyboardWidthRatio = 0.3
local numberRowKeys = 4

local numberKeyWidthPart = 9
local numberKeyWidthMarginPart = 1

local numberTotalWidthParts = numberRowKeys * numberKeyWidthPart + (numberRowKeys + 1) * numberKeyWidthMarginPart
local numberKeyboardTotalWidth = display.viewableContentWidth * numberKeyboardWidthRatio
local numberPartWidth = numberKeyboardTotalWidth / numberTotalWidthParts

local numberKeyWidth = numberPartWidth * numberKeyWidthPart
local numberMarginWidth = numberPartWidth * numberKeyWidthMarginPart

local numberHalfKeyWidth = numberKeyWidth * 0.5

local booleanKeyboardWidthRatio = 0.25
local booleanKeyboardTotalWidth = display.viewableContentWidth * booleanKeyboardWidthRatio
local booleanKeyboardTotalHeight = totalHeight * 0.75
local booleanKeyWidth = booleanKeyboardTotalWidth - numberMarginWidth * 2
local booleanHalfKeyWidth = booleanKeyWidth * 0.5

local keySheetOptions = {
	frames = {
		{ x=0, y=0, width=8, height=8 },
		{ x=8, y=0, width=16, height=8 },
		{ x=24, y=0, width=8, height=8 },
		{ x=0, y=8, width=8, height=48 },
		{ x=8, y=8, width=16, height=48 },
		{ x=24, y=8, width=8, height=48 },
		{ x=0, y=56, width=8, height=8 },
		{ x=8, y=56, width=16, height=8 },
		{ x=24, y=56, width=8, height=8 },
		{ x=240, y=0, width=8, height=8 },
		{ x=261, y=0, width=16, height=8 },
		{ x=459, y=0, width=8, height=8 },
		{ x=240, y=8, width=8, height=48 },
		{ x=261, y=8, width=16, height=48 },
		{ x=459, y=8, width=8, height=48 },
		{ x=240, y=56, width=8, height=8 },
		{ x=261, y=56, width=16, height=8 },
		{ x=459, y=56, width=8, height=8 }
	},
	sheetContentWidth = 64,
	sheetContentHeight = 64,
}

local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/"
local paddingImagePath = PATH_IMAGES.."padding.png"
local backspaceIconPath = PATH_IMAGES.."backspace.png"
local keySheet = graphics.newImageSheet( PATH_IMAGES.."key.png", keySheetOptions )

local defaultButtonOptions = {
	width = stringKeyWidth,
	height = keyHeight,
	sheet = keySheet,
	topLeftFrame = 1,
	topMiddleFrame = 2,
	topRightFrame = 3,
	middleLeftFrame = 4,
	middleFrame = 5,
	middleRightFrame = 6,
	bottomLeftFrame = 7,
	bottomMiddleFrame = 8,
	bottomRightFrame = 9,
	topLeftOverFrame = 10,
	topMiddleOverFrame = 11,
	topRightOverFrame = 12,
	middleLeftOverFrame = 13,
	middleOverFrame = 14,
	middleRightOverFrame = 15,
	bottomLeftOverFrame = 16,
	bottomMiddleOverFrame = 17,
	bottomRightOverFrame = 18,
	
	label = "",
	fontSize = 45,
	labelColor = { default={ 0, 0, 0 }, over={ 1, 1, 1} }
}
---------------------------------------------- Variables
local created, isShowing
local stringKeyGroup, stringKeys
local numberKeyGroup, numberKeys
local booleanKeyGroup
local stringBuffer, numberBuffer, numberMinusBuffer, booleanBuffer
local buttonsEnabled, shiftToggleState, numbersToggleState
local onChangeEvent, onCompleteEvent
local stageMoved
local shiftKey, numbersKey
local stringBackspaceIsPressed, backspaceFrames
---------------------------------------------- Functions
local function soundFunction()
	if keyboard and created then
		if keyboard.soundFunction and "function" == type(keyboard.soundFunction) and buttonsEnabled then
			keyboard.soundFunction()
		end
	end
end 

local function newButton(options)
	local button = widget.newButton(options)
	button._view._hasAlphaFade = false
	
	function button:setFillColor( ... )		
		for i = self._view.numChildren, 1, -1 do
			local child = self._view[i]
			if child.setFillColor and "function" == type( child.setFillColor ) and not child._isLabel then
				child:setFillColor( ... )
			end
		end
	end
	
	return button
end

local function updateOnChangeEvent(value)
	if onChangeEvent ~= nil then
		onChangeEvent(value)
	end
end

local function updateOnCompleteEvent(value)
	if onCompleteEvent ~= nil then
		onCompleteEvent(value)
	end
end

local function stringDoneReleased()
	updateOnCompleteEvent(stringBuffer)
	keyboard:hide()
end

local function setUpperCase(key, value)
	local letter = key.value
	if value == true then
		local uppercase = string.upper(letter)
		key:setLabel(uppercase)
		key.value = uppercase
	else
		local lowercase = string.lower(letter)
		key:setLabel(lowercase)
		key.value = lowercase
	end
end

local function shiftReleased()
	if buttonsEnabled then
		shiftToggleState = not shiftToggleState
		
		local color = shiftToggleState and colors.darkGray or colors.lightGray
		shiftKey:setFillColor(unpack(color))
		
		for row = #CHARACTERS_STRING_KEYS,1,-1 do
			for column = 1,#CHARACTERS_STRING_KEYS[row] do
				local key = stringKeys[row][column]
				setUpperCase(key, shiftToggleState)
			end
		end
	end
end

local function stringKeyReleased(event)
	if buttonsEnabled then
		local key = event.target
		stringBuffer = stringBuffer..key.value
		updateOnChangeEvent(stringBuffer)
		
		if shiftToggleState then
			shiftReleased()
		end
	end
end

local function stringRemoveLastLetter()
	if stringBuffer:len() > 0 then
		stringBuffer = string.sub(stringBuffer, 1, -2)
	end
	updateOnChangeEvent(stringBuffer)
end

local function stringBackspacePressed()
	if buttonsEnabled then
		soundFunction()
		stringBackspaceIsPressed = true
		backspaceFrames = FRAMES_BACKSPACE_START
		stringRemoveLastLetter()
	end
end

local function stringBackspaceReleased()
	if buttonsEnabled then
		stringBackspaceIsPressed = false
	end
end

local function setSymbol(key, row, column)
	if numbersToggleState == true then
		local character = CHARACTERS_STRING_NUMBER_KEYS[row][column]
		key:setLabel(character)
		key.value = character
	else
		local character = CHARACTERS_STRING_KEYS[row][column]
		key.value = character
		key:setLabel(character)
		if shiftToggleState then
			setUpperCase(key, true)
		end
	end
end

local function numbersReleased()
	if buttonsEnabled then
		numbersToggleState = not numbersToggleState
		
		local color = numbersToggleState and colors.darkGray or colors.lightGray
		numbersKey:setFillColor(unpack(color))
		
		for row = #CHARACTERS_STRING_KEYS,1,-1 do
			for column = 1,#CHARACTERS_STRING_KEYS[row] do
				local key = stringKeys[row][column]
				setSymbol(key, row, column, numbersToggleState)
			end
		end
	end
end

local function numberKeyReleased(event)
	if buttonsEnabled then
		local key = event.target
		if numberBuffer:sub(1, 1) == "0" and key.value ~= "0" then
			if numberBuffer:len() > 1 and numberBuffer:sub(1, 2) == "0." then
				numberBuffer = numberBuffer..key.value
			else
				numberBuffer = key.value
			end
		else
			if numberBuffer:sub(1, 1) ~= "0" or numberBuffer:len() > 1 and numberBuffer:sub(2, 2) == "." then
				numberBuffer = numberBuffer..key.value
			end
		end
		updateOnChangeEvent(numberMinusBuffer..numberBuffer)
	end
end

local function numberBackspaceReleased()
	if buttonsEnabled then
		if numberBuffer:len() > 0 then
			numberBuffer = string.sub(numberBuffer, 1, -2)
			if numberBuffer:len() <= 0 then
				numberBuffer = "0"
			end
		end
		updateOnChangeEvent(numberMinusBuffer..numberBuffer)
	end
end

local function numberMinusReleased()
	if buttonsEnabled then
		if numberMinusBuffer == "" then
			numberMinusBuffer = "-"
		else
			numberMinusBuffer = ""
		end
		updateOnChangeEvent(numberMinusBuffer..numberBuffer)
	end
end

local function numberDotReleased()
	if buttonsEnabled then
		local found = string.find(numberBuffer,"%.")
		if not found then
			numberBuffer = numberBuffer.."."
		else
			numberBuffer = numberBuffer:sub(1, found - 1)..numberBuffer:sub(found + 1, -1).."."
			if numberBuffer:sub(1, 1) == "0" and numberBuffer:sub(2, 2) ~= "." then
				numberBuffer = numberBuffer:sub(2,-1)
			end
		end
		updateOnChangeEvent(numberMinusBuffer..numberBuffer)
	end
end

local function numberDoneReleased()
	updateOnCompleteEvent(numberMinusBuffer..numberBuffer)
	keyboard:hide()
end

local function booleanKeyReleased(event)
	if buttonsEnabled then
		local key = event.target
		booleanBuffer = key.value
		updateOnChangeEvent(tostring(booleanBuffer))
	end
end

local function booleanDoneReleased()
	updateOnCompleteEvent(booleanBuffer)
	keyboard:hide()
end

local function getKeyY(row)
	return display.screenOriginY + display.viewableContentHeight - marginHeight - (marginHeight + keyHeight) * (rows - row) - halfKeyHeight
end

local function createLevel4Keys()
	
	defaultButtonOptions.sheet = keySheet
	local idealSpaceParts = math.floor(stringTotalWidthParts * 0.6)
	local spaceParts = idealSpaceParts % 2 == 0 and idealSpaceParts or idealSpaceParts - 1
	local spaceWidth = spaceParts * stringPartWidth
	
	defaultButtonOptions.label = "Space"
	defaultButtonOptions.width = spaceWidth
	defaultButtonOptions.onRelease = stringKeyReleased
	local spaceBar = newButton(defaultButtonOptions)
	spaceBar.value = " "
	spaceBar.x = display.contentCenterX
	spaceBar.y = getKeyY(4)
	stringKeyGroup:insert(spaceBar)
	
	local level4KeyParts = (stringTotalWidthParts - spaceParts - (stringKeyWidthMarginPart * 4)) * 0.5
	local level4KeyWidth = level4KeyParts * stringPartWidth
	
	defaultButtonOptions.label = "Numbers"
	defaultButtonOptions.width = level4KeyWidth
	defaultButtonOptions.onRelease = numbersReleased
	numbersKey = newButton(defaultButtonOptions)
	numbersKey.x = display.screenOriginX + stringMarginWidth + level4KeyWidth * 0.5
	numbersKey.y = getKeyY(4)
	
	stringKeyGroup:insert(numbersKey)
	
	defaultButtonOptions.label = "Done"
	defaultButtonOptions.width = level4KeyWidth
	defaultButtonOptions.onRelease = stringDoneReleased
	local done = newButton(defaultButtonOptions)
	done.x = display.screenOriginX + display.viewableContentWidth - stringMarginWidth - level4KeyWidth * 0.5
	done.y = getKeyY(4)
	stringKeyGroup:insert(done)

	local color = colors.lightGray
	spaceBar:setFillColor(unpack(color))
	numbersKey:setFillColor(unpack(color))
	done:setFillColor(unpack(color))
	
end

local function createLevel3Keys()
	defaultButtonOptions.sheet = keySheet
	
	local level3Keys = #CHARACTERS_STRING_KEYS[3]
	local level3ButtonParts = (stringTotalWidthParts - (level3Keys * stringKeyWidthPart) - (level3Keys + 3) * stringKeyWidthMarginPart) * 0.5
	local level3KeyWidth = level3ButtonParts * stringPartWidth
	
	defaultButtonOptions.label = "Shift"
	defaultButtonOptions.width = level3KeyWidth
	defaultButtonOptions.onRelease = shiftReleased
	shiftKey = newButton(defaultButtonOptions)
	shiftKey.x = display.screenOriginX + stringMarginWidth + level3KeyWidth * 0.5
	shiftKey.y = getKeyY(3)
	stringKeyGroup:insert(shiftKey)
	
	defaultButtonOptions.label = ""
	defaultButtonOptions.width = level3KeyWidth
	defaultButtonOptions.onPress = stringBackspacePressed
	defaultButtonOptions.onRelease = stringBackspaceReleased
	local backspace = newButton(defaultButtonOptions)
	local backspaceIcon = display.newImageRect(backspaceIconPath, keyHeight, keyHeight)
	backspaceIcon.x = level3KeyWidth * 0.5
	backspaceIcon.y = halfKeyHeight
	backspaceIcon:setFillColor(0)
	backspace:insert(backspaceIcon)
	backspace.x = display.screenOriginX + display.viewableContentWidth - stringMarginWidth - level3KeyWidth * 0.5
	backspace.y = getKeyY(3)
	stringKeyGroup:insert(backspace)
	
	defaultButtonOptions.onPress = soundFunction
	
	local color = colors.lightGray
	shiftKey:setFillColor(unpack(color))
	backspace:setFillColor(unpack(color))
end
	
local function createStringKeyboard(keyboard)
	local group = keyboard.view
	stringKeyGroup = display.newGroup()
	group:insert(stringKeyGroup)
	
	local background = display.newImageRect(paddingImagePath, display.viewableContentWidth + 2, totalHeight)
	background.x = display.contentCenterX
	background.y = display.screenOriginY + display.viewableContentHeight - totalHeight * 0.5
	stringKeyGroup:insert(background)
		
	stringKeys = {}
	
	for row = 1, #CHARACTERS_STRING_KEYS do
		local columns = #CHARACTERS_STRING_KEYS[row]
		stringKeys[row] = {}
		
		local startingX = display.contentCenterX - (columns * stringKeyWidth + (columns + 1) * stringMarginWidth) * 0.5
		for column = 1, columns do
			local value = CHARACTERS_STRING_KEYS[row][column]
			
			defaultButtonOptions.width = stringKeyWidth
			defaultButtonOptions.label = value
			defaultButtonOptions.onRelease = stringKeyReleased
			defaultButtonOptions.sheet = keySheet
			local key = newButton(defaultButtonOptions)
			key.value = value
			key.x = startingX + (stringMarginWidth + stringKeyWidth) * column - stringHalfKeyWidth
			key.y = getKeyY(row)
			stringKeyGroup:insert(key)
			
			stringKeys[row][column] = key
		end
	end
	
	createLevel4Keys()
	createLevel3Keys()
end

local function createNumberKeyboard(keyboard)
	local group = keyboard.view
	numberKeyGroup = display.newGroup()
	group:insert(numberKeyGroup)
	
	local background = display.newImageRect(paddingImagePath, numberKeyboardTotalWidth + 2, totalHeight)
	background.x = display.screenOriginX + display.viewableContentWidth - numberKeyboardTotalWidth * 0.5
	background.y = display.screenOriginY + display.viewableContentHeight - totalHeight * 0.5
	numberKeyGroup:insert(background)
	
	numberKeys = {}
	
	for row = 1, #CHARACTERS_NUMBER_KEYS do
		local columns = #CHARACTERS_NUMBER_KEYS[row]
		numberKeys[row] = {}
		for column = 1, columns do
			local value = CHARACTERS_NUMBER_KEYS[row][column]
			
			defaultButtonOptions.width = numberKeyWidth
			defaultButtonOptions.label = value
			defaultButtonOptions.onRelease = numberKeyReleased
			defaultButtonOptions.sheet = keySheet
			local key = newButton(defaultButtonOptions)
			key.value = value
			key.x = display.screenOriginX + display.viewableContentWidth - numberKeyboardTotalWidth + (numberKeyWidth + numberMarginWidth) * column - numberHalfKeyWidth
			key.y = getKeyY(row)
			numberKeyGroup:insert(key)
			
			numberKeys[row][column] = key
		end
	end
	
	local lastRowX = display.screenOriginX + display.viewableContentWidth - (numberKeyWidth + numberMarginWidth) + numberHalfKeyWidth
	
	defaultButtonOptions.width = numberKeyWidth
	defaultButtonOptions.sheet = keySheet
	
	defaultButtonOptions.label = "-"
	defaultButtonOptions.onRelease = numberMinusReleased
	local minus = newButton(defaultButtonOptions)
	minus.x = lastRowX
	minus.y = getKeyY(1)
	numberKeyGroup:insert(minus)
	
	defaultButtonOptions.label = "."
	defaultButtonOptions.onRelease = numberDotReleased
	local dot = newButton(defaultButtonOptions)
	dot.x = lastRowX
	dot.y = getKeyY(2)
	numberKeyGroup:insert(dot)
	
	defaultButtonOptions.label = ""
	defaultButtonOptions.onRelease = numberBackspaceReleased
	local backspace = newButton(defaultButtonOptions)
	backspace.x = lastRowX
	backspace.y = getKeyY(3)
	local backspaceIcon = display.newImageRect(backspaceIconPath, keyHeight, keyHeight)
	backspaceIcon.x = numberHalfKeyWidth
	backspaceIcon.y = halfKeyHeight
	backspaceIcon:setFillColor(0)
	backspace:insert(backspaceIcon)
	numberKeyGroup:insert(backspace)
	
	local doneWidth = numberKeyWidth * 3 + numberMarginWidth * 2
	
	defaultButtonOptions.label = "Done"
	defaultButtonOptions.width = doneWidth
	defaultButtonOptions.onRelease = numberDoneReleased
	local done = newButton(defaultButtonOptions)
	done.x = display.screenOriginX + display.viewableContentWidth - (doneWidth + numberMarginWidth) + doneWidth * 0.5
	done.y = getKeyY(4)
	numberKeyGroup:insert(done)
	
	local color = colors.lightGray
	minus:setFillColor(unpack(color))
	dot:setFillColor(unpack(color))
	backspace:setFillColor(unpack(color))
	done:setFillColor(unpack(color))
	
end

local function createBooleanKeyboard(keyboard)
	local group = keyboard.view
	booleanKeyGroup = display.newGroup()
	group:insert(booleanKeyGroup)
	
	local background = display.newImageRect(paddingImagePath, booleanKeyboardTotalWidth + 2, booleanKeyboardTotalHeight)
	background.x = display.screenOriginX + display.viewableContentWidth - booleanKeyboardTotalWidth * 0.5
	background.y = display.screenOriginY + display.viewableContentHeight - booleanKeyboardTotalHeight * 0.5
	booleanKeyGroup:insert(background)
	
	local booleanText = {"True","False"}
	local booleanValues = {true,false}
	
	local positionX = display.screenOriginX + display.viewableContentWidth - (numberMarginWidth + booleanKeyWidth) + booleanHalfKeyWidth
	
	for index = 1,2 do
		defaultButtonOptions.width = booleanKeyWidth
		defaultButtonOptions.label = booleanText[index]
		defaultButtonOptions.onRelease = booleanKeyReleased
		defaultButtonOptions.sheet = keySheet
		local boolean = newButton(defaultButtonOptions)
		boolean.value = booleanValues[index]
		boolean.x = positionX
		boolean.y = getKeyY(4 - index)
		booleanKeyGroup:insert(boolean)
	end
	
	defaultButtonOptions.width = booleanKeyWidth
	defaultButtonOptions.label = "Done"
	defaultButtonOptions.onRelease = booleanDoneReleased
	defaultButtonOptions.sheet = keySheet
	local done = newButton(defaultButtonOptions)
	done.x = positionX
	done.y = getKeyY(4)
	booleanKeyGroup:insert(done)
	
	local color = colors.lightGray
	done:setFillColor(unpack(color))
end

local function createTouchCatcher(keyboard)
	local group = keyboard.view
	
	local touchCatcher = display.newRect(display.contentCenterX, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2 + totalHeight)
	touchCatcher.isHitTestable = true
	touchCatcher.isVisible = false
	touchCatcher.anchorY = 0
	touchCatcher.y = display.screenOriginY - totalHeight
	
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	
	group:insert(touchCatcher)
end

local function onHide()
	keyboard.view.isVisible = false
	isShowing = false
end

local function enterFrame(event)
	if stringBackspaceIsPressed then
		if backspaceFrames > 0 then
			backspaceFrames = backspaceFrames - 1
		else
			backspaceFrames = FRAMES_BACKSPACE_REPEAT
			stringRemoveLastLetter()
		end
	end
end

function keyboard:hide()
	onChangeEvent = nil
	onCompleteEvent = nil
	if buttonsEnabled then
		buttonsEnabled = false
		
		Runtime:removeEventListener("enterFrame", enterFrame)
		if not stageMoved then
			transition.to(self.view,{time = 350, y = 200, alpha = 0, transition = easing.inQuad, onComplete = function()
				onHide()
			end})
		else
			transition.to(director.stage,{time = 350, y = 0, transition = easing.inQuad, onComplete = function()
				onHide()
			end})
		end
	end
end

local function reset()
	shiftToggleState = false
	numbersToggleState = false
	
	local color = colors.lightGray
	shiftKey:setFillColor(unpack(color))
	numbersKey:setFillColor(unpack(color))
	
	for row = #CHARACTERS_STRING_KEYS,1,-1 do
		for column = 1,#CHARACTERS_STRING_KEYS[row] do
			local key = stringKeys[row][column]
			setSymbol(key, row, column, numbersToggleState)
		end
	end
end

function keyboard.setNumberBuffer(newBuffer)
	numberBuffer = newBuffer
end

function keyboard.setStringBuffer(newBuffer)
	stringBuffer = newBuffer
end

function keyboard:show(params)
	if not isShowing then
		isShowing = true
		
		params = params or {}
		local value = params.value
		local onChange = params.onChange
		local onComplete = params.onComplete
		local targetY = params.targetY

		if onChange ~= nil and type(onChange) ~= "function" then
			error("onChange must be a function or nil.", 3)
		end
		
		if onComplete ~= nil and type(onComplete) ~= "function" then
			error("onComplete must be a function or nil.", 3)
		end

		onChangeEvent = onChange
		onCompleteEvent = onComplete

		stageMoved = false
		stringKeyGroup.isVisible = false
		numberKeyGroup.isVisible = false
		booleanKeyGroup.isVisible = false

		reset()
		if not params.mode then
			if value == nil then
				logger.log("Automatically setting keyboard to string.")
				self.mode = "string"
			else
				self.mode = type(value)
			end
		else
			self.mode = params.mode
		end

		if self.mode == "string" then
			stringKeyGroup.isVisible = true
			stringBuffer = value or ""
		elseif self.mode == "number" then
			numberKeyGroup.isVisible = true
			value = value or "0"
			numberBuffer = ""..value
			numberMinusBuffer = ""
			if numberBuffer:sub(1, 1) == "-" then
				numberMinusBuffer = "-"
				numberBuffer = numberBuffer:sub(2,-1)
			end
		elseif self.mode == "boolean" then
			booleanKeyGroup.isVisible = true
			booleanBuffer = value or false
		else
			error("Value must be either string, number or boolean.", 3)
		end

		self.view.alpha = 0
		self.view.isVisible = true
		self.view:toFront()
		
		Runtime:addEventListener("enterFrame", enterFrame)
		
		if targetY and targetY > display.screenOriginY + display.viewableContentHeight - totalHeight then
			stageMoved = true
			self.view.y = display.screenOriginY + totalHeight
			self.view.alpha = 1
			transition.to(director.stage,{time = 500, y = -totalHeight, alpha = 1, transition = easing.outQuad, onComplete = function()
				buttonsEnabled = true
			end})
		else
			self.view.y = display.screenOriginY + 200
			transition.to(self.view,{time = 500, y = 0, alpha = 1, transition = easing.outQuad, onComplete = function()
				buttonsEnabled = true
			end})
		end
	else
		logger.log("keyboard is already showing.")
	end
end

function keyboard:create()
	if not created then
		logger.log("Creating keyboard.")
		
		created = true
		stringBuffer = ""
		numberBuffer = ""
		numberMinusBuffer = ""
		booleanBuffer = false

		shiftToggleState = false
		numbersToggleState = false
		
		self.view = display.newGroup()
		display.getCurrentStage():insert(self.view)
		self.view.isVisible = false
		self.view.alpha = 0
		
		defaultButtonOptions.onPress = soundFunction
		function self:setSoundFunction(soundFunction)
			self.soundFunction = soundFunction
		end
		
		createTouchCatcher(self)
		createStringKeyboard(self)
		createNumberKeyboard(self)
		createBooleanKeyboard(self)
	end
end

keyboard:create()

return keyboard
