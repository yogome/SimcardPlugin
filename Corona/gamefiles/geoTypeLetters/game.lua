------------------------------------ letras_0014
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local screen = require( "libs.helpers.screen" )
local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require("libs.helpers.sound")
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local circuloInterno
local angulo
local preguntaRndm
local subString
local RGrupo
local respuesta
local respuestaTxt
local respuestaCompleta
local isFirstTime
local OGrupo
local manager
local pregunta
local instructions
local isGameOver
local questionGroup
local gameTutorial
local instructions
local questionText
local answerText
local grupoRespuesta
local grupoOpciones
local opcionesGrupo
------------------------------------ Constantes
local BACKGROUND_COLOR = {147/255, 204/255, 201/255}
local BORDER_COLOR = {22/255, 153/255, 149/255}
local NUMERO_OPCIONES = 27
local FONT_SIZE = 100
local OPTIONS_FONT_COLOR = {226/255, 0/255, 245/255}
local QUESTION_FONT_COLOR = {70/255, 19/255, 81/255}
local ABECEDARIO = {
	[1] = "A", [2] = "B", [3] = "C", [4] = "D", [5] = "E", [6] = "F", [7] = "G", [8] = "H", [9] = "I", [10] = "J", [11] = "K", [12] = "L", [13] = "M", [14] = "N", [15] = "Ñ", [16] = "O", [17] = "P", [18] = "Q", [19] = "R", [20] = "S", [21] = "T", [22] = "U", [23] = "V", [24] = "W", [25] ="X", [26] = "Y", [27] = "Z"
}

