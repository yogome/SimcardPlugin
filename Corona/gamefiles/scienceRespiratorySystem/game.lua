----------------------------------------------- Test minigame
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer
local backgroundLayer
local textLayer, instructions
local manager
local isFirstTime
local gameTutorial
local correctAnswers
local organGroup
local glowingOrgansGroup, colorOrgansGroup
local popupImagesGroup, popupTextGroup
local fosasNasales, faringe, laringe, traquea, pulmon, bronquiolo, bronquio
local balloonGroup, balloons, balloonSpace
local sidebarHeaderText, encabezadoText
----------------------------------------------- Constants
local ORGANS_NUMBER = 7
local FONT_NAME = settings.fontName

local INSTRUCTIONS_FONT_COLOR = { 37/255, 95/255, 147/255 }
local HEADER_FONT_COLOR = { 255/255, 255/255, 255/255 }
local BACKGROUND_COLOR_LEFT = { 15/255, 151/255, 188/255 }
local BACKGROUND_COLOR_RIGHT = { 166/255, 221/255, 211/255 }

local FOSAS_TEXT_COLOR = {226/255, 83/255, 27/255}
local FARINGE_TEXT_COLOR = {25/255, 52/255, 119/255}
local LARINGE_TEXT_COLOR = {25/255, 73/255, 26/255}
local TRAQUEA_TEXT_COLOR = {179/255, 145/255, 23/255}
local PULMON_TEXT_COLOR = {106/255, 7/255, 130/255}
local BRONQUIOLO_TEXT_COLOR = {106/255, 7/255, 130/255}
local BRONQUIO_TEXT_COLOR = {179/255, 145/255, 23/255}

local BALLOONIMAGES = {
	   [1] = {scenePath = "1.png"},
	   [2] = {scenePath = "2.png"},
	   [3] = {scenePath = "3.png"},
	   [4] = {scenePath = "4.png"},
	   [5] = {scenePath = "5.png"},
	   [6] = {scenePath = "6.png"},
	   [7] = {scenePath = "7.png"},
	   [8] = {scenePath = "8.png"}
	}
----------------------------------------------- Functions
local function createAppleSpace()
	balloonGroup = display.newGroup()
	balloons = {}
	   	
	for i = 1, #BALLOONIMAGES do
		balloons[i] = display.newImage( balloonGroup, assetPath ..BALLOONIMAGES[i].scenePath)
		balloons[i].x = balloonSpace.x
		balloons[i].y = balloonSpace.y - 20
		balloons[i].isVisible = false
		answersLayer:insert(balloons[i])
	end
	
	balloonGroup.currentBalloon = 1
	balloons[balloonGroup.currentBalloon].isVisible = true
end

