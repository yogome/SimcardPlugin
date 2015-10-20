----------------------------------------------- SkeletonData
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local SkeletonData = {}
----------------------------------------------- Module functions
function SkeletonData.new()
	local self = {
		version = 0, hash = 0,
		width = 0, height = 0,
		bones = {},
		slots = {},
		slotNameIndices = {},
		skins = {},
		events = {},
		animations = {},
		ikConstraints = {},
		defaultSkin = nil
	}

	function self:findBone(boneName)
		if not boneName then error("boneName cannot be nil.", 2) end
		for i,bone in ipairs(self.bones) do
			if bone.name == boneName then return bone end
		end
		return nil
	end

	function self:findBoneIndex(boneName)
		if not boneName then error("boneName cannot be nil.", 2) end
		for i,bone in ipairs(self.bones) do
			if bone.name == boneName then return i end
		end
		return -1
	end

	function self:findSlot(slotName)
		if not slotName then error("slotName cannot be nil.", 2) end
		for i,slot in ipairs(self.slots) do
			if slot.name == slotName then return slot end
		end
		return nil
	end

	function self:findSlotIndex(slotName)
		if not slotName then error("slotName cannot be nil.", 2) end
		return self.slotNameIndices[slotName] or -1
	end

	function self:findSkin(skinName)
		if not skinName then error("skinName cannot be nil.", 2) end
		for index = 1, #self.skins do
			if self.skins[index].name == skinName then return self.skins[index] end
		end
		return nil
	end

	function self:findEvent(eventName)
		if not eventName then error("eventName cannot be nil.", 2) end
		for i,event in ipairs(self.events) do
			if event.name == eventName then return event end
		end
		return nil
	end

	function self:findAnimation(animationName)
		if not animationName then error("animationName cannot be nil.", 2) end
		for i,animation in ipairs(self.animations) do
			if animation.name == animationName then return animation end
		end
		return nil
	end

	function self:findIkConstraint(ikConstraintName)
		if not ikConstraintName then error("ikConstraintName cannot be nil.", 2) end
		for i,ikConstraint in ipairs(self.ikConstraints) do
			if ikConstraint.name == ikConstraintName then return ikConstraint end
		end
		return nil
	end

	return self
end
return SkeletonData
