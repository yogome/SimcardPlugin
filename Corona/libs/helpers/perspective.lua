---------------------------------------------- Perspective
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local sound = require( folder.."sound" ) 

local Perspective={}
---------------------------------------------- Cache
local mathAbs = math.abs
local mathHuge = math.huge
local mathCos = math.cos
local mathSin = math.sin

local ccx = display.contentCenterX
local ccy = display.contentCenterY
local vcw = display.viewableContentWidth
local vch = display.viewableContentHeight
---------------------------------------------- Functions
function Perspective.newCamera(numLayers)
	logger.log("Creating view.")
	numLayers = (type(numLayers)=="number" and numLayers) or 1

	local isTracking = false
	local layer = {}
	local camera = display.newGroup()
	camera.scrollX = 0
	camera.scrollY = 0
	camera.damping = 10
	camera.values = {
		x1 = -mathHuge,
		x2 = mathHuge,
		y1 = -mathHuge,
		y2 = mathHuge,
		prevDamping = 10,
		damping = 0.1,
		trackRotation = false,
		zoom = 1,
		zoomMultiplier = 1,
		defaultRotation = 0,
		x = 0,
		y = 0,
	}
	
	for index = numLayers, 1, -1 do
		layer[index] = display.newGroup()
		layer[index].parallaxRatio = 1
		layer[index]._isPerspectiveLayer = true
		camera:insert(layer[index])
	end
	
	function camera:add(object, level, isFocus)
		local isFocus = isFocus or false
		local level = level or 1
		
		layer[level]:insert(object)
		object.layer=level
		
		if isFocus then
			camera.values.focus = object
		end
		
		function object:toLayer(newLayer)
			if layer[newLayer] then
				layer[newLayer]:insert(self)
				self._perspectiveLayer = newLayer
			end
		end
		
		function object:back()
			if layer[object._perspectiveLayer + 1] then
				local backLayer = layer[object._perspectiveLayer+1]
				backLayer:insert(object)
				object._perspectiveLayer = object.layer+1
			end
		end
		
		function object:forward()
			if layer[object._perspectiveLayer - 1] then
				local frontLayer = layer[object._perspectiveLayer - 1]
				frontLayer:insert(object)
				object._perspectiveLayer=object.layer - 1
			end
		end
		
		function object:toCameraFront()
			layer[1]:insert(object)
			object._perspectiveLayer = 1
			object:toFront()
		end
		
		function object:toCameraBack()
			layer[numLayers]:insert(object)
			object._perspectiveLayer=numLayers
			object:toBack()
		end
	end
	
	function camera:setZoom(zoomLevel, zoomDelay, zoomTime)
		zoomLevel = zoomLevel or 1
		zoomDelay = zoomDelay or 0
		zoomTime = zoomTime or 500
		self.values.zoom = zoomLevel
		self.values.zoomMultiplier = 1 / zoomLevel
		local targetScale = (1 - zoomLevel) * 0.5
		
		transition.cancel(camera)
		if zoomDelay <= 0 and zoomTime <= 0 then
			self.xScale = zoomLevel
			self.yScale = zoomLevel
			self.x = self.values.x + display.viewableContentWidth * targetScale
			self.y = self.values.y + display.viewableContentHeight * targetScale
		else
			transition.to(self, {xScale = zoomLevel, yScale = zoomLevel, x = self.values.x + display.viewableContentWidth * targetScale, y = self.values.y + display.viewableContentHeight * targetScale, time = zoomTime, delay = zoomDelay, transition = easing.inOutQuad})
		end
	end
	
	function camera:getZoom()
		return self.values.zoom
	end
	
	function camera.trackFocus() -- TODO must restore camera bounds, with scaling
		if camera.values.prevDamping ~= camera.damping then
			camera.values.prevDamping = camera.damping
			camera.values.damping = 1 / camera.damping
		end
		
		if camera.values.focus then
			layer[1].parallaxRatio = 1
			camera.scrollX, camera.scrollY = layer[1].x, layer[1].y
			for index = 1, numLayers do
						
				local currentLayer = layer[index]
				local targetRotation = camera.values.trackRotation and -camera.values.focus.rotation or camera.values.defaultRotation
				
				currentLayer.rotation = (currentLayer.rotation - (currentLayer.rotation - targetRotation) * camera.values.damping)

				local focusAngle = currentLayer.rotation * 0.0174532925
				
				camera.values.targetX = (camera.values.targetX - (camera.values.targetX - (camera.values.focus.x) * layer[index].parallaxRatio) * camera.values.damping)
				camera.values.targetY = (camera.values.targetY - (camera.values.targetY - (camera.values.focus.y) * layer[index].parallaxRatio) * camera.values.damping)
										
				camera.values.targetX = camera.values.x1 < camera.values.targetX and camera.values.targetX or camera.values.x1
				camera.values.targetX = camera.values.x2 > camera.values.targetX and camera.values.targetX or camera.values.x2
				
				camera.values.targetY = camera.values.y1 < camera.values.targetY and camera.values.targetY or camera.values.y1
				camera.values.targetY = camera.values.y2 > camera.values.targetY and camera.values.targetY or camera.values.y2
				
				local otherRotationX = mathSin(focusAngle) * camera.values.targetY
				local rotationX = mathCos(focusAngle) * camera.values.targetX
				local finalX = -rotationX + otherRotationX
				
				local otherRotationY = mathCos(focusAngle) * camera.values.targetY
				local rotationY = mathSin(focusAngle) * camera.values.targetX
				local finalY = -rotationY - otherRotationY
				
				layer[index].x = finalX + ccx
				layer[index].y = finalY + ccy
			end
		end
	end
	
	function camera:start()
		if not isTracking then
			isTracking = true
			Runtime:addEventListener("enterFrame", camera.trackFocus)
		end
	end
	
	function camera:stop()
		if isTracking then
			Runtime:removeEventListener("enterFrame", camera.trackFocus)
			isTracking = false
		end
	end
	
	function camera:setBounds(x1, x2, y1, y2)
		x1 = x1 or -mathHuge
		x2 = x2 or mathHuge
		y1 = y1 or -mathHuge
		y2 = y2 or mathHuge
		
		if "boolean" == type(x1) then
			camera.values.x1, camera.values.x2, camera.values.y1, camera.values.y2 = -mathHuge, mathHuge, -mathHuge, mathHuge
		else
			camera.values.x1, camera.values.x2, camera.values.y1, camera.values.y2 = x1, x2, y1, y2
		end
		
		logger.log("Bounds set.")
	end
	
	function camera:setPosition(x, y)
		self.values.x = x
		self.values.y = y
		self.x = x
		self.y = y
	end
	
	function camera:playSound(soundID, x, y) -- TODO could add zoom precision
		local leftX = camera.values.targetX - vcw * 0.5
		local rightX = camera.values.targetX + vcw * 0.5
		
		local topY = camera.values.targetY - vch * 0.5
		local bottomY = camera.values.targetY + vch * 0.5
		
		if x > leftX and x < rightX then
			if y < topY and y > bottomY then
				sound.play(soundID)
			end
		end
	end
	
	function camera:toPoint(x, y, options)
		local x = x or ccx
		local y = y or ccy
		
		camera:stop()
		local tempFocus = {x = x, y = y}
		camera:setFocus(tempFocus, options)
		camera:start()
		
		return tempFocus
	end
	
	function camera:removeFocus()
		camera.values.focus = nil
	end
	
	function camera:setFocus(object, options)
		options = options or {}
		local trackRotation = options.trackRotation
		local soft = options.soft
		
		if object and object.x and object.y and camera.values.focus ~= object then
			camera.values.focus = object
			
			if not soft then
				camera.values.targetX = object.x
				camera.values.targetY = object.y
			end
		else
			camera.values.focus = nil
		end
		
		camera.values.defaultRotation = 0 --Reset rotation
		if not soft then
			for index = 1, numLayers do
				layer[index].rotation = 0
			end
		end
		
		camera.values.trackRotation = trackRotation
	end
	
	function camera:layer(index)
		return layer[index]
	end
	
	function camera:setParallax(...)
		for index = 1, #arg do 
			layer[index].parallaxRatio = arg[index]
		end
	end
	
	function camera:remove(object)
		if object and layer[object._perspectiveLayer] then
			layer[object._perspectiveLayer]:remove(object)
		end
	end
	
	camera:addEventListener("finalize", function(event)
		if isTracking then
			Runtime:removeEventListener("enterFrame", camera.trackFocus)
		end
	end)
	
	return camera
end

return Perspective

