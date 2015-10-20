----------------------------------------------- AttachmentLoader
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local AttachmentType = require( folder.."AttachmentType" )
local MeshAttachment = require( folder.."MeshAttachment" )
local RegionAttachment = require( folder.."RegionAttachment" )
local BoundingBoxAttachment = require( folder.."BoundingBoxAttachment" )
local SkinnedMeshAttachment = require( folder.."SkinnedMeshAttachment" )

local AttachmentLoader = {}
----------------------------------------------- Module functions
function AttachmentLoader.new()
	local self = {}

	function self:newRegionAttachment(skin, name, path)
		return RegionAttachment.new(name)
	end

	function self:newMeshAttachment(skin, name, path)
		return MeshAttachment.new(name)
	end

	function self:newSkinnedMeshAttachment(skin, name, path)
		return SkinnedMeshAttachment.new(name)
	end

	function self:newBoundingBoxAttachment(skin, name)
		return BoundingBoxAttachment.new(name)
	end

	return self
end
return AttachmentLoader
