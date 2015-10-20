------------------------------------ stars_005
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require("libs.helpers.extratable")

local game = director.newScene()
------------------------------------ Variables
local manager
local preguntaRndm
local respuestasAleatoriasGeneradas
local widthImg
local heightImg
local RGrupo = {}
local ordenRespuestas = {}
local isFirstTime
local timerTutorial
local preguntaGrupo
local respuestaGrupo, grupoTutorial
local line2
local line3
local line4
local line5
local numLineas = 1
local drawing = { [1] = false, [2] = false, [3] = false, [4] = false, [5] = false}
local manoTutorial
local instructions
local gameTutorial
local wrongAnswers
local rightAnswers
------------------------------------ Constantes
local BACKGROUND_COLOR = {0/255, 0/255, 102/255}
local FONT_SIZE = 100
local FONT_FACE = "VAGRounded"
local FONT_COLOR_QUESTION = {101/255, 95/255, 102/255}
local NUMERO_RESPUESTAS
local LINE_COLOR = {185/255, 21/255, 209/255}
local PREGUNTAS = 
{
	[1] = {idPregunta = 1, texto = "¿Cuáles son los tipos de galaxias que hay en el universo?"},
	[2] = {idPregunta = 2 , texto = "¿Cuáles son los planetas que tienen anillos?"},
	[3] = {idPregunta = 3 , texto = "¿Cuáles son los planetas que son considerados rocosos en el Sistema Solar?"},
	[4] = {idPregunta = 4, texto = "Son los tipos de planetas que existen en el Sistema Solar:"},
	[5] = {idPregunta = 5, texto = "¿Cuáles son planetas jovianos que hay en el Sistema Solar?"},
	[6] = {idPregunta = 6 , texto = "¿Qué planetas no tienen satélites?"},
	[7] = {idPregunta = 7 , texto = "¿Cuáles son los planetas interiores?"},
	[8] = {idPregunta = 8, texto = "¿Cuáles son los planetas exteriores?"},
	[9] = {idPregunta = 9 , texto = "Ceres es uno de los planetas enanos. Entre cuáles planetas se encuentra:"}
}
local RESPUESTAS_CORRECTAS = 
{
	[1] = {["idRespuestaC"] = 1, [1] = "Elípticas", [2] = "Espirales", [3] = "Irregulares"},
	[2] = {["idRespuestaC"] = 2, [1] = "Júpiter", [2] = "Urano", [3] = "Neptuno", [4] = "Saturno"},
	[3] = {["idRespuestaC"] = 3, [1] = "Mercurio", [2] = "Venus", [3] = "Tierra", [4] = "Marte"},
	[4] = {["idRespuestaC"] = 4, [1] = "Rocosos", [2] = "Jovianos", [3] = "Enanos"},
	[5] = {["idRespuestaC"] = 5, [1] = "Júpiter", [2] = "Saturno", [3] = "Urano", [4] = "Neptuno"},
	[6] = {["idRespuestaC"] = 6, [1] = "Mercurio", [2] = "Venus"},
	[7] = {["idRespuestaC"] = 7, [1] = "Mercurio", [2] = "Venus", [3] = "Tierra", [4] = "Marte"},
	[8] = {["idRespuestaC"] = 8, [1] = "Júpiter", [2] = "Saturno", [3] = "Urano", [4] = "Neptuno"},
	[9] = {["idRespuestaC"] = 9, [1] = "Marte", [2] = "Júpiter"}
}
local RESPUESTAS_INCORRECTAS =
{
	[1] = {["idRespuestaI"] = 1, [1] = "Gaseosas", [2] = "Luminosas"},
	[2] = {["idRespuestaI"] = 2, [1] = "Mercurio"},
	[3] = {["idRespuestaI"] = 3, [1] = "Neptuno"},
	[4] = {["idRespuestaI"] = 4, [1] = "Gaseosos", [2] = "Mayores"},
	[5] = {["idRespuestaI"] = 5, [1] = "Marte"},
	[6] = {["idRespuestaI"] = 6, [1] = "Urano", [2] = "Tierra", [3] = "Júpiter"},
	[7] = {["idRespuestaI"] = 7, [1] = "Saturno"},
	[8] = {["idRespuestaI"] = 8, [1] = "Tierra"},
	[9] = {["idRespuestaI"] = 9, [1] = "Tierra", [2] = "Venus", [3] = "Mercurio"}
}

