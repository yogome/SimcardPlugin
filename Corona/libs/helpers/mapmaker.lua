local widget = require("widget")

local mapmaker = {}

local mathCeil = math.ceil

function mapmaker.newScrollMap(options)
	options = options or {}
	
	local direction = options.direction or "horizontal"
	local images = options.images or {height = 1024, width = 1024}
	
	local map = display.newGroup()
	map.x, map.y = display.screenOriginX, display.screenOriginY
	
	local mapView = widget.newScrollView({
		x = 0,
		y = 0,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		scrollWidth = 100,
		scrollHeight = 100,
		hideBackground = true, 
		verticalScrollDisabled = direction == "horizontal",
		horizontalScrollDisabled = direction == "vertical",
		isBounceEnabled = false,
	})
	
	mapView.anchorX, mapView.anchorY = 0, 0
	map:insert(mapView)
	
	local responsiveLenght = direction == "horizontal" and display.viewableContentHeight or display.viewableContentWidth
	local scrollLenght = direction == "horizontal" and display.viewableContentWidth or display.viewableContentHeight
	map.responsiveScale = responsiveLenght / (direction == "horizontal" and images.height or images.width)
	
	local incrementIndex = direction == "horizontal" and "x" or "y"
	local incrementDelta = direction == "horizontal" and images.width or images.height
	incrementDelta = incrementDelta * map.responsiveScale
	
	local tiles = {}
	for index = 1, #images do
		local mapTile = display.newRect(0, 0, images.width, images.height)
		mapTile.xScale, mapTile.yScale = map.responsiveScale, map.responsiveScale
		mapTile.anchorX, mapTile.anchorY = 0, 0
		mapTile[incrementIndex] = (index - 1) * incrementDelta
		
		mapTile:setFillColor(0.5)
		mapTile.strokeWidth = 6
		mapTile.stroke = {0, 1}
		
		tiles[index] = mapTile
		mapView:insert(mapTile)
	end
	
	local scaledDeltaReciprocal = 1 / incrementDelta
	local extraIndex = mathCeil(scrollLenght / incrementDelta)
	local currentScroll = 0
	local minIndex = 1
	local maxIndex = 1
	local function runtimeUpdate()
		currentScroll = -mapView._view[incrementIndex]
		
		minIndex = mathCeil(currentScroll * scaledDeltaReciprocal + 0.0001)
		maxIndex = minIndex + extraIndex
		
		for index = 1, #tiles do
			if index >= minIndex and index <= maxIndex then
				if not tiles[index].set then
					tiles[index].set = true
					tiles[index].fill = {type = "image", filename = images[index]}
				end
			else
				tiles[index].fill = {0}
				tiles[index].set = false
			end
		end
	end
	
	Runtime:addEventListener("enterFrame", runtimeUpdate)
	map:addEventListener("finalize", function(event)
		Runtime:removeEventListener("enterFrame", runtimeUpdate)
	end)
	
	return map
end

return mapmaker
