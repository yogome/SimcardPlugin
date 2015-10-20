----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extratable = require( folder.."extratable" )
local extrastring = require( folder.."extrastring" )

local spine = {}

spine.utils = require( folder.."spineRuntime.utils" )
spine.SkeletonJson = require( folder.."spineRuntime.SkeletonJson" )
spine.SkeletonData = require( folder.."spineRuntime.SkeletonData" )
spine.BoneData = require( folder.."spineRuntime.BoneData" )
spine.SlotData = require( folder.."spineRuntime.SlotData" )
spine.IkConstraintData = require( folder.."spineRuntime.IkConstraintData" )
spine.Skin = require( folder.."spineRuntime.Skin" )
spine.RegionAttachment = require( folder.."spineRuntime.RegionAttachment" )
spine.MeshAttachment = require( folder.."spineRuntime.MeshAttachment" )
spine.SkinnedMeshAttachment = require( folder.."spineRuntime.SkinnedMeshAttachment" )
spine.Skeleton = require( folder.."spineRuntime.Skeleton" )
spine.Bone = require( folder.."spineRuntime.Bone" )
spine.Slot = require( folder.."spineRuntime.Slot" )
spine.IkConstraint = require( folder.."spineRuntime.IkConstraint" )
spine.AttachmentType = require( folder.."spineRuntime.AttachmentType" )
spine.AttachmentLoader = require( folder.."spineRuntime.AttachmentLoader" )
spine.Animation = require( folder.."spineRuntime.Animation" )
spine.AnimationStateData = require( folder.."spineRuntime.AnimationStateData" )
spine.AnimationState = require( folder.."spineRuntime.AnimationState" )
spine.EventData = require( folder.."spineRuntime.EventData" )
spine.Event = require( folder.."spineRuntime.Event" )
spine.SkeletonBounds = require( folder.."spineRuntime.SkeletonBounds" )
spine.BlendMode = require( folder.."spineRuntime.BlendMode" )
----------------------------------------------- Variables
local initialized
local spines
local removeGroup
----------------------------------------------- Caches
local tableRemove = table.remove
----------------------------------------------- Constants
local PATH_SPINES = string.gsub(folder,"[%.]","/").."spines/"
local SPINE_DEFAULT = PATH_SPINES.."Barril/ObjetoBarril.json"
local SPEED_ANIMATION_DEFAULT = 1
----------------------------------------------- Functions
local function initialize() 
	if not initialized then
		initialized = true
		
		spines = {}
		
		removeGroup = display.newGroup()
		removeGroup.isVisible = false
		display.getCurrentStage():insert(removeGroup)
		
		local lastTime = 0
		local currentTime = 0
		local delta = 0
		
		Runtime:addEventListener("enterFrame", function (event)
			currentTime = event.time * 0.0001 -- Milliseconds
			
			delta = currentTime - lastTime
			lastTime = currentTime

			for index = #spines, 1, -1 do
				if spines[index] and spines[index].object then
					if spines[index].object.removeFlag then
						display.remove(spines[index].object)
						tableRemove(spines, index)
					else
						spines[index].animationState:update(delta * spines[index].animationSpeed)
						spines[index].animationState:apply(spines[index].skeleton)
						spines[index].skeleton:updateWorldTransform()
					end
				end
			end
			
		end)
	end
end

local function removeSpine(event)
	local spineObject = event.target
	spine.remove(spineObject)
