----------------------------------------------- EquationMarker
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local firstTime
local primerOperando
local segundoOperando
local signoIgual
local respuestaOperando
local answerGroup = {}
local posicionEcuacionY
local grupoEcuacionPregunta
local answerSplit = {}
local correctAnswerTable
local respuestasAleatorias = {}
local frutaElegida
local respuestaContestada = {}
local grupoOpciones
local grupoEcuacionRespuesta
local playerWin
local conjuntoOpciones = {}
local timerTutorial
local signoMatematico
local operand1
local operand2
local correctAnswer
local wrongAnswers
local nameImageOperator
local instructions
local gameTutorial
local grupoEcuacionOpcion
----------------------------------------------- Constants
local POS_NUMBER_OBJECTS = {
	[0] = {{x=0,y=0},},
	[1] = {{x=0,y=0},},
	[2] = {{x=-0.5,y=0},{x=0.5,y=0},},
	[3] = {{x=-0.5,y=-0.75},{x=0,y=0},{x=0.5,y=0.75},},
	[4] = {{x=-0.5,y=-0.5},{x=0.5,y=0.5},{x=-0.5,y=0.5},{x=0.5,y=-0.5},},
	[5] = {{x=-0.5,y=-0.75},{x=0.5,y=0.75},{x=-0.5,y=0.75},{x=0.5,y=-0.75},{x=0,y=0},},
	[6] = {{x=-0.5,y=-0.75},{x=0.5,y=0.75},{x=-0.5,y=0.75},{x=0.5,y=-0.75},{x=-0.5,y=0},{x=0.5,y=0},},
	[7] = {{x=-0.7,y=-0.75},{x=0,y=-0.75},{x=-0.7,y=0.75},{x=0.7,y=-0.75},{x=-0.7,y=0},{x=0.7,y=0},{x=0,y=0},},
	[8] = {{x=-0.7,y=-0.75},{x=0,y=0.75},{x=-0.7,y=0.75},{x=0.7,y=-0.75},{x=-0.7,y=0},{x=0.7,y=0},{x=0,y=0},{x=0,y=-0.75},},
	[9] = {{x=-0.7,y=-0.75},{x=0.7,y=0.75},{x=-0.7,y=0.75},{x=0.7,y=-0.75},{x=-0.7,y=0},{x=0.7,y=0},{x=0,y=0},{x=0,y=-0.75},{x=0,y=0.75},},
}
local FONT_NAME = settings.fontName
local NUMERO_ELEMENTOS_ECUACION = 5
local NUMERO_RESPUESTAS = 4
----------------------------------------------- Functions
local function tutorial()
	if firstTime then 
		local posRes
		for indexRespuestaCorrecta = 1, #conjuntoOpciones do
			if answerSplit[1] == respuestasAleatorias[indexRespuestaCorrecta] then
				posRes = indexRespuestaCorrecta
			end
		end
		local tutorialOptions = {
			iterations = 5,
			scale = 0.7,
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = conjuntoOpciones[posRes].x, y = conjuntoOpciones[posRes].y, toX = answerGroup[1].x, toY = answerGroup[1].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) -- TODO gameTutorial es una variable global
	end
end

local function createImageAnswerGroup(number, pX, pY)
	local answerGroupImages = display.newGroup()
	local offsetY = -10
	local tablePos = POS_NUMBER_OBJECTS[number]
	for index=1, #tablePos do
		local object = display.newImage(assetPath .. frutaElegida .. ".png")
		object.x = pX + tablePos[index].x * object.width * 0.65
		object.y = pY + tablePos[index].y * object.height * 0.75 + offsetY
		object.xScale = 0.5
		object.yScale = 0.5
		answerGroupImages:insert(object)
	end
	return answerGroupImages
end

local function checarRespuestaCorrecta()
	playerWin = true
	local data = {}
	local answerGroup = display.newGroup()
	local nextPosition = -300
	for indexChecarRespuesta = 1, #respuestaContestada do
		local card = display.newImage( assetPath .. "carta.png" )
		card.x = nextPosition
		local fruits = createImageAnswerGroup(answerSplit[indexChecarRespuesta], nextPosition, 0)
		answerGroup:insert(card)
		answerGroup:insert(fruits)
		nextPosition = nextPosition + 300
		if respuestaContestada[indexChecarRespuesta] ~= answerSplit[indexChecarRespuesta] then
			playerWin = false
		end
	end
	
	local operation = display.newImage(nameImageOperator)
	operation.x = -150
	answerGroup:insert(operation)
	
	local equals = display.newImage("images/minigames/equalsWhite.png")
	equals.x = 150
	answerGroup:insert(equals)
	
	answerGroup.x = 9999 ; answerGroup.y = 9999
	answerGroup.xScale = 0.5 ; answerGroup.yScale = 0.5
	answerGroup.alpha = 1
	if playerWin then 
		manager.correct(data)
	else
		manager.wrong({id = "group", group = answerGroup})
	end