local function doTouchedEvent(event)
	local touchedObject = event.target
	if event.phase == "began" then
		display.getCurrentStage():setFocus(touchedObject);
		touchedObject.isFocus = true
		transition.cancel( "backTransition" )
		touchedObject:toFront()
		tutorials.cancel(gameTutorial, 300)
		touchedObject.x = event.x
		touchedObject.y = event.y
		touchedObject.xScale = 1
		touchedObject.yScale = 1
		
		touchedObject.markedX = touchedObject.x
		touchedObject.markedY = touchedObject.y

		if touchedObject.id == fosasNasales then
			touchedObject.xScale = 1.10
		end

		sound.play("dragtrash")

	elseif touchedObject.isFocus then
		if event.phase == "moved" then
			touchedObject.x = event.x
			touchedObject.y = event.y

		elseif event.phase=="ended" then
			touchedObject.hasFocus = false
			display.getCurrentStage():setFocus(nil)
			local radius = 50
			
			if touchedObject.x > touchedObject.id.x - radius and touchedObject.x < touchedObject.id.x + radius and
				touchedObject.y > touchedObject.id.y - radius and touchedObject.y < touchedObject.id.y + radius then
					if touchedObject.id == bronquiolo then
						director.to(scenePath, touchedObject, {time = 500, x = touchedObject.id.x + 7, y = touchedObject.id.y + 14, transition = easing.outQuad, onComplete = function()
						display.remove(touchedObject)				
					end})
					else
					director.to(scenePath, touchedObject, {time = 500, x = touchedObject.id.x, y = touchedObject.id.y, transition = easing.outQuad, onComplete = function()
						display.remove(touchedObject)				
					end})
					end
					correctAnswers = correctAnswers + 1

					balloonGroup.currentBalloon = correctAnswers + 1
					
					balloons[balloonGroup.currentBalloon].isVisible = true
					display.remove(balloons[balloonGroup.currentBalloon - 1])
					
					if touchedObject.id == fosasNasales then
						director.to(scenePath, glowingOrgansGroup.glowFosasNasales, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.fosasNasalesImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.fosasNasalesText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == faringe then
						director.to(scenePath, glowingOrgansGroup.glowFaringe, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.faringeImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.faringeText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == laringe then
						director.to(scenePath, glowingOrgansGroup.glowLaringe, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.laringeImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.laringeText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == traquea then
						director.to(scenePath, glowingOrgansGroup.glowTraquea, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.traqueaImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.traqueaText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						
					elseif touchedObject.id == pulmon then
						director.to(scenePath, glowingOrgansGroup.glowPulmon, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.pulmonImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.pulmonText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						
					elseif touchedObject.id == bronquiolo then
						director.to(scenePath, glowingOrgansGroup.glowBronquiolo, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.bronquioloImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.bronquioloText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
				
					elseif touchedObject.id == bronquio then
						director.to(scenePath, glowingOrgansGroup.glowBronquio, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.bronquioImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.bronquioText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
					end
										
					touchedObject:removeEventListener( "touch", doTouchedEvent )
					sound.play("pop")
					
					if correctAnswers == ORGANS_NUMBER then			
						manager.correct()
						display.remove(balloons[balloonGroup.currentBalloon])
					end
			else
				sound.play("cut")
				director.to(scenePath, touchedObject, {time = 500, x = touchedObject.initX, y = touchedObject.initY, tag = "backTransition"})
				
				touchedObject.xScale = 0.80
				touchedObject.yScale = 0.80
			end
		end
	end
end

local function createGlowingOrgansAndPopups()
	local glowscale = 1
	
	glowingOrgansGroup = display.newGroup()
	popupImagesGroup = display.newGroup()
	popupTextGroup = display.newGroup()
	
	glowingOrgansGroup.glowFosasNasales = display.newImage(assetPath.."glowfosas.png")
	glowingOrgansGroup.glowFosasNasales:scale(1.10, glowscale)
	glowingOrgansGroup.glowFosasNasales.x = fosasNasales.x
	glowingOrgansGroup.glowFosasNasales.y = fosasNasales.y
	glowingOrgansGroup.glowFosasNasales.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowFosasNasales)
	popupImagesGroup.fosasNasalesImagen = display.newImage(assetPath.."fosas2.png")
	popupImagesGroup.fosasNasalesImagen.x = glowingOrgansGroup.glowFosasNasales.x
	popupImagesGroup.fosasNasalesImagen.y = glowingOrgansGroup.glowFosasNasales.y - 80
	popupImagesGroup.fosasNasalesImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.fosasNasalesImagen)
	local fosasNasalesTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioFosas"),	 
		x = popupImagesGroup.fosasNasalesImagen.x,
		y = popupImagesGroup.fosasNasalesImagen.y - 10,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.fosasNasalesText = display.newText(fosasNasalesTextOptions)
	popupTextGroup.fosasNasalesText:setFillColor(unpack(FOSAS_TEXT_COLOR))
	popupTextGroup.fosasNasalesText.alpha = 0
	popupTextGroup:insert(popupTextGroup.fosasNasalesText)
	
	glowingOrgansGroup.glowLaringe = display.newImage(assetPath.."glowlaringe.png")
	glowingOrgansGroup.glowLaringe:scale(glowscale, glowscale)
	glowingOrgansGroup.glowLaringe.x = laringe.x
	glowingOrgansGroup.glowLaringe.y = laringe.y
	glowingOrgansGroup.glowLaringe.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowLaringe)
	popupImagesGroup.laringeImagen = display.newImage(assetPath.."laringe2.png")
	popupImagesGroup.laringeImagen.x = glowingOrgansGroup.glowLaringe.x + 85
	popupImagesGroup.laringeImagen.y = glowingOrgansGroup.glowLaringe.y - 10
	popupImagesGroup.laringeImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.laringeImagen)
	local laringeTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioLaringe"),	 
		x = popupImagesGroup.laringeImagen.x,
		y = popupImagesGroup.laringeImagen.y - 7,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.laringeText = display.newText(laringeTextOptions)
	popupTextGroup.laringeText:setFillColor(unpack(LARINGE_TEXT_COLOR))
	popupTextGroup.laringeText.alpha = 0
	popupTextGroup:insert(popupTextGroup.laringeText)
	
	glowingOrgansGroup.glowFaringe = display.newImage(assetPath.."glowfaringe.png")
	glowingOrgansGroup.glowFaringe:scale(glowscale, glowscale)
	glowingOrgansGroup.glowFaringe.x = faringe.x
	glowingOrgansGroup.glowFaringe.y = faringe.y
	glowingOrgansGroup.glowFaringe.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowFaringe)
	popupImagesGroup.faringeImagen = display.newImage(assetPath.."faringe2.png")
	popupImagesGroup.faringeImagen.x = glowingOrgansGroup.glowFaringe.x + 55
	popupImagesGroup.faringeImagen.y = glowingOrgansGroup.glowFaringe.y - 55
	popupImagesGroup.faringeImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.faringeImagen)
	local faringeTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioFaringe"),	 
		x = popupImagesGroup.faringeImagen.x,
		y = popupImagesGroup.faringeImagen.y - 20,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.faringeText = display.newText(faringeTextOptions)
	popupTextGroup.faringeText:setFillColor(unpack(FARINGE_TEXT_COLOR))
	popupTextGroup.faringeText.alpha = 0
	popupTextGroup:insert(popupTextGroup.faringeText)

	glowingOrgansGroup.glowTraquea = display.newImage(assetPath.."glowtraquea.png")
	glowingOrgansGroup.glowTraquea:scale(glowscale, glowscale)
	glowingOrgansGroup.glowTraquea.x = traquea.x
	glowingOrgansGroup.glowTraquea.y = traquea.y
	glowingOrgansGroup.glowTraquea.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowTraquea)
	popupImagesGroup.traqueaImagen = display.newImage(assetPath.."traquea2.png")
	popupImagesGroup.traqueaImagen.x = glowingOrgansGroup.glowTraquea.x + 75
	popupImagesGroup.traqueaImagen.y = glowingOrgansGroup.glowTraquea.y - 25
	popupImagesGroup.traqueaImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.traqueaImagen)
	local traqueaTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioTraquea"),	 
		x = popupImagesGroup.traqueaImagen.x,
		y = popupImagesGroup.traqueaImagen.y + 5,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.traqueaText = display.newText(traqueaTextOptions)
	popupTextGroup.traqueaText:setFillColor(unpack(TRAQUEA_TEXT_COLOR))
	popupTextGroup.traqueaText.alpha = 0
	popupTextGroup:insert(popupTextGroup.traqueaText)
	
	glowingOrgansGroup.glowBronquiolo = display.newImage(assetPath.."glowbronquiolo.png")
	glowingOrgansGroup.glowBronquiolo:scale(glowscale, glowscale)
	glowingOrgansGroup.glowBronquiolo.x = bronquiolo.x + 7
	glowingOrgansGroup.glowBronquiolo.y = bronquiolo.y + 14
	glowingOrgansGroup.glowBronquiolo.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowBronquiolo)
	popupImagesGroup.bronquioloImagen = display.newImage(assetPath.."bronquiolo2.png")
	popupImagesGroup.bronquioloImagen.x = glowingOrgansGroup.glowBronquiolo.x + 110
	popupImagesGroup.bronquioloImagen.y = glowingOrgansGroup.glowBronquiolo.y + 25
	popupImagesGroup.bronquioloImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.bronquioloImagen)
	local bronquioloTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioBronquiolo"),	 
		x = popupImagesGroup.bronquioloImagen.x + 5,
		y = popupImagesGroup.bronquioloImagen.y + 7,
		width = 125,
		font = FONT_NAME,   
		fontSize = 23,
		align = "center"
	}
	popupTextGroup.bronquioloText = display.newText(bronquioloTextOptions)
	popupTextGroup.bronquioloText:setFillColor(unpack(BRONQUIOLO_TEXT_COLOR))
	popupTextGroup.bronquioloText.alpha = 0
	popupTextGroup:insert(popupTextGroup.bronquioloText)
	
	glowingOrgansGroup.glowPulmon = display.newImage(assetPath.."glowpulmon.png")
	glowingOrgansGroup.glowPulmon:scale(glowscale, glowscale)
	glowingOrgansGroup.glowPulmon.x = pulmon.x
	glowingOrgansGroup.glowPulmon.y = pulmon.y
	glowingOrgansGroup.glowPulmon.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowPulmon)
	popupImagesGroup.pulmonImagen = display.newImage(assetPath.."pulmon2.png")
	popupImagesGroup.pulmonImagen.x = glowingOrgansGroup.glowPulmon.x - 120
	popupImagesGroup.pulmonImagen.y = glowingOrgansGroup.glowPulmon.y
	popupImagesGroup.pulmonImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.pulmonImagen)
	local pulmonTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioPulmon"),	 
		x = popupImagesGroup.pulmonImagen.x,
		y = popupImagesGroup.pulmonImagen.y - 9,
		width = 110,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.pulmonText = display.newText(pulmonTextOptions)
	popupTextGroup.pulmonText:setFillColor(unpack(PULMON_TEXT_COLOR))
	popupTextGroup.pulmonText.alpha = 0
	popupTextGroup:insert(popupTextGroup.pulmonText)
	
	glowingOrgansGroup.glowBronquio = display.newImage(assetPath.."glowbronquio.png")
	glowingOrgansGroup.glowBronquio:scale(glowscale, glowscale)
	glowingOrgansGroup.glowBronquio.x = bronquio.x
	glowingOrgansGroup.glowBronquio.y = bronquio.y
	glowingOrgansGroup.glowBronquio.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowBronquio)
	popupImagesGroup.bronquioImagen = display.newImage(assetPath.."bronquio2.png")
	popupImagesGroup.bronquioImagen.x = glowingOrgansGroup.glowBronquio.x - 15
	popupImagesGroup.bronquioImagen.y = glowingOrgansGroup.glowBronquio.y + 85
	popupImagesGroup.bronquioImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.bronquioImagen)
	local bronquioTextOptions = 
	{
		text = localization.getString("instructionsAparatoRespiratorioBronquio"),	 
		x = popupImagesGroup.bronquioImagen.x,
		y = popupImagesGroup.bronquioImagen.y + 50,
		width = 110,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.bronquioText = display.newText(bronquioTextOptions)
	popupTextGroup.bronquioText:setFillColor(unpack(BRONQUIO_TEXT_COLOR))
	popupTextGroup.bronquioText.alpha = 0
	popupTextGroup:insert(popupTextGroup.bronquioText)
	
	answersLayer:insert(glowingOrgansGroup)
	answersLayer:insert(popupImagesGroup)
	answersLayer:insert(popupTextGroup)
end

local function createGreyOrgans()	
	local greyOrgansBg = display.newImage(assetPath.."silueta.png")
	greyOrgansBg.x = display.contentCenterX*1.285
	greyOrgansBg.y = display.contentCenterY
	answersLayer:insert(greyOrgansBg)
	
	local offsetY = (display.viewableContentHeight - greyOrgansBg.height)/2
	
	if offsetY >= 0 then
		greyOrgansBg.height = greyOrgansBg.height + offsetY*2
	else
		greyOrgansBg.height = greyOrgansBg.height - offsetY*2
	end
	
	fosasNasales = display.newImage(assetPath.."fosas3.png")
	fosasNasales:scale(1.10, 1)
	fosasNasales.x = greyOrgansBg.x - 213
	fosasNasales.y = greyOrgansBg.y - 146
	answersLayer:insert(fosasNasales)
	
	laringe = display.newImage(assetPath.."laringe3.png")
	laringe.x = greyOrgansBg.x - 47
	laringe.y = greyOrgansBg.y - 31	
	answersLayer:insert(laringe)
	
	faringe = display.newImage(assetPath.."faringe3.png")
	faringe.x = greyOrgansBg.x - 100
	faringe.y = greyOrgansBg.y - 94
	answersLayer:insert(faringe)
	
	traquea = display.newImage(assetPath.."traquea3.png")
	traquea.x = greyOrgansBg.x - 40
	traquea.y = greyOrgansBg.y + 87
	answersLayer:insert(traquea)
	
	pulmon = display.newImage(assetPath.."pulmon3.png")
	pulmon.x = greyOrgansBg.x - 106
	pulmon.y = greyOrgansBg.y + 192
	answersLayer:insert(pulmon)
	
	bronquiolo = display.newImage(assetPath.."bronquiolo3.png")
	bronquiolo.x = greyOrgansBg.x + 23
	bronquiolo.y = greyOrgansBg.y + 191
	answersLayer:insert(bronquiolo)
	
	bronquio = display.newImage(assetPath.."bronquio3.png")
	bronquio.x = greyOrgansBg.x - 20
	bronquio.y = greyOrgansBg.y + 180
	answersLayer:insert(bronquio)
end

local function createColorOrgans()
	colorOrgansGroup = display.newGroup()
	organGroup = display.newGroup()
	
	colorOrgansGroup.colorOrgansBg = display.newImage(assetPath.."tabla.png")
	colorOrgansGroup.colorOrgansBg.x = display.contentCenterX/3.5 + 25
	colorOrgansGroup.colorOrgansBg.y = display.contentCenterY + 35
	colorOrgansGroup:insert(colorOrgansGroup.colorOrgansBg)
	answersLayer:insert(colorOrgansGroup)
	
	organGroup.bronquiolo = display.newImage(assetPath.."bronquiolo.png")
	organGroup.bronquiolo:scale(.80, .80)
	organGroup.bronquiolo.x = colorOrgansGroup.colorOrgansBg.x + 30
	organGroup.bronquiolo.y = display.contentCenterY + 225
	organGroup.bronquiolo.initX = colorOrgansGroup.colorOrgansBg.x + 30
	organGroup.bronquiolo.initY = display.contentCenterY + 225
	organGroup.bronquiolo.id = bronquiolo
	organGroup.bronquiolo:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.bronquiolo)

	organGroup.fosasNasales = display.newImage(assetPath.."fosas.png")
	organGroup.fosasNasales:scale(.80, .80)
	organGroup.fosasNasales.x = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.fosasNasales.y = display.contentCenterY + 100
	organGroup.fosasNasales.initX = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.fosasNasales.initY = display.contentCenterY + 100
	organGroup.fosasNasales.id = fosasNasales
	organGroup.fosasNasales:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.fosasNasales)
	
	organGroup.laringe = display.newImage(assetPath.."laringe.png")
	organGroup.laringe:scale(.80, .80)
	organGroup.laringe.x = colorOrgansGroup.colorOrgansBg.x + 35
	organGroup.laringe.y = display.contentCenterY - 180
	organGroup.laringe.initX = colorOrgansGroup.colorOrgansBg.x + 35
	organGroup.laringe.initY = display.contentCenterY - 180
	organGroup.laringe.id = laringe
	organGroup.laringe:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.laringe)
	
	organGroup.faringe = display.newImage(assetPath.."faringe.png")
	organGroup.faringe:scale(.80, .80)
	organGroup.faringe.x = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.faringe.y = display.contentCenterY
	organGroup.faringe.initX = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.faringe.initY = display.contentCenterY
	organGroup.faringe.id = faringe
	organGroup.faringe:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.faringe)
	
	organGroup.pulmon = display.newImage(assetPath.."pulmon.png")
	organGroup.pulmon:scale(.90, .90)
	organGroup.pulmon.x = colorOrgansGroup.colorOrgansBg.x - 45
	organGroup.pulmon.y = display.contentCenterY - 170
	organGroup.pulmon.initX = colorOrgansGroup.colorOrgansBg.x - 45
	organGroup.pulmon.initY = display.contentCenterY - 170
	organGroup.pulmon.id = pulmon
	organGroup.pulmon:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.pulmon)
	
	organGroup.traquea = display.newImage(assetPath.."traquea.png")
	organGroup.traquea:scale(.90, .90)
	organGroup.traquea.x = colorOrgansGroup.colorOrgansBg.x - 60
	organGroup.traquea.y = display.contentCenterY + 225	
	organGroup.traquea.initX = colorOrgansGroup.colorOrgansBg.x - 60
	organGroup.traquea.initY = display.contentCenterY + 225
	organGroup.traquea.id = traquea
	organGroup.traquea:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.traquea)
	
	organGroup.bronquio = display.newImage(assetPath.."bronquio.png")
	organGroup.bronquio:scale(.90, .90)
	organGroup.bronquio.x = colorOrgansGroup.colorOrgansBg.x + 30
	organGroup.bronquio.y = display.contentCenterY - 35
	organGroup.bronquio.initX = colorOrgansGroup.colorOrgansBg.x + 30
	organGroup.bronquio.initY = display.contentCenterY - 35
	organGroup.bronquio.id = bronquio
	organGroup.bronquio:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.bronquio)
		
	answersLayer:insert(organGroup)
