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
local colorOrgansGroup, glowingOrgansGroup
local popupImagesGroup, popupTextGroup
local boca, esofago, higado, estomago, intdelgado, intgrueso
local appleGroup, apples, appleSpace
local sidebarHeaderText, encabezadoText
----------------------------------------------- Constants
local ORGANS_NUMBER = 6
local FONT_NAME = settings.fontName

local INSTRUCTIONS_FONT_COLOR = { 37/255, 95/255, 147/255 }
local HEADER_FONT_COLOR = { 255/255, 255/255, 255/255 }
local BACKGROUND_COLOR_LEFT = { 106/255, 7/255, 130/255 }
local BACKGROUND_COLOR_RIGHT = { 167/255, 219/255, 195/255 }

local BOCA_TEXT_COLOR = {226/255, 83/255, 27/255}
local ESOFAGO_TEXT_COLOR = {25/255, 73/255, 26/255}
local HIGADO_TEXT_COLOR = {127/255, 15/255, 15/255}
local ESTOMAGO_TEXT_COLOR = {179/255, 145/255, 23/255}
local INTDELGADO_TEXT_COLOR = {25/255, 52/255, 119/255}
local INTGRUESO_TEXT_COLOR = {106/255, 7/255, 130/255}

local APPLEIMAGES = {
	   [1] = {scenePath = "1.png"},
	   [2] = {scenePath = "2.png"},
	   [3] = {scenePath = "3.png"},
	   [4] = {scenePath = "4.png"},
	   [5] = {scenePath = "5.png"},
	   [6] = {scenePath = "6.png"}
	}
