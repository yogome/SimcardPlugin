----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger")
local screen = require(folder.."screen")
local extratable = require(folder.."extratable")
local extrastring = require(folder.."extrastring")

local spine = {
	utils = require(folder.."spineRuntime.utils"),
	SkeletonJson = require(folder.."spineRuntime.SkeletonJson"),
	SkeletonData = require(folder.."spineRuntime.SkeletonData"),
	BoneData = require(folder.."spineRuntime.BoneData"),
	SlotData = require(folder.."spineRuntime.SlotData"),
	IkConstraintData = require(folder.."spineRuntime.IkConstraintData"),
	Skin = require(folder.."spineRuntime.Skin"),
	RegionAttachment = require(folder.."spineRuntime.RegionAttachment"),
	MeshAttachment = require(folder.."spineRuntime.MeshAttachment"),
	SkinnedMeshAttachment = require(folder.."spineRuntime.SkinnedMeshAttachment"),
	Skeleton = require(folder.."spineRuntime.Skeleton"),
	Bone = require(folder.."spineRuntime.Bone"),
	Slot = require(folder.."spineRuntime.Slot"),
	IkConstraint = require(folder.."spineRuntime.IkConstraint"),
	AttachmentType = require(folder.."spineRuntime.AttachmentType"),
	AttachmentLoader = require(folder.."spineRuntime.AttachmentLoader"),
	Animation = require(folder.."spineRuntime.Animation"),
	AnimationStateData = require(folder.."spineRuntime.AnimationStateData"),
	AnimationState = require(folder.."spineRuntime.AnimationState"),
	EventData = require(folder.."spineRuntime.EventData"),
	Event = require(folder.."spineRuntime.Event"),
	SkeletonBounds = require(folder.."spineRuntime.SkeletonBounds"),
	BlendMode = require(folder.."spineRuntime.BlendMode"),
	
	globalScale = 1,
}
----------------------------------------------- Variables
local initialized
local spines
local removeGroup
local fileCache
----------------------------------------------- Caches
local tableRemove = table.remove
local stringSub = string.sub
local stringMatch = string.match
local stringGsub = string.gsub
local stringLen = string.len
local type = type
local pairs = pairs
----------------------------------------------- Constants
local PATH_SPINES = stringGsub(folder,"[%.]","/").."spines/"
local SPINE_DEFAULT = PATH_SPINES.."Barril/ObjetoBarril.json"
local SPEED_ANIMATION_DEFAULT = 1
----------------------------------------------- Functions
local function createImage(self, attachment)
	local imageGroup = screen.newColorGroup()
	local image = attachment.isCustom and display.newImage(attachment.name..".png") or display.newImage(self.folder..attachment.name..".png")

	imageGroup:insert(image)
	imageGroup.insertmage = image
	
	self.group.groups[attachment] = imageGroup

	return imageGroup
end

local function setAnimation(self, animationName, options)
	options = options or {}
	local loop = options.loop
	local fade = options.fade or 0

	local currentAnimationState = self.animationState:getCurrent(0)
	if currentAnimationState then
		self.animationStateData:setMix(currentAnimationState.animation.name, animationName, fade)
	end

	self.animationState:setAnimationByName(0, animationName, loop)
end

local function setSkin(self, skinName)
	self.skeleton:setSkin(skinName)
end

local function getSkins(self)
	local skinNames = {}
	for index = 1, #self.skeleton.data.skins do
		skinNames[index] = self.skeleton.data.skins[index].name
	end
	return skinNames
end

local function getAnimations(self)
	local animationNames = {}
	for index = 1, #self.skeleton.data.animations do
		animationNames[index] = self.skeleton.data.animations[index].name
	end
	return animationNames
end

local function getSlots(self)
	local slotNames = {}
	for index = 1, #self.skeleton.data.slots do
		slotNames[index] = self.skeleton.data.slots[index].name
	end
	return slotNames
end

local function setSlotSkin(self, slotName, skinName)
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

local function setCustomAttachment(self, attachmentName, filename)
	if filename and "string" == type(filename) and stringLen(filename) >= stringLen(".png") then
		if stringSub(filename, -4, -1) == ".png" then
			local attachmentFilename = stringSub(filename, 1, -5)

			local foundAttachment = false
			local customSkin = self:getCustomSkin()
			for index, value in pairs(customSkin.attachments) do
				local matchResult = stringMatch(index, attachmentName)
				if matchResult then
					customSkin.attachments[index][3].name = attachmentFilename
					customSkin.attachments[index][3].isCustom = true
					foundAttachment = true
				end
			end

			if not foundAttachment then
				logger.log([[did not find any attachment named "]]..tostring(attachmentName)..[["]])
			end
			self:setSkin("custom")
		else
			logger.log([[filename "]]..tostring(filename)..[[" must be a PNG]])
		end
	else
		logger.log([[Failed to load "]]..tostring(filename)..[["]])
	end