end

local function createEncabezado()
	local encabezadoGroup = display.newGroup()
	local encabezado = display.newImage(assetPath .. "encabezado.png")
	encabezado:scale(1, 1)
	encabezado.x = display.contentCenterX * 1.25
	encabezado.y = display.contentCenterY * 0.10
	encabezadoGroup:insert(encabezado)
	
	local encabezadoTextOptions = 
	{
		text = "",	 
		x = encabezado.x,
		y = encabezado.y,
		font = FONT_NAME,   
		fontSize = 28,
		align = "center"
	}
	
	encabezadoText = display.newText(encabezadoTextOptions)
	encabezadoGroup:insert(encabezadoText)
	answersLayer:insert(encabezadoGroup)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	
	correctAnswers = 0
	
	createGlowingOrgansAndPopups()
	createColorOrgans()
	createAppleSpace()
	
	instructions.text = localization.getString("instructionsAparatoRespiratorio")
	sidebarHeaderText.text = localization.getString("instructionsAparatoRespiratorioOrganos")
	encabezadoText.text = localization.getString("instructionsAparatoRespiratorioHeader")
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 4,
			scale = 0.6,
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = organGroup.fosasNasales.x, y = organGroup.fosasNasales.y, toX = fosasNasales.x , toY = fosasNasales.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		wrongDelay = 1000,
		correctDelay = 1000,
		
		name = "Respiratory system",
		category = "science",
		subcategories = {"biology"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
		},
	}
