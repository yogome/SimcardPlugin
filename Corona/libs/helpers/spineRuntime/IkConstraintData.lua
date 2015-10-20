----------------------------------------------- IkConstraintData
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local IkConstraintData = {}
----------------------------------------------- Module functions
function IkConstraintData.new(name)
	if not name then error("name cannot be nil", 2) end

	local self = {
		name = name,
		bones = {},
		target = nil,
		bendDirection = 1,
		mix = 1
	}

	return self
end
return IkConstraintData
