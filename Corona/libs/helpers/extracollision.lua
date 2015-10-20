-------------------------------------------- Extra collision
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extramath = require( folder.."extramath" )
local logger = require( folder.."logger" )  
local colors = require( folder.."colors" )
local physics = require( "physics" )
local json = require( "json" )

local extraCollision = {}
------------------------------------------- Variables
------------------------------------------- Caches  
------------------------------------------- Constants 
local DEFAULT_ID_CHARACTER = "character"
local DEFAULT_ID_VEHICLE = "vehicle"
local DEFAULT_ID_SHIP = "ship"
------------------------------------------- Functions
local function addWheel(joinTo, wheelData)
	local positionX = wheelData.x or 0
	local positionY = wheelData.y or 0
	local radius = wheelData.radius or 18
	local torque = wheelData.torque or 100
	local image = wheelData.image
	
	local friction = wheelData.friction or 8
	local bounce = wheelData.bounce or 0
	local density = wheelData.density or 0.8
		
	local wheel = display.newCircle(positionX, positionY, radius)
	if image then
		wheel.fill = {type = "image", filename = image}
	end
	
	physics.addBody(wheel, "dynamic", {density = density, filter = {groupIndex= -1}, friction = friction, radius = radius, bounce = bounce})
	local pivot = physics.newJoint( "pivot", joinTo, wheel, wheel.x, wheel.y )
	wheel.angularDamping = 0.5
	wheel.torque = torque
	wheel.pivot = pivot
	return wheel
end 

------------------------------------------- Module functions
function extraCollision.checkCircleCollision( object1, object2 )
	if object1 and object2 then
		local radius1 = object1.radius or object1.width * 0.5
		local radius2 = object2.radius or object2.width * 0.5
		
		local distanceX = object1.x - object2.x
		local distanceY = object1.y - object2.y

		local distanceSquared = distanceX * distanceX + distanceY * distanceY
		local radiusSum = radius2 + radius1
		local radii = radiusSum * radiusSum

		if distanceSquared < radii then
		   return true
		end
	end
	return false
end

