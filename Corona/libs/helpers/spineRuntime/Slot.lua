----------------------------------------------- Slot
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local Slot = {}
----------------------------------------------- Module functions
function Slot.new(slotData, bone)
	if not slotData then error("slotData cannot be nil", 2) end
	if not bone then error("bone cannot be nil", 2) end

	local self = {
		data = slotData,
		bone = bone,
		r = 1, g = 1, b = 1, a = 1,
		attachment = nil,
		attachmentTime = 0,
		attachmentVertices = nil,
		attachmentVerticesCount = 0
	}

	function self:setColor(r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	end

	function self:setAttachment(attachment)
		self.attachment = attachment
		self.attachmentTime = self.bone.skeleton.time
		self.attachmentVerticesCount = 0
	end

	function self:setAttachmentTime(time)
		self.attachmentTime = self.bone.skeleton.time - time
	end

	function self:getAttachmentTime()
		return self.bone.skeleton.time - self.attachmentTime
	end

	function self:setToSetupPose()
		local data = self.data

		self:setColor(data.r, data.g, data.b, data.a)

		local attachment
		if data.attachmentName then 
			attachment = self.bone.skeleton:getAttachment(data.name, data.attachmentName)
		end
		self:setAttachment(attachment)
	end

	self:setToSetupPose()

	return self
end
return Slot