end

local function getCurrentAnimation(self)
	return self.animationState.tracks[0].animation
end

local function setAttachmentSkin(self, attachmentName, skinFolder)
	local customSkin = self:getCustomSkin()

	local foundAttachment = false
	for index, value in pairs(customSkin.attachments) do
		local matchResult = stringMatch(index, attachmentName)
		if matchResult then
			local attachmentSplit = extrastring.split(index, ":")
			local attachmentName = attachmentSplit[2]
			customSkin.attachments[index][3].name = skinFolder.."/"..attachmentName

			foundAttachment = true
		end
	end

	if not foundAttachment then
		logger.log([[did not find any attachment named "]]..attachmentName..[["]])
	end
	self:setSkin("custom")
end

local function getCustomSkin(self)
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
			logger.error("Custom skin could not be created")
		end

		return newCustomSkin
	else
		logger.error("Custom skin cannot be created if there is no previous skin")
	end
end

local function getAnimationDuration(self, animationName)
	local animation = self.skeleton.data:findAnimation(animationName)
	if animation then
		return animation.duration
	end
end

local function initialize() 
	if not initialized then
		initialized = true
		
		spines = {}
		fileCache = {}
		
		removeGroup = display.newGroup()
		removeGroup.isVisible = false
		display.getCurrentStage():insert(removeGroup)
		
		local lastTime = 0
		local currentTime = 0
		local delta = 0
		
		Runtime:addEventListener("memoryWarning", function(event)
			fileCache = {}
			collectgarbage()
		end)
		
		Runtime:addEventListener("enterFrame", function (event)
			currentTime = event.time * 0.0001 -- Milliseconds
			
			delta = currentTime - lastTime
			lastTime = currentTime

			for index = #spines, 1, -1 do
				if spines[index] and spines[index].object then
					if spines[index].object.removeFlag then
						display.remove(spines[index].object)
						tableRemove(spines, index)
					elseif spines[index].object.isVisible then
						spines[index].animationState:update(delta * spines[index].object.animationSpeed * spine.globalScale)
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
	
	local debugSkeleton = options.debugSkeleton
	local animationSpeed = options.animationSpeed or SPEED_ANIMATION_DEFAULT
	local defaultMix = options.defaultMix or 0.1
	local animationEvents = options.animationEvents or {}
	-- animationEvents = {["TALK"] = {onStart = function() end, onEnd = function() end, onComplete = function(event) end, onEvent = function(event) end}}

	local skeletonJson = spine.SkeletonJson.new()
	
	local skeletonData = fileCache[filename] or skeletonJson:readSkeletonDataFile(filename)
	fileCache[filename] = skeletonData

	local skeleton = spine.Skeleton.new(skeletonData)
	skeleton.debug = debugSkeleton
	skeleton.debugAabb = debugSkeleton
	skeleton.flipX = not not options.flipX
	skeleton.flipY = not not options.flipY
	
	local scale = options.scale or 1
		
	skeleton.folder = options.folder or stringSub(filename:match("(.-)[^%.]+$"), 1, -2):match("(.-)[^%/]+$")
	skeleton.createImage = createImage
	
	skeleton:setToSetupPose()
	skeleton:setSlotsToSetupPose()
	skeleton:setBonesToSetupPose()
	
	local spineObject = skeleton.group -- Actual object returned
	spineObject.groups = {}
	spineObject.isSpine = true
	spineObject.xScale = scale
	spineObject.yScale = scale
		
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
	spineObject.animationSpeed = animationSpeed

	spines[#spines + 1] = {
		object = spineObject,
		animationState = animationState,
		skeleton = skeleton,
	}
	
	local storedTimeScale = spineObject.animationState.timeScale
	function spineObject:setPaused(paused)
		storedTimeScale = self.animationState.timeScale > 0 and self.animationState.timeScale or storedTimeScale
		self.animationState.timeScale = paused and 0 or storedTimeScale
	end
	
	spineObject.getAnimationDuration = getAnimationDuration
	spineObject.setAnimation = setAnimation
	spineObject.getCustomSkin = getCustomSkin
	spineObject.setAttachmentSkin = setAttachmentSkin
	spineObject.getCurrentAnimation = getCurrentAnimation
	spineObject.setCustomAttachment = setCustomAttachment
	spineObject.setSkin = setSkin
	spineObject.setSlotSkin = setSlotSkin
	spineObject.getSkins = getSkins
	spineObject.getAnimations = getAnimations
	spineObject.getSlots = getSlots
	
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
