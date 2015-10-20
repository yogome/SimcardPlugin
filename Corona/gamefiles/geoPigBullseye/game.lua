------------------------------------ diana_007
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local extratable = require( "libs.helpers.extratable" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local manager
local preguntaRndm
local preguntaImg
local columpio
local pelota
local canion
local pelotaX
local pelotaY
local cerditoCae
local cerdito
local agua
local posicionRespuestaCorrecta
local RGrupo = {}
local respuestasAleatoriasGeneradas = {}
local timerTutorial
local textoTutorial
local optionsRespuestaTxt
local shooter
local gameGroup, preguntaGrupo
local question
local correctAnswer
local wrongAnswer
local isFirstTime, gameTutorial
local tapsEnabled
------------------------------------ Constantes
local BACKGROUND_COLOR = {255/255, 255/255, 204/255}
local FONT_SIZE = 100
local FONT_COLOR = {13/255, 131/255, 158/255}
local FONT_FACE = settings.font
local NUMERO_RESPUESTAS = 3
------------------------------------ Functions
local function showTutorial()
	local correctAnswerIndex
	for index = 1, 3 do
		if respuestasAleatoriasGeneradas[index].text ==  correctAnswer then
			correctAnswerIndex = index
		end
	end
	
	local posX = RGrupo[correctAnswerIndex].x
	local posY = RGrupo[correctAnswerIndex].y
	
	local tutorialOptions = {
			iterations = 3,
			scale = 0.6, 
			parentScene = game.view,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = posX, y = posY + 50},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
end

local function checarRespuestaCorrecta(respuestaContestada)
	sound.play("ballImpact")
	local data = {}
	if respuestasAleatoriasGeneradas[respuestaContestada].isCorrect then --RESPUESTA_CORRECTA[preguntaRndm][1] then
		manager.correct()
		cerdito.isVisible = false
		cerditoCae.isVisible = true
		transition.to (cerditoCae, {time=800, y = agua.y, onStart = function(obj) director.to(scenePath, agua, {time = 250, alpha=1, delay = 750, onComplete = function(obj) sound.play("waterBigImpact")end})end})
	else
		manager.wrong({id = "text", text = correctAnswer, fontSize = 40})
	end
end

local function generarRespuestasAleatorias()
	respuestasAleatoriasGeneradas = {
		[1] = {
			text = wrongAnswer[1],
			isCorrect = false
		},
		[2] = {
			text = wrongAnswer[2],
			isCorrect = false
		},
		[3] = {
			text = correctAnswer,
			isCorrect = true
		},
	}
	
	respuestasAleatoriasGeneradas = extratable.shuffle(respuestasAleatoriasGeneradas)
end

local function crearRespuestas(respuestasIndex, sceneView) 
	local respuestaImg = display.newImage(assetPath .. "respuesta.png")
	local optionspreguntaTxt = {}
	respuestaImg:scale(1.1, 1.1)
	if preguntaRndm ~= 3 then
		optionsRespuestaTxt = 
		{
			text = respuestasAleatoriasGeneradas[respuestasIndex].text,
			x = -25,
			y = 0,
			width = respuestaImg.width*0.7,
			height = 0,
			font = FONT_FACE,
			fontSize = FONT_SIZE/4,
			align = "left"
		}
	else
		optionsRespuestaTxt = 
		{
			text = respuestasAleatoriasGeneradas[respuestasIndex].text,
			x = -35,
			y = 0,
			width = respuestaImg.width*0.7,
			height = 0,
			font = FONT_FACE,
			fontSize = FONT_SIZE/5,
			align = "left"
		}
	end
	local respuestaTxt = display.newText(optionsRespuestaTxt)
	respuestaTxt:setFillColor( unpack(FONT_COLOR) )
	local grupoRespuestas = display.newGroup( )
	gameGroup:insert(grupoRespuestas)
	grupoRespuestas:insert(respuestaImg)
	grupoRespuestas:insert(respuestaTxt)
	--sceneView:insert(grupoRespuestas)
	gameGroup:insert(grupoRespuestas)
	RGrupo[respuestasIndex] = grupoRespuestas

	function respuestaImg:tap(event)
		if tapsEnabled then
			sound.play("pop")
			tutorials.cancel(gameTutorial, 300)
			--[[if primeraVez then
				timer.cancel( timerTutorial )
				textoTutorial.isVisible = false
			end]]
			if event.x > RGrupo[1].contentBounds.xMin and event.x < RGrupo[1].contentBounds.xMax and event.y > RGrupo[1].contentBounds.yMin and event.y < RGrupo[1].contentBounds.yMax then
				director.to(scenePath,  shooter, { rotation=20, time=500, transition=easing.inOutCubic, 
					onStart = function() 
						tapsEnabled = false 
					end, 
					onComplete = function(obj) 
						sound.play("shootBall") 
						pelota.x = pelotaX + 10 
						director.to(scenePath, pelota, {time=300, alpha = 1})
						director.to(scenePath, pelota, {time = 500, x = RGrupo[1].contentBounds.xMin+RGrupo[1].width*0.825, y = RGrupo[1].contentBounds.yMin + RGrupo[1].height*0.5, rotation = 360, 
							onComplete = function(obj) 
								checarRespuestaCorrecta(1) 
								transition.to (pelota, {time = 500, xScale = 0, yScale = 0 })
							end})
					end } )	
			end
			if event.x > RGrupo[2].contentBounds.xMin and event.x < RGrupo[2].contentBounds.xMax and event.y > RGrupo[2].contentBounds.yMin and event.y < RGrupo[2].contentBounds.yMax then
				director.to(scenePath,  shooter, { rotation=-10, time=500, transition=easing.inOutCubic, 
					onStart = function() 
						tapsEnabled = false 
					end, 
					onComplete = function(obj) 
						sound.play("shootBall") 
						pelota.x = pelotaX 
						pelota.y = pelotaY 
						director.to(scenePath, pelota, {time=300, alpha = 1})
						director.to(scenePath, pelota, {time = 500, x = RGrupo[2].contentBounds.xMin+RGrupo[2].width*0.825, y = RGrupo[2].contentBounds.yMin + RGrupo[2].height*0.5, rotation = 360, 
							onComplete = function(obj) 
								checarRespuestaCorrecta(2) 
								transition.to (pelota, {time = 500, xScale = 0, yScale = 0})
							end}) 
					end } )
			end
			if event.x > RGrupo[3].contentBounds.xMin and event.x < RGrupo[3].contentBounds.xMax and event.y > RGrupo[3].contentBounds.yMin and event.y < RGrupo[3].contentBounds.yMax then
				director.to(scenePath,  shooter, { rotation=-30, time=500, transition=easing.inOutCubic, 
					onStart = function() 
						tapsEnabled = false 
					end, 
					onComplete = function(obj) 
						sound.play("shootBall") 
						pelota.x = pelotaX+10 
						director.to(scenePath, pelota, {time=300, alpha = 1})
						director.to(scenePath, pelota, {time = 500, x = RGrupo[3].contentBounds.xMin+RGrupo[3].width*0.825, y = RGrupo[3].contentBounds.yMin + RGrupo[3].height*0.5, rotation = 360, 
							onComplete = function(obj) 
								checarRespuestaCorrecta(3) 
								transition.to (pelota, {time = 500, xScale = 0, yScale = 0})
							end}) 
					end } )
			end
			return true
		end
	end
	respuestaImg:addEventListener("tap")
	return respuestaImg
end

local function inicializar(sceneView, parameters)
	parameters = parameters or {}
	isFirstTime = parameters.isFirstTime
	question = parameters.question
	correctAnswer = parameters.answer
	wrongAnswer = parameters.wrongAnswers
	tapsEnabled = true
	--local preguntaTxtRndm = PREGUNTAS[preguntaRndm].texto
	local optionspreguntaTxt =
	{
		text = question,
		x = 0,
		y = 0,
		width = preguntaImg.width*0.55*0.9,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	}
	
	local preguntaTxt = display.newText(optionspreguntaTxt)
	preguntaGrupo:insert(preguntaImg)
	preguntaGrupo:insert(preguntaTxt)
	
	local optionsTxtTutorial = 
	{
		text = localization.getString("instructionsDiana_007"),
		x = (display.viewableContentWidth/3)*1.9,
		y = (display.viewableContentHeight/12)*3.4,
		width = display.viewableContentWidth/3,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	}
	textoTutorial = display.newText( optionsTxtTutorial )
	textoTutorial:setFillColor( unpack(FONT_COLOR))
	gameGroup:insert(textoTutorial)
	--sceneView:insert( textoTutorial )

	generarRespuestasAleatorias()

	canion = display.newImage(assetPath .. "canon2.png")
	canion.x = display.viewableContentWidth+2 - ((canion.width*0.75)/2)
	canion.y = (display.viewableContentHeight)*0.6
	canion:scale(0.75, 0.75)
	gameGroup:insert(canion)
	--sceneView:insert(canion)

	shooter = display.newImage(assetPath .. "canon.png" )
	shooter.x = display.viewableContentWidth+2 - ((canion.width/4))
	shooter.y = (display.viewableContentHeight)*0.6
	shooter:scale(0.75, 0.75)
	shooter.anchorX = 0.75
	gameGroup:insert(shooter)
	--sceneView:insert(shooter)

	local estanque = display.newImage( assetPath .. "estanque.png")
	estanque.x = display.viewableContentWidth/5.5
	estanque.y = display.viewableContentHeight - ((estanque.height/2)*1.3)
	estanque:scale( 1.125, 1.125 )
	gameGroup:insert(estanque)
	--sceneView:insert(estanque)

	cerditoCae = display.newImage(assetPath .. "puerquito2.png" )
	cerditoCae.x = display.viewableContentWidth/5.5
	cerditoCae.y = (columpio.height/2)*1.3
	cerditoCae:scale(0.75, 0.75)
	gameGroup:insert(cerditoCae)
	--sceneView:insert(cerditoCae)
	cerditoCae.isVisible = false

	agua = display.newImage( assetPath .. "agua.png" )
	agua.x = display.viewableContentWidth/5.5
	agua.y = display.viewableContentHeight - ((estanque.height/2)*1.3)
	agua:scale(1.125, 1.125)
	gameGroup:insert(agua)
	--sceneView:insert(agua)
	agua.alpha = 0

	cerdito = display.newImage( assetPath .. "puerquito.png" )
	cerdito.x = display.viewableContentWidth/5.5
	cerdito.y = (columpio.height/2)*1.3
	cerdito:scale(0.8, 0.8)
	gameGroup:insert(cerdito)
	--sceneView:insert(cerdito)

	local respuestas = display.newGroup( )
	gameGroup:insert(respuestas)
	for respuestasIndex = 1, NUMERO_RESPUESTAS do
		local respuesta = crearRespuestas(respuestasIndex, sceneView)
		RGrupo[respuestasIndex].x = preguntaImg.contentBounds.xMin + ((respuesta.width*2)/2)
		RGrupo[respuestasIndex].y = (((display.viewableContentHeight )/(NUMERO_RESPUESTAS+2)))*(respuestasIndex+1)
		respuestas:insert(RGrupo[respuestasIndex])
	end
	respuestas.y = 50
	--sceneView:insert(respuestas)

	pelota = display.newImage(assetPath .. "bola.png")
	pelota:scale(0.75, 0.75)
	pelota.x = shooter.x
	pelota.y = shooter.y
	pelotaX = pelota.x
	pelotaY = pelota.y
	pelota.alpha = 0
	gameGroup:insert(pelota)
	--sceneView:insert(pelota)

	--mostrarTutorial(sceneView)
	if isFirstTime then
		showTutorial()
	end
end
------------------------------------ Module functions
function game.getInfo()
	return {
		-- TODO this game seems to have responsive issues, ball shoots from wrong offset (Borderless iPad @1x 768)
		available = false,
		correctDelay = 1100,
		wrongDelay = 200,
		
		name = "Geo diana",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 2},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local background = display.newRect(display.contentCenterX,display.contentCenterY, display.viewableContentWidth + 2 ,display.viewableContentHeight + 2)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	sceneView:insert(background)
	
	preguntaGrupo = display.newGroup( )
	preguntaGrupo.x = display.screenOriginX+(display.viewableContentWidth*0.625)
	preguntaGrupo.y = display.screenOriginY+(display.viewableContentHeight*0.125)
	sceneView:insert(preguntaGrupo)
	
	preguntaImg = display.newImage(assetPath .. "barra-05.png")
	preguntaImg:scale(0.55, 0.9)
	--preguntaGrupo:insert(preguntaImg)

	columpio = display.newImage(assetPath .. "columpio.png")
	columpio.x = display.viewableContentWidth/5.5
	columpio.y = columpio.height/2
	sceneView:insert(columpio)
end

function game:show(event)
	local phase = event.phase
	local sceneGroup = self.view

	if( phase == "will") then
		manager = event.parent
		gameGroup = display.newGroup()
		sceneGroup:insert(gameGroup)
		inicializar(gameGroup, event.params)
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		display.remove(gameGroup)
		tutorials.cancel(gameTutorial)
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