----------------------------------------------- Functions
local function createAppleSpace()
	appleGroup = display.newGroup()
	apples = {}
	
	for i = 1, #APPLEIMAGES do
		apples[i] = display.newImage( appleGroup, assetPath ..APPLEIMAGES[i].scenePath)
		apples[i].x = appleSpace.x
		apples[i].y = appleSpace.y
		apples[i].isVisible = false
		answersLayer:insert(apples[i])
	end
	
	appleGroup.currentApple = 1
	apples[appleGroup.currentApple].isVisible = true
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

		if touchedObject.id == esofago then
			touchedObject.yScale = 1.20
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
					director.to(scenePath, touchedObject, {time = 500, x = touchedObject.id.x, y = touchedObject.id.y, transition = easing.outQuad, onComplete = function()
						display.remove(touchedObject)				
					end})		
					correctAnswers = correctAnswers + 1

					appleGroup.currentApple = correctAnswers + 1
						
					if appleGroup.currentApple > 6 then
						appleGroup.currentApple = 6
						display.remove(apples[appleGroup.currentApple])
					end
					
					apples[appleGroup.currentApple].isVisible = true
					display.remove(apples[appleGroup.currentApple - 1])
					
					if touchedObject.id == boca then
						director.to(scenePath, glowingOrgansGroup.glowBoca, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.bocaImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.bocaText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == esofago then
						director.to(scenePath, glowingOrgansGroup.glowEsofago, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.esofagoImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.esofagoText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == higado then
						director.to(scenePath, glowingOrgansGroup.glowHigado, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.higadoImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.higadoText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})

					elseif touchedObject.id == estomago then
						director.to(scenePath, glowingOrgansGroup.glowEstomago, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.estomagoImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.estomagoText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						
					elseif touchedObject.id == intdelgado then
						director.to(scenePath, glowingOrgansGroup.glowIntDelgado, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.intDelgadoImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.intDelgadoText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						
					elseif touchedObject.id == intgrueso then
						director.to(scenePath, glowingOrgansGroup.glowIntGrueso, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupImagesGroup.intGruesoImagen, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
						director.to(scenePath, popupTextGroup.intGruesoText, {time = 500, delay = 500, alpha = 1, transition = easing.outQuad})
					end
										
					touchedObject:removeEventListener( "touch", doTouchedEvent )
					sound.play("pop")
					
					if correctAnswers == ORGANS_NUMBER then
						manager.correct()
					end
			else
				sound.play("cut")
				director.to(scenePath, touchedObject, {time = 500, x = touchedObject.initX, y = touchedObject.initY, tag = "backTransition"})
				
				if touchedObject.id == esofago then
					touchedObject.yScale = 1.20
				else
					touchedObject.xScale = 0.80
					touchedObject.yScale = 0.80
				end
			end
		end
	end
end

local function createGlowingOrgansAndPopups()
	local glowscale = 1
	
	glowingOrgansGroup = display.newGroup()
	popupImagesGroup = display.newGroup()
	popupTextGroup = display.newGroup()
	
	glowingOrgansGroup.glowBoca = display.newImage(assetPath.."glowboca.png")
	glowingOrgansGroup.glowBoca:scale(glowscale, glowscale)
	glowingOrgansGroup.glowBoca.x = boca.x
	glowingOrgansGroup.glowBoca.y = boca.y
	glowingOrgansGroup.glowBoca.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowBoca)
	popupImagesGroup.bocaImagen = display.newImage(assetPath.."boca2.png")
	popupImagesGroup.bocaImagen.x = glowingOrgansGroup.glowBoca.x
	popupImagesGroup.bocaImagen.y = glowingOrgansGroup.glowBoca.y - 70
	popupImagesGroup.bocaImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.bocaImagen)
	local bocaTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoBoca"),	 
		x = popupImagesGroup.bocaImagen.x,
		y = popupImagesGroup.bocaImagen.y - 10,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.bocaText = display.newText(bocaTextOptions)
	popupTextGroup.bocaText:setFillColor(unpack(BOCA_TEXT_COLOR))
	popupTextGroup.bocaText.alpha = 0
	popupTextGroup:insert(popupTextGroup.bocaText)
	
	glowingOrgansGroup.glowHigado = display.newImage(assetPath.."glowhigado.png")
	glowingOrgansGroup.glowHigado:scale(glowscale, glowscale)
	glowingOrgansGroup.glowHigado.x = higado.x
	glowingOrgansGroup.glowHigado.y = higado.y
	glowingOrgansGroup.glowHigado.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowHigado)
	popupImagesGroup.higadoImagen = display.newImage(assetPath.."higado2.png")
	popupImagesGroup.higadoImagen.x = glowingOrgansGroup.glowHigado.x - 100
	popupImagesGroup.higadoImagen.y = glowingOrgansGroup.glowHigado.y - 65
	popupImagesGroup.higadoImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.higadoImagen)
	local higadoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoHigado"),	 
		x = popupImagesGroup.higadoImagen.x + 2,
		y = popupImagesGroup.higadoImagen.y - 18,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.higadoText = display.newText(higadoTextOptions)
	popupTextGroup.higadoText:setFillColor(unpack(HIGADO_TEXT_COLOR))
	popupTextGroup.higadoText.alpha = 0
	popupTextGroup:insert(popupTextGroup.higadoText)
	
	glowingOrgansGroup.glowEsofago = display.newImage(assetPath.."glowesofago.png")
	glowingOrgansGroup.glowEsofago:scale(glowscale, 1.20)
	glowingOrgansGroup.glowEsofago.x = esofago.x
	glowingOrgansGroup.glowEsofago.y = esofago.y
	glowingOrgansGroup.glowEsofago.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowEsofago)
	popupImagesGroup.esofagoImagen = display.newImage(assetPath.."esofago2.png")
	popupImagesGroup.esofagoImagen.x = glowingOrgansGroup.glowEsofago.x + 70
	popupImagesGroup.esofagoImagen.y = glowingOrgansGroup.glowEsofago.y - 70
	popupImagesGroup.esofagoImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.esofagoImagen)
	local esofagoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoEsofago"),	 
		x = popupImagesGroup.esofagoImagen.x,
		y = popupImagesGroup.esofagoImagen.y - 12,
		width = 120,
		font = FONT_NAME,   
		fontSize = 25,
		align = "center"
	}
	popupTextGroup.esofagoText = display.newText(esofagoTextOptions)
	popupTextGroup.esofagoText:setFillColor(unpack(ESOFAGO_TEXT_COLOR))
	popupTextGroup.esofagoText.alpha = 0
	popupTextGroup:insert(popupTextGroup.esofagoText)

	glowingOrgansGroup.glowEstomago = display.newImage(assetPath.."glowestomago.png")
	glowingOrgansGroup.glowEstomago:scale(glowscale, glowscale)
	glowingOrgansGroup.glowEstomago.x = estomago.x
	glowingOrgansGroup.glowEstomago.y = estomago.y
	glowingOrgansGroup.glowEstomago.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowEstomago)
	popupImagesGroup.estomagoImagen = display.newImage(assetPath.."estomago2.png")
	popupImagesGroup.estomagoImagen.x = glowingOrgansGroup.glowEstomago.x + 150
	popupImagesGroup.estomagoImagen.y = glowingOrgansGroup.glowEstomago.y - 50
	popupImagesGroup.estomagoImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.estomagoImagen)
	local estomagoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoEstomago"),	 
		x = popupImagesGroup.estomagoImagen.x + 3,
		y = popupImagesGroup.estomagoImagen.y - 12,
		width = 120,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.estomagoText = display.newText(estomagoTextOptions)
	popupTextGroup.estomagoText:setFillColor(unpack(ESTOMAGO_TEXT_COLOR))
	popupTextGroup.estomagoText.alpha = 0
	popupTextGroup:insert(popupTextGroup.estomagoText)
	
	glowingOrgansGroup.glowIntGrueso = display.newImage(assetPath.."glowintgrueso.png")
	glowingOrgansGroup.glowIntGrueso:scale(glowscale, glowscale)
	glowingOrgansGroup.glowIntGrueso.x = intgrueso.x
	glowingOrgansGroup.glowIntGrueso.y = intgrueso.y
	glowingOrgansGroup.glowIntGrueso.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowIntGrueso)
	popupImagesGroup.intGruesoImagen = display.newImage(assetPath.."intestinogrueso2.png")
	popupImagesGroup.intGruesoImagen.x = glowingOrgansGroup.glowIntGrueso.x - 175
	popupImagesGroup.intGruesoImagen.y = glowingOrgansGroup.glowIntGrueso.y
	popupImagesGroup.intGruesoImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.intGruesoImagen)
	local intGruesoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoIntGrueso"),	 
		x = popupImagesGroup.intGruesoImagen.x - 7,
		y = popupImagesGroup.intGruesoImagen.y - 10,
		width = 110,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.intGruesoText = display.newText(intGruesoTextOptions)
	popupTextGroup.intGruesoText:setFillColor(unpack(INTGRUESO_TEXT_COLOR))
	popupTextGroup.intGruesoText.alpha = 0
	popupTextGroup:insert(popupTextGroup.intGruesoText)
	
	glowingOrgansGroup.glowIntDelgado = display.newImage(assetPath.."glowintdelgado.png")
	glowingOrgansGroup.glowIntDelgado:scale(glowscale, glowscale)
	glowingOrgansGroup.glowIntDelgado.x = intdelgado.x
	glowingOrgansGroup.glowIntDelgado.y = intdelgado.y
	glowingOrgansGroup.glowIntDelgado.alpha = 0
	glowingOrgansGroup:insert(glowingOrgansGroup.glowIntDelgado)
	popupImagesGroup.intDelgadoImagen = display.newImage(assetPath.."intestinodelgado2.png")
	popupImagesGroup.intDelgadoImagen.x = glowingOrgansGroup.glowIntDelgado.x + 135
	popupImagesGroup.intDelgadoImagen.y = glowingOrgansGroup.glowIntDelgado.y
	popupImagesGroup.intDelgadoImagen.alpha = 0
	popupImagesGroup:insert(popupImagesGroup.intDelgadoImagen)
	local intDelgadoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoIntDelgado"),	 
		x = popupImagesGroup.intDelgadoImagen.x + 38,
		y = popupImagesGroup.intDelgadoImagen.y - 2,
		width = 110,
		font = FONT_NAME,   
		fontSize = 26,
		align = "center"
	}
	popupTextGroup.intDelgadoText = display.newText(intDelgadoTextOptions)
	popupTextGroup.intDelgadoText:setFillColor(unpack(INTDELGADO_TEXT_COLOR))
	popupTextGroup.intDelgadoText.alpha = 0
	popupTextGroup:insert(popupTextGroup.intDelgadoText)
	
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
	--print(offsetY)
	
	if offsetY >= 0 then
		greyOrgansBg.height = greyOrgansBg.height + offsetY*2
	else
		greyOrgansBg.height = greyOrgansBg.height - offsetY*2
	end
	
	boca = display.newImage(assetPath.."boca3.png")
	boca.x = greyOrgansBg.x - 80
	boca.y = greyOrgansBg.y - 207
	answersLayer:insert(boca)
	
	higado = display.newImage(assetPath.."higado3.png")
	higado.x = greyOrgansBg.x + 12
	higado.y = greyOrgansBg.y + 55
	answersLayer:insert(higado)
	
	esofago = display.newImage(assetPath.."esofago3.png")
	esofago:scale(1, 1.20)
	esofago.x = greyOrgansBg.x + 12
	esofago.y = greyOrgansBg.y - 45
	answersLayer:insert(esofago)
	
	estomago = display.newImage(assetPath.."estomago3.png")
	estomago.x = greyOrgansBg.x + 35
	estomago.y = greyOrgansBg.y + 95
	answersLayer:insert(estomago)
	
	intdelgado = display.newImage(assetPath.."intestinodelgado3.png")
	intdelgado.x = greyOrgansBg.x + 34
	intdelgado.y = greyOrgansBg.y + 242
	answersLayer:insert(intdelgado)
	
	intgrueso = display.newImage(assetPath.."intestinogrueso3.png")
	intgrueso.x = greyOrgansBg.x + 35
	intgrueso.y = greyOrgansBg.y + 220
	answersLayer:insert(intgrueso)