------------------------------------ Functions
local function mostrarTutorial()
	if isFirstTime then
		local indicesAlphabet = {}
		for indexRespuesta = 1, #subString do
			for indexAbecedario = 1, #ABECEDARIO do
				if subString[indexRespuesta] == ABECEDARIO[indexAbecedario] then
					indicesAlphabet[#indicesAlphabet + 1] = indexAbecedario
				end
			end
		end
		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {}
		}
		
		for index = 1, #indicesAlphabet do
			tutorialOptions.steps[#tutorialOptions.steps + 1] = {id = "tap",delay = 1000, time = 2000, x = OGrupo[indicesAlphabet[index]].x, y = OGrupo[indicesAlphabet[index]].y}
		end
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function checarRespuestaCorrecta()
	isGameOver = true
	local playerWin = true
	local data = {}
	for indexChecarRC = 1, #subString do
		if string.lower(subString[indexChecarRC]) ~= string.lower(respuesta[indexChecarRC]) then
			playerWin = false
		end
	end
	if playerWin then
		manager.correct()
	else
		manager.wrong({id = "text", text = answerText, fontSize = 54})
	end
end

local function crearOpciones(opcionesIndex)
	opcionesGrupo = display.newGroup( )
	local opciones = display.newImage(assetPath.."letra.png")
	local textoOpcionesO = {
		text = ABECEDARIO[opcionesIndex],
		x = 0,
		y = 0,
		width = opciones.width*0.25*0.9,
		height = 0,
		font = settings.fontName,
		fontSize = FONT_SIZE/3,
		align = "center"
	}
	local textoOpciones = display.newText( textoOpcionesO )
	textoOpciones:setFillColor( unpack(OPTIONS_FONT_COLOR))
	opcionesGrupo:insert(opciones)
	opcionesGrupo:insert(textoOpciones)
	opciones:scale(0.25, 0.25)
	angulo = angulo + 0.2325
	opcionesGrupo.x = circuloInterno.x + ((circuloInterno.width*0.8)/2)*(math.cos(angulo))
	opcionesGrupo.y = circuloInterno.y + ((circuloInterno.width*0.8)/2)*(math.sin(angulo))
	opcionesGrupo.name = ABECEDARIO[opcionesIndex]
	OGrupo[opcionesIndex] = opcionesGrupo
	function opcionesGrupo:tap(event)
		if not isGameOver then
			tutorials.cancel(gameTutorial,300)
			sound.play("flipCard")
			respuesta[#respuesta+1] = self.name
			local respuestaTxtOpciones = {
				text = respuesta[#respuesta],
				x = 0,
				y = 0,
				width = circuloInterno.width*0.85*0.8,
				height = 0,
				font = settings.fontName,
				fontSize = FONT_SIZE/3.5,
				align = "center"
			}
			respuestaTxt = display.newText( respuestaTxtOpciones )
			respuestaTxt:setFillColor( {147/255, 204/255, 201/255} )
			RGrupo[#respuesta]:insert(respuestaTxt)
			if #respuesta == #subString then
				checarRespuestaCorrecta()
			end
		end
		return true
	end
	opcionesGrupo:addEventListener( "tap")
	return opcionesGrupo
end

local function createQuestion()
	grupoOpciones = display.newGroup( )
	for indexOpciones = 1, NUMERO_OPCIONES do
		local opcion = crearOpciones(indexOpciones, questionGroup)
		grupoOpciones:insert(opcion)
	end
	questionGroup:insert(grupoOpciones)
	local textoPreguntaO = {
		text = questionText,
		x = 0,
		y = 0,
		width = circuloInterno.width*0.85*0.8,
		height = 0,
		font = settings.fontName,
		fontSize = FONT_SIZE/3.5,
		align = "center"
	}
	pregunta = display.newText( textoPreguntaO )
	pregunta:setFillColor( unpack(QUESTION_FONT_COLOR) )
	pregunta.x = display.contentCenterX
	pregunta.y = display.viewableContentHeight*0.425
	questionGroup:insert(pregunta)

	for indexSubString = 1, string.len(answerText) do
		subString[indexSubString] = string.upper(answerText:sub(indexSubString, indexSubString))
	end

	grupoRespuesta = display.newGroup( )
	local respuestaImg	questionGroup:insert(grupoRespuesta)
	for indexR = 1, #subString do
		respuestaCompleta = display.newGroup( )
		respuestaImg = display.newImage( assetPath .. "opcion.png" )
		respuestaImg:scale( 0.2075, 0.2075 )
		respuestaCompleta: insert(respuestaImg)
		respuestaCompleta.x = ((((display.screenOriginX + (display.viewableContentWidth)) - (((respuestaImg.width*0.2125))* #subString))/2))-25+((respuestaImg.width*0.2125))*indexR
		respuestaCompleta.y = display.screenOriginY + (display.viewableContentHeight*0.565)
		RGrupo[indexR] = respuestaCompleta
		grupoRespuesta:insert(respuestaCompleta)
	end
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	isFirstTime = parameters.isFirstTime
	
	manager = event.parent
	
	questionText = parameters.question
	answerText = parameters.answer

	subString = {}
	RGrupo = {}
	respuesta = {}
	OGrupo = {}

	isGameOver = false
	angulo = 48.8
	
	instructions.text = localization.getString("instructionsLetras_0014")
end
------------------------------------ Module functions
function game.getInfo()
	return {
		available = false,
		correctDelay = 800,
		wrongDelay = 500,
		
		name = "Geo letras",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
		},
		--TO DO Add an space character
	}
end 

function game:create(event)
	local sceneView = self.view
	local background = display.newRect(display.contentCenterX,display.contentCenterY, display.viewableContentWidth + 2 ,display.viewableContentHeight + 2)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	sceneView:insert(background)
		
	local paint = {22/255, 153/255, 149/255}
	background.stroke = paint
	background.strokeWidth = 40
	local rectanguloDerecho = display.newRect( 0, display.contentCenterY, display.viewableContentWidth*0.3, display.viewableContentHeight*0.4 )
	rectanguloDerecho:setFillColor( unpack(BORDER_COLOR) )
	sceneView:insert(rectanguloDerecho)
	local rectanguloIzquierdo = display.newRect(display.viewableContentWidth, display.contentCenterY, display.viewableContentWidth*0.3, display.viewableContentHeight*0.4 )
	rectanguloIzquierdo:setFillColor( unpack(BORDER_COLOR) )
	sceneView:insert(rectanguloIzquierdo)
	local circuloExterno = display.newImage( assetPath .. "2.png" )
	circuloExterno.x = display.contentCenterX
	circuloExterno.y = display.contentCenterY
	circuloExterno:scale(0.925, 0.925)
	sceneView:insert(circuloExterno)
	circuloInterno = display.newImage( assetPath .. "1.png" )
	circuloInterno.x = display.contentCenterX
	circuloInterno.y = display.contentCenterY
	circuloInterno:scale( 0.8, 0.8 )
	sceneView:insert(circuloInterno)
		
	local borrar = display.newImage(assetPath .. "borrar.png")
	borrar.x = display.contentCenterX
	borrar.y = display.viewableContentHeight*0.675
	borrar:scale(0.25, 0.25)
	sceneView:insert(borrar)

	function borrar:tap(event)
		sound.play("flipCard")
		if #respuesta > 0 then
			RGrupo[#respuesta]:remove(2)
			respuesta[#respuesta] = nil
		end
		return true
	end
		
	borrar:addEventListener( "tap")
	
	local instructionsOptions = {
		text = "",
		x = display.contentCenterX,
		y = screen.getPositionY(0.3),
		width = circuloInterno.width *0.8 * 0.6,
		height = 0,
		font = settings.fontName,
		fontSize = FONT_SIZE/3,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
	
	questionGroup = display.newGroup()
	sceneView:insert(questionGroup)
end

function game:show(event)
	local phase = event.phase
	if phase == "will" then
		initialize(event)
		createQuestion()
		mostrarTutorial()
	elseif phase == "did" then
		
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if phase == "will" then
		
	elseif phase == "did" then
		for indexT = 1, #respuesta do
			respuesta[indexT] = nil
		end
		for indexS = 1, #subString do
			subString[indexS] = nil
		end
		for indexR = 1, #RGrupo do
			display.remove(RGrupo[indexR])
		end
		for indexO = 1, #OGrupo do
			display.remove(OGrupo[indexO])
		end
		display.remove( pregunta )
		display.remove(grupoRespuesta)
		display.remove(grupoOpciones)
		display.remove(opcionesGrupo)
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