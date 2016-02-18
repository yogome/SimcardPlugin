--------------------------------------------- Transforms - 3D and 2D transforms
local transforms = {}
--------------------------------------------- Caches
local mathSin = math.sin
local mathCos = math.cos
--------------------------------------------- Constants
local focalLength = 1000
--------------------------------------------- Local functions
local function createPoint3D(x, y, z)
	return {x = x, y = y, z = z}
end

local function createPoint2D(x, y, depth, scaleFactor)
	return {x = x, y = y, depth = depth, scaleFactor = scaleFactor}
end

local function rotatePoints(points, rotation)
	local transformedPoints = {}
	local sx = mathSin(rotation.x)
	local cx = mathCos(rotation.x)
	local sy = mathSin(rotation.y)
	local cy = mathCos(rotation.y)
	local sz = mathSin(rotation.z)
	local cz = mathCos(rotation.z)
	local x, y, z, xy, xz, yx, yz, zx, zy, scaleFactor

	local index = #points

	while index > 0 do
		x = points[index].x
		y = points[index].y
		z = points[index].z

		-- X rotation
		xy = cx * y - sx * z
		xz = sx * y + cx * z
		-- Y rotation
		yz = cy * xz - sy * x
		yx = sy * xz + cy * x
		-- Z rotation
		zx = cz * yx - sz * xy
		zy = sz * yx + cz * xy
		
		scaleFactor = focalLength / (focalLength + yz)
		x = zx * scaleFactor
		y = zy * scaleFactor
		z = yz

		transformedPoints[index] = {x = x, y = y, z = z, w = scaleFactor}
		index = index - 1
	end
	
	return transformedPoints
end

local function updateTransform(object, points, rotation, postRotation)
	
	local transformedPoints = rotatePoints(points, rotation)
	if postRotation and (postRotation.x ~= 0 or postRotation.y ~= 0 or postRotation.z ~= 0) then
		transformedPoints = rotatePoints(transformedPoints, postRotation)
	end
	
	object.path.x1 = transformedPoints[1].x - points[1].x
	object.path.y1 = transformedPoints[1].y - points[1].y
	
	object.path.x2 = transformedPoints[2].x - points[2].x
	object.path.y2 = transformedPoints[2].y - points[2].y
	
	object.path.x3 = transformedPoints[3].x - points[3].x
	object.path.y3 = transformedPoints[3].y - points[3].y
	
	object.path.x4 = transformedPoints[4].x - points[4].x
	object.path.y4 = transformedPoints[4].y - points[4].y
	
	return transformedPoints
end
--------------------------------------------- Module functions
function transforms.add3DRotation(displayObject)
	if displayObject and displayObject.path and displayObject.path.x1 then
		
		displayObject.anchorX = 0.5
		displayObject.anchorY = 0.5
		
		local rotation = {
			x = 0, y = 0, z = displayObject.rotation,
		}
		
		local postRotation = {
			x = 0, y = 0, z = 0,
		}
		
		local points
		local function recalculateDimensions()
			local hW = displayObject.width * 0.5 * displayObject.xScale
			local hH = displayObject.height * 0.5 * displayObject.yScale
			
			points = {
				[1] = createPoint3D(-hW, -hH, 0),
				[2] = createPoint3D(-hW, hH, 0),
				[3] = createPoint3D(hW, hH, 0),
				[4] = createPoint3D(hW, -hH, 0),
			}
		end
		recalculateDimensions()
		
		displayObject.rotation = 0
		local oldMetatable = getmetatable(displayObject)
		setmetatable(displayObject, {
			__index = function(self, index)
				if index == "xRotation" then
					return rotation.x
				elseif index == "xRotationPost" then
					return postRotation.x
				elseif index == "yRotation" then
					return rotation.y
				elseif index == "yRotationPost" then
					return postRotation.y
				elseif index == "rotation" or index == "zRotation" then
					return rotation.z
				elseif index == "zRotationPost" then
					return postRotation.z
				elseif index == "anchorX" or index == "anchorY" then
					return 0.5
				else
					return oldMetatable.__index(self, index)
				end
			end,
			__newindex = function(self, index, value)
				if index == "xRotation" then
					rotation.x = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "xRotationPost" then
					postRotation.x = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "yRotation" then
					rotation.y = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "yRotationPost" then
					postRotation.y = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "rotation" or index == "zRotation" then
					rotation.z = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "zRotationPost" then
					postRotation.z = value
					updateTransform(self, points, rotation, postRotation)
				elseif index == "anchorX" or index == "anchorY" then
					-- Do nothing, just intercept
				else
					oldMetatable.__newindex(self, index, value)
					
					if index == "width" or index == "height" or index == "xScale" or index == "yScale" then
						recalculateDimensions()
					end
				end
			end,
		})
		
		displayObject.rotation = rotation.z
		
		function displayObject:setRotation(x, y, z)
			rotation = {x = x, y = y, z = z}
			updateTransform(self, points, rotation, postRotation)
		end
		
		function displayObject:setPostRotation(x, y, z)
			postRotation = {x = x, y = y, z = z}
			updateTransform(self, points, rotation, postRotation)
		end
	end
end

return transforms