end

local function createColorOrgans()
	colorOrgansGroup = display.newGroup()
	organGroup = display.newGroup()
	
	colorOrgansGroup.colorOrgansBg = display.newImage(assetPath.."tabla.png")
	colorOrgansGroup.colorOrgansBg.x = display.contentCenterX/3.5 + 25
	colorOrgansGroup.colorOrgansBg.y = display.contentCenterY + 35
	colorOrgansGroup:insert(colorOrgansGroup.colorOrgansBg)
	answersLayer:insert(colorOrgansGroup)
	
	organGroup.intestinoGrueso = display.newImage(assetPath.."intestinogrueso.png")
	organGroup.intestinoGrueso:scale(.80, .80)
	organGroup.intestinoGrueso.x = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.intestinoGrueso.y = display.contentCenterY - 190
	organGroup.intestinoGrueso.initX = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.intestinoGrueso.initY = display.contentCenterY - 190
	organGroup.intestinoGrueso.id = intgrueso
	organGroup.intestinoGrueso:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.intestinoGrueso)

	organGroup.boca = display.newImage(assetPath.."boca.png")
	organGroup.boca:scale(.80, .80)
	organGroup.boca.x = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.boca.y = display.contentCenterY - 65
	organGroup.boca.initX = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.boca.initY = display.contentCenterY - 65
	organGroup.boca.id = boca
	organGroup.boca:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.boca)
	
	organGroup.higado = display.newImage(assetPath.."higado.png")
	organGroup.higado:scale(.80, .80)
	organGroup.higado.x = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.higado.y = display.contentCenterY + 35
	organGroup.higado.initX = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.higado.initY = display.contentCenterY + 35
	organGroup.higado.id = higado
	organGroup.higado:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.higado)
	
	organGroup.esofago = display.newImage(assetPath.."esofago.png")
	organGroup.esofago:scale(1, 1.20)
	organGroup.esofago.x = colorOrgansGroup.colorOrgansBg.x + 55
	organGroup.esofago.y = display.contentCenterY + 20
	organGroup.esofago.initX = colorOrgansGroup.colorOrgansBg.x + 55
	organGroup.esofago.initY = display.contentCenterY + 20
	organGroup.esofago.id = esofago
	organGroup.esofago:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.esofago)
	
	organGroup.intestinoDelgado = display.newImage(assetPath.."intestinodelgado.png")
	organGroup.intestinoDelgado:scale(.90, .90)
	organGroup.intestinoDelgado.x = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.intestinoDelgado.y = display.contentCenterY + 160
	organGroup.intestinoDelgado.initX = colorOrgansGroup.colorOrgansBg.x - 30
	organGroup.intestinoDelgado.initY = display.contentCenterY + 160
	organGroup.intestinoDelgado.id = intdelgado
	organGroup.intestinoDelgado:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.intestinoDelgado)
	
	organGroup.estomago = display.newImage(assetPath.."estomago.png")
	organGroup.estomago:scale(.90, .90)
	organGroup.estomago.x = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.estomago.y = display.contentCenterY + 250
	organGroup.estomago.initX = colorOrgansGroup.colorOrgansBg.x - 10
	organGroup.estomago.initY = display.contentCenterY + 250
	organGroup.estomago.id = estomago
	organGroup.estomago:addEventListener( "touch", doTouchedEvent )
	organGroup:insert(organGroup.estomago)
		
	answersLayer:insert(organGroup)
