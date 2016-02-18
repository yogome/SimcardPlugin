------------------------------------------- Extra math
local extramath = {}
------------------------------------------- Caches
local mathDeg = math.deg
local mathRad = math.rad
local mathAtan2 = math.atan2
local mathCos = math.cos
local mathSin = math.sin
------------------------------------------- Functions
function extramath.getFullAngle(x, y)
	local angle = mathDeg(mathAtan2(-x, y))
	return angle
end

function extramath.rotateVertex(vertex, rotation)
	rotation = mathRad(rotation)
	local newX = vertex.x * mathCos(rotation) + vertex.y * mathSin(rotation)
	local newY = vertex.x * mathSin(rotation) + vertex.y * mathCos(rotation)
	
	return unpack({-newX, newY})
end

function extramath.rangesOverlap(x1, x2, y1, y2)
	return x1 <= y2 and y1 <= x2
end
function extramath.isInRadialRange(minNum, maxNum, num)
	minNum = minNum % 360
	maxNum = maxNum % 360
	num = num % 360
	
	if minNum < maxNum then
		return minNum<= num and num <= maxNum
	else
		return (0 <= num and num <= maxNum) or (minNum <= num and num <= 360)
	end
end

function extramath.doLinesIntersect(line1, line2)
	if line1 and line2 then
		local x11 = line1.x1
		local x12 = line1.x2
		local y11 = line1.y1
		local y12 = line1.y2
		
		local x21 = line2.x1
		local x22 = line2.x2
		local y21 = line2.y1
		local y22 = line2.y2
		
		
		local a1 = y12 - y11
		local b1 = x11 - x12--
		local c1 = a1 * x11 + b1 * y11
		
		local a2 = y22 - y21
		local b2 = x21 - x22--
		local c2 = a2 * x21 + b2 * y21
		
		local det = a1 * b2 - a2 * b1
		if det == 0 then
			return false
		else
			local x = (b2 * c1 - b1 * c2) / det
			local y = (a1 * c2 - a2 * c1) / det
			
			return {x = x, y = y}
		end
	end
	return false
end

function extramath.sum(sumTable)
	local total = 0
	for index = 1, #sumTable do
		total = total + sumTable[index]
	end
	return total
end

function extramath.factors(number)
    local factors = {}
 
    for index = 1, number * 0.5 do
        if number % index == 0 then 
            factors[#factors + 1] = index
        end
    end
    factors[#factors + 1] = number
 
    return factors
end

function extramath.smoothVertexList(vertices, smoothLevels)
	smoothLevels = smoothLevels or 1
	local newVertices
	
	for smoothIndex = 1, smoothLevels do
		newVertices = {}
		for index = 1, #vertices, 2 do
			local currentX = vertices[index]
			local currentY = vertices[index + 1]

			local nextX = vertices[index + 2]
			local nextY = vertices[index + 3]
			if index >= #vertices - 1 then
				nextX = vertices[1]
				nextY = vertices[2]
			end

			local newX = (currentX + nextX) * 0.5
			local newY = (currentY + nextY) * 0.5

			newVertices[#newVertices + 1] = currentX
			newVertices[#newVertices + 1] = currentY
			newVertices[#newVertices + 1] = newX
			newVertices[#newVertices + 1] = newY
		end

		for index = 1, #newVertices - 2, 4 do
			local previousX = 0
			local previousY = 0
			if index <= 1 then
				previousX = newVertices[#newVertices - 1]
				previousY = newVertices[#newVertices]
			else
				previousX = newVertices[index - 2]
				previousY = newVertices[index - 1]
			end


			local nextX = newVertices[index + 2]
			local nextY = newVertices[index + 3]

			newVertices[index] = (previousX + nextX + newVertices[index]) / 3
			newVertices[index + 1] = (previousY + nextY + newVertices[index + 1]) / 3
			
			vertices = newVertices
		end
	end
	
	return newVertices
end

return extramath

