------------------------------------ tirarAlAgua_0013
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local director = require( "libs.helpers.director" )
local sound = require("libs.helpers.sound")
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local koalaNormal
local koalaCorrecto
local koalaIncorrecto
local respuestasAleatoriasGeneradas = {}
local manager
local estanque2
local secuenciaRandom = {}
local instructions
local isFirstTime, gameTutorial
local question, correctAnswer, wrongAnswer
local tapsEnabled
local objectsGroup, dynamicGroup
------------------------------------ Constantes
local BACKGROUND_COLOR = {47/255, 12/255, 102/255}
local QUESTION_FONT_COLOR = {27/255, 52/255, 71/255}
local ANSWER_FONT_COLOR = {0/255, 94/255, 109/255}
local TUTORIAL_FONT_COLOR = {13/255, 131/255, 158/255}
local NUMERO_OPCIONES = 4
local FONT_FACE = "VAGRounded"
local FONT_SIZE = 100
------------------------------------ Functions
local function showTutorial()
	local PosX
	local PosY
	
	if secuenciaRandom[#secuenciaRandom] <= NUMERO_OPCIONES/2 then
		PosX = display.screenOriginX + (((display.viewableContentWidth/4)*(secuenciaRandom[#secuenciaRandom]+1))*1.05)
		PosY = display.screenOriginY + (display.viewableContentHeight*0.475)
	else
		PosX = display.screenOriginX + (((display.viewableContentWidth/4)*((secuenciaRandom[#secuenciaRandom]-(NUMERO_OPCIONES/2))+1))*1.05)
		PosY = display.screenOriginY + (display.viewableContentHeight*0.7)
	end
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = PosX, y = PosY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function checarRespuestaCorrecta(name)
	tapsEnabled = false
	local data = {id = "text",
				text = respuestasAleatoriasGeneradas[secuenciaRandom[#secuenciaRandom]],
				fontSize = 40}
	koalaNormal.isVisible = false
	if secuenciaRandom[#secuenciaRandom] == name then	
		koalaCorrecto.isVisible = true
		manager.correct()
	else
		koalaIncorrecto.isVisible = true
		manager.wrong({id = "text", text = correctAnswer, fontSize = 40})
		director.to(scenePath, koalaIncorrecto, {time=1000, y = estanque2.y, onStart = function()
			director.to(scenePath, estanque2, {time=250, alpha=1, delay = 750, onComplete = function()
				sound.play("waterBigImpact")
			end})
		end})
	end
end

local function generarRespuestasAleatorias()
	secuenciaRandom = {[1] = math.random(1, NUMERO_OPCIONES)}
	local estaRepetido = false
	repeat
		local rand = math.random(1, NUMERO_OPCIONES)
		for indexRepetido = 1, #secuenciaRandom do
			if rand == secuenciaRandom[indexRepetido] then
			estaRepetido = true
			end
		end
		if estaRepetido then
		else
			secuenciaRandom[#secuenciaRandom+1] = rand
		end
		estaRepetido = false
	until #secuenciaRandom == NUMERO_OPCIONES

	respuestasAleatoriasGeneradas[secuenciaRandom[#secuenciaRandom]] = correctAnswer
	for indexRespuestaAleatoria = 1, #secuenciaRandom-1 do
		respuestasAleatoriasGeneradas[secuenciaRandom[indexRespuestaAleatoria]] = wrongAnswer[indexRespuestaAleatoria]
	end
end

local function crearOpciones(sceneView, indexO)
	local gOpcion = display.newGroup( )
	local opcionImg = display.newImage(assetPath .. "opcion.png")
	opcionImg:scale( 0.875, 0.875 )
	local opcionOpciones = 
	{
		text = respuestasAleatoriasGeneradas[indexO],
		x = 0,
		y = 0,
		width = opcionImg.width*0.875*0.9,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	}
	local opcionTxt = display.newText( opcionOpciones )
	opcionTxt:setFillColor( unpack( ANSWER_FONT_COLOR ) )
	gOpcion:insert(opcionImg)
	gOpcion:insert(opcionTxt)
	gOpcion.name = indexO

	if indexO<= NUMERO_OPCIONES/2 then
		gOpcion.x = display.screenOriginX + (((display.viewableContentWidth/4)*(indexO+1))*1.05)
		gOpcion.y = display.screenOriginY + (display.viewableContentHeight*0.475)
	else
		gOpcion.x = display.screenOriginX + (((display.viewableContentWidth/4)*((indexO-(NUMERO_OPCIONES/2))+1))*1.05)
		gOpcion.y = display.screenOriginY + (display.viewableContentHeight*0.7)
	end

	function gOpcion:tap(event)
		if tapsEnabled then
			tutorials.cancel(gameTutorial,300)
			gOpcion:removeEventListener("tap")
			sound.play("pop")
			checarRespuestaCorrecta(self.name)
			return true
		end
	end

	gOpcion:addEventListener("tap" )
	return gOpcion
end

local function inicializar(sceneView, parameters)
	dynamicGroup = display.newGroup( )
	objectsGroup:insert(dynamicGroup)

	tapsEnabled = true
	parameters = parameters or {}
		
	local preguntaCompleta = display.newGroup( )
	local pregunta = display.newImage( assetPath .. "pregunta.png" )
	pregunta:scale(1.1, 1.1)
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsTiraralagua_0013")
	
	question = parameters.question
	correctAnswer = parameters.answer
	wrongAnswer = parameters.wrongAnswers
	
	local opcionesPregunta =
	{
		text = question,
		x = 0,
		y = 0,
		width = pregunta.width*1.1*0.9,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/3.5,
		align = "center"
	}
	
	local preguntaTxt = display.newText( opcionesPregunta )
	preguntaTxt:setFillColor( unpack( QUESTION_FONT_COLOR ) )
	preguntaCompleta:insert(pregunta)
	preguntaCompleta:insert(preguntaTxt)
	preguntaCompleta.x = display.screenOriginX + (display.viewableContentWidth*0.65)
	preguntaCompleta.y = display.screenOriginY + (display.viewableContentHeight*0.125)
	dynamicGroup:insert(preguntaCompleta)

	generarRespuestasAleatorias()

	local grupoOpciones = display.newGroup( )
	for indexOpciones = 1, NUMERO_OPCIONES do
		local opcion = crearOpciones(sceneView, indexOpciones)
		grupoOpciones:insert(opcion)
	end
	dynamicGroup:insert(grupoOpciones)

	local hierba = display.newImage(assetPath .. "hierba.png")
	hierba.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	hierba.y = hierba.height/2
	dynamicGroup:insert(hierba)

	local estanque1 = display.newImage( assetPath .. "estanque1.png")
	estanque1:scale(1.15, 1.15)
	estanque1.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	estanque1.y = display.screenOriginY + (display.viewableContentHeight*0.775)
	dynamicGroup:insert(estanque1)

	koalaNormal = display.newImage( assetPath .. "normal.png" )
	koalaNormal:scale(0.8, 0.8)
	koalaNormal.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	koalaNormal.y = (koalaNormal.height/3)*1.925
	dynamicGroup:insert(koalaNormal)

	koalaCorrecto = display.newImage( assetPath .. "correcto.png" )
	koalaCorrecto:scale(0.8, 0.8)
	koalaCorrecto.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	koalaCorrecto.y = (koalaNormal.height/3)*1.925
	koalaCorrecto.isVisible = false
	dynamicGroup:insert(koalaCorrecto)

	koalaIncorrecto = display.newImage(assetPath .. "incorrecto.png")
	koalaIncorrecto:scale(0.8, 0.8)
	koalaIncorrecto.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	koalaIncorrecto.y = (koalaNormal.height/3)*1.925
	koalaIncorrecto.isVisible = false
	koalaIncorrecto:toFront( )
	dynamicGroup:insert(koalaIncorrecto)

	estanque2 = display.newImage(assetPath .. "estanque2.png")
	estanque2:scale(1.15, 1.15)
	estanque2.x = display.screenOriginX + (display.viewableContentWidth*0.2)
	estanque2.y = display.screenOriginY + (display.viewableContentHeight*0.775)
	estanque2.alpha = 0
	dynamicGroup:insert(estanque2)
	
	showTutorial()
end
------------------------------------ Module functions
function game.getInfo()
	return {
		-- TODO answers are in spanish only
		available = false,
		correctDelay = 600,
		wrongDelay = 1200,
		
		name = "Geo Agua",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 3},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	local background = display.newRect(display.contentCenterX,display.contentCenterY, display.viewableContentWidth + 2 ,display.viewableContentHeight + 2)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	sceneView:insert(background)
	
	local instructionsOptions = 
	{
		text = "",
		x = display.screenOriginX + (display.viewableContentWidth*0.65),
		y = display.screenOriginY + (display.viewableContentHeight*0.3),
		width = display.viewableContentWidth*0.6,
		height = 0,
		font = settings.fontName,
		fontSize = FONT_SIZE/3,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(unpack( TUTORIAL_FONT_COLOR ))
	sceneView:insert(instructions)
	objectsGroup = display.newGroup( )
	sceneView:insert(objectsGroup)
end

function game:show(event)
	local phase = event.phase
	manager = event.parent
	if( phase == "will") then
		inicializar(self.view, event.params)
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		tutorials.cancel(gameTutorial)
		display.remove(koalaIncorrecto)
		display.remove(koalaCorrecto)
		display.remove(koalaNormal)
		display.remove(dynamicGroup)
		dynamicGroup = nil
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