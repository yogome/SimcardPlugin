-------------------------------------------- Textbox
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local colors = require( folder.."colors" )
local keycodes = require( folder.."keycodes" )

local textbox = {}
------------------------------------------- Variables
local initialized
local dummyField
local currentField
------------------------------------------- Constants
local cursorOffsetX = 5
local YPOSITION_HIDDEN_DUMMYFIELD = display.screenOriginY - 1000
local PLATFORMNAME = system.getInfo("platformName")
local IS_MAC = PLATFORMNAME == "Mac OS X"
local KEYCODE_ENTER = IS_MAC and 36 or 13
local KEYCODE_BACKSPACE = IS_MAC and 51 or 8

local CHARACTERS_SHIFT = {
	mac = {
		[18] = "!",--1
		[19] = "@",--2
		[20] = "#",--3
		[21] = "$",--4
		[23] = "%",--5
		[22] = "^",--6
		[26] = "&",--7
		[28] = "*",--8
		[25] = "(",--9
		[29] = ")",--0
		[27] = "_",---
		[24] = "+",--=
	},
	pc = {
		[49] = "!",--1
		[50] = "@",--2
		[51] = "#",--3
		[52] = "$",--4
		[53] = "%",--5
		[54] = "^",--6
		[55] = "&",--7
		[56] = "*",--8
		[57] = "(",--9
		[58] = ")",--0
		[48] = "_",---
		[189] = "+",--=
	}
}

local ACCEPTED_CHARACTERS = "[A-Za-z0-9%.%!%@%#%$%%%^%&%*%(%)%_%+%-%=%s]"
------------------------------------------- Functions
local function cancelCursorAnimations(cursor)
	if cursor.timer then
		timer.cancel(cursor.timer)
	end
	if cursor.transition1 then
		transition.cancel(cursor.transition1)
	end
	if cursor.transition2 then
		transition.cancel(cursor.transition2)
	end
	if cursor.transition3 then
		transition.cancel(cursor.transition3)
	end
end

local function onChange(field)
	if field and field.text and field.text.text and field.maxChars then
		if string.len(field.text.text) <= field.maxChars or field.maxChars <= 0 then
			if field.usesContainer and field.text.width > field.textContainer.width then
				field.text.x = (field.textContainer.width - field.text.width) * 0.5 - 15
			else
				field.text.x = field.text.offset.x -- TODO should measure textOffset
			end

			field.cursor.x = field.text.x + field.text.width/2 + 5

			if field.onChange then
				field.onChange({target = field})
			end
		else
			local substring = field.text.text:sub(1, field.maxChars)
			field.text.text = substring
		end
	end
end

local function onComplete(field)
	native.setKeyboardFocus(nil)
	field.text:setFillColor(unpack(field.text.defaultColor))
	cancelCursorAnimations(field.cursor)
	field.cursor.transition1 = transition.to(field.cursor, {time = 120, alpha = 0, transition = easing.inOutQuad})
	
	if string.len(field.text.text) <= 0 then
		field.placeholderText.isVisible = true
	end
	currentField = nil
	if field.onComplete then
		field.onComplete({target = field})
	end
	field.hasFocus = false
end

local function onKeyEvent( event )
	local phase = event.phase
	
	if currentField then
		if phase == "down" then
			if event.nativeKeyCode == KEYCODE_ENTER or event.descriptor == "enter" then
				
			elseif event.nativeKeyCode == KEYCODE_BACKSPACE or event.descriptor == "deleteBack" then
				currentField.value = string.sub(currentField.value, 1, -2)
				local passwordValue = string.gsub(currentField.value, ".", "*")
				currentField.text.text = currentField.isPassword and passwordValue or currentField.value
				onChange(currentField)
			else
				local character = string.len(event.keyName) <= 1 and event.keyName or ""
				character = character:match(currentField.acceptedCharacters) or ""

				if event.isShiftDown then
					character = string.upper(character)
					if CHARACTERS_SHIFT[(IS_MAC and "mac" or "pc")][event.nativeKeyCode] then
						character = CHARACTERS_SHIFT[(IS_MAC and "mac" or "pc")][event.nativeKeyCode]
					end
				end
				currentField.value = currentField.value..character
				local passwordValue = string.gsub(currentField.value, ".", "*")
				currentField.text.text = currentField.isPassword and passwordValue or currentField.value
				onChange(currentField)
			end
			return true
		elseif phase == "up" then
			if event.nativeKeyCode == KEYCODE_ENTER or event.descriptor == "enter" then
				onComplete(currentField)
			end
		end
	end
	return false