end

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)
		
	local backgroundLeft = display.newRect( display.contentCenterX/3.5, display.contentCenterY, display.viewableContentWidth/3.5, display.viewableContentHeight )
	backgroundLeft:setFillColor( unpack(BACKGROUND_COLOR_LEFT))
	backgroundLayer:insert(backgroundLeft)
	
	local backgroundRight = display.newRect( display.contentCenterX*1.285, display.contentCenterY, display.viewableContentWidth/1.40, display.viewableContentHeight )
	backgroundRight:setFillColor( unpack(BACKGROUND_COLOR_RIGHT))
	backgroundLayer:insert(backgroundRight)
	
	balloonSpace = display.newImage(assetPath.."cuadro.png")
	balloonSpace:scale(1, .85)
	balloonSpace.x = display.contentCenterX * 1.80
	balloonSpace.y = display.contentCenterY * 0.47
	answersLayer:insert(balloonSpace)
	
	local sidebarHeader = display.newImage(assetPath .. "organos.png")
	sidebarHeader.x = display.contentCenterX/3.5 + 15
	sidebarHeader.y = display.contentCenterY - 325
	answersLayer:insert(sidebarHeader)
	
	local sidebarHeaderTextOptions = 
	{
		text = "",	 
		x = display.contentCenterX/3.5 + 15,
		y = display.contentCenterY - 325,
		width = 210,
		font = FONT_NAME,   
		fontSize = 24,
		align = "center"
	}
	
	sidebarHeaderText = display.newText(sidebarHeaderTextOptions)
	sidebarHeaderText:setFillColor(unpack(HEADER_FONT_COLOR))
	textLayer:insert(sidebarHeaderText)
	
	createGreyOrgans()

	local instructionsOptions = 
	{
		text = "",	 
		x = display.contentCenterX * 1.25,
		y = display.contentCenterY * 0.30,
		width = 210,
		font = FONT_NAME,   
		fontSize = 24,
		align = "center"
	}

	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(unpack(INSTRUCTIONS_FONT_COLOR))
	textLayer:insert(instructions)
	
	createEncabezado()
end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		tutorial()
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
	
	elseif phase == "did" then
		display.remove(popupTextGroup)
		display.remove(popupImagesGroup)
		display.remove(glowingOrgansGroup)
		display.remove(organGroup)
		display.remove(colorOrgansGroup)
		display.remove(balloons[balloonGroup.currentBalloon])
		for i = 1, #BALLOONIMAGES do
			display.remove(balloons[i])
		end
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
