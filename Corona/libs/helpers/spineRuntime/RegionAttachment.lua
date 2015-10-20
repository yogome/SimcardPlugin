----------------------------------------------- RegionAttachment
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$") 

local AttachmentType = require( folder.."AttachmentType" )

local RegionAttachment = {}
----------------------------------------------- Caches
local mathPi = math.pi
local mathCos = math.cos
local mathSin = math.sin
----------------------------------------------- Module functions
function RegionAttachment.new(name)
	if not name then error("name cannot be nil", 2) end
	
	local self = {
		name = name,
		type = AttachmentType.region,
		x = 0, y = 0,
		rotation = 0,
		scaleX = 1, scaleY = 1,
		width = 0, height = 0,
		offset = {},
		uvs = {},
		r = 1, g = 1, b = 1, a = 1,
		path = null,
		rendererObject = null,
		regionOffsetX = 0, regionOffsetY = 0,
		regionWidth = 0, regionHeight = 0,
		regionOriginalWidth = 0, regionOriginalHeight = 0
	}

	function self:updateOffset()
		local regionScaleX = self.width / self.regionOriginalWidth * self.scaleX
		local regionScaleY = self.height / self.regionOriginalHeight * self.scaleY
		local localX = -self.width / 2 * self.scaleX + self.regionOffsetX * regionScaleX
		local localY = -self.height / 2 * self.scaleY + self.regionOffsetY * regionScaleY
		local localX2 = localX + self.regionWidth * regionScaleX
		local localY2 = localY + self.regionHeight * regionScaleY
		local radians = self.rotation * mathPi / 180
		local cos = mathCos(radians)
		local sin = mathSin(radians)
		local localXCos = localX * cos + self.x
		local localXSin = localX * sin
		local localYCos = localY * cos + self.y
		local localYSin = localY * sin
		local localX2Cos = localX2 * cos + self.x
		local localX2Sin = localX2 * sin
		local localY2Cos = localY2 * cos + self.y
		local localY2Sin = localY2 * sin
		local offset = self.offset
		offset[0] = localXCos - localYSin -- X1
		offset[1] = localYCos + localXSin -- Y1
		offset[2] = localXCos - localY2Sin -- X2
		offset[3] = localY2Cos + localXSin -- Y2
		offset[4] = localX2Cos - localY2Sin -- X3
		offset[5] = localY2Cos + localX2Sin -- Y3
		offset[6] = localX2Cos - localYSin -- X4
		offset[7] = localYCos + localX2Sin -- Y4
	end

	function self:computeWorldVertices(x, y, bone, worldVertices)
		x = x + bone.worldX
		y = y + bone.worldY
		local m00, m01, m10, m11 = bone.m00, bone.m01, bone.m10, bone.m11
		local offset = self.offset
		worldVertices[0] = offset[0] * m00 + offset[1] * m01 + x -- TODO this worldVertices was named vertices
		worldVertices[1] = offset[0] * m10 + offset[1] * m11 + y
		worldVertices[2] = offset[2] * m00 + offset[3] * m01 + x
		worldVertices[3] = offset[2] * m10 + offset[3] * m11 + y
		worldVertices[4] = offset[4] * m00 + offset[5] * m01 + x
		worldVertices[5] = offset[4] * m10 + offset[5] * m11 + y
		worldVertices[6] = offset[6] * m00 + offset[7] * m01 + x
		worldVertices[7] = offset[6] * m10 + offset[7] * m11 + y
	end

	return self
end
return RegionAttachment
