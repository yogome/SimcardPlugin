------------------------------------ tirarAlAgua_0013
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local manager
local generadorRandom ={}
local startX = display.viewableContentWidth*0.2
local endX = display.viewableContentWidth*0.9
local inicioX = startX
local finX
local finY
local startY = display.viewableContentHeight*0.01
local endY = display.viewableContentHeight*0.7
local bala
local disparador
local respuestas = {}
local numTapDone = 0
local opcionesObjetos = {}
local isGameOver
local instructions
local isFirstTime, gameTutorial
local preguntaTxt

------------------------------------ Constantes
local FONT_FACE = settings.fontName
local FONT_SIZE = 100
local NUMERO_OPCIONES = 18
local OBJETOS = 13
local IMAGENES = 
{
	[1] = {fileName = "9.png" , type="planeta"},
	[2] = {fileName = "jupiter.png" , type="planeta"},
	[3] = {fileName = "marte.png", type="planeta"},
	[4] = {fileName = "tierra.png", type="planeta"},
	[5] = {fileName = "venus.png", type="planeta"},
	[6] = {fileName = "1.png", type="objeto"},
	[7] = {fileName = "2.png", type="objeto"},
	[8] = {fileName = "3.png", type="objeto"},
	[9] = {fileName = "4.png", type="objeto"},
	[10] = {fileName = "5.png", type="objeto"},
	[11] = {fileName = "6.png", type="objeto"},
	[12] = {fileName = "7.png", type="objeto"},
	[13] = {fileName = "8.png", type="objeto"},
	[14] = {fileName = "14.png", type="objeto"},
	[15] = {fileName = "10.png", type="objeto"},
	[16] = {fileName = "11.png", type="objeto"},
	[17] = {fileName = "12.png", type="objeto"},
	[18] = {fileName = "13.png", type="objeto"},	
}
------------------------------------ Functions
local function showTutorial()
	local posicionCorrecta
	local esCorrecta = false
	local index = 1
	repeat
		if IMAGENES[generadorRandom[index]].type == "objeto" then
			posicionCorrecta = index
			esCorrecta = true
		end
		index = index+1
	until esCorrecta == true
	
	local PosX = opcionesObjetos[posicionCorrecta].x
	local PosY = opcionesObjetos[posicionCorrecta].y
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 5,
			scale = 0.6,
			parentScene = game.view,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 2500, x = PosX, y = PosY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function checarRespuestas()
	local data = {}
		isGameOver = true
	if #respuestas == OBJETOS then
		manager.correct()
	else
		local wrongGroup = display.newGroup()
		local elementX = -250
		local elementY = -50
		for index = 6, 18 do
			local wrongImage = display.newImage(assetPath..IMAGENES[index].fileName)
			wrongImage.x = elementX ; wrongImage.y = elementY
			elementX = elementX + 100
			if elementX >= 350 then
				elementX = -250
				elementY = elementY + 100
			end
			wrongImage.xScale = 0.35 ; wrongImage.yScale = 0.35
			wrongGroup:insert(wrongImage)
		end
		wrongGroup.x = 9999 ; wrongGroup.y = 9999
		manager.wrong({id = "group", group = wrongGroup})
	end
end

