----------------------------------------------- Screen helper
local screen = {}

----------------------------------------------- Caches
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenOriginX = display.screenOriginX
local screenOriginY = display.screenOriginY
local viewableContentWidth = display.viewableContentWidth
local viewableContentHeight = display.viewableContentHeight
----------------------------------------------- Functions

----------------------------------------------- Module functions
function screen.leftEdge()
	return screenOriginX
end

function screen.rightEdge()
	return screenOriginX + viewableContentWidth
end

function screen.topEdge()
	return screenOriginY
end

function screen.bottomEdge()
	return screenOriginY + viewableContentHeight
end

function screen.getPositionX(ratio)
	return screenOriginX + (viewableContentWidth * ratio)
end

function screen.getPositionY(ratio)
	return screenOriginY + (viewableContentHeight * ratio)
end

function screen.getPosition(ratioX, ratioY)
	return screenOriginX + (viewableContentWidth * ratioX), screenOriginY + (viewableContentHeight * ratioY)
end

function screen.getHalfWidth(displayObject)
	return displayObject.contentWidth * 0.5
end

function screen.getHalfHeight(displayObject)
	return displayObject.contentHeight * 0.5
end

function screen.toRelative(displayObject, ratioX, ratioY)
	displayObject.x, displayObject.y = screen.getPosition(ratioX, ratioY)
end

function screen.toCenter(displayObject)
	displayObject.x, displayObject.y = centerX, centerY
end

function screen.getContentRotation(displayObject)
	local function getContentRotation(object, pastRotation)
		pastRotation = pastRotation + object.rotation or 0
		if object.parent then
			return getContentRotation(object.parent, pastRotation)
		else
			return pastRotation
		end
	end
	
	if displayObject and displayObject.rotation and displayObject.parent then
		return getContentRotation(displayObject, 0)
	elseif displayObject and displayObject.rotation then
		return displayObject.rotation
	end
end

function screen.newColorGroup()
	local group = display.newGroup()
	function group:setFillColor(...)
		for index = 1, self.numChildren do
			local child = self[index]
			if child and child.setFillColor then
				child:setFillColor(...)
			end
		end
	end
	return group
end

function screen.newGrid(rows, columns, spacing, width)
	spacing = spacing or 100
	rows = rows or 1
	columns = columns or 1
	width = width or 2
	
	local grid = screen.newColorGroup()
	
	local totalWidth = (columns - 1) * spacing
	local totalHeight = (rows - 1) * spacing
	
	local startX = -totalWidth * 0.5
	local startY = -totalHeight * 0.5
	
	for index = 1, rows do
		display.newRect(grid, 0, startY + ((index - 1) * spacing), totalWidth + spacing, width)
	end
	
	for index = 1, columns do
		display.newRect(grid, startX + ((index - 1) * spacing), 0, width, totalHeight + spacing)
	end
	
	return grid
end

return screen