end

local function createEncabezado()
	local encabezadoGroup = display.newGroup()
	local encabezado = display.newImage(assetPath .. "encabezado.png")
	encabezado:scale(1.30, 1.30)
	encabezado.x = display.contentCenterX * 0.90
	encabezado.y = display.contentCenterY * 0.10
	encabezadoGroup:insert(encabezado)
	
	local encabezadoTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoHeader"),	 
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
	
	instructions.text = localization.getString("instructionsAparatoDigestivo")
	sidebarHeaderText.text = localization.getString("instructionsAparatoDigestivoOrganos")
	encabezadoText.text = localization.getString("instructionsAparatoDigestivoHeader")
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.6,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 3000, x = organGroup.boca.x, y = organGroup.boca.y, toX = boca.x , toY = boca.y},
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
		
		name = "Digestive system",
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
	
	appleSpace = display.newImage(assetPath.."cuadro.png")
	appleSpace:scale(1.20, 1.20)
	appleSpace.x = display.contentCenterX * 1.80
	appleSpace.y = display.contentCenterY * 0.25
	answersLayer:insert(appleSpace)
	
	local sidebarHeader = display.newImage(assetPath .. "organos.png")
	sidebarHeader.x = display.contentCenterX/3.5 + 15
	sidebarHeader.y = display.contentCenterY - 325
	answersLayer:insert(sidebarHeader)
	
	local sidebarHeaderTextOptions = 
	{
		text = localization.getString("instructionsAparatoDigestivoOrganos"),	 
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
		x = display.contentCenterX * 1.75,
		y = display.contentCenterY * 0.65,
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
		display.remove(glowingOrgansGroup)
		display.remove(organGroup)
		display.remove(popupImagesGroup)
		display.remove(popupTextGroup)
		display.remove(colorOrgansGroup)
		display.remove(apples[appleGroup.currentApple])
		for i = 1, #APPLEIMAGES do
			display.remove(apples[i])
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
