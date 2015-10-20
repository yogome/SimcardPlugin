----------------------------------------------- Skeleton
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local Bone = require( folder.."Bone" )
local Slot = require( folder.."Slot" )
local utils = require( folder.."utils" )
local BlendMode = require( folder.."BlendMode" )
local IkConstraint = require( folder.."IkConstraint" )
local AttachmentType = require( folder.."AttachmentType" )
local SkeletonBounds = require( folder.."SkeletonBounds" )
local AttachmentLoader = require( folder.."AttachmentLoader" )

local Skeleton = {
	failed = {} -- Placeholder for an image that failed to load. 
}
----------------------------------------------- Module functions
function Skeleton.new(skeletonData)
	if not skeletonData then error("skeletonData cannot be nil", 2) end

	local self = {
		data = skeletonData,
		bones = {},
		slots = {},
		slotsByName = {},
		drawOrder = {},
		ikConstraints = {},
		r = 1, g = 1, b = 1, a = 1,
		skin = nil,
		flipX = false, flipY = false,
		time = 0,
		x = 0, y = 0
	}

	-- Caches information about bones and IK constraints. Must be called if bones or IK constraints are added or removed.
	function self:updateCache()
		self.boneCache = {}
		local boneCache = self.boneCache
		local ikConstraints = self.ikConstraints
		local ikConstraintsCount = #ikConstraints

		local arrayCount = ikConstraintsCount + 1
		while #boneCache < arrayCount do
			boneCache[#boneCache + 1] = {}
		end

		local nonIkBones = boneCache[1]

		for index = 1, #self.bones do
			local current = self.bones[index]
			local continueOuter
			repeat
				for ii,ikConstraint in ipairs(ikConstraints) do
					local parent = ikConstraint.bones[0]
					local child = ikConstraint.bones[#ikConstraint.bones - 1]
					while true do
						if current == child then
							table.insert(boneCache[ii], self.bones[index])
							table.insert(boneCache[ii + 1], self.bones[index])
							ii = ikConstraintsCount
							continueOuter = true
							break
						end
						if child == parent then break end
						child = child.parent
					end
				end
				if continueOuter then break end
				current = current.parent
			until not current
			nonIkBones[#nonIkBones + 1] = self.bones[index]
		end
	end

	-- Updates the world transform for each bone and applies IK constraints.
	function self:updateWorldTransform()
		local bones = self.bones
		for index = 1, #self.bones do
			self.bones[index].rotationIK = self.bones[index].rotation
		end
		local boneCache = self.boneCache
		local ikConstraints = self.ikConstraints
		local i = 1
		local last = #boneCache
		while true do
			for indexCache = 1, #boneCache[i] do
				boneCache[i][indexCache]:updateWorldTransform()
			end
			if i == last then break end
			ikConstraints[i]:apply()
			i = i + 1
		end
	end

	function self:setToSetupPose()
		self:setBonesToSetupPose()
		self:setSlotsToSetupPose()
	end

	function self:setBonesToSetupPose()
		for index = 1, #self.bones do
			self.bones[index]:setToSetupPose()
		end

		for i,ikConstraint in ipairs(self.ikConstraints) do
			ikConstraint.bendDirection = ikConstraint.data.bendDirection
			ikConstraint.mix = ikConstraint.data.mix
		end
	end

	function self:setSlotsToSetupPose()
		for i,slot in ipairs(self.slots) do
			self.drawOrder[i] = slot
			slot:setToSetupPose()
		end
	end

	function self:getRootBone()
		return self.bones[1]
	end

	function self:findBone(boneName)
		if not boneName then error("boneName cannot be nil.", 2) end
		for i,bone in ipairs(self.bones) do
			if bone.data.name == boneName then return bone end
		end
		return nil
	end

	function self:findSlot(slotName)
		if not slotName then error("slotName cannot be nil.", 2) end
		return self.slotsByName[slotName]
	end

	-- Sets the skin used to look up attachments before looking in the {@link SkeletonData#getDefaultSkin() default skin}. 
	-- Attachments from the new skin are attached if the corresponding attachment from the old skin was attached. If there was 
	-- no old skin, each slot's setup mode attachment is attached from the new skin.
	function self:setSkin(skinName)
		local newSkin
		if skinName then
			newSkin = self.data:findSkin(skinName)
			if not newSkin then error("Skin not found = " .. skinName, 2) end
			if self.skin then
				-- Attach all attachments from the new skin if the corresponding attachment from the old skin is currently attached.
				for k,v in pairs(self.skin.attachments) do
					local attachment = v[3]
					local slotIndex = v[1]
					local slot = self.slots[slotIndex]
					if slot.attachment == attachment then
						local name = v[2]
						local newAttachment = newSkin:getAttachment(slotIndex, name)
						if newAttachment then slot:setAttachment(newAttachment) end
					end
				end
			else
				-- No previous skin, attach setup pose attachments.
				for index = 1, #self.slots do
					local name = self.slots[index].data.attachmentName
					if name then
						local attachment = newSkin:getAttachment(index, name)
						if attachment then self.slots[index]:setAttachment(attachment) end
					end
				end
			end
		end
		self.skin = newSkin
	end

	function self:getAttachment(slotName, attachmentName)
		if not slotName then error("slotName cannot be nil.", 2) end
		if not attachmentName then error("attachmentName cannot be nil.", 2) end
		local slotIndex = skeletonData.slotNameIndices[slotName]
		if slotIndex == -1 then error("Slot not found = " .. slotName, 2) end
		if self.skin then
			local attachment = self.skin:getAttachment(slotIndex, attachmentName)
			if attachment then return attachment end
		end
		if self.data.defaultSkin then
			return self.data.defaultSkin:getAttachment(slotIndex, attachmentName)
		end
		return nil
	end

	function self:setAttachment(slotName, attachmentName)
		if not slotName then error("slotName cannot be nil.", 2) end
		for i,slot in ipairs(self.slots) do
			if slot.data.name == slotName then
				if not attachmentName then 
					slot:setAttachment(nil)
				else
					slot:setAttachment(self:getAttachment(slotName, attachmentName))
				end
				return
			end
		end
		error("Slot not found = " .. slotName, 2)
	end

	function self:update(delta)
		self.time = self.time + delta
	end

	function self:setColor(r, g, b, a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	end

	for index = 1, #skeletonData.bones do
		local parent
		if skeletonData.bones[index].parent then parent = self.bones[utils.indexOf(skeletonData.bones, skeletonData.bones[index].parent)] end
		self.bones[#self.bones + 1] = Bone.new(skeletonData.bones[index], self, parent)
	end
	
	for i,slotData in ipairs(skeletonData.slots) do
		local bone = self.bones[utils.indexOf(skeletonData.bones, slotData.boneData)]
		local slot = Slot.new(slotData, bone)
		table.insert(self.slots, slot)
		self.slotsByName[slot.data.name] = slot
		table.insert(self.drawOrder, slot)
	end

	for index = 1, #skeletonData.ikConstraints do
		self.ikConstraints[#self.ikConstraints + 1] = IkConstraint.new(skeletonData.ikConstraints[index], self)
	end
	
	self:updateCache()

	return self
end

Skeleton.new_super = Skeleton.new
function Skeleton.new(skeletonData, group)
	local self = Skeleton.new_super(skeletonData)
	self.group = group or display.newGroup()

	self.images = {}

	-- Customizes where images are found.
	function self:createImage (attachment)
		return display.newImage(attachment.name .. ".png")
	end

	-- Customizes what happens when an image changes, return false to recreate the image.
	function self:modifyImage (attachment)
		return false
	end

	-- updateWorldTransform positions images.
	local updateWorldTransform_super = self.updateWorldTransform
	function self:updateWorldTransform()
		updateWorldTransform_super(self)

		local images = self.images
		local skeletonR, skeletonG, skeletonB, skeletonA = self.r, self.g, self.b, self.a
		for index = 1, #self.drawOrder do
			local slot = self.drawOrder[index]
			
			local image = images[slot]
			local attachment = slot.attachment
			if not attachment then -- Attachment is gone, remove the image.
				if image then
					display.remove(image)
					images[slot] = nil
				end
			elseif attachment.type == AttachmentType.region then
				if image and image.attachment ~= attachment then -- Attachment image has changed.
					if self:modifyImage(image, attachment) then
						image.lastR, image.lastA = nil, nil
						image.attachment = attachment
					else -- If not modified, remove the image and it will be recreated.
						display.remove(image)
						images[slot] = nil
						image = nil
					end
				end
				if not image then -- Create new image.
					image = self:createImage(attachment)
					if image then
						image.attachment = attachment
						image.anchorX = 0.5
						image.anchorY = 0.5
						image.width = attachment.width
						image.height = attachment.height
					else
						print("Error creating image: " .. attachment.name)
						image = Skeleton.failed
					end
					if slot.data.blendMode == BlendMode.normal then
						image.blendMode = "normal"
					elseif slot.data.blendMode == BlendMode.additive then
						image.blendMode = "add"
					elseif slot.data.blendMode == BlendMode.multiply then
						image.blendMode = "multiply"
					elseif slot.data.blendMode == BlendMode.screen then
						image.blendMode = "screen"
					end
					images[slot] = image
				end
				-- Position image based on attachment and bone.
				if image ~= Skeleton.failed then
					local bone = slot.bone
					local flipX, flipY = ((bone.worldFlipX and -1) or 1), ((bone.worldFlipY and -1) or 1)

					local x = bone.worldX + attachment.x * bone.m00 + attachment.y * bone.m01
					local y = -(bone.worldY + attachment.x * bone.m10 + attachment.y * bone.m11)
					if not image.lastX then
						image.x, image.y = x, y
						image.lastX, image.lastY = x, y
					elseif image.lastX ~= x or image.lastY ~= y then
						image:translate(x - image.lastX, y - image.lastY)
						image.lastX, image.lastY = x, y
					end

					local xScale = attachment.scaleX * flipX
					local yScale = attachment.scaleY * flipY
					-- Fix scaling when attachment is rotated 90 or -90.
					-- Math.abs replacement
					local rotation = (attachment.rotation >= 0 and attachment.rotation or -attachment.rotation) % 180
					xScale = xScale * bone.worldScaleY
					yScale = yScale * bone.worldScaleX
						
					if not image.lastScaleX then
						image.xScale, image.yScale = xScale, yScale
						image.lastScaleX, image.lastScaleY = xScale, yScale
					elseif image.lastScaleX ~= xScale or image.lastScaleY ~= yScale then
						image:scale(xScale / image.lastScaleX, yScale / image.lastScaleY)
						image.lastScaleX, image.lastScaleY = xScale, yScale
					end

					rotation = -(bone.worldRotation + attachment.rotation) * flipX * flipY
					if not image.lastRotation then
						image.rotation = rotation
						image.lastRotation = rotation
					elseif rotation ~= image.lastRotation then
						image:rotate(rotation - image.lastRotation)
						image.lastRotation = rotation
					end

					local r, g, b = skeletonR * slot.r, skeletonG * slot.g, skeletonB * slot.b
					if image.lastR ~= r or image.lastG ~= g or image.lastB ~= b or not image.lastR then
						image:setFillColor(r, g, b)
						image.lastR, image.lastG, image.lastB = r, g, b
					end
					local a = skeletonA * slot.a
					if a and (image.lastA ~= a or not image.lastA) then
						image.lastA = a
						image.alpha = image.lastA -- 0-1 range, unlike RGB.
					end
					
					self.group:insert(image)
				end
			end
		end

		if self.debug then
			for index = 1, #self.bones do
				local bone = self.bones[index]
				
				if not bone.line then
					bone.line = display.newLine(0, 0, bone.data.length, 0)
					bone.line:setStrokeColor(1, 0, 0)
				end
				bone.line.x = bone.worldX
				bone.line.y = -bone.worldY
				bone.line.rotation = -bone.worldRotation
				if bone.worldFlipX then
					bone.line.xScale = -1
					bone.line.rotation = -bone.line.rotation
				else
					bone.line.xScale = 1
				end
				if bone.worldFlipY then
					bone.line.yScale = -1
					bone.line.rotation = -bone.line.rotation
				else
					bone.line.yScale = 1
				end
				self.group:insert(bone.line)

				if not bone.circle then
					bone.circle = display.newCircle(0, 0, 3)
					bone.circle:setFillColor(0, 1, 0)
				end
				bone.circle.x = bone.worldX
				bone.circle.y = -bone.worldY
				self.group:insert(bone.circle)
			end
		end

		if self.debugAabb then
			if not self.bounds then
				self.bounds = SkeletonBounds.new()
				self.boundsRect = display.newRect(self.group, 0, 0, 0, 0)
				self.boundsRect:setFillColor(0, 0, 0, 0)
				self.boundsRect.strokeWidth = 1
				self.boundsRect:setStrokeColor(0, 1, 0, 1)
			end
			self.bounds:update(self, true)
			local width = self.bounds:getWidth()
			local height = self.bounds:getHeight()
			self.boundsRect.x = self.bounds.minX + width / 2
			self.boundsRect.y = -self.bounds.minY - height / 2
			self.boundsRect.width = width
			self.boundsRect.height = height
			self.group:insert(self.boundsRect)
		end
	end
	return self
end

return Skeleton