local ESTRELLA = {}

------------------------------------ Functions
local function mostrarTutorial()
	if isFirstTime then
		local respuestasCorrectas = {}
		local indexRC = 1

		for indexTutorial = 1, #RGrupo do
			grupoTutorial:insert(RGrupo[indexTutorial])
		end

		for indexCorrectas = 1, #respuestasAleatoriasGeneradas do
			for checarCorrectas = 1, #RESPUESTAS_CORRECTAS[preguntaRndm] do
				if respuestasAleatoriasGeneradas[indexCorrectas] == RESPUESTAS_CORRECTAS[preguntaRndm][checarCorrectas] then
					respuestasCorrectas[indexRC] = indexCorrectas
					indexRC = indexRC + 1
				end
			end
		end

		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag",delay = 800, time = 2500, x = RGrupo[respuestasCorrectas[1]].x, y = RGrupo[respuestasCorrectas[1]].y +(heightImg/2), toY = RGrupo[respuestasCorrectas[2]].x, toY = RGrupo[respuestasCorrectas[2]].y+(heightImg/2)},
			}
		}

		for indexIterations = 3, #respuestasCorrectas do
			tutorialOptions.steps[#tutorialOptions.steps+1] = {id = "drag", delay = 1000, time = 2500, x = RGrupo[respuestasCorrectas[indexIterations]].x, y = RGrupo[respuestasCorrectas[indexIterations]].y +(heightImg/2), toX = RGrupo[respuestasCorrectas[indexIterations]].x, toY = RGrupo[respuestasCorrectas[indexIterations]].y+(heightImg/2)}
		end

		
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function checarRespuestasCorrectas()
	local data = {}
	local ganaste = true
	if #ordenRespuestas == #rightAnswers then --#RESPUESTAS_CORRECTAS[preguntaRndm] then
		for checarRespuesta =  1, #ordenRespuestas do
			for checarCorrectas = 1, #rightAnswers do --#RESPUESTAS_CORRECTAS[preguntaRndm] do
				--if respuestasAleatoriasGeneradas[ordenRespuestas[checarRespuesta]] == RESPUESTAS_INCORRECTAS[preguntaRndm][checarCorrectas] then
				if respuestasAleatoriasGeneradas[ordenRespuestas[checarRespuesta]] == wrongAnswers[checarCorrectas] then
					ganaste = false
				end
			end
		end
	else
		ganaste = false
	end
	if ganaste then
		manager.correct(data)
	else
		manager.wrong({id = "text", text = "WIP", fontSize = 40})
	end
end

local function crearRespuestas(respuestasIndex, sceneView)
	local respuestaImgOn= display.newImage( ESTRELLA["Encendida"] )
	respuestaImgOn.isVisible = false
	local respuestaImgOff= display.newImage( ESTRELLA["Apagada"] )
	widthImg = respuestaImgOff.width
	heightImg = respuestaImgOff.height
	local optionsRespuestaTxt =
	{
		text = respuestasAleatoriasGeneradas[respuestasIndex],
		x = 0,
		y = 45,
		width = respuestaImgOff.width*0.8,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	} 
	local respuestaTxt = display.newText( optionsRespuestaTxt )
	local grupoRespuestas = display.newGroup( )
	grupoRespuestas:insert(respuestaImgOn)
	grupoRespuestas:insert(respuestaImgOff)
	grupoRespuestas:insert(respuestaTxt)
	sceneView:insert(grupoRespuestas)
	RGrupo[respuestasIndex] = grupoRespuestas
	sceneView:insert(RGrupo[respuestasIndex])

	function respuestaImgOff:touch( event )
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			display.getCurrentStage():setFocus( self, event.id )
			self.isFocus = true
			self.markX = self.x	
			self.markY = self.y		
			sound.play("dragtrash")
		elseif self.isFocus then
			if event.phase == "moved" then 
				--timer.cancel(timerTutorial)
				if event.x > RGrupo[1].contentBounds.xMin+85 and event.x < RGrupo[1].contentBounds.xMax-85 and event.y > RGrupo[1].contentBounds.yMin+45 and event.y < RGrupo[1].contentBounds.yMax-45 then
					if drawing[1] == false then
						sound.play("pop")
						RGrupo[1][1].isVisible = true
						RGrupo[1][2].isVisible = false
						ordenRespuestas[#ordenRespuestas+1] = 1
						numLineas = numLineas + 1
						drawing[1] = true
					end
				elseif event.x > RGrupo[2].contentBounds.xMin+85 and event.x < RGrupo[2].contentBounds.xMax-85 and event.y > RGrupo[2].contentBounds.yMin+45 and event.y < RGrupo[2].contentBounds.yMax-45 then
					if drawing[2] == false then
						sound.play("pop")
						RGrupo[2][1].isVisible = true
						RGrupo[2][2].isVisible = false
						ordenRespuestas[#ordenRespuestas+1] = 2
						numLineas = numLineas + 1
						drawing[2] = true
					end
				elseif event.x > RGrupo[3].contentBounds.xMin+85 and event.x < RGrupo[3].contentBounds.xMax-85 and event.y > RGrupo[3].contentBounds.yMin+45 and event.y < RGrupo[3].contentBounds.yMax-45 then
					if drawing[3] == false then
						sound.play("pop")
						RGrupo[3][1].isVisible = true
						RGrupo[3][2].isVisible = false
						ordenRespuestas[#ordenRespuestas+1] = 3
						numLineas = numLineas + 1
						drawing[3] = true
					end
				elseif event.x > RGrupo[4].contentBounds.xMin+85 and event.x < RGrupo[4].contentBounds.xMax-85 and event.y > RGrupo[4].contentBounds.yMin+45 and event.y < RGrupo[4].contentBounds.yMax-45 then
					if drawing[4] == false then
						sound.play("pop")
						RGrupo[4][1].isVisible = true
						RGrupo[4][2].isVisible = false
						ordenRespuestas[#ordenRespuestas+1] = 4
						numLineas = numLineas + 1
						drawing[4] = true
					end
				elseif event.x > RGrupo[5].contentBounds.xMin+85 and event.x < RGrupo[5].contentBounds.xMax-85 and event.y > RGrupo[5].contentBounds.yMin+45 and event.y < RGrupo[5].contentBounds.yMax-45 then
					if drawing[5] == false then
						sound.play("pop")
						RGrupo[5][1].isVisible = true
						RGrupo[5][2].isVisible = false
						ordenRespuestas[#ordenRespuestas+1] = 5
						numLineas = numLineas + 1
						drawing[5] = true
					end
				end

				if numLineas == 2 then
					display.remove(line2)
					line2 = display.newLine(RGrupo[ordenRespuestas[1]].x, RGrupo[ordenRespuestas[1]].y, event.x, event.y)
					line2.strokeWidth = 8
					line2:setStrokeColor( unpack( LINE_COLOR ))
					sceneView:insert(line2)

				elseif numLineas == 3 then
					display.remove(line2)
					line2 = display.newLine(RGrupo[ordenRespuestas[1]].x, RGrupo[ordenRespuestas[1]].y, RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y)
					display.remove(line3)
					line3 = display.newLine(RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y, event.x, event.y)
					line2.strokeWidth = 8		
					line3.strokeWidth = 8
					line2:setStrokeColor( unpack( LINE_COLOR ))
					line3:setStrokeColor( unpack( LINE_COLOR ))
					sceneView:insert(line2)
					sceneView:insert(line3)

				elseif numLineas == 4 then
					display.remove(line2)
					line2 = display.newLine(RGrupo[ordenRespuestas[1]].x, RGrupo[ordenRespuestas[1]].y, RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y)
					display.remove(line3)
					line3 = display.newLine(RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y, RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y)
					display.remove(line4)
					line4 = display.newLine(RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y, event.x, event.y)
					line2.strokeWidth = 8		
					line3.strokeWidth = 8
					line4.strokeWidth = 8
					line2:setStrokeColor( unpack( LINE_COLOR ))
					line3:setStrokeColor( unpack( LINE_COLOR ))
					line4:setStrokeColor( unpack( LINE_COLOR ))
					sceneView:insert(line2)
					sceneView:insert(line3)
					sceneView:insert(line4)

				elseif numLineas == 5 then
					display.remove(line2)
					line2 = display.newLine(RGrupo[ordenRespuestas[1]].x, RGrupo[ordenRespuestas[1]].y, RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y)
					display.remove(line3)
					line3 = display.newLine(RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y, RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y)
					display.remove(line4)
					line4 = display.newLine(RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y, RGrupo[ordenRespuestas[4]].x, RGrupo[ordenRespuestas[4]].y)
					display.remove(line5)
					line5 = display.newLine(RGrupo[ordenRespuestas[4]].x, RGrupo[ordenRespuestas[4]].y, event.x, event.y)
					line2.strokeWidth = 8		
					line3.strokeWidth = 8
					line4.strokeWidth = 8
					line5.strokeWidth = 8
					line2:setStrokeColor( unpack( LINE_COLOR ))
					line3:setStrokeColor( unpack( LINE_COLOR ))
					line4:setStrokeColor( unpack( LINE_COLOR ))
					line5:setStrokeColor( unpack( LINE_COLOR ))
					sceneView:insert(line2)
					sceneView:insert(line3)
					sceneView:insert(line4)
					sceneView:insert(line5)

				elseif numLineas == 6 then
					display.remove(line2)
					line2 = display.newLine(RGrupo[ordenRespuestas[1]].x, RGrupo[ordenRespuestas[1]].y, RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y)
					display.remove(line3)
					line3 = display.newLine(RGrupo[ordenRespuestas[2]].x, RGrupo[ordenRespuestas[2]].y, RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y)
					display.remove(line4)
					line4 = display.newLine(RGrupo[ordenRespuestas[3]].x, RGrupo[ordenRespuestas[3]].y, RGrupo[ordenRespuestas[4]].x, RGrupo[ordenRespuestas[4]].y)
					display.remove(line5)
					line5 = display.newLine(RGrupo[ordenRespuestas[4]].x, RGrupo[ordenRespuestas[4]].y, RGrupo[ordenRespuestas[5]].x, RGrupo[ordenRespuestas[5]].y)
					line2.strokeWidth = 8		
					line3.strokeWidth = 8
					line4.strokeWidth = 8
					line5.strokeWidth = 8
					line2:setStrokeColor( unpack( LINE_COLOR ))
					line3:setStrokeColor( unpack( LINE_COLOR ))
					line4:setStrokeColor( unpack( LINE_COLOR ))
					line5:setStrokeColor( unpack( LINE_COLOR ))
					sceneView:insert(line2)
					sceneView:insert(line3)
					sceneView:insert(line4)
					sceneView:insert(line5)
				end
			
			elseif event.phase == "ended" or event.phase == "cancelled" then

		  		display.getCurrentStage():setFocus( self,nil )
		  		self.isFocus = false
		  		if numLineas == 2 then
		  			display.remove(line2)
		  		elseif numLineas == 3 then
		  			display.remove(line3)
		  		elseif numLineas == 4 then
		  			display.remove(line4)
		  		elseif numLineas == 5 then
		  			display.remove(line5)
		  		end
		  		
		  		checarRespuestasCorrectas()
		  	end
		end
		
		return true
	end
	respuestaImgOff:addEventListener("touch")
	return grupoRespuestas
end

local function generarRespuestasAleatorias()
	respuestasAleatoriasGeneradas = {}
	for index = 1, 5 do
		if rightAnswers[index] then
			respuestasAleatoriasGeneradas[index] = rightAnswers[index]
		else
			respuestasAleatoriasGeneradas[index] = wrongAnswers[index-#rightAnswers]
		end
	end
	
	respuestasAleatoriasGeneradas = extratable.shuffle(respuestasAleatoriasGeneradas)
	
	--[[local respuestaAleatoria
	local respuestaAleatoriaIndex = 1
	local indexRG = 1
	local indexRI = 1
	local estaRepetido = false
	local RIRepetida = false
	local posicionRespuestaIncorrecta = math.random(1, NUMERO_RESPUESTAS)
	respuestasAleatoriasGeneradas = {
			[posicionRespuestaIncorrecta] = wrongAnswers[1] --RESPUESTAS_INCORRECTAS[preguntaRndm][1]
	}

	if #RESPUESTAS_INCORRECTAS[preguntaRndm] > 1 then
		repeat
			posicionRespuestaIncorrecta = math.random(1, NUMERO_RESPUESTAS)
			if respuestasAleatoriasGeneradas[posicionRespuestaIncorrecta] ~= nil then
				RIRepetida = true
			end
			if RIRepetida == false then
				respuestasAleatoriasGeneradas[posicionRespuestaIncorrecta] = RESPUESTAS_INCORRECTAS[preguntaRndm][indexRI+1]
				indexRI = indexRI + 1
			end
			RIRepetida = false
		until indexRI == #RESPUESTAS_INCORRECTAS[preguntaRndm]
	end

	repeat
		if(respuestasAleatoriasGeneradas[respuestaAleatoriaIndex] == nil) then
			respuestaAleatoria = math.random(1,#RESPUESTAS_CORRECTAS[preguntaRndm]) 
			for checarRespuestaRepetida = 1, NUMERO_RESPUESTAS do
				if RESPUESTAS_CORRECTAS[preguntaRndm][respuestaAleatoria] == respuestasAleatoriasGeneradas[checarRespuestaRepetida] then
					estaRepetido = true
				end
			end
			if estaRepetido == false then
				respuestasAleatoriasGeneradas[respuestaAleatoriaIndex] = RESPUESTAS_CORRECTAS[preguntaRndm][respuestaAleatoria]
				indexRG = indexRG + 1
			else
				respuestaAleatoriaIndex = respuestaAleatoriaIndex-1
			end	
			estaRepetido = false
		end
		respuestaAleatoriaIndex = respuestaAleatoriaIndex+1
	until indexRG == #RESPUESTAS_CORRECTAS[preguntaRndm]+1]]
end

local function inicializar(sceneView, parameters)
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime 
	wrongAnswers = parameters.wrongAnswers
	rightAnswers = parameters.answers
	
	ESTRELLA =
	{
		["Apagada"] = assetPath .. "estrella_1.png",
		["Encendida"] = assetPath .. "estrella_2.png"
	}
	
	instructions.text = localization.getString("instructionsStars_005")

	local preguntaImg = display.newImage(assetPath .. "barra.png")
	preguntaRndm = math.random(1, #PREGUNTAS)
	local preguntaTxtRndm = parameters.question --PREGUNTAS[preguntaRndm].texto
	local optionspreguntaTxt =
	{
		text = preguntaTxtRndm,
		x = 0,
		y = -10,
		width = preguntaImg.width*0.9,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	} 
	local preguntaTxt = display.newText(optionspreguntaTxt)
	preguntaTxt:setFillColor( unpack( FONT_COLOR_QUESTION ) )
	NUMERO_RESPUESTAS = #RESPUESTAS_CORRECTAS[preguntaRndm] + #RESPUESTAS_INCORRECTAS[preguntaRndm]

	preguntaGrupo = display.newGroup( )
	preguntaGrupo.x = display.contentCenterX
	preguntaGrupo.y = display.contentCenterY*0.25
	preguntaGrupo:insert(preguntaImg)
	preguntaGrupo:insert(preguntaTxt)

	sceneView:insert(preguntaGrupo)

	generarRespuestasAleatorias()
	respuestaGrupo = display.newGroup( )
	for respuestasIndex = 1, NUMERO_RESPUESTAS do
		local respuesta = crearRespuestas(respuestasIndex, sceneView)
		respuestaGrupo:insert(respuesta)
	end
	sceneView:insert(respuestaGrupo)
	RGrupo[1].x = math.random(widthImg,(display.viewableContentWidth + 2)/4 )
	RGrupo[1].y = math.random((((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*1)+(display.contentCenterY*0.7),(((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*2)+(display.contentCenterY*0.7) )
	RGrupo[2].x = math.random((display.viewableContentWidth + 2)/4+widthImg, ((display.viewableContentWidth + 2)/4)*2  )
	RGrupo[2].y = math.random(display.contentCenterY*0.7,(((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*1)+(display.contentCenterY*0.7) )
	RGrupo[3].x = math.random((((display.viewableContentWidth + 2)/4)*2)+widthImg, (display.viewableContentWidth + 2)-widthImg  )
	RGrupo[3].y = math.random((((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*1)+(display.contentCenterY*0.7),(((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*2)+(display.contentCenterY*0.7) )
	RGrupo[4].x = math.random(widthImg, (display.viewableContentWidth + 2)/3 )
	RGrupo[4].y = math.random(((((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*2)+(display.contentCenterY*0.7))+heightImg,((((((display.viewableContentHeight + 2)-(heightImg/2))-(display.contentCenterY*0.7))/4)*4)+(display.contentCenterY*0.7))-50 )
	RGrupo[5].x = math.random(((display.viewableContentWidth + 2)/3)+widthImg, (display.viewableContentWidth-2)-widthImg  )
	RGrupo[5].y = math.random(((((((display.viewableContentHeight + 2)-heightImg)-(display.contentCenterY*0.7))/4)*2)+(display.contentCenterY*0.7))+heightImg,((((((display.viewableContentHeight + 2)-(heightImg/2))-(display.contentCenterY*0.7))/4)*4)+(display.contentCenterY*0.7))-50 )
	
end

------------------------------------ Module functions
function game.getInfo()
	return {
		-- TODO answers are in spanish only
		available = false,
		correctDelay = 0,
		wrongDelay = 0,
		
		name = "Geo Stars",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "wrongAnswer", amount = 4},
			{id = "multipleAnswerQuestion", maxAnswers=math.random(2,4)},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	
	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x =display.contentCenterX
	background.y = display.contentCenterY
	sceneView:insert(background)

	instructions = display.newText("", display.screenOriginX+(display.viewableContentWidth*0.5), display.screenOriginY+(display.viewableContentHeight*0.2), settings.fontName, 32)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end

function game:show(event)
	manager = event.parent
	local phase = event.phase
	local sceneView = self.view
	if( phase == "will") then
		grupoTutorial = display.newGroup( )
		sceneView:insert(grupoTutorial)
		inicializar(self.view, event.params)
		mostrarTutorial()
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		display.remove(grupoTutorial)
		display.remove( preguntaGrupo )
		display.remove( respuestaGrupo )
		display.remove(line2)
		display.remove(line3)
		display.remove(line4)
		display.remove(line5)
		tutorials.cancel(gameTutorial)
		numLineas = 1
		drawing = { [1] = false, [2] = false, [3] = false, [4] = false, [5] = false}
		for indexR = 1, #RGrupo do
			display.remove(RGrupo[indexR])
		end
		for indexO = 1, #ordenRespuestas do
			ordenRespuestas[indexO] = nil
		end
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