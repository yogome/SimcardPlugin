----------------------------------------------- Colorpicker
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )  
local widget = require( "widget" )
local extratable = require( folder.."extratable" )
local colorpicker = {}

---------------------------------------------- Functions
local function createColorIcon(backPath, frontPath, color)
	local colorIcon = display.newGroup()
	colorIcon.color = color
	if backPath then
		local iconBack = display.newImage(backPath)
		colorIcon:insert(iconBack)
	else
		
	end
	
	if frontPath then
		local iconFront = display.newImage(frontPath)
		colorIcon:insert(iconFront)
		iconFront:setFillColor(unpack(color))
	else
		local iconFront = display.newRect(0,0,32,32)
		colorIcon:insert(iconFront)
		iconFront:setFillColor(unpack(color))
	end
	
	return colorIcon
end

local function createColorpicker(newColorpicker, options)
	newColorpicker.isVisible = false
	newColorpicker.y = display.contentCenterY
	
	if options.position == "right" then
		newColorpicker.x = display.screenOriginX + display.viewableContentWidth + options.width * 0.5
	else
		newColorpicker.x = display.screenOriginX - options.width * 0.5
	end
	newColorpicker.position = options.position
	
	if not options.backgroundSheet then
		local background = display.newRect(0, 0, options.width, display.viewableContentHeight + 2)
		newColorpicker:insert(background)
	else
		local background = display.newGroup()
		
		local sheetOptions = {
			viewTop = {
				{
					name = "default",
					start = options.backgroundTopFrame,
					count = 1,
				},
			},
			viewMiddle = {
				{
					name = "default",
					start = options.backgroundMiddleFrame,
					count = 1,
				},
			},
			viewBottom = {
				{
					name = "default",
					start = options.backgroundBottomFrame,
					count = 1,
				},
			},
		}
		
		local backgroundTop = display.newSprite(background, options.backgroundSheet, sheetOptions.viewTop)
		local backgroundMiddle = display.newSprite(background, options.backgroundSheet, sheetOptions.viewMiddle)
		local backgroundBottom = display.newSprite(background, options.backgroundSheet, sheetOptions.viewBottom)
		
		backgroundTop.width = options.width
		backgroundMiddle.width = options.width
		backgroundBottom.width = options.width
		
		backgroundMiddle.height = display.viewableContentHeight - backgroundTop.height - backgroundBottom.height
		
		backgroundTop.y = -display.viewableContentHeight * 0.5 + backgroundTop.height * 0.5
		backgroundMiddle.y = 0
		backgroundBottom.y = display.viewableContentHeight * 0.5 - backgroundBottom.height * 0.5
		
		newColorpicker:insert(background)
	end
	
	local scrollViewOptions = {
		x = 0,
		y = 0,
		width = options.width - options.padding * 2,
		height = display.viewableContentHeight - options.padding * 2,
		horizontalScrollDisabled = true,
		hideBackground = true,
	}
	
	local scrollview = widget.newScrollView(scrollViewOptions)
	newColorpicker:insert(scrollview)
	newColorpicker.scrollview = scrollview
	
	local function colorTap(event)
		local colorButton = event.target
		local colorpicker = colorButton.colorpicker
		if colorpicker.isEnabled then
			if colorpicker.onSelect and "function" == type(colorpicker.onSelect) then
				event.color = colorButton.color
				event.index = colorButton.index
				event.colorName = colorButton.colorName
				colorpicker.onSelect(event)
			end
			colorpicker:hide()
		end
	end
	
	local index = 1
	for colorName, colorValues in pairs(options.colorlist) do
		if type(colorValues) == "table" then
			local colorIcon = createColorIcon(options.iconBack, options.iconFront, colorValues, colorTap)
			colorIcon.index = index
			colorIcon.colorpicker = newColorpicker
			colorIcon.color = colorValues
			colorIcon.colorName = colorName
			colorIcon:addEventListener("tap", colorTap)
			colorIcon.x = scrollview.width * 0.5
			colorIcon.y = index * (colorIcon.height + options.padding) - colorIcon.height * 0.5 - options.padding
			scrollview:insert(colorIcon)

			index = index + 1
		end
	end
	
	newColorpicker.isEnabled = true
	function newColorpicker:setEnabled(value)
		self.isEnabled = value
		if not value then
			self:hide()
		end
	end
	
	function newColorpicker:show(params)
		params = params or {}
		local onSelect = params.onSelect
		
		if onSelect then
			if "function" == type(onSelect) then
				self.onSelect = onSelect
			else
				error("onSelect must be a function.", 3)
			end
		end
		
		local function animationTransition()
			self.scrollview:scrollToPosition({ y = -1000, time = 0, onComplete = function()
				self.scrollview:scrollToPosition({ y = 0, time = 800,})
			end})
		end

		self.isVisible = true
		self.alpha = 0

		if self.transition then
			transition.cancel(self.transition)
		end

		if self.position == "right" then
			if self.x >= display.screenOriginX + display.viewableContentWidth + self.width * 0.5 then animationTransition() end
			self.transition = transition.to(self, {time = 400, alpha = 1, x = display.screenOriginX + display.viewableContentWidth - self.width * 0.5, transition = easing.outQuad})
		else
			if self.x <= display.screenOriginX - self.width * 0.5 then animationTransition() end
			self.transition = transition.to(self, {time = 400, alpha = 1, x = display.screenOriginX + self.width * 0.5, transition = easing.outQuad})
		end
	end
	
	function newColorpicker:hide()
		if self.transition then
			transition.cancel(self.transition)
		end

		local function hide()
			self.isVisible = false
		end

		if self.position == "right" then
			self.transition = transition.to(self, {time = 400, x = display.screenOriginX + display.viewableContentWidth + self.width * 0.5, transition = easing.outQuad, onComplete = hide})
		else
			self.transition = transition.to(self, {time = 400, x = display.screenOriginX - self.width * 0.5, transition = easing.outQuad, onComplete = hide})
		end
	end
end

function colorpicker.new(options)
	if not (options and "table" == type(options))then
		error("Options must be a table.", 3)
	end
	
	if options.backgroundSheet then
		if not(options.backgroundTopFrame and options.backgroundMiddleFrame and options.backgroundBottomFrame) then
			error("You must include backgroundTopFrame, backgroundMiddleFrame, and backgroundBottomFrame if you include backgroundSheet.", 3)
		else
			if not("number" == type(options.backgroundTopFrame) and "number" == type(options.backgroundMiddleFrame) and "number" == type(options.backgroundMiddleFrame)) then
				error("backgroundTopFrame, backgroundMiddleFrame, and backgroundBottomFrame must be numbers.", 3)
			end
		end
	end
	
	if not(options.width and "number" == type(options.width)) then
		error("width must be a number.", 3)
	end
	
	if not options.position then
		options.position = "right"
		logger.log([[[Colorpicker] Setting position to "left"]])
	elseif not("string" == type(options.position) and ("left" == options.position or "right" == options.position))then
		error([[position must be a string, "left" or "right".]], 3)
	end
	
	if not(options.colorlist and "table" == type(options.colorlist) and not extratable.isEmpty(options.colorlist)) then
		error([[colorlist must be a table and not be empty.]], 3)
	end
	
	if not options.padding then
		options.padding = 0
	elseif not "number" == type(options.padding) then
		error([[padding must be a number.]], 3)
	end
	
	local newColorpicker = display.newGroup()
	createColorpicker(newColorpicker, options)
	
	return newColorpicker
end

return colorpicker
