------------------------------------------- Stage loader
local path = ...
local folder = path:match("(.-)[^%.]+$")

local extracollision = require(folder.."extracollision")
local extratable = require(folder.."extratable")
local extrajson = require(folder.."extrajson")
local logger = require(folder.."logger")
local physics = require("physics")

local stageloader = {}
------------------------------------------- Variables
local itemLoader
local sceneryData
local backgroundGroup
local sceneryGroup
local itemGroup
local polygonGroup
local foregroundGroup
------------------------------------------- Constants
local GRAVITY_DEFAULT = {0, 32}
local TEXTURE_SIZE = 256
------------------------------------------- Caches
local ioOpen = io.open
local ioClose = io.close
------------------------------------------- Local functions
local function addVertex(polygonObject, x, y, color)
	polygonObject[#polygonObject + 1] = {x = x, y = y}
end

local function reTexturePolygon(polygon, textureFile)
	polygon.textureFile = textureFile
	display.setDefault("textureWrapX", "repeat")
	display.setDefault("textureWrapY", "repeat")
	polygon.image.fill = {type = "image", filename = polygon.textureFile}
	display.setDefault("textureWrapX", "clampToEdge")
	display.setDefault("textureWrapY", "clampToEdge")
	
	local fillXScale = TEXTURE_SIZE / polygon.image.width
	local fillYScale = TEXTURE_SIZE / polygon.image.height
	
	polygon.image.fill.scaleX = fillXScale
	polygon.image.fill.scaleY = fillYScale
	polygon.image.polygon = polygon
end

local function saveBackground(background, textureFile)
	if background[1].x == background[#background].x and background[1].y == background[#background].y then
		if #background > 1 then
			background[#background] = nil
		end
	end
	
	local vertices = {}
	for index = 1, #background do
		local vertex = background[index]
		
		background.xMin = background.xMin < vertex.x and background.xMin or vertex.x
		background.yMin = background.yMin < vertex.y and background.yMin or vertex.y
		
		background.xMax = background.xMax > vertex.x and background.xMax or vertex.x
		background.yMax = background.yMax > vertex.y and background.yMax or vertex.y
	
		vertices[#vertices + 1] = vertex.x
		vertices[#vertices + 1] = vertex.y
	end
	
	background.image = display.newPolygon(background.xMin, background.yMin, vertices)
	background.image.anchorX, background.image.anchorY = 0, 0
	
	background.polygonView:insert(background.image)
	
	reTexturePolygon(background, textureFile)
end

local function savePolygon(polygon, textureFile)
	if polygon[1].x == polygon[#polygon].x and polygon[1].y == polygon[#polygon].y then
		if #polygon > 1 then
			polygon[#polygon] = nil
		end
	end
	
	local vertices = {}
	for index = 1, #polygon do
		local vertex = polygon[index]
		
		polygon.xMin = polygon.xMin < vertex.x and polygon.xMin or vertex.x
		polygon.yMin = polygon.yMin < vertex.y and polygon.yMin or vertex.y
		
		polygon.xMax = polygon.xMax > vertex.x and polygon.xMax or vertex.x
		polygon.yMax = polygon.yMax > vertex.y and polygon.yMax or vertex.y
	
		vertices[#vertices + 1] = vertex.x
		vertices[#vertices + 1] = vertex.y
	end
	
	polygon.image = display.newPolygon(polygon.xMin, polygon.yMin, vertices)
	polygon.image.anchorX, polygon.image.anchorY = 0, 0
	
	polygon.polygonView:insert(polygon.image)
	
	local centerX = (polygon.xMin + polygon.xMax) * 0.5
	local centerY = (polygon.yMin + polygon.yMax) * 0.5
	
	local physicsVertices = {}
	for index = 1, #vertices, 2 do
		physicsVertices[index] = vertices[index] - centerX
		physicsVertices[index + 1] = vertices[index + 1] - centerY
	end
	
	physics.addBody( polygon.image, "static", {
		friction = 0.5,
		bounce = 0,
		chain = physicsVertices,
		connectFirstAndLastChainVertex = true
	})

	reTexturePolygon(polygon, textureFile)
end

local function loadPolygon(polygonData)
	local polygon = {
		["polygonView"] = display.newGroup(),
		["previewObjectList"] = {},
		["xMin"] = math.huge,
		["yMin"] = math.huge,
		["xMax"] = -math.huge,
		["yMax"] = -math.huge,
		["textureFile"] = polygonData.textureFile,
	}
	polygonGroup:insert(polygon.polygonView)
	for vertexIndex = 1, #polygonData do
		addVertex(polygon, polygonData[vertexIndex].x, polygonData[vertexIndex].y)
	end
	savePolygon(polygon, polygon.textureFile)
end

local function loadBackground(backgroundData)
	local background = {
		["polygonView"] = display.newGroup(),
		["previewGroup"] = display.newGroup(),
		["previewObjectList"] = {},
		["xMin"] = math.huge,
		["yMin"] = math.huge,
		["xMax"] = -math.huge,
		["yMax"] = -math.huge,
		["textureFile"] = backgroundData.textureFile,
		["foreground"] = backgroundData.foreground and true
	}
	
	local parent = backgroundData.foreground and foregroundGroup or backgroundGroup
	parent:insert(background.polygonView)
	for vertexIndex = 1, #backgroundData do
		addVertex(background, backgroundData[vertexIndex].x, backgroundData[vertexIndex].y)
	end
	saveBackground(background, background.textureFile)
	
	local image = background.image
	image.fill.x = backgroundData.fillX or image.fill.x
	image.fill.y = backgroundData.fillY or image.fill.y
	if backgroundData.fillScaleX and backgroundData.fillScaleX ~= image.fill.scaleX then image.fill.scaleX = backgroundData.fillScaleX end
	if backgroundData.fillScaleY and backgroundData.fillScaleY ~= image.fill.scaleY then image.fill.scaleY = backgroundData.fillScaleY end
	image.fill.rotation = backgroundData.fillRotation or image.fill.rotation
	
	image.r = backgroundData.r or 1
	image.g = backgroundData.g or 1
	image.b = backgroundData.b or 1
	image.alpha = backgroundData.alpha or image.alpha
	
	image:setFillColor(image.r, image.g, image.b)
end

local function addScenery(data)
	local scenery = display.newImage(data.image)
	scenery.anchorX = data.anchorX
	scenery.anchorY = data.anchorY
	scenery.x = data.x or 0
	scenery.y = data.y or 0
	scenery.xScale = data.xScale or 1
	scenery.yScale = data.yScale or 1
	scenery.rotation = data.rotation or 0
	scenery.alpha = data.alpha or 1
	
	sceneryGroup:insert(scenery)
end

local function createRadialGravityField(gravityFieldData)
	gravityFieldData = gravityFieldData or {}
	
	local gravityField = extracollision.newRadialGravityField(gravityFieldData)
	gravityField.x = gravityFieldData.x
	gravityField.y = gravityFieldData.y
	backgroundGroup:insert(gravityField)
end

local function addItem(positionX, positionY, itemIndex)
	local item = itemLoader({
		id = itemIndex,
		x = positionX,
		y = positionY,
	})
	
	if item then
		item.x, item.y = positionX, positionY
		itemGroup:insert(item)
	end
end

------------------------------------------- Module functions
function stageloader.build(options)
	local filename = options.filename
	
	itemLoader = options.itemLoader
	sceneryData = options.sceneryData or {}
	
	backgroundGroup = options.backgroundGroup
	sceneryGroup = options.sceneryGroup
	itemGroup = options.itemGroup
	polygonGroup = options.polygonGroup
	foregroundGroup = options.foregroundGroup
	
	local camera = options.camera
	
	if not (itemLoader and "function" == type(itemLoader)) then
		error("itemLoader must be a function", 3)
	end
	
	if not (backgroundGroup and "table" == type(backgroundGroup) and backgroundGroup.insert and "function" == type(backgroundGroup.insert)) then
		error("backgroundGroup must be a display group", 3)
	end
	
	if not (sceneryGroup and "table" == type(sceneryGroup) and sceneryGroup.insert and "function" == type(sceneryGroup.insert)) then
		error("sceneryGroup must be a display group", 3)
	end
	
	if not (itemGroup and "table" == type(itemGroup) and itemGroup.insert and "function" == type(itemGroup.insert)) then
		error("itemGroup must be a display group", 3)
	end
	
	if not (polygonGroup and "table" == type(polygonGroup) and polygonGroup.insert and "function" == type(polygonGroup.insert)) then
		error("polygonGroup must be a display group", 3)
	end
	
	if not (foregroundGroup and "table" == type(foregroundGroup) and foregroundGroup.insert and "function" == type(foregroundGroup.insert)) then
		error("foregroundGroup must be a display group", 3)
	end
	
	local function buildStage(data)
		if data then
			local levelData = extrajson.decodeFixed(data)
			if levelData then
				local newStage = {}

				local counts = {
					["polygons"] = 0,
					["backgrounds"] = 0,
					["scenery"] = 0,
					["gravity"] = 0,
					["items"] = 0,
				}
				
				if levelData.polygonList then
					for index = 1, #levelData.polygonList do
						loadPolygon(levelData.polygonList[index])
					end
					counts["polygons"] = #levelData.polygonList
				end
				
				if levelData.backgroundList then
					for index = 1, #levelData.backgroundList do
						loadBackground(levelData.backgroundList[index])
					end
					counts["backgrounds"] = #levelData.backgroundList
				end
				
				if levelData.sceneryList then
					for index = 1, #levelData.sceneryList do
						local sceneryData = levelData.sceneryList[index]
						addScenery(sceneryData.sceneryIndex, sceneryData)
					end
					counts["scenery"] = #levelData.sceneryList
				end

				if levelData.cameraBounds and not extratable.isEmpty(levelData.cameraBounds) then
					if camera and camera.setBounds then
						camera:setBounds(unpack(levelData.cameraBounds))
					else
						logger.error("[Stage builder] No camera to set bounds.")
					end
				end
				
				local currentGravity = levelData.gravity or GRAVITY_DEFAULT
				physics.setGravity(unpack(currentGravity))

				if levelData.radialGravityFieldList then
					for index = 1, #levelData.radialGravityFieldList do
						local gravityFieldData = levelData.radialGravityFieldList[index]
						createRadialGravityField(gravityFieldData)
					end
					counts["gravity"] = #levelData.radialGravityFieldList
				end

				if levelData.itemList then
					for index = 1, #levelData.itemList do
						local itemData = levelData.itemList[index]
						addItem(itemData.x, itemData.y, itemData.itemIndex)
					end
					counts["items"] = #levelData.itemList
				end

				logger.log("[Stage loader] "..tostring(filename).." was built.")
				return newStage
			end
		end
	end
	
	local path = system.pathForFile(filename)
	local data = ""
	if path then
		if pcall(function()
			local fileObject = ioOpen(path, "r")
			if fileObject then
				data = fileObject:read("*a")
				ioClose( fileObject )
			end
		end) then
			logger.log("[Stage loader] Loaded "..tostring(filename).." succesfully.")
			return buildStage(data)
		else
			logger.error("[Stage loader] "..tostring(filename).." could not be opened.")
		end
	else
		logger.error("[Stage loader] "..tostring(filename).." could not be opened.")
	end
end

return stageloader