local function crearOpciones(sceneView, indexObj)
	
	local inicioY 

	if indexObj == 1 or indexObj == ((NUMERO_OPCIONES/3)*2)+1 or indexObj == (NUMERO_OPCIONES/3)+1 then
		inicioX = display.viewableContentWidth*0.2
		startX = display.viewableContentWidth*0.2
		endX = display.viewableContentWidth*0.9
		finX = ((endX-startX)/((NUMERO_OPCIONES/3)+1)) + startX
	end

	if indexObj <= NUMERO_OPCIONES/3 then
		inicioY = (((endY - startY)/4))+startY
		finY = (((endY - startY)/4)*2)+startY
	elseif indexObj <= (NUMERO_OPCIONES/3)*2 then
		inicioY = (((endY - startY)/4)*2)+startY + 80
		finY = (((endY - startY)/4)*3)+startY
	else
		inicioY = (((endY - startY)/4)*3)+startY + 80
		finY = (((endY - startY)/4)*4)+startY
	end

	local imagenOpcion = display.newImage(assetPath .. IMAGENES[generadorRandom[indexObj]].fileName )
	imagenOpcion:scale(0.35, 0.35)
	imagenOpcion.x = math.random(inicioX, finX )
	imagenOpcion.y = math.random(inicioY, finY)
	inicioX = finX + ((imagenOpcion.width*0.35)/2)+50
	imagenOpcion.name = IMAGENES[generadorRandom[indexObj]].type
	opcionesObjetos[indexObj] = imagenOpcion

	if indexObj <= NUMERO_OPCIONES/3 then
		finX = (((endX-startX)/((NUMERO_OPCIONES/3)+1))*(indexObj+1))+startX
	elseif indexObj <= (NUMERO_OPCIONES/3)*2 then
		finX = (((endX-startX)/((NUMERO_OPCIONES/3)+1))*(indexObj-(NUMERO_OPCIONES/3)+1))+startX
	else
		finX = (((endX-startX)/((NUMERO_OPCIONES/3)+1))*(indexObj-((NUMERO_OPCIONES/3)*2)+1))+startX
	end

	function imagenOpcion:tap(event)
		tutorials.cancel(gameTutorial, 300)
		if not isGameOver then
			numTapDone = numTapDone + 1
			local hipotenusa= math.sqrt((math.pow((event.x - disparador.x),2)) + (math.pow((event.y - disparador.y),2)))
			local catetoAdyacente =  event.x - disparador.x
			local grados = math.acos(catetoAdyacente/hipotenusa)
			--disparador.rotation = -(math.deg(grados) - 90)
			if numTapDone == 1 then
				bala = display.newImage( assetPath .. "bala.png" )
				sound.play("superLightBeamGun")
				sceneView:insert(bala)
				bala:scale(0.0825, 0.0825)
				bala.x = disparador.x
				bala.y = disparador.y 
				disparador:toFront()
				director.to(scenePath, disparador, {rotation = -(math.deg(grados) - 90), time = 100, transition = easing.inOutCubic, onComplete = function()
					director.to(scenePath, bala, {time=hipotenusa*0.5,  x=imagenOpcion.x, y=imagenOpcion.y, onComplete = function(obj) 
						transition.to (self, {time = 50, alpha=0, onComplete = function(obj) 
							display.remove(bala) 
							display.remove(self)
							sound.play("pop")
							numTapDone = 0
							if self.name == "planeta" then 
								checarRespuestas() 
							else 
								respuestas[#respuestas+1] = true 
								if #respuestas == OBJETOS then 
									 checarRespuestas() 
								end 
							end 
						end}) 
					end})
				end})
			end
		end
	end

	imagenOpcion:addEventListener( "tap")
	return imagenOpcion 
end

local function generarPosicionesRandom()
	generadorRandom = {[1] = math.random(1, #IMAGENES)}
	local estaRepetido = false
	repeat 
		local aleatorio = math.random(1, #IMAGENES)
		for indexRndm = 1, #generadorRandom do
			if aleatorio == generadorRandom[indexRndm] then
				estaRepetido = true
			end
		end
		if estaRepetido == false then
			generadorRandom[#generadorRandom+1] = aleatorio
		end
		estaRepetido = false
	until #generadorRandom == NUMERO_OPCIONES
end

local function inicializar(sceneView, parameters)
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsCanon_0018")
	preguntaTxt.text = localization.getString("questionCanon_0018")
	
	isGameOver = false
	
	disparador = display.newImage( assetPath .. "disparador.png" )
	disparador:scale(0.65, 0.65)
	disparador.anchorY = 0.75
	sceneView:insert(disparador)
	disparador.x = display.contentCenterX
	disparador.y = display.viewableContentHeight - (181*0.45/2) --tablero.height
	
	generarPosicionesRandom()
	finX = ((endX-startX)/((NUMERO_OPCIONES/3)+1)) + startX
	for indexObjetos = 1, NUMERO_OPCIONES do
		local opciones = crearOpciones(sceneView, indexObjetos)
		sceneView:insert(opciones)
	end
end
------------------------------------ Module functions
function game.getInfo()
	return {
		--TODO answers are in spanish, instructions are not localized
		available = false,
		wrongDelay = 300,
		correctDelay = 300,
		
		name = "Geo cannon",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	local background = display.newImage(assetPath .. "fondo.png")
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:scale(backgroundScale, backgroundScale)
	sceneView:insert(background)
	
	local instructionsOptions = 
	{
		text = "",     
		x = display.screenOriginX+(display.viewableContentWidth*0.20),
		y = display.screenOriginY+(display.viewableContentHeight*0.87),
		width = 425,
		font = settings.fontName,   
		fontSize = 32,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
	
	local grupoPregunta = display.newGroup( )
	local pregunta = display.newImage( assetPath .. "pregunta.png" )
	pregunta:scale(0.7, 0.7)
	local opcionesTextoPregunta = {
		text = "", --"¿Qué elementos no corresponden al universo?",
		x = 0,
		y = 0,
		width = pregunta.width*0.9*0.7,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/3.25,
		align = "center"
	}
	preguntaTxt = display.newText(opcionesTextoPregunta)
	grupoPregunta:insert(pregunta)
	grupoPregunta:insert(preguntaTxt)
	grupoPregunta.x = display.contentCenterX
	grupoPregunta.y = display.viewableContentHeight*0.07
	sceneView:insert(grupoPregunta)
	local tablero = display.newImage( assetPath .. "tablero.png" )
	tablero:scale(0.65, 0.65)
	tablero.x = display.contentCenterX
	tablero.y = display.viewableContentHeight - (tablero.height*0.65/2)
	sceneView:insert(tablero)
end

function game:show(event)
	local phase = event.phase
	manager = event.parent
	if( phase == "will") then
		inicializar(self.view, event.params)
		showTutorial()
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		tutorials.cancel(gameTutorial)
		for indexImg = 1 , #IMAGENES do
			display.remove(opcionesObjetos[indexImg])
		end
		for indexR = 1, #respuestas do
			respuestas[indexR] = nil
		end
		display.remove(disparador)
		--[[timer.cancel( timerTutorial )
		display.remove( koalaIncorrecto )
		display.remove(koalaCorrecto)
		display.remove(koalaNormal)
		display.remove(tutorialTxt)]]--
	end
end

function game:destroy()

end
------------------------------------ Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game