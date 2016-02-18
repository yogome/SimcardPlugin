---------------------------------------------- Robot
local robot = {}
 
--------------------------------------------- Functions
function robot.press(object)
	if object and object.dispatchEvent then
		object:dispatchEvent({name = "touch", phase = "began", target = object})
		object:dispatchEvent({name = "touch", phase = "ended", target = object})
	end
end

function robot.drag(object, params)
	params = params or {}
	if object and object.dispatchEvent and object.x and object.y then
		local dragTime = params.time or 0
		local targetX = params.x or object.x
		local targetY = params.y or object.y
		
		local easingFunction = params.transition or easing.linear
		
		local xStart = params.xStart or object.x
		local yStart = params.yStart or object.y
		
		local currentX = xStart
		local currentY = yStart
		
		object:dispatchEvent({name = "touch", phase = "began", target = object, x = xStart, y = yStart, xStart = xStart, yStart = yStart})
		
		local object = setmetatable({}, {
			__newindex = function(self, index, value)
				if index == "x" then
					currentX = value
				elseif index == "y" then
					currentY = value
				else
					rawset(self, index, value)
				end
				
				if index == "x" or index == "y" then
					object:dispatchEvent({name = "touch", phase = "moved", target = object, x = currentX, y = currentY, xStart = xStart, yStart = yStart})
								
					if currentX == targetX and currentY == targetY then
						object:dispatchEvent({name = "touch", phase = "ended", target = object, x = targetX, y = targetY, xStart = xStart, yStart = yStart})
					end
				end
			end,
			__index = function(self, index)
				if index == "x" then
					return currentX
				elseif index == "y" then
					return currentY
				else
					return rawget(self, index)
				end
			end
		})
		
		transition.to(object, {time = dragTime, x = targetX, y = targetY, transition = easingFunction})
	end
end

function robot.tap(object)
	if object and object.dispatchEvent then
		object:dispatchEvent({name = "tap", target = object})
	end
end

return robot
