----------------------------------------------- Bone
local modulePath = ... 
local folder = modulePath:match("(.-)[^%.]+$")

local Bone = {}
----------------------------------------------- Caches
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
----------------------------------------------- Module functions
function Bone.new(data, skeleton, parent)
	if not data then error("data cannot be nil", 2) end
	if not skeleton then error("skeleton cannot be nil", 2) end

	local self = {
		data = data,
		skeleton = skeleton,
		parent = parent,
		x = 0, y = 0,
		rotation = 0, rotationIK = 0,
		scaleX = 1, scaleY = 1,
		flipX = false, flipY = false,
		m00 = 0, m01 = 0, worldX = 0, -- a b x
		m10 = 0, m11 = 0, worldY = 0, -- c d y
		worldRotation = 0,
		worldScaleX = 1, worldScaleY = 1,
		worldFlipX = false, worldFlipY = false,
	}

	function self:updateWorldTransform(flipX, flipY)
		local parent = self.parent
		if parent then
			self.worldX = self.x * parent.m00 + self.y * parent.m01 + parent.worldX
			self.worldY = self.x * parent.m10 + self.y * parent.m11 + parent.worldY
			if self.data.inheritScale then
				 self.worldScaleX = parent.worldScaleX * self.scaleX
				 self.worldScaleY = parent.worldScaleY * self.scaleY
			else
				 self.worldScaleX = self.scaleX
				 self.worldScaleY = self.scaleY
			end
			if self.data.inheritRotation then
				 self.worldRotation = parent.worldRotation + self.rotationIK
			else
				 self.worldRotation = self.rotationIK
			end
			self.worldFlipX = parent.worldFlipX ~= self.flipX
			self.worldFlipY = parent.worldFlipY ~= self.flipY
		else
			local skeletonFlipX, skeletonFlipY = self.skeleton.flipX, self.skeleton.flipY
			
			self.worldX = skeletonFlipX and -self.x or self.x
			self.worldY = skeletonFlipY and -self.y or self.y

			self.worldScaleX = self.scaleX
			self.worldScaleY = self.scaleY
			self.worldRotation = self.rotationIK
			self.worldFlipX = skeletonFlipX ~= self.flipX
			self.worldFlipY = skeletonFlipY ~= self.flipY
		end
		local radians = mathRad(self.worldRotation)
		local cosine = mathCos(radians)
		local sine = mathSin(radians)
		if self.worldFlipX then
			self.m00 = -cosine * self.worldScaleX
			self.m01 = sine * self.worldScaleY
		else
			self.m00 = cosine * self.worldScaleX
			self.m01 = -sine * self.worldScaleY
		end
		if self.worldFlipY then
			self.m10 = -sine * self.worldScaleX
			self.m11 = -cosine * self.worldScaleY
		else
			self.m10 = sine * self.worldScaleX
			self.m11 = cosine * self.worldScaleY
		end
	end

	function self:setToSetupPose()
		local data = self.data
		self.x = data.x
		self.y = data.y
		self.rotation = data.rotation
		self.rotationIK = self.rotation
		self.scaleX = data.scaleX
		self.scaleY = data.scaleY
		self.flipX = data.flipX
		self.flipY = data.flipY
	end

	function self:worldToLocal(worldCoords)
		local dx = worldCoords[1] - self.worldX
		local dy = worldCoords[2] - self.worldY
		local m00 = self.m00
		local m10 = self.m10
		local m01 = self.m01
		local m11 = self.m11
		if self.worldFlipX ~= self.worldFlipY then
			m00 = -m00
			m11 = -m11
		end
		local invDet = 1 / (m00 * m11 - m01 * m10)
		worldCoords[1] = dx * m00 * invDet - dy * m01 * invDet
		worldCoords[2] = dy * m11 * invDet - dx * m10 * invDet
	end

	function self:localToWorld(localCoords)
		local localX = localCoords[1]
		local localY = localCoords[2]
		localCoords[1] = localX * self.m00 + localY * self.m01 + self.worldX
		localCoords[2] = localX * self.m10 + localY * self.m11 + self.worldY
	end

	self:setToSetupPose()
	return self
end
return Bone
