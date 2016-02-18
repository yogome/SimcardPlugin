----------------------------------------------- Extra widget
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extratable = require(folder.."extratable")
local widget = require("widget")

local extrawidget = {}

----------------------------------------------- Constants
local IS_DEVICE = system.getInfo("environment") == "device"
local ZOOM_MAX_DEFAULT = 1.5
local ZOOM_MIN_DEFAULT = 0.5

local ERROR_FLOAT = 0.00001
----------------------------------------------- Caches
local mathFloor = math.floor
local display = display
----------------------------------------------- Module functions

system.activate("multitouch")

local function getVectorLenght(vectorA, vectorB)
    local width, height = vectorB.x - vectorA.x, vectorB.y - vectorA.y
    return (width * width + height * height) ^ 0.5
end

local function getCenter(points)
	local x, y = 0, 0
	
	for index = 1, #points do
		local point = points[index]
		x = x + point.x
		y = y + point.y
	end
	
	return {x = x / #points, y = y / #points}
end

local function updateTracking(center, points)
	for index = 1, #points do
		local point = points[index]
		point.prevDistance = point.distance
		point.distance = getVectorLenght(center, point)
	end
end

local function getScaling(points)
	local total = 0
	
	for index = 1, #points do
		local point = points[index]
		total = total + point.distance / point.prevDistance
	end
	
	return total / #points
end

local function newTrackDot(event)
	local circle = display.newCircle(event.x, event.y, 20)
	
	local view = event.target
	
	if not view.testDots then
		circle.isHitTestable = true
		circle.isVisible = false
	end
	
	function circle:touch(event)
		local target = circle
		
		event.parent = view
		
		if event.phase == "began" then
			display.getCurrentStage():setFocus(target, event.id)
			target.hasFocus = true
			return true
		elseif target.hasFocus then
			if event.phase == "moved" then
				target.x, target.y = event.x, event.y
			else
				display.getCurrentStage():setFocus(target, nil)
				target.hasFocus = false
			end
			
			view:touch(event)
			return true
		end
		
		return false
	end
	
	circle:addEventListener("touch")
	
	function circle:tap(event)
		if event.numTaps == 2 then
			event.parent = view
			
			view:touch(event)
		end
		return true
	end
	
	if view.testDots then
		circle:addEventListener("tap")
	end
	
	circle:touch(event)
	return circle
end

local function touch(self, event)
	local target = event.target
	
	local view = self
	local oldX = view.x
	local oldY = view.y
	
	if event.phase == "began" then
		local dot = newTrackDot(event)
		
		view.dots[#view.dots + 1] = dot
		view.prevCenter = getCenter(view.dots)
		updateTracking(view.prevCenter, view.dots)
		return true
	elseif event.parent == view then
		if event.phase == "moved" then
			local center, scale = {}, 1
			
			center = getCenter( view.dots )
			updateTracking(view.prevCenter, view.dots)
			if #view.dots > 1 then
				scale = getScaling(view.dots)
				view.xScale, view.yScale = view.xScale * scale, view.yScale * scale
			end
			
			local pt = {}
			
			pt.x = view.x + (center.x - view.prevCenter.x)
			pt.y = view.y + (center.y - view.prevCenter.y)
			
			pt.x = center.x + ((pt.x - center.x) * scale)
			pt.y = center.y + ((pt.y - center.y) * scale)
			
			view.x, view.y = pt.x, pt.y
			
			view.prevCenter = center
		else
			if not view.testDots or event.numTaps == 2 then
				local index = table.indexOf(view.dots, target)
				table.remove(view.dots, index)
				display.remove(target)
				view.prevCenter = getCenter(view.dots)
				updateTracking(view.prevCenter, view.dots)
			end
		end
		
		if view.xScale > view.maxZoom then 
			view.xScale = view.maxZoom - ERROR_FLOAT
			view.yScale = view.maxZoom - ERROR_FLOAT
			
			view.x = oldX
			view.y = oldY
		end
		if view.xScale < view.minZoom then
			view.xScale = view.minZoom + ERROR_FLOAT
			view.yScale = view.minZoom + ERROR_FLOAT
			
			view.x = oldX
			view.y = oldY
		end
		
		local leftLimit = ((view.width * 0.5) * view.xScale) + display.screenOriginX
		local rightLimit = -((view.width * 0.5) * view.xScale) + display.viewableContentWidth + display.screenOriginX
		
		if view.x > leftLimit then view.x = leftLimit end
		if view.x < rightLimit then view.x = rightLimit end
		
		local topLimit = ((view.height * 0.5) * view.yScale) + display.screenOriginY
		local bottomLimit = -((view.height * 0.5) * view.yScale) + display.viewableContentHeight + display.screenOriginY
		
		if view.y > topLimit then view.y = topLimit end
		if view.y < bottomLimit then view.y = bottomLimit end
		
		return true
	end
	
	return false
end

local function setZoom(self, zoomLevel)
	self.xScale = zoomLevel
	self.yScale = zoomLevel
	
	if self.xScale > self.maxZoom then 
		self.xScale = self.maxZoom - ERROR_FLOAT
		self.yScale = self.maxZoom - ERROR_FLOAT
	end
	if self.xScale < self.minZoom then
		self.xScale = self.minZoom + ERROR_FLOAT
		self.yScale = self.minZoom + ERROR_FLOAT
	end
end

local function scrollToObject(self, toObject, fromZ, scrollTime)
	scrollTime = scrollTime or 500
	local toZ = 1

	local objectPositionX = -toObject.x
	local objectPositionY = -toObject.y

	local leftInvertedLimit = self.width * 0.5 - self.x
	local rightInvertedLimit = -(self.width * 0.5 - self.x)
	local topInvertedLimit = self.height * 0.5 - self.y
	local bottomInvertedLimit = -(self.height * 0.5 - self.y)

	if objectPositionX > leftInvertedLimit then objectPositionX = leftInvertedLimit end
	if objectPositionX < rightInvertedLimit then objectPositionX = rightInvertedLimit end
	if objectPositionY > topInvertedLimit then objectPositionY = topInvertedLimit end
	if objectPositionY < bottomInvertedLimit then objectPositionY = bottomInvertedLimit end

	local toX = objectPositionX * toZ + self.x * toZ
	local toY = objectPositionY * toZ + self.y * toZ

	self.xScale = fromZ
	self.yScale = fromZ

	transition.to(self, {delay = 200, time = scrollTime,x = toX, y = toY, xScale = toZ, yScale = toZ, transition = easing.inOutQuad})
end

function extrawidget.newZoomView(options)
	options = options or {}
	
	local pinchZoomView = display.newGroup()
	pinchZoomView.anchorChildren = true
	pinchZoomView.anchorX = 0.5
	pinchZoomView.anchorY = 0.5
	pinchZoomView.dots = {}
	
	pinchZoomView.touch = touch
	pinchZoomView.scrollToObject = scrollToObject
	pinchZoomView.setZoom = setZoom
	
	pinchZoomView.testDots = options.testDots
	pinchZoomView.maxZoom = options.maxZoom or ZOOM_MAX_DEFAULT
	pinchZoomView.minZoom = options.minZoom or ZOOM_MIN_DEFAULT
	
	pinchZoomView:addEventListener("touch")
	
	if pinchZoomView.testDots == nil then
		pinchZoomView.testDots = not IS_DEVICE
	end
	
	return pinchZoomView
end

function extrawidget.newTextList(options)
	options = options or {}
	local width = options.width or 400
	local height = options.height or 400
	local strings = options.strings or {"option1"}
	local font = options.font or native.systemFont
	local fontSize = options.fontSize or 28
	local fontColor = options.fontColor or {1,1,1}
	local onSelect = options.onSelect
	
	local selectSize = fontSize + (fontSize * 0.25)
	local textlistOptions = {
		x = 0,
		y = 0,
		width = width,
		height = height,
		scrollWidth = 100,
		scrollHeight = 100,
		hideBackground = false,
		backgroundColor = {0.8, 0.8, 0.8},
	}
	local textlist = widget.newScrollView(textlistOptions)
	
	local highlightRect = display.newRect(0, 0, width, selectSize)
	highlightRect.anchorX, highlightRect.anchorY = 0, 0
	highlightRect:setFillColor(0.5)
	highlightRect.isVisible = false
	textlist:insert(highlightRect)
	
	local generalTextGroup = display.newGroup()
	textlist:insert(generalTextGroup)
	
	local textOptions = {
		text = "",	 
		x = 0,
		y = 0,
		font = font,   
		fontSize = fontSize,
		align = "left"
	}
	
	textlist:addEventListener("tap", function(event)
		local scrollX, scrollY = textlist:getContentPosition()
		local localX, localY = textlist:contentToLocal(event.x, event.y)
		localY = localY - scrollY
		local rectPosition = (localY + height * 0.5) - ((localY + height * 0.5) % selectSize)
		local selectedIndex = mathFloor(rectPosition / selectSize) + 1
		
		if selectedIndex > 0 and selectedIndex <= #strings then
			highlightRect.y = rectPosition
			highlightRect.isVisible = true
			if onSelect and "function" == type(onSelect) then
				onSelect({index = selectedIndex, value = strings[selectedIndex]})
			end
		end
	end)
	
	function textlist:setStrings(newStrings)
		strings = newStrings
		highlightRect.isVisible = false
		
		for childIndex = generalTextGroup.numChildren, 1, -1 do
			display.remove(generalTextGroup[childIndex])
		end
		
		local newScrollHeight = #strings * selectSize
		textlist:setScrollHeight(newScrollHeight > height and newScrollHeight or height)
		
		for index = 1, #strings do
			local textObject = display.newText(textOptions)
			textObject:setFillColor(unpack(fontColor))
			textObject.anchorX, textObject.anchorY = 0, 0
			textObject.y = (index - 1) * selectSize
			textObject.text = strings[index]
			generalTextGroup:insert(textObject)
		end
	end
	
	textlist:setStrings(strings)
	
	return textlist
end

function extrawidget.newButton(options, onRelease, onPress)
	local ourOptions = extratable.deepcopy(options)
	ourOptions.onRelease = onRelease or ourOptions.onRelease
	ourOptions.onPress = onPress or ourOptions.onPress
	local button = widget.newButton(ourOptions)
	
	return button
end

return extrawidget
