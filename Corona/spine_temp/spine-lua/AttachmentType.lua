----------------------------------------------- Spine runtimes
local path = ...
local folder = path:match("(.-)[^%.]+$")

local AttachmentType = {
	region = 0,
	boundingbox = 1,
	mesh = 2,
	skinnedmesh = 3
}
return AttachmentType