end

local function unselectCurrentField()
	if currentField and currentField.text and currentField.text.text then
		if string.len(currentField.text.text) <= 0 then
			currentField.placeholderText.isVisible = true
		end

		currentField.text:setFillColor(unpack(currentField.text.defaultColor))
		cancelCursorAnimations(currentField.cursor)
		currentField.cursor.transition1 = transition.to(currentField.cursor, {time = 120, alpha = 0, transition = easing.inOutQuad})
	end
	
	currentField = nil
	native.setKeyboardFocus(nil)
end

local function initialize()
	if not initialized then
		initialized = true
		
		if PLATFORMNAME == "iPhone OS" or PLATFORMNAME == "Android" then
			dummyField = native.newTextField( display.contentCenterX, YPOSITION_HIDDEN_DUMMYFIELD, 200, 40 )
			dummyField.isVisible = true -- Needs to be visible on android to work
			dummyField.isSecure = PLATFORMNAME ~= "Android" -- isSecure always true on iOS
			dummyField:addEventListener( "userInput", function(event)
				if currentField then
					if event.phase == "editing" then
						event.numDeleted = event.numDeleted or 0
						local newCharacters = event.newCharacters or ""
						newCharacters = newCharacters:match(currentField.acceptedCharacters) or ""

						if event.numDeleted and event.numDeleted > 0 then
							currentField.value = string.sub(currentField.value, 1, -2)
						end
						
						currentField.value = currentField.value..newCharacters
						local passwordValue = string.gsub(currentField.value, ".", "*")
						currentField.text.text = currentField.isPassword and passwordValue or currentField.value
						dummyField.text = currentField.value
						onChange(currentField)
					elseif event.phase == "submitted" then
						onComplete(currentField) -- TODO Corona does not do anything to handle keyboard hiding
					end
				end
			end)
			local globalStage = display.getCurrentStage()
			globalStage:insert(dummyField)	
		else
			Runtime:addEventListener("key", onKeyEvent)
		end
		
		Runtime:addEventListener( "tap", function()
			if currentField and currentField.isValid then -- This is to enable tapping on other textboxes
				currentField.isValid = false
			else
				unselectCurrentField()
			end
		end)
	end
end

local function textboxTapped(event)
	local textbox = event.target
	if textbox.isEnabled then
		textbox.placeholderText.isVisible = false
		
		local text = textbox.text
		local cursor = textbox.cursor
		
		cancelCursorAnimations(cursor)
		
		local function blink(cursor)
			cursor.transition1 = transition.to(cursor, {time = 900, alpha = 1, transition = easing.inOutSine})
			cursor.transition2 = transition.to(cursor, {delay = 900, alpha = 0.0005, transition = easing.inOutSine})
		end
		
		blink(cursor)
		cursor.timer = timer.performWithDelay(1800, function()
			blink(cursor)
		end, -1)
		
		text:setFillColor(unpack(text.selectedColor))
		
		textbox.isValid = true -- This is for the runtime listener to not unselect this textbox
		if currentField ~= textbox then
			unselectCurrentField()
		end
		currentField = textbox
		if dummyField then
			dummyField.isSecure = textbox.isPassword and PLATFORMNAME == "Android" -- Needs to differentiate on Android
			dummyField.text = textbox.value
			native.setKeyboardFocus(dummyField)
			dummyField:setSelection(256,256)
			logger.log("[Textbox] setKeyboardFocus called on textbox")
		end
		
		textbox.hasFocus = true
		if textbox.onFocus then
			textbox.onFocus()
		end
	end
end