end

local function generarRespuestasAleatorias()
	correctAnswerTable = extratable.deepcopy(answerSplit)

	for indexChar = 1, NUMERO_RESPUESTAS do
		local randomIndex = math.random(1, #correctAnswerTable)
		local temp = correctAnswerTable[indexChar]
		correctAnswerTable[indexChar] = correctAnswerTable[randomIndex]
		correctAnswerTable[randomIndex] = temp
	end
	
	respuestasAleatorias = correctAnswerTable
end

local function crearPreguntaEcuacion (indexCrearEcuacion)
	local xPosition = display.screenOriginX+(display.viewableContentWidth/(NUMERO_RESPUESTAS+1))*indexCrearEcuacion
	local yPosition = display.screenOriginY+(display.viewableContentHeight*0.85)
	grupoOpciones = display.newGroup()
	local imagenPreguntaEcuacion = display.newImage( assetPath .. "carta.png" )
	local imagesGroup = createImageAnswerGroup(respuestasAleatorias[indexCrearEcuacion], 0, 0)
	grupoOpciones:insert(imagenPreguntaEcuacion)
	grupoOpciones:insert(imagesGroup)
	grupoOpciones.onSlot = false
	grupoOpciones.x = xPosition
	grupoOpciones.y = yPosition
	grupoOpciones.initX = xPosition
	grupoOpciones.initY = yPosition
	grupoOpciones.char = respuestasAleatorias[indexCrearEcuacion]
	conjuntoOpciones[indexCrearEcuacion]= grupoOpciones
	
	function grupoOpciones:touch(event)
		if event.phase == "began" then
			tutorials.cancel(gameTutorial, 300)
			self:toFront( )
			self.x = event.x
			self.y = event.y
			self.onSlot = false
			sound.play("dragtrash")
			if self.slot then
				self.slot.isEmpty = true
				self.slot = nil
			end
			display.getCurrentStage():setFocus( self, event.id )
			self.isMoving = true
			transition.cancel(self)
		elseif event.phase == "moved" then
			if self.isMoving then
				self.x = event.x
				self.y = event.y
			end
		elseif event.phase == "ended" or event.phase == "cancelled" then
			local isTimeToCheckAnswer = true
			for indexAnswer = 1, #answerGroup do
				local currentSlot = answerGroup[indexAnswer]
				if self.x < (currentSlot.x + currentSlot.contentWidth * 0.5) and
					self.x > (currentSlot.x - currentSlot.contentWidth * 0.5) and
					self.y < (currentSlot.y + currentSlot.contentHeight * 0.5) and
					self.y > (currentSlot.y - currentSlot.contentHeight * 0.5) then
					if currentSlot.isEmpty then
						respuestaContestada[answerGroup[indexAnswer].id] = self.char
						currentSlot.isEmpty = false
						self.onSlot = true
						self.slot = currentSlot
					end
	   			end
	   		 	isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			end
			if self.slot then
				director.to(scenePath, self, {time = 200, x = self.slot.x, y = self.slot.y, xScale = 0.875, yScale = 0.875})
				sound.play("pop")
			else
				director.to(scenePath, self, {time = 500, x = self.initX, y = self.initY, xScale = 0.75, yScale = 0.75})
			end
	
			if isTimeToCheckAnswer then
				self:removeEventListener( "touch" )
				checarRespuestaCorrecta()
			end
	  		display.getCurrentStage():setFocus( self, nil )
		end
		return true
	end

	grupoOpciones:addEventListener( "touch" )
	return grupoOpciones
end

local function createElements()
	local sceneView = game.view
	primerOperando.text = operand1
	segundoOperando.text = operand2
	respuestaOperando.text = correctAnswer
	signoMatematico = display.newImage(nameImageOperator)
	signoMatematico.x = display.viewableContentWidth*0.40
	signoMatematico.y = posicionEcuacionY
	grupoEcuacionPregunta:insert(signoMatematico)
	frutaElegida = math.random(1, 7)

	grupoEcuacionRespuesta = display.newGroup( )
	
	for indexCrearEcuacion = 1, NUMERO_ELEMENTOS_ECUACION do
		local imagenRespuestaEcuacion
		if indexCrearEcuacion%2 == 0 then
			if indexCrearEcuacion == NUMERO_ELEMENTOS_ECUACION - 1 then
				imagenRespuestaEcuacion = display.newImage("images/minigames/equalsWhite.png")
			else
				imagenRespuestaEcuacion = display.newImage(nameImageOperator)
			end
		else
			imagenRespuestaEcuacion = display.newImage( assetPath .. "respuesta.png" )
			answerGroup[#answerGroup+1] = imagenRespuestaEcuacion
			answerGroup[#answerGroup].id = #answerGroup 
			imagenRespuestaEcuacion.isEmpty = true
		end
		imagenRespuestaEcuacion.x = display.screenOriginX+(display.viewableContentWidth/(NUMERO_ELEMENTOS_ECUACION+1))*indexCrearEcuacion
		imagenRespuestaEcuacion.y = display.screenOriginY+(display.viewableContentHeight*0.475)
		imagenRespuestaEcuacion:scale( 0.85, 0.85 )
		grupoEcuacionRespuesta:insert(imagenRespuestaEcuacion)
	end
	sceneView:insert(grupoEcuacionRespuesta)

	grupoEcuacionOpcion = display.newGroup( )
	for indexCrearEcuacion = 1, NUMERO_RESPUESTAS do
		local crearEcuacion = crearPreguntaEcuacion(indexCrearEcuacion)
		grupoEcuacionOpcion:insert(crearEcuacion)
		crearEcuacion:scale( 0.75, 0.75 )
	end
	sceneView:insert(grupoEcuacionOpcion)
end

local function initialize(parameters)
	local sceneView = game.view
	parameters = parameters or {}

	firstTime = parameters.isFirstTime
	
	instructions.text = localization.getString("instructionsEquationmarker")
	
	local operatorFilenames = {
		["addition"] = "images/minigames/plusWhite.png",
		["subtraction"] = "images/minigames/minusWhite.png",
		["multiplication"] = "images/minigames/multiplyWhite.png",
		["division"] = "images/minigames/divisionWhite.png",
	}
	
	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	operand1 = operation.operands and operation.operands[1] or 0
	operand2 = operation.operands and operation.operands[2] or 0
	correctAnswer = operation.result or 0
	wrongAnswers = parameters.wrongAnswers
	
	local answersSettedTable = {operand1, operand2, correctAnswer, 0}
	local fakeAnswer
	repeat 
		fakeAnswer = wrongAnswers[math.random(1,#wrongAnswers)]
	until not extratable.containsValue(answersSettedTable, fakeAnswer)
	table.insert(answersSettedTable, fakeAnswer)
	

	nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	
	answerSplit[1] = operand1
	answerSplit[2] = operand2
	answerSplit[3] = correctAnswer
	answerSplit[4] = fakeAnswer
	generarRespuestasAleatorias()
end

----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 400,
		wrongDelay = 400,
		
		
		name = "Equation Marker",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minAnswer = 1, maxAnswer = 9, maxOperand = 9, minOperand = 1},
			{id = "wrongAnswer", amount = 5, minNumber = 1, maxNumber = 9},
		},
	}
end 

function game:create(event)

	local sceneGroup = self.view
	local background = display.newImage(assetPath .. "fondo.png")
	background.anchorY = 0.65
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight*0.65
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale(backgroundScale, backgroundScale)
	sceneGroup:insert(background)
	background:toBack( )
	
	grupoEcuacionPregunta = display.newGroup( )
	posicionEcuacionY = display.viewableContentHeight*0.175
	primerOperando = display.newText("?", display.viewableContentWidth*0.30, posicionEcuacionY , FONT_NAME, 124)
	grupoEcuacionPregunta:insert(primerOperando)

	segundoOperando = display.newText("?", display.viewableContentWidth*0.50, posicionEcuacionY, FONT_NAME, 124)
	grupoEcuacionPregunta:insert(segundoOperando)

	signoIgual = display.newImage("images/minigames/equalsWhite.png")
	signoIgual.x = display.viewableContentWidth*0.60
	signoIgual.y = posicionEcuacionY
	grupoEcuacionPregunta:insert(signoIgual)

	respuestaOperando = display.newText("?", display.viewableContentWidth*0.70, posicionEcuacionY, FONT_NAME, 124)
	grupoEcuacionPregunta:insert(respuestaOperando)
	
	sceneGroup:insert(grupoEcuacionPregunta)
	
	instructions = display.newText("",  display.contentCenterX, display.screenOriginY + 45, settings.fontName, 32)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneGroup:insert(instructions)
	
end


function game:destroy()
	
end


function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		manager = event.parent
		initialize(event.params)
		createElements()
		tutorial()
	elseif ( phase == "did" ) then

	end
end


function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		for indexRemoverOpciones = 1, #conjuntoOpciones do
			display.remove(conjuntoOpciones[indexRemoverOpciones])
		end
		display.remove(grupoEcuacionRespuesta)
		display.remove(signoMatematico)
		display.remove(grupoEcuacionOpcion)
		playerWin = true
		for indexT = 1, #answerGroup do
			answerGroup[indexT] = nil
		end
		for indexS = 1, #answerSplit do
			answerSplit[indexS] = nil
		end
		for indexRemoveAnswer = 1, #respuestaContestada do
			respuestaContestada[indexRemoveAnswer] = nil
		end
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