end
----------------------------------------------- Module functions
function spine.new(filename, options)
	filename = filename or SPINE_DEFAULT
	options = options or {}
	
	local scale = options.scale or 1
	local folder = options.folder or string.sub(filename:match("(.-)[^%.]+$"), 1, -2):match("(.-)[^%/]+$")
	local debugSkeleton = options.debugSkeleton
	local animationSpeed = options.animationSpeed or SPEED_ANIMATION_DEFAULT
	local defaultMix = options.defaultMix or 0.1
	local animationEvents = options.animationEvents or {}
	-- animationEvents = {["TALK"] = {onStart = function() end, onEnd = function() end, onComplete = function(event) end, onEvent = function(event) end}}

	local skeletonJson = spine.SkeletonJson.new()
	skeletonJson.scale = scale
	
	local skeletonData = skeletonJson:readSkeletonDataFile(filename)

	local skeleton = spine.Skeleton.new(skeletonData)
	skeleton.debug = debugSkeleton
	skeleton.debugAabb = debugSkeleton
	
	function skeleton:createImage(attachment)
		return display.newImage(folder..attachment.name..".png")
	end
	
	skeleton:setToSetupPose()
	skeleton:setSlotsToSetupPose()
	skeleton:setBonesToSetupPose()
	
	local spineObject = skeleton.group -- Actual object returned
	spineObject.isSpine = true
		
	local animationStateData = spine.AnimationStateData.new(skeletonData)
	animationStateData.defaultMix = defaultMix
	
	local animationState = spine.AnimationState.new(animationStateData)
	
	animationState.onStart = function(trackIndex)
		local eventFunctions = animationEvents[animationState:getCurrent(trackIndex).animation.name]
		if eventFunctions and eventFunctions.onStart then
			eventFunctions.onStart({target = spineObject})
		end
	end
	animationState.onEnd = function(trackIndex)
		local eventFunctions = animationEvents[animationState:getCurrent(trackIndex).animation.name]
		if eventFunctions and eventFunctions.onEnd then
			eventFunctions.onEnd({target = spineObject})
		end
	end
	animationState.onComplete = function(trackIndex, loopCount)
		local eventFunctions = animationEvents[animationState:getCurrent(trackIndex).animation.name]
		if eventFunctions and eventFunctions.onComplete then
			eventFunctions.onComplete({loopCount = loopCount, target = spineObject})
		end
	end
	animationState.onEvent = function(trackIndex, event)
		local eventFunctions = animationEvents[animationState:getCurrent(trackIndex).animation.name]
		if eventFunctions and eventFunctions.onEvent then
			event.target = spineObject
			eventFunctions.onEvent(event)
		end
	end
	
	spineObject.skeleton = skeleton
	spineObject.animationState = animationState
	spineObject.animationStateData = animationStateData

	spines[#spines + 1] = {
		object = spineObject,
		animationState = animationState,
		skeleton = skeleton,
		animationSpeed = animationSpeed,
	}
	
	local storedTimeScale = spineObject.animationState.timeScale
	function spineObject:setPaused(paused)
		storedTimeScale = self.animationState.timeScale > 0 and self.animationState.timeScale or storedTimeScale
		self.animationState.timeScale = paused and 0 or storedTimeScale
	end
	
	function spineObject:setAnimation(animationName, options)
		options = options or {}
		local loop = options.loop
		local fade = options.fade or 0
		
		local currentAnimationState = self.animationState:getCurrent(0)
		if currentAnimationState then
			animationStateData:setMix(currentAnimationState.animation.name, animationName, fade)
		end
	
		animationState:setAnimationByName(0, animationName, loop)
	end
	
	function spineObject:getCustomSkin()
		if self.skeleton.skin then
			local customSkin = self.skeleton.data:findSkin("custom")
			
			local skinIndex = #self.skeleton.data.skins + 1
			if customSkin then
				skinIndex = extratable.searchIndex(self.skeleton.data.skins, customSkin)
			end
			
			local newCustomSkin = extratable.deepcopy(self.skeleton.skin)
			newCustomSkin.name = "custom"
			if self.skeleton and self.skeleton.data and self.skeleton.data.skins then
				self.skeleton.data.skins[skinIndex] = newCustomSkin
			else
				logger.error("[Spine] Custom skin could not be created")
			end
			
			return newCustomSkin
		else
			logger.error("[Spine] Custom skin cannot be created if there is no previous skin")
		end
	end
	
	function spineObject:setAttachmentSkin(attachmentName, skinFolder)
		local customSkin = self:getCustomSkin()
		
		local foundAttachment = false
		for index, value in pairs(customSkin.attachments) do
			local matchResult = string.match(index, attachmentName)
			if matchResult then
				local attachmentSplit = extrastring.split(index, ":")
				local attachmentName = attachmentSplit[2]
				customSkin.attachments[index][3].name = skinFolder.."/"..attachmentName
				
				foundAttachment = true
			end
		end
		
		if not foundAttachment then
			logger.log([[[Spine] did not find any attachment named "]]..attachmentName..[["]])
		end
		self:setSkin("custom")
	end
	
	function spineObject:setCustomAttachment(attachmentName, filename)
		if filename and "string" == type(filename) and string.len(filename) >= string.len(".png") then
			if string.sub(filename, -4, -1) == ".png" then
				local attachmentFilename = string.sub(filename, 1, -5)
				
				local rootPath = ""
				local folders = extrastring.split(folder, "/")
				for index = 1, #folders do
					rootPath = rootPath.."../"
				end
				
				local foundAttachment = false
				local customSkin = self:getCustomSkin()
				for index, value in pairs(customSkin.attachments) do
					local matchResult = string.match(index, attachmentName)
					if matchResult then
						customSkin.attachments[index][3].name = rootPath..attachmentFilename
						foundAttachment = true
					end
				end
				
				if not foundAttachment then
					logger.log([[[Spine] did not find any attachment named "]]..tostring(attachmentName)..[["]])
				end
				self:setSkin("custom")
			else
				logger.log([[[Spine] filename "]]..tostring(filename)..[[" must be a PNG]])
			end
		else
			logger.log([[[Spine] Failed to load "]]..tostring(filename)..[["]])
		end
	end
	
	function spineObject:setSkin(skinName)
		self.skeleton:setSkin(skinName)
	end
	
	function spineObject:setSlotSkin(slotName, skinName)
		local newSkin
		if skinName then
			newSkin = self.skeleton.data:findSkin(skinName)
			if not newSkin then error("Skin not found = " .. skinName, 2) end
			if self.skeleton.skin then
				-- Attach all attachments from the new skin if the corresponding attachment from the old skin is currently attached.
				for attachmentName, attachmentData in pairs(self.skeleton.skin.attachments) do
					local attachment = attachmentData[3]
					local slotIndex = attachmentData[1]
					local slot = self.skeleton.slots[slotIndex]
					if slot.attachment == attachment and slot.data.name == slotName then
						local name = attachmentData[2]
						local newAttachment = newSkin:getAttachment(slotIndex, name)
						if newAttachment then
							newAttachment.skinName = skinName
							slot:setAttachment(newAttachment)
							self.skeleton.skin.attachments[attachmentName] = newSkin.attachments[attachmentName]
						end
					end
				end
			end
		end
	end
	
	function spineObject:getSkins()
		local skinNames = {}
		for index = 1, #self.skeleton.data.skins do
			skinNames[index] = self.skeleton.data.skins[index].name
		end
		return skinNames
	end
	
	function spineObject:getAnimations()
		local animationNames = {}
		for index = 1, #self.skeleton.data.animations do
			animationNames[index] = self.skeleton.data.animations[index].name
		end
		return animationNames
	end
	
	function spineObject:getSlots()
		local slotNames = {}
		for index = 1, #self.skeleton.data.slots do
			slotNames[index] = self.skeleton.data.slots[index].name
		end
		return slotNames
	end
	
	spineObject.skeleton:updateWorldTransform()
	
	spineObject:addEventListener("finalize", removeSpine)
	
	return spineObject
end

function spine.remove(spineObject)
	if spineObject and "table" == type(spineObject) and spineObject.isSpine then
		spineObject.removeFlag = true
		removeGroup:insert(spineObject)
	end
end

initialize()

return spine
