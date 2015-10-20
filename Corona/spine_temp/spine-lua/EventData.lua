----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")

local EventData = {}
---------------------------------------------- Functions
function EventData.new (name)
	if not name then error("name cannot be nil", 2) end

	local self = {
		name = name,
		intValue = 0,
		floatValue = 0,
		stringValue = nil
	}

	return self
end
return EventData
