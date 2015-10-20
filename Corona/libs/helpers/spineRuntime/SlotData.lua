----------------------------------------------- SlotData
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")
local BlendMode = require( folder.."BlendMode" )

local SlotData = {}
----------------------------------------------- Module functions
function SlotData.new(name, boneData)
	if not name then error("name cannot be nil", 2) end
	if not boneData then error("boneData cannot be nil", 2) end
	
	local self = {
		name = name,
		boneData = boneData,
		r = 1, g = 1, b = 1, a = 1,
		attachmentName = nil,
		blendMode = BlendMode.normal
	}

	function self:setColor(r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	end

	return self
end
return SlotData