local function createTextbox(newTextbox, options)
	newTextbox:addEventListener("tap", textboxTapped)
	
	newTextbox.onFocus = options.onFocus
	newTextbox.onChange = options.onChange
	newTextbox.onComplete = options.onComplete
	newTextbox.maxChars = options.maxChars
	newTextbox.isPassword = options.isPassword
	newTextbox.value = ""
	newTextbox.acceptedCharacters = options.acceptedCharacters or ACCEPTED_CHARACTERS
	
	function newTextbox:setEnabled(isEnabled)
		self.isEnabled = isEnabled
	end
	
	function newTextbox:setText(text)
		self.text.text = text
		self.value = text
		
		if self.usesContainer and self.text.width > self.textContainer.width then
			self.text.x = (self.textContainer.width - self.text.width) * 0.5 - 15
		else
			self.text.x = self.text.offset.x -- TODO should measure textOffset
		end
		
		self.cursor.x = self.text.x + self.text.width * 0.5 + cursorOffsetX

		self.placeholderText.isVisible = string.len(text) <= 0
	end
	
	function newTextbox:getText()
		return self.text.text
	end
	
	newTextbox.isEnabled = true
	if dummyField then
		dummyField.inputType = options.inputType
	end
	
	local function createRectBackground()
		local background = display.newRect(0, 0, options.width, options.height)
		local backgroundColor = options.backgroundColor or colors.gray
		background:setFillColor(unpack(backgroundColor))
		newTextbox:insert(background)
	end
	
	if options.backgroundImage then
		if options.width and options.height then
			local background = display.newImageRect(options.backgroundImage, options.width, options.height)
			newTextbox:insert(background)
		else
			local background = display.newImage(options.backgroundImage, true)
			if options.backgroundScale then
				background.xScale = options.backgroundScale
				background.yScale = options.backgroundScale
				options.width = background.width * options.backgroundScale
				options.height = background.height * options.backgroundScale
			end
			options.width = background.contentWidth
			options.height = background.contentHeight
			newTextbox:insert(background)
		end
	else
		createRectBackground()
	end
	
	local textContainer = options.useContainer and display.newContainer(options.width - options.textPadding, options.height - options.textPadding) or display.newGroup()
	newTextbox:insert(textContainer)
	newTextbox.textContainer = textContainer
	newTextbox.usesContainer = options.useContainer
	
	local cursor = display.newRect(0,0, math.ceil(options.fontSize * 0.05), math.ceil(options.fontSize * 0.75))
	cursor:setFillColor(1)
	cursor.alpha = 0
	newTextbox.cursor = cursor
	textContainer:insert(cursor)
	
	local textOptions = {
		x = options.offsetText.x,
		y = options.offsetText.y,
		--width = options.width, -- Messes up cursor
		align = "center",
		text = "",
		fontSize = options.fontSize,
		font = options.font,
	}
	
	local text = display.newText(textOptions)
	text.defaultColor = options.color.default or colors.white
	text.selectedColor = options.color.selected or colors.white
	text:setFillColor(unpack(text.defaultColor))
	text.offset = options.offsetText
	newTextbox.text = text
	textContainer:insert(text)
	
	local placeholderTextOptions = {
		x = options.offsetText.x,
		y = options.offsetText.y,
		align = "center",
		text = options.placeholder or "",
		fontSize = options.fontSize,
		font = options.font,
	}
	
	local placeholderText = display.newText(placeholderTextOptions)
	placeholderText:setFillColor(unpack(options.color.placeholder))
	newTextbox.placeholderText = placeholderText
	textContainer:insert(placeholderText)
	
	local oldRemoveSelf = newTextbox.removeSelf
	function newTextbox.removeSelf(self, ...)
		if self == currentField then
			unselectCurrentField()
		end
		oldRemoveSelf(self, ...)
	end
	
	cursor:setFillColor(unpack(text.selectedColor))
	cursor.y = options.offsetText.y
	cursor.x = text.x + text.width/2 + cursorOffsetX
	
	newTextbox:setText(options.text)
end

function textbox.removeFocus()
	unselectCurrentField()
end

function textbox.new(options)	
	if not options and "table" == type(options) then
		error("New textbox options must be a table and not nil.", 3)
	end
	
	if not options.backgroundScale then
		if not options.width and options.height then
			error("You must specify a width and height, or backgroundScale property on options.", 3)
		end
	end
	
	options.offsetText = options.offsetText or {x = 0, y = 0}
	
	options.fontSize = options.fontSize or 20
	
	options.maxChars = options.maxChars or 0
	options.textPadding = options.textPadding or 0
	
	options.color = options.color or { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} }
	if not "table" == type(options.color) then
		error("color must contain a table.", 3)
	end
	
	local text = options.text or ""
	if not "string" == type(text) then
		error("Text must be a string.", 3)
	end
	options.text = text
	
	if options.backgroundImage and not "string" == type(options.backgroundImage) then
		error("backgroundImage must be a string.", 3)
	end
	
	if not (not options.onFocus or (options.onFocus and "function" == type(options.onFocus))) then
		error("onFocus must be a function.", 3)
	end
	
	if not (not options.onChange or (options.onChange and "function" == type(options.onChange))) then
		error("onChange must be a function.", 3)
	end
	
	if not (not options.onComplete or (options.onComplete and "function" == type(options.onComplete))) then
		error("onComplete must be a function.", 3)
	end
	
	local newTextbox = display.newGroup()
	newTextbox.anchorChildren = true
	
	createTextbox(newTextbox, options)
	
	return newTextbox
end

initialize()

return textbox