function extraCollision.newVehicle(parentGroup, options)
	options = options or {}
	
	local vehicle = display.newGroup()
	parentGroup:insert(vehicle)
	vehicle.name = "vehicle"
	
	local graphics = options.graphics
	if graphics and "table" == type(graphics) then
		for index = 1, #graphics do
			local graphicData = graphics[index]
			local image = display.newImage(graphicData.image)
			image.x, image.y = graphicData.x or 0, graphicData.y or 0
			image.xScale, image.yScale = graphicData.xScale or 1, graphicData.yScale or 1
			image.anchorX, image.anchorY = graphicData.anchorX or 0.5, graphicData.anchorY or 0.5
			vehicle:insert(image)
		end
	else
		local bodyWidth = options.bodyWidth or 140
		local bodyHeight = options.bodyHeight or 40
		local bodyColor = options.bodyColor or colors.gray
		local rectBody = display.newRect(0, 0, bodyWidth, bodyHeight)
		rectBody:setFillColor(unpack(bodyColor))
		vehicle:insert(rectBody)
	end
	
	local bodyProperties = {vehicle, "dynamic"}
	local bodyParts = options.bodyParts or {{density = 1.2, friction = 0.8, bounce = 0.5}}
	for index = 1, #bodyParts do
		bodyParts[index].filter = {groupIndex = -1}
		bodyProperties[#bodyProperties + 1] = bodyParts[index]
	end
	
	physics.addBody(unpack(bodyProperties))
	vehicle.angularDamping = options.angularDamping or 0.25
	
	options.wheelData = options.wheelData or {
		[1] = {
			["x"] = 52,
			["y"] = 22,
			["radius"] = 18,
			["wheelTexture"] = nil,
			["torque"] = 100,
		},
		[2] = {
			["x"] = -52,
			["y"] = 22,
			["radius"] = 18,
			["wheelTexture"] = nil,
			["torque"] = 100,
		},
	}
	
	local wheels = {}
	vehicle.wheels = wheels
	for wheelIndex = 1, #options.wheelData do
		local data = options.wheelData[wheelIndex]
		local wheel = addWheel(vehicle, data)
		parentGroup:insert(wheel)
		wheels[wheelIndex] = wheel
	end
	
	local oldRemoveSelf = vehicle.removeSelf
	function vehicle.removeSelf(...)
		oldRemoveSelf(...)
		for index = 1, #wheels do
			display.remove(wheels[index])
		end
	end
	
	function vehicle:move(analogX)
		if analogX > 1 then analogX = 1 end
		if analogX < -1 then analogX = -1 end
			
		vehicle:applyAngularImpulse(analogX * 90) -- TODO extract this 90
		for index = 1, #wheels do
			wheels[index]:applyTorque(wheels[index].torque * analogX)
		end
	end
	
	function vehicle:reset(xPosition, yPosition)
		vehicle.x = xPosition or vehicle.x
		vehicle.y = (yPosition or vehicle.y)
		vehicle.rotation = vehicle.rotation + 180

		for index = 1, #wheels do
			wheels[index].x = xPosition or wheels[index].x
			wheels[index].y = (yPosition or wheels[index].y)
		end
	end
	
	return vehicle
end

function extraCollision.newItem(options)
	options = options or {}
	local radius = options.radius or 15
	local onGrab = options.onGrab
	local canGrab = options.canGrab or {vehicle = true, character = true, ship = true}
	
	local item = display.newGroup()
	
	display.newCircle(item, 0, 0, radius)
	
	physics.addBody(item, "kinematic", {isSensor = true, radius = radius})
	
	local isGrabbed
	local function onLocalCollision( self, event )
		local otherObject = event.other
		
		local function grabItem()
			if onGrab and "function" == type(onGrab) then
				if not isGrabbed then
					isGrabbed = onGrab({target = item, grabber = otherObject})
				end
			end
		end
				
		if event.phase == "began" then
			if otherObject.name == DEFAULT_ID_VEHICLE and canGrab.vehicle then
				grabItem()
			elseif otherObject.name == DEFAULT_ID_CHARACTER and canGrab.character then
				grabItem()
			elseif otherObject.name == DEFAULT_ID_SHIP and canGrab.ship then
				grabItem()
			end
		end
	end
	
	item.collision = onLocalCollision
	item:addEventListener( "collision", item )
		
	return item
end

function extraCollision.newRadialGravityField(options)
	options = options or {}
	local radius = options.radius or 200
	local force = options.force or 50
	local gravityDamping = options.gravityDamping or 1
	
	local radiusForce = radius * force
	
	local field = display.newGroup()
	
	local debugTextOptions = {
		x = 0,
		y = 0,
		font = native.systemFont,
		fontSize = 18,
		width = 800,
		align = "left",
		text = "",
	}
	
	local debugText = display.newText(debugTextOptions)
	field:insert(debugText)
	
	local circle = display.newCircle(field, 0, 0, radius)
	circle.alpha = 0.2
	physics.addBody(field, "kinematic", {isSensor = true, radius = radius})

	local otherBodyList = {} -- TODO keymaps resulted in better performance vs indexed long lists (20 keys vs 40 indexes)

	local function updateGravity(event)
		for index, otherBody in pairs(otherBodyList) do
			if otherBody and otherBody.applyForce then
				local distanceX = otherBody.x - field.x
				local distanceY = otherBody.y - field.y
				local distance = (distanceX * distanceX + distanceY * distanceY) ^ 0.5 -- 200% times faster than cached math.sqrt
				
				if distance <= radius and distance > 0 then
					-- TODO apply or multiply damping
					local vectorSum = (distanceX >=0 and distanceX or -distanceX) + (distanceY >=0 and distanceY or -distanceY)-- 250% faster than cached math.abs
					local distanceForceMultiplier = (1 / vectorSum) * (radiusForce / distance)
					
					-- Negative distance is the gravity vector
					local gravityX = -distanceX * distanceForceMultiplier
					local gravityY = -distanceY * distanceForceMultiplier

					otherBody:applyForce(gravityX, gravityY, otherBody.x, otherBody.y)
				end
			else
				otherBodyList[index] = nil
			end
		end
	end
	Runtime:addEventListener("enterFrame", updateGravity)
	
	local removeSelf = field.removeSelf
	function field.removeSelf(self, ...)
		Runtime:removeEventListener("enterFrame", updateGravity)
		removeSelf(self, ...)
	end
	
	function field:setForce(newForce)
		force = newForce
		radiusForce = radius * force
	end
	
	function field:getForce()
		return force
	end
	
	function field:getRadius()
		return radius
	end
	
	local function onLocalCollision(self, event)
		local otherObject = event.other
		if event.phase == "began" then
			otherBodyList[tostring(otherObject)] = otherObject
		elseif event.phase == "ended" then
			otherBodyList[tostring(otherObject)] = nil
		end
	end
	
	field.collision = onLocalCollision
	field:addEventListener( "collision", field )
	
	return field
end

function extraCollision.newShip(options)
	options = options or {}
	local radius = options.radius or 30
	local size = radius * 2
	
	-- TODO add image loading, custom body and params, rotation params
	
	local shipBody = display.newGroup()
	
	physics.addBody( shipBody, {density = 0.5, friction = 0.3, bounce = 0.3, radius = radius})
	shipBody.gravityScale = 0
	shipBody.isFixedRotation = true
	shipBody.linearDamping = 0.5
	shipBody.name = DEFAULT_ID_SHIP
	
	shipBody.acceleration = 120
	
	local shipBodyRect = display.newRect(0, 0, size, size)
	shipBody:insert(shipBodyRect)
	
	local maxSpeed = 600
	
	function shipBody:move(analogX, analogY)
		if analogX ~= 0 or analogY ~= 0 then
			if analogX > 1 then analogX = 1 end
			if analogY > 1 then analogY = 1 end
			if analogX < -1 then analogX = -1 end
			if analogY < -1 then analogY = -1 end
			
			local speedX = analogX * self.acceleration
			local speedY = analogY * self.acceleration
			
			local vX, vY = self:getLinearVelocity()
			
			local analogMaxSpeedX = maxSpeed * math.abs(analogX)
			local analogMaxSpeedY = maxSpeed * math.abs(analogY)
			
			if vX < analogMaxSpeedX and speedX > 0 then
				self:applyForce(speedX, 0, self.x, self.y)
			elseif vX > -analogMaxSpeedX and speedX < 0 then
				self:applyForce(speedX, 0, self.x, self.y)
			end
			
			if vY < analogMaxSpeedY and speedY > 0 then
				self:applyForce(0, speedY, self.x, self.y)
			elseif vY > -analogMaxSpeedY and speedY < 0 then
				self:applyForce(0, speedY, self.x, self.y)
			end
			
			self.rotation = extramath.getFullAngle(vX, vY) + 90
		end
	end
	
	return shipBody
end

function extraCollision.newCharacterController(options)
	options = options or {}
	local bodyWidth = options.bodyWidth or 30
	local bodyHeight = options.bodyHeight or 60
	local bodyRadius = bodyWidth * 0.5
	local halfFloorSensorWidth = bodyWidth * 0.1
	local floorSensorHeight = bodyRadius * 1.2
	
	local characterController = display.newGroup()
	characterController.maxSpeed = options.maxSpeed or 200
	characterController.maxAirSpeed = options.maxAirSpeed or 120
	characterController.airAcceleration = options.airAcceleration or 1
	characterController.jumpForce = options.jumpForce or -450
	characterController.maxJumps = options.maxJumps or 2
	characterController.name = "character"
	
	physics.addBody(characterController, "dynamic", unpack({
		{friction = 0.5, bounce = 0.05, density = 2, radius = bodyRadius},
		{friction = 0, bounce = 0.1, density = 1, shape = {-bodyRadius,-bodyHeight ,-bodyRadius,0, bodyRadius,0, bodyRadius,-bodyHeight}},
		{isSensor = true, shape = {-halfFloorSensorWidth,0 ,halfFloorSensorWidth,0, halfFloorSensorWidth,floorSensorHeight, -halfFloorSensorWidth,floorSensorHeight}},
	}))
	
	local availableJumps = 0
	local footSensorCollisions = 0
	local steppingOnVehicle
	local function onLocalCollision( self, event )
		local otherObject = event.other
		if event.selfElement == 3 then -- 3 is foot sensor
			if event.phase == "began" then
				availableJumps = self.maxJumps
				footSensorCollisions = footSensorCollisions + 1
				if otherObject.name == "vehicle" then
					steppingOnVehicle = event.other
				end
			elseif event.phase == "ended" then
				footSensorCollisions = footSensorCollisions - 1
				if otherObject.name == "vehicle" then
					steppingOnVehicle = nil
				end
			end
		end
	end
	
	characterController.collision = onLocalCollision
	characterController:addEventListener( "collision", characterController )
		
	characterController.isFixedRotation = true
	characterController.isBullet = true
	characterController.linearDamping = 0.8
	characterController.isSleepingAllowed = false
	
	function characterController:move(side)
		side = side > 1 and 1 or side
		side = side < -1 and -1 or side
		
		local linearX, linearY = self:getLinearVelocity()
		if footSensorCollisions > 0 then
			if steppingOnVehicle then
				local vehicleX, vehicleY = steppingOnVehicle:getLinearVelocity()
				self:setLinearVelocity(self.maxSpeed * side + vehicleX,linearY)
			else
				self:setLinearVelocity(self.maxSpeed * side,linearY)
			end
		else
			if side > 0 then
				if linearX < self.maxAirSpeed then
					self:applyLinearImpulse(self.airAcceleration,0,0,0)
				end
			elseif side < 0 then
				if linearX > -self.maxAirSpeed then
					self:applyLinearImpulse(-self.airAcceleration,0,0,0)
				end
			end
		end
	end
	
	function characterController:jump()
		if availableJumps > 0 then
			availableJumps = availableJumps - 1
			local linearX, linearY = self:getLinearVelocity()
			self:setLinearVelocity(linearX,self.jumpForce)
		end
	end
	
	local rect = display.newRect(characterController, 0, 0, bodyWidth, bodyHeight)
	rect.anchorY = 1
	display.newCircle(characterController, 0, 0, bodyRadius)
	
	return characterController
end

return extraCollision