----------------------------------------------- IkConstraint
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local IkConstraint = {}
----------------------------------------------- Caches
local mathAtan2 = math.atan2
local mathPi = math.pi
local mathAcos = math.acos
local mathSin = math.sin
----------------------------------------------- Module functions
function IkConstraint.new(data, skeleton)
	if not data then error("data cannot be nil", 2) end
	if not skeleton then error("skeleton cannot be nil", 2) end

	local self = {
		data = data,
		skeleton = skeleton,
		bones = {},
		target = nil,
		bendDirection = data.bendDirection,
		mix = data.mix
	}

	function self:apply()
		local target = self.target
		local bones = self.bones
		local boneCount = #bones
		if boneCount == 1 then
			IkConstraint.apply1(bones[1], target.worldX, target.worldY, self.mix)
		elseif boneCount == 2 then
			IkConstraint.apply2(bones[1], bones[2], target.worldX, target.worldY, self.bendDirection, self.mix)
		end
	end

	for index = 1, #data.bones do --i,boneData in ipairs(data.bones) do
		self.bones[#self.bones + 1] = skeleton:findBone(data.bones[index].name)
	end
	self.target = skeleton:findBone(data.target.name)

	return self
end

local radDeg = 180 / mathPi
local degRad = mathPi / 180

function IkConstraint.apply1(bone, targetX, targetY, alpha)
	local parentRotation
	if not bone.data.inheritRotation or not bone.parent then
		parentRotation = 0
	else
		parentRotation = bone.parent.worldRotation
	end
	local rotation = bone.rotation
	local rotationIK = mathAtan2(targetY - bone.worldY, targetX - bone.worldX) * radDeg
	if bone.worldFlipX ~= bone.worldFlipY then
		rotationIK = -rotationIK
	end
	rotationIK = rotationIK - parentRotation
	bone.rotationIK = rotation + (rotationIK - rotation) * alpha
end

local temp = {}

function IkConstraint.apply2(parent, child, targetX, targetY, bendDirection, alpha)
	local childRotation = child.rotation
	local parentRotation = parent.rotation
	if not alpha then
		child.rotationIK = childRotation
		parent.rotationIK = parentRotation
		return
	end
	local positionX, positionY
	local tempPosition = temp
	local parentParent = parent.parent
	if parentParent then
		tempPosition[1] = targetX
		tempPosition[2] = targetY
		parentParent:worldToLocal(tempPosition)
		targetX = (tempPosition[1] - parent.x) * parentParent.worldScaleX
		targetY = (tempPosition[2] - parent.y) * parentParent.worldScaleY
	else
		targetX = targetX - parent.x
		targetY = targetY - parent.y
	end
	if child.parent == parent then
		positionX = child.x
		positionY = child.y
	else
		tempPosition[1] = child.x
		tempPosition[2] = child.y
		child.parent:localToWorld(tempPosition)
		parent:worldToLocal(tempPosition)
		positionX = tempPosition[1]
		positionY = tempPosition[2]
	end
	local childX = positionX * parent.worldScaleX
	local childY = positionY * parent.worldScaleY
	local offset = mathAtan2(childY, childX)
	local len1 = (childX * childX + childY * childY) ^ 0.5
	local len2 = child.data.length * child.worldScaleX
	local cosDenom = 2 * len1 * len2
	if cosDenom < 0.0001 then
		child.rotationIK = childRotation + (mathAtan2(targetY, targetX) * radDeg - parentRotation - childRotation) * alpha
		return
	end
	local cosine = (targetX * targetX + targetY * targetY - len1 * len1 - len2 * len2) / cosDenom
	if cosine < -1 then
		cosine = -1
	elseif cosine > 1 then
		cosine = 1
	end
	local childAngle = mathAcos(cosine) * bendDirection
	local adjacent = len1 + len2 * cosine
	local opposite = len2 * mathSin(childAngle)
	local parentAngle = mathAtan2(targetY * adjacent - targetX * opposite, targetX * adjacent + targetY * opposite)
	local rotation = (parentAngle - offset) * radDeg - parentRotation
	if rotation > 180 then
		rotation = rotation - 360
	elseif rotation < -180 then
		rotation = rotation + 360
	end
	parent.rotationIK = parentRotation + rotation * alpha
	rotation = (childAngle + offset) * radDeg - childRotation
	if rotation > 180 then
		rotation = rotation - 360
	elseif rotation < -180 then
		rotation = rotation + 360
	end
	child.rotationIK = childRotation + (rotation + parent.worldRotation - child.parent.worldRotation) * alpha
end

return IkConstraint
