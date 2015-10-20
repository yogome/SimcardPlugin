----------------------------------------------- Tester
local director = require( "libs.helpers.director" )
local dictionary = require( "minigames.dictionary" )

local game = director.newScene() 
----------------------------------------------- Variables

----------------------------------------------- Constants
local AMOUNT_SLANT = 50
local HEIGHT_TEXTURE_FLOOR = 128
local WIDTH_TEXTURE_FLOOR = 128
----------------------------------------------- Functions
local function applySlant(rectangle, teamSide)
	rectangle.path.x1 = AMOUNT_SLANT * 0.5 * teamSide
	rectangle.path.x2 = AMOUNT_SLANT * -0.5 * teamSide
	rectangle.path.x4 = AMOUNT_SLANT * 0.5 * teamSide
	rectangle.path.x3 = AMOUNT_SLANT * -0.5 * teamSide
end

local function createCorner(positionX, positionY, teamIndex)
	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	local cornerTexture = display.newRect(positionX, positionY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
	cornerTexture.fill = { type = "image", filename = "images/game/textures/corner_"..teamIndex..".png" }
	return cornerTexture
end

local function createFloor(columns, laneList, teamSide)
	
	local teamIndex = (teamSide + 3) / 2
	local numLanes = #laneList
	local floorWidth = WIDTH_TEXTURE_FLOOR * columns
	local halfFloorWidth = floorWidth * 0.5
	local floorHeight = HEIGHT_TEXTURE_FLOOR * #laneList
	local halfFloorHeight = floorHeight * 0.5
	local centerFillX = ((columns + 1) % 2) * 0.5
	
	local totalSlant = #laneList * AMOUNT_SLANT
	
	local function getPosition(laneIndex)
		local slantOffset = teamSide > 0 and (AMOUNT_SLANT * (#laneList - laneIndex)) or (AMOUNT_SLANT * (laneIndex - 1))
		local centerX = -(totalSlant * 0.5) + slantOffset + AMOUNT_SLANT * 0.5
		local centerY = -(floorHeight * 0.5) + HEIGHT_TEXTURE_FLOOR * (laneIndex - 1) + HEIGHT_TEXTURE_FLOOR * 0.5
		
		return centerX, centerY
	end
	
	local topCenterX, topCenterY = getPosition(0)
	
	local innerTopX = topCenterX + (halfFloorWidth * teamSide)
	local innerTopCorner = createCorner(innerTopX, topCenterY, teamIndex)
	innerTopCorner.anchorX = 1 - (teamIndex - 1)
	innerTopCorner.fill.scaleY = 1
	innerTopCorner.fill.scaleX = -1 * teamSide
	applySlant(innerTopCorner, teamSide)
	laneList[1]:insert(innerTopCorner)
	
	local outerTopX = topCenterX - (halfFloorWidth * teamSide)
	local outerTopCorner = createCorner(outerTopX, topCenterY, teamIndex)
	outerTopCorner.anchorX = teamIndex - 1
	outerTopCorner.fill.scaleY = 1
	outerTopCorner.fill.scaleX = teamSide
	applySlant(outerTopCorner, teamSide)
	laneList[1]:insert(outerTopCorner)
	
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	local topCenterTexture = display.newRect(topCenterX, topCenterY, floorWidth, HEIGHT_TEXTURE_FLOOR)
	topCenterTexture.fill = { type = "image", filename = "images/game/textures/top_"..teamIndex..".png" }
	topCenterTexture.fill.x = centerFillX
	topCenterTexture.fill.scaleY = 1
	topCenterTexture.fill.scaleX = -(1 / columns)
	applySlant(topCenterTexture, teamSide)
	laneList[1]:insert(topCenterTexture)
	
	for laneIndex = 1, #laneList do
		local centerX, centerY = getPosition(laneIndex)
		
		display.setDefault( "textureWrapX", "repeat" )
		display.setDefault( "textureWrapY", "repeat" )
		
		local centerTexture = display.newRect(centerX, centerY, floorWidth, HEIGHT_TEXTURE_FLOOR)
		centerTexture.fill = { type = "image", filename = "images/game/textures/center_"..teamIndex..".png" }
		centerTexture.fill.x = centerFillX
		centerTexture.fill.scaleY = 1
		centerTexture.fill.scaleX = -(1 / columns)
		applySlant(centerTexture, teamSide)
		
		local centerGridTexture = display.newRect(centerX, centerY, floorWidth, HEIGHT_TEXTURE_FLOOR)
		centerGridTexture.fill = { type = "image", filename = "images/game/textures/grid.png" }
		centerGridTexture.fill.x = centerFillX
		centerGridTexture.fill.scaleY = 1
		centerGridTexture.fill.scaleX = -(1 / columns)
		applySlant(centerGridTexture, teamSide)
		
		display.setDefault( "textureWrapX", "clampToEdge" )
		display.setDefault( "textureWrapY", "clampToEdge" )
		
		local innerEdgeX = centerX + (halfFloorWidth * teamSide)
		local innerEdgeTexture = display.newRect(innerEdgeX, centerY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
		innerEdgeTexture.anchorX = 1 - (teamIndex - 1)
		innerEdgeTexture.fill = { type = "image", filename = "images/game/textures/side_"..teamIndex..".png" }
		innerEdgeTexture.fill.scaleY = 1
		innerEdgeTexture.fill.scaleX = -1 * teamSide
		applySlant(innerEdgeTexture, teamSide)
		
		local outerEdgeX = centerX - (halfFloorWidth * teamSide)
		local outerEdgeTexture = display.newRect(outerEdgeX, centerY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
		outerEdgeTexture.anchorX = teamIndex - 1
		outerEdgeTexture.fill = { type = "image", filename = "images/game/textures/side_"..teamIndex..".png" }
		outerEdgeTexture.fill.scaleY = 1
		outerEdgeTexture.fill.scaleX = teamSide
		applySlant(outerEdgeTexture, teamSide)
		
		laneList[laneIndex]:insert(centerTexture)
		laneList[laneIndex]:insert(centerGridTexture)
		laneList[laneIndex]:insert(innerEdgeTexture)
		laneList[laneIndex]:insert(outerEdgeTexture)
	end
	
	local bottomCenterX, bottomCenterY = getPosition(#laneList + 1)
	
	local innerEdgeX = bottomCenterX + (halfFloorWidth * teamSide)
	local innerBottomCorner = createCorner(innerEdgeX, bottomCenterY, teamIndex)
	innerBottomCorner.anchorX = 1 - (teamIndex - 1)
	innerBottomCorner.fill.scaleY = -1
	innerBottomCorner.fill.scaleX = -1 * teamSide
	applySlant(innerBottomCorner, teamSide)
	laneList[numLanes]:insert(innerBottomCorner)
	
	local outerEdgeX = bottomCenterX - (halfFloorWidth * teamSide)
	local outerBottomCorner = createCorner(outerEdgeX, bottomCenterY, teamIndex)
	outerBottomCorner.anchorX = teamIndex - 1
	outerBottomCorner.fill.scaleY = -1
	outerBottomCorner.fill.scaleX = teamSide
	applySlant(outerBottomCorner, teamSide)
	laneList[numLanes]:insert(outerBottomCorner)
	
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )
	
	local topCenterTexture = display.newRect(bottomCenterX, bottomCenterY, floorWidth, HEIGHT_TEXTURE_FLOOR)
	topCenterTexture.fill = { type = "image", filename = "images/game/textures/top_"..teamIndex..".png" }
	topCenterTexture.fill.x = 0.5
	topCenterTexture.fill.scaleY = -1
	topCenterTexture.fill.scaleX = -(1 / columns)
	applySlant(topCenterTexture, teamSide)
	laneList[numLanes]:insert(topCenterTexture)
end

----------------------------------------------- Module functions 
function game:create(event)
	local sceneView = self.view
	
	local columns = 2
	local laneList = {
		[1] = display.newGroup(),
		[2] = display.newGroup(),
		--[3] = display.newGroup(),
		--[4] = display.newGroup(),
	}
	
	for index = 1, #laneList do
		laneList[index].x = display.contentCenterX
		laneList[index].y = display.contentCenterY
		sceneView:insert(laneList[index])
	end
	
	createFloor(columns, laneList, 1)
	
	local centerRect = display.newRect(display.contentCenterX, display.contentCenterY, 10,10)
	sceneView:insert(centerRect)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game


