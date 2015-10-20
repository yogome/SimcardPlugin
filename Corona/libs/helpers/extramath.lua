------------------------------------------- Extra math
local extramath = {}
------------------------------------------- Caches
local mathDeg = math.deg
local mathAtan2 = math.atan2
------------------------------------------- Functions
function extramath.getFullAngle(x, y)
	local angle = mathDeg(mathAtan2(-x, y))
	return angle
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

