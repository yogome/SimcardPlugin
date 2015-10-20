----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")

local MeshAttachment = require( folder.."MeshAttachment" )
local SkinnedMeshAttachment = require( folder.."SkinnedMeshAttachment" )
local RegionAttachment = require( folder.."RegionAttachment" )
local BoundingBoxAttachment = require( folder.."BoundingBoxAttachment" )

local AttachmentLoader = {}
---------------------------------------------- Functions
function AttachmentLoader.new ()
	local self = {}

	function self:newRegionAttachment (skin, name, path)
		return RegionAttachment.new(name)
	end

	function self:newMeshAttachment (skin, name, path)
		return MeshAttachment.new(name)
	end

	function self:newSkinningMeshAttachment (skin, name, path)
		return SkinnedMeshAttachment.new(name)
	end

	function self:newBoundingBoxAttachment (skin, name)
		return BoundingBoxAttachment.new(name)
	end

	return self
end
return AttachmentLoader
