----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")

local spine = {}

spine.utils = require( folder.."spine-lua.utils" )
spine.SkeletonJson = require( folder.."spine-lua.SkeletonJson" )
spine.SkeletonData = require( folder.."spine-lua.SkeletonData" )
spine.BoneData = require( folder.."spine-lua.BoneData" )
spine.SlotData = require( folder.."spine-lua.SlotData" )
spine.Skin = require( folder.."spine-lua.Skin" )
spine.RegionAttachment = require( folder.."spine-lua.RegionAttachment" )
spine.MeshAttachment = require( folder.."spine-lua.MeshAttachment" )
spine.SkinnedMeshAttachment = require( folder.."spine-lua.SkinnedMeshAttachment" )
spine.Skeleton = require( folder.."spine-lua.Skeleton" )
spine.Bone = require( folder.."spine-lua.Bone" )
spine.Slot = require( folder.."spine-lua.Slot" )
spine.AttachmentType = require( folder.."spine-lua.AttachmentType" )
spine.AttachmentLoader = require( folder.."spine-lua.AttachmentLoader" )
spine.Animation = require( folder.."spine-lua.Animation" )
spine.AnimationStateData = require( folder.."spine-lua.AnimationStateData" )
spine.AnimationState = require( folder.."spine-lua.AnimationState" )
spine.EventData = require( folder.."spine-lua.EventData" )
spine.Event = require( folder.."spine-lua.Event" )
spine.SkeletonBounds = require( folder.."spine-lua.SkeletonBounds" )

----------------------------------------------- Functions
spine.utils.readFile = function (fileName, base)
	if not base then base = system.ResourceDirectory end
	local path = system.pathForFile(fileName, base)
	local file = io.open(path, "r")
	if not file then return nil end
	local contents = file:read("*a")
	io.close(file)
	return contents
end
 
local json = require "json"
spine.utils.readJSON = function (text)
	return json.decode(text)
end
 
spine.Skeleton.failed = {} -- Placeholder for an image that failed to load.
 
spine.Skeleton.new_super = spine.Skeleton.new
function spine.Skeleton.new (skeletonData, group)
	local self = spine.Skeleton.new_super(skeletonData)
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
	function self:updateWorldTransform ()
		updateWorldTransform_super(self)

		local images = self.images
		local skeletonR, skeletonG, skeletonB, skeletonA = self.r, self.g, self.b, self.a
		for i,slot in ipairs(self.drawOrder) do
			local image = images[slot]
			local attachment = slot.attachment
			if not attachment then -- Attachment is gone, remove the image.
				if image then
					display.remove(image)
					images[slot] = nil
				end
			elseif attachment.type == spine.AttachmentType.region then
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
						image = spine.Skeleton.failed
					end
					if slot.data.additiveBlending then image.blendMode = "add" end
					images[slot] = image
				end
				-- Position image based on attachment and bone.
				if image ~= spine.Skeleton.failed then
					local flipX, flipY = ((self.flipX and -1) or 1), ((self.flipY and -1) or 1)

					local x = slot.bone.worldX + attachment.x * slot.bone.m00 + attachment.y * slot.bone.m01
					local y = -(slot.bone.worldY + attachment.x * slot.bone.m10 + attachment.y * slot.bone.m11)
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
					local rotation = math.abs(attachment.rotation) % 180
					if (rotation == 90) then
						xScale = xScale * slot.bone.worldScaleY
						yScale = yScale * slot.bone.worldScaleX
					else
						xScale = xScale * slot.bone.worldScaleX
						yScale = yScale * slot.bone.worldScaleY
					end
					if not image.lastScaleX then
						image.xScale, image.yScale = xScale, yScale
						image.lastScaleX, image.lastScaleY = xScale, yScale
					elseif image.lastScaleX ~= xScale or image.lastScaleY ~= yScale then
						image:scale(xScale / image.lastScaleX, yScale / image.lastScaleY)
						image.lastScaleX, image.lastScaleY = xScale, yScale
					end

					rotation = -(slot.bone.worldRotation + attachment.rotation) * flipX * flipY
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
			for i,bone in ipairs(self.bones) do
				if not bone.line then
					bone.line = display.newLine(0, 0, bone.data.length, 0)
					bone.line:setStrokeColor(1, 0, 0)
				end
				bone.line.x = bone.worldX
				bone.line.y = -bone.worldY
				bone.line.rotation = -bone.worldRotation
				if self.flipX then
					bone.line.xScale = -1
					bone.line.rotation = -bone.line.rotation
				else
					bone.line.xScale = 1
				end
				if self.flipY then
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
				self.bounds = spine.SkeletonBounds.new()
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

function spine.newImageSheetOptions(atlasFile)
	local extrafile = require( folder.."extrafile" )
	local atlasContents = extrafile.getLines(atlasFile)
	
	for index = 1, #atlasContents do
		atlasContents[index] = atlasContents[index]:gsub("%s+", "")
	end
	
	local totalFrames = (#atlasContents - 7) / 7
	
	local frames = {}
	for index = 1, totalFrames do
		local startLine = 7 + (index - 1 ) * 7
	
		local positionString = atlasContents[startLine + 2]
		local sizeString = atlasContents[startLine + 3]
		local originalSizeString = atlasContents[startLine + 4]
		local offsetString = atlasContents[startLine + 5]

		local x,y = positionString:match("%:(.+)%,(.+)")
		local width, height = sizeString:match("%:(.+)%,(.+)")
		local sourceWidth, sourceHeight = originalSizeString:match("%:(.+)%,(.+)")
		local offsetX, offsetY = offsetString:match("%:(.+)%,(.+)")
		
		local frameData = {
			x = x,
			y = y,
			width = width,
			height = height,
			sourceX = offsetX,
			sourceY = offsetY,
			sourceWidth = sourceWidth,
			sourceHeight = sourceHeight
		}
		
		frames[#frames + 1] = frameData
	end
	
	local sheetOptions = {
		frames = frames,
	}
	
	return sheetOptions
end

return spine

