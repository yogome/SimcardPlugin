----------------------------------------------- Game helper
local director = require("libs.helpers.director") 
local sound = require ("libs.helpers.sound")

local helper = {}

---------------------------------------------- Constants
local HEIGHT_LANE = 76
local HEIGHT_TEXTURE_FLOOR = HEIGHT_LANE
local WIDTH_TEXTURE_FLOOR = 128
local AMOUNT_SLANT = 40
local doorWidth = 512
local openTime = 400
local closeTime = 600

local SCALE_HAND = 1.25

local WORLDS_PATH = {
	[1] = "world01",
	[2] = "world02",
	[3] = "world03"
}
---------------------------------------------- Functions
local function getDoors()
	local doors = display.newGroup()
	
	local doorScale = (display.actualContentWidth * 0.5) / doorWidth
	local doorScaleX = doorScale
	local doorScaleY = doorScale
	
	local rightClosedX = display.contentCenterX
	local rightOpenX = display.screenOriginX + display.viewableContentWidth
	
	local leftClosedX = display.contentCenterX
	local leftOpenX = display.screenOriginX
	
	local rightDoor = display.newImage( "images/game/cleandoor1.png",true )
	rightDoor.anchorX = 0
	rightDoor.x = rightOpenX
	rightDoor.y = display.contentCenterY
	rightDoor.xScale = doorScaleX
	rightDoor.yScale = doorScaleY
	doors:insert(rightDoor)
	
	local leftDoor = display.newImage( "images/game/cleandoor2.png",true )
	leftDoor.anchorX = 1
	leftDoor.x = leftOpenX
	leftDoor.y = display.contentCenterY
	leftDoor.xScale = doorScaleX
	leftDoor.yScale = doorScaleY
	doors:insert(leftDoor)
	
	function doors:open(onComplete)
		self:toFront()
		transition.to( leftDoor, {delay = 500, time = openTime, x = leftOpenX, transition=easing.outQuad} )
		transition.to( rightDoor, {delay = 500, time = openTime, x = rightOpenX, transition=easing.outQuad, onStart = function()
			--sounds.doorOpen()
		end, onComplete = onComplete})
	end
	
	function doors:close(options)
		options = options or {}
		local onComplete = options.onComplete
		self:toFront()
		transition.to( leftDoor, {time = closeTime, x = leftClosedX, transition=easing.outQuad} )
		transition.to( rightDoor, {time = closeTime, x = rightClosedX, transition=easing.outQuad, onComplete = function()
			sound.play("ironShellShield")
			if onComplete then
				onComplete()
			end
		end})
	end
	
	return doors
end

local function applySlant(rectangle, teamSide)
	rectangle.path.x1 = AMOUNT_SLANT * 0.5 * -teamSide
	rectangle.path.x2 = AMOUNT_SLANT * -0.5 * -teamSide
	rectangle.path.x4 = AMOUNT_SLANT * 0.5 * -teamSide
	rectangle.path.x3 = AMOUNT_SLANT * -0.5 * -teamSide
end

