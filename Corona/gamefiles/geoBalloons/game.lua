------------------------------------ letras_0014
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local preguntaRandom
local respuestasAleatoriasGeneradas = {}
local manager
local secuenciaRandom
local OGrupo = {}
local instructions
local esCorrecta
local globos
local isGameOver
local isFirstTime
local dynamicGroup
local elementsGroup
local gameTutorial
local question
local correctAnswer
local answers
------------------------------------ Constantes
local FONT_SIZE = 100
local FONT_FACE = settings.fontName
local NUMERO_OPCIONES = 3
local FONT_COLOR_QUESTION = {79/255, 172/255, 224/255}
local FONT_COLOR_ANSWERS = {178/255, 89/255, 0/255}
local FONT_COLOR_TUTORIAL = {84/255, 124/255, 150/255}

------------------------------------ Functions
local function showTutorial()
	if isFirstTime then
		local posicionRespuestaCorrecta
		for indexRespuestaCorrecta = 1, NUMERO_OPCIONES do
			if OGrupo[indexRespuestaCorrecta].answer == correctAnswer then
					posicionRespuestaCorrecta = indexRespuestaCorrecta
			end
		end
		local tutorialOptions = {
			iterations = 4,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2500, x = OGrupo[posicionRespuestaCorrecta].x, y = OGrupo[posicionRespuestaCorrecta].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function checarRespuestaCorrecta(obj, obj2, answer)
		isGameOver = true
	if answer.isCorrect then
		manager.correct()
		director.to(scenePath, obj, {time=3000, y = 0, onStart= function() sound.play("pop") end})
	else
		manager.wrong({id = "text", text = correctAnswer , fontSize = 54})
		director.to(scenePath, obj, {time= 1500, xScale=0, yScale=0, onStart = function()
			director.to(scenePath, obj2, {delay = 1000, time=1500, alpha=1, onStart = function()
				sound.play("minigamesBallonAirRelease") 
			end})
		end})
	end
end

local function crearOpciones(indexO)
	local bombaImagen = display.newImage(assetPath .. "bomba de aire.png")
	local opcionesTxtBomba = {
		text = answers[indexO],
		x = -17,
		y = 20,
		width = bombaImagen.width*0.9,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/4,
		align = "center"
	}
	
	local bombaTxt = display.newText( opcionesTxtBomba )
	bombaTxt:setFillColor( unpack( FONT_COLOR_ANSWERS ) )
	local bombaCompleta = display.newGroup( )
	bombaCompleta:insert(bombaImagen)
	bombaCompleta:insert(bombaTxt)
	bombaCompleta.x = (display.viewableContentWidth/(NUMERO_OPCIONES+1))*indexO
	bombaCompleta.y = display.viewableContentHeight - (bombaImagen.height/2)
	bombaCompleta.numTaps = 0
	bombaCompleta.name = indexO
	
	if answers[indexO] == correctAnswer then
		bombaCompleta.isCorrect = true
	else
		bombaCompleta.isCorrect = false
	end
	
	OGrupo[indexO] = bombaCompleta
	local globoInflado = display.newImage(assetPath .. "globo2.png")
	globoInflado.anchorY = 1
	globoInflado.x = bombaCompleta.contentBounds.xMax - 35
	globoInflado.y = display.viewableContentHeight - bombaCompleta.height + 10
	globoInflado:scale(0.5, 0.5)
	local globoPonchado = display.newImage(assetPath .. "globo3.png")
	globoPonchado.anchorY = 1
	globoPonchado.x = bombaCompleta.contentBounds.xMax - 20
	globoPonchado.y = display.viewableContentHeight - bombaCompleta.height + 20
	globoPonchado:scale(0.25, 0.25)
	globoPonchado.alpha = 0
	
	local globoBomba = display.newGroup( )
	globoBomba:insert(bombaCompleta)
	globoBomba:insert(globoInflado)
	globoBomba:insert(globoPonchado)
	
	globos[indexO] = globoBomba ------------------------------------------
	
	function bombaCompleta:tap(event)
		if not isGameOver then
			sound.play("dragUnit")
			tutorials.cancel(gameTutorial,300)
			self.numTaps = self.numTaps +1
			if self.numTaps == 1 then
				director.to(scenePath, self.parent[2], {time=1000, xScale = 0.6666, yScale = 0.6666})
			elseif self.numTaps == 2 then
				director.to(scenePath, self.parent[2], {time=1000, xScale = 0.8333, yScale = 0.8333})
			else
				director.to(scenePath, self.parent[2], {time=1000, xScale = 1, yScale = 1, onComplete = checarRespuestaCorrecta(self.parent[2], self.parent[3], self)})
			end
			return true
		end
	end
	bombaCompleta:addEventListener( "tap")
	return globoBomba
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	isFirstTime = parameters.isFirstTime
	isGameOver = false
	globos = {}
	esCorrecta = false
	instructions.text = localization.getString("instructionsGlobos_0019")
	
	question = parameters.question
	correctAnswer = parameters.answer
	local wrongAnswers = parameters.wrongAnswers
	answers = {}
	answers[1] = correctAnswer
	answers[2] = wrongAnswers[1]
	answers[3] = wrongAnswers[2]
	
	answers = extratable.shuffle(answers)
end

local function createElements()
	display.remove(dynamicGroup)
	dynamicGroup = display.newGroup()
	elementsGroup:insert(dynamicGroup)
	
	local nube = display.newImage( assetPath .. "nube.png" )
	nube:scale(1.05, 1.05)
	local opcionesTxtPregunta = {
		text = question,
		x = 0,
		y = 20,
		width = nube.width*0.9*1.05,
		height = 0,
		font = FONT_FACE,
		fontSize = 26,
		align = "center"
	}
	local preguntaTxt = display.newText( opcionesTxtPregunta )
	preguntaTxt:setFillColor( unpack( FONT_COLOR_QUESTION ) )
	local preguntaCompleta = display.newGroup( )
	preguntaCompleta:insert(nube)
	preguntaCompleta:insert(preguntaTxt)	
	preguntaCompleta.x = display.contentCenterX
	preguntaCompleta.y = display.viewableContentHeight*0.1
	dynamicGroup:insert(preguntaCompleta)
	
	local grupoOpciones = display.newGroup( )
	for indexOpciones = 1, NUMERO_OPCIONES do
		local opcion = crearOpciones(indexOpciones)
		grupoOpciones:insert(opcion)
	end
	dynamicGroup:insert(grupoOpciones)
	local pasto = display.newImage( assetPath .. "pasto.png" )
	pasto.width = display.viewableContentWidth +2
	pasto.y = (display.viewableContentHeight - (pasto.height/2)) + 2
	pasto.x = display.contentCenterX
	dynamicGroup:insert(pasto)
end
------------------------------------ Module functions
function game.getInfo()
	return {
		-- Answers and questions only in spanish
		available = false,
		correctDelay = 1000,
		wrongDelay = 1800,
		
		name = "Geo Globos",
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
	
	local background = display.newImage(assetPath .. "fondo.png")
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:scale(backgroundScale, backgroundScale)
	sceneView:insert(background)
	
	elementsGroup = display.newGroup()
	sceneView:insert(elementsGroup)
	
	local optionsTxtTutorial = {
		text = "",
		x = display.contentCenterX,
		y = display.screenOriginY + (display.viewableContentHeight*0.25),
		width = display.viewableContentWidth *0.75,
		height = 0,
		font = FONT_FACE,
		fontSize = 24,
		align = "center"
	}
	instructions = display.newText(optionsTxtTutorial)
	instructions:setFillColor( unpack( FONT_COLOR_TUTORIAL ) )
	sceneView:insert(instructions)
end

function game:show(event)
	local phase = event.phase
	manager = event.parent
	if( phase == "will") then
		initialize(event)
		createElements()
		showTutorial()
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if phase == "will" then
		
	elseif phase == "did" then
		display.remove(dynamicGroup)
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