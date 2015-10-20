---------------------------------------------- Robot
local robot = {}
 
 --------------------------------------------- Functions
function robot.press(object)
	if object and object.dispatchEvent then
		object:dispatchEvent({name = "touch", phase = "began", target = object})
		object:dispatchEvent({name = "touch", phase = "ended", target = object})
	end
end

function robot.tap(object)
	if object and object.dispatchEvent then
		object:dispatchEvent({name = "tap", target = object})
	end
end

return robot