local function createCorner(positionX, positionY, teamIndex, worldIndex, texturePath)
	display.setDefault( "textureWrapX", "clampToEdge" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	local cornerTexture = display.newRect(positionX, positionY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
	cornerTexture.fill = { type = "image", filename = texturePath .."corner_"..teamIndex..".png" }
	return cornerTexture
end
---------------------------------------------- Module functions
function helper.createFloor(columns, laneList, teamSide, worldIndex, positionX, positionY, texturePath)
	positionX = positionX or 0
	positionY = positionY or 0
	local teamIndex = (teamSide + 3) / 2
	local numLanes = #laneList
	local floorWidth = WIDTH_TEXTURE_FLOOR * columns
	local halfFloorWidth = floorWidth * 0.5
	local floorHeight = HEIGHT_TEXTURE_FLOOR * #laneList
	local halfFloorHeight = floorHeight * 0.5
	local centerFillX = ((columns + 1) % 2) * 0.5
	
	local totalSlant = #laneList * AMOUNT_SLANT
	
	local function getPosition(laneIndex)
		local extraY = (laneIndex <= 0 and -HEIGHT_TEXTURE_FLOOR) or (laneIndex > #laneList and HEIGHT_TEXTURE_FLOOR) or 0
		local slantOffset = teamSide < 0 and (AMOUNT_SLANT * (#laneList - laneIndex)) or (AMOUNT_SLANT * (laneIndex - 1))
		local centerX = -(totalSlant * 0.5) + slantOffset + AMOUNT_SLANT * 0.5
		local centerY = extraY---(floorHeight * 0.5) + HEIGHT_TEXTURE_FLOOR * (laneIndex - 1) + HEIGHT_TEXTURE_FLOOR * 0.5
		
		return centerX + positionX, centerY + positionY
	end
	
	local topCenterX, topCenterY = getPosition(0)
	
	local innerTopX = topCenterX + (halfFloorWidth * teamSide)
	local innerTopCorner = createCorner(innerTopX, topCenterY, teamIndex, worldIndex, texturePath)
	innerTopCorner.anchorX = 1 - (teamIndex - 1)
	innerTopCorner.fill.scaleY = 1
	innerTopCorner.fill.scaleX = -1 * teamSide
	applySlant(innerTopCorner, teamSide)
	laneList[1]:insert(innerTopCorner)
	
	local outerTopX = topCenterX - (halfFloorWidth * teamSide)
	local outerTopCorner = createCorner(outerTopX, topCenterY, teamIndex, worldIndex, texturePath)
	outerTopCorner.anchorX = teamIndex - 1
	outerTopCorner.fill.scaleY = 1
	outerTopCorner.fill.scaleX = teamSide
	applySlant(outerTopCorner, teamSide)
	laneList[1]:insert(outerTopCorner)
	
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "clampToEdge" )
	
	local topCenterTexture = display.newRect(topCenterX, topCenterY, floorWidth, HEIGHT_TEXTURE_FLOOR)
	topCenterTexture.fill = { type = "image", filename = texturePath .. "top_"..teamIndex..".png" }
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
		centerTexture.fill = { type = "image", filename = texturePath .. "center_"..teamIndex..".png" }
		centerTexture.fill.x = centerFillX
		centerTexture.fill.scaleY = 1
		centerTexture.fill.scaleX = -(1 / columns)
		applySlant(centerTexture, teamSide)
		
		local centerGridTexture = display.newRect(centerX, centerY, floorWidth, HEIGHT_TEXTURE_FLOOR)
		centerGridTexture.fill = { type = "image", filename = texturePath .. "grid.png" }
		centerGridTexture.fill.x = centerFillX
		centerGridTexture.fill.scaleY = 1
		centerGridTexture.fill.scaleX = -(1 / columns)
		applySlant(centerGridTexture, teamSide)
		
		display.setDefault( "textureWrapX", "clampToEdge" )
		display.setDefault( "textureWrapY", "clampToEdge" )
		
		local innerEdgeX = centerX + (halfFloorWidth * teamSide)
		local innerEdgeTexture = display.newRect(innerEdgeX, centerY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
		innerEdgeTexture.anchorX = 1 - (teamIndex - 1)
		innerEdgeTexture.fill = { type = "image", filename = texturePath .. "side_"..teamIndex..".png" }
		innerEdgeTexture.fill.scaleY = 1
		innerEdgeTexture.fill.scaleX = -1 * teamSide
		applySlant(innerEdgeTexture, teamSide)
		
		local outerEdgeX = centerX - (halfFloorWidth * teamSide)
		local outerEdgeTexture = display.newRect(outerEdgeX, centerY, WIDTH_TEXTURE_FLOOR, HEIGHT_TEXTURE_FLOOR)
		outerEdgeTexture.anchorX = teamIndex - 1
		outerEdgeTexture.fill = { type = "image", filename = texturePath .. "side_"..teamIndex..".png" }
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
	local innerBottomCorner = createCorner(innerEdgeX, bottomCenterY, teamIndex, worldIndex, texturePath)
	innerBottomCorner.anchorX = 1 - (teamIndex - 1)
	innerBottomCorner.fill.scaleY = -1
	innerBottomCorner.fill.scaleX = -1 * teamSide
	applySlant(innerBottomCorner, teamSide)
	laneList[numLanes]:insert(innerBottomCorner)
	
	local outerEdgeX = bottomCenterX - (halfFloorWidth * teamSide)
	local outerBottomCorner = createCorner(outerEdgeX, bottomCenterY, teamIndex, worldIndex, texturePath)
	outerBottomCorner.anchorX = teamIndex - 1
	outerBottomCorner.fill.scaleY = -1
	outerBottomCorner.fill.scaleX = teamSide
	applySlant(outerBottomCorner, teamSide)
	laneList[numLanes]:insert(outerBottomCorner)
	
	display.setDefault( "textureWrapX", "repeat" )
	display.setDefault( "textureWrapY", "repeat" )
	
	local topCenterTexture = display.newRect(bottomCenterX, bottomCenterY, floorWidth, HEIGHT_TEXTURE_FLOOR)
	topCenterTexture.fill = { type = "image", filename = texturePath .. "top_"..teamIndex..".png" }
	topCenterTexture.fill.x = 0.5
	topCenterTexture.fill.scaleY = -1
	topCenterTexture.fill.scaleX = -(1 / columns)
	applySlant(topCenterTexture, teamSide)
	laneList[numLanes]:insert(topCenterTexture)
end

function helper.getCoin()
	local coinData = { width = 60, height = 60, numFrames = 12 }
	local coinSheet = graphics.newImageSheet( "images/game/rotatingcoin.png", coinData )

	local coinSequenceData = {
		{name = "idle", sheet = coinSheet, start = 1, count = 1 },
		{name = "rotate", sheet = coinSheet, start = 1, count = 12, time = 500 },
	}
	
	local coin = display.newSprite( coinSheet, coinSequenceData )
	
	coin:setSequence("rotate")
	coin:play()

	return coin
end

function helper.getTutorialHand()
	local likeSheet = graphics.newImageSheet("images/game/tutorial/hand_like.png", {width = 77, height = 79, numFrames = 16, sheetContentWidth = 512, sheetContentHeight = 256})
	local pressSheet = graphics.newImageSheet("images/game/tutorial/hand_press.png", {width = 64, height = 64, numFrames = 10, sheetContentWidth = 512, sheetContentHeight = 128})
	local indicateSheet = graphics.newImageSheet("images/game/tutorial/hand_indicate.png", {width = 81, height = 79, numFrames = 10, sheetContentWidth = 512, sheetContentHeight = 256})

	local handSequenceData = {
		{name = "normal", frames = {1,1,2,3,4,5}, time = 400, sheet = pressSheet},
		{name = "like", start = 1 , count = 16, time = 800, sheet = likeSheet},
		{name = "press" , start = 1, count = 8, time = 400, sheet = pressSheet, loopCount = 1},
		{name = "tap" , start = 1, count = 8, time = 400, sheet = pressSheet},
		{name = "unpress" , frames = {8,7,6,5,4,3,2,1}, time = 400, sheet = pressSheet, loopCount = 1},
		{name = "indicate" , start = 1, count = 8, time = 400, sheet = indicateSheet},
	}
	
	local tutorialHand = display.newSprite(pressSheet, handSequenceData)
	tutorialHand.xScale = SCALE_HAND
	tutorialHand.yScale = SCALE_HAND

	function tutorialHand:sprite(event)
		if "ended" == event.phase then
			if event.target.sequence == "fire" then
				self:playSequence("idle")
			end
		end
	end
	tutorialHand:addEventListener("sprite")
	
	function tutorialHand:playSequence(sequence)
		if self and self.setSequence and self.play then
			self:setSequence(sequence)
			self:play()
		end
	end
	
	tutorialHand:playSequence("normal")
	
	return tutorialHand
end

function helper.getFlag()
	local flagData = { width = 128, height = 256, numFrames = 8 }
	local flagSheet = graphics.newImageSheet( "images/game/banderita01.png", flagData )

	local flagSequenceData = {
		{name = "idle", sheet = flagSheet, time = 800, start = 1, count = 8 },
	}

	local flag = display.newSprite( flagSheet, flagSequenceData )
	flag.xScale = 0.35
	flag.yScale = 0.35
	flag:setSequence("idle")
	flag:play()
	
	return flag
end

function helper.loader(sceneName, sceneParams, loaderParams)
	local doors = getDoors()
	director.stage:insert(doors)
	
	loaderParams = loaderParams or {}
	local onDoorClose = loaderParams.onDoorClose
	
	doors:close({onComplete = function()
		timer.performWithDelay(100, function()
			if onDoorClose then
				onDoorClose()
			end
			if sceneName then
				director.gotoScene(sceneName,{params = sceneParams})
			end
			doors:open(function()
				display.remove(doors)
			end)
		end)
	end})
end

return helper
