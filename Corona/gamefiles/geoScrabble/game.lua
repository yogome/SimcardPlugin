------------------------------------ Scrabble_009
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local extratable = require("libs.helpers.extratable")
local settings = require("settings")
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene()
------------------------------------ Variables

local answerGroup = {}
local respuestasAleatorias = {}
local manager
local tablero
local playerWon = true
local grupoRespuesta
local isFirstTime
local answerSplit = {}
local preguntaTxt
local respuestaContestada = {}
local lettersGroup
local timerTutorial
local correctAnswer
local optionGroup
local instructions
local gameTutorial
local answerText
local tapsEnabled
------------------------------------ Constantes
local BACKGROUND_COLOR = {53/255, 4/255, 173/255}
local FONT_COLOR_PREGUNTA = {53/255, 4/255, 173/255}
local FONT_COLOR_OPCIONES = {0/255, 160/255, 168/255}
local NUMERO_OPCIONES = 10

------------------------------------ Functions
local function mostrarTutorial()
	if isFirstTime then
		local correctAnswerPosition
		local positionX = tablero.x - (tablero.width*0.25)
		local positionY = tablero.y - ((tablero.height*0.75)*0.175) 

		for indexCheckPosition = 1, NUMERO_OPCIONES do
			if correctAnswer[indexCheckPosition] == answerSplit[1] then
				correctAnswerPosition = indexCheckPosition
				break
			end
			if indexCheckPosition % 5 == 0 then
				positionX = tablero.x - (tablero.width*0.25)
				positionY = positionY + (optionGroup.contentHeight)
			else
				positionX = positionX + (optionGroup.contentWidth)
			end	
		end

		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 800, time = 2500, x = positionX, y = positionY, toX = answerGroup[1].x, toY = answerGroup[1].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function checarRespuestaCorrecta()
	for indexCheckAnswer = 1, #answerSplit do
		if respuestaContestada[indexCheckAnswer] ~= answerSplit[indexCheckAnswer] then
			playerWon = false
		end
	end
	if playerWon then
		manager.correct()
	else
		manager.wrong({id = "text", text = answerText , fontSize = 75})
	end
end

local function generarRespuestasAleatorias ()
				
	correctAnswer = extratable.deepcopy(answerSplit)
	
	local currentLength = #correctAnswer
	local lenghtToComplete = NUMERO_OPCIONES - currentLength
	
	for indexOption = 1, lenghtToComplete do
		local randomCharacter = string.char(math.random(65, 90))
		correctAnswer[#correctAnswer + 1] = string.upper(randomCharacter)	
	end
	
	correctAnswer = extratable.shuffle(correctAnswer)
	respuestasAleatorias = correctAnswer
end

local function letterTouched(event)
	if tapsEnabled then
		local phase = event.phase
		local target = event.target
		if phase == "began" then
			tutorials.cancel(gameTutorial,300)
			transition.cancel(target)
			target:toFront( )
			target.x = event.x
			target.y = event.y
			sound.play("dragtrash")
			target.onSlot = false
			if target.slot then
				target.slot.isEmpty = true
				target.slot = nil
			end
			display.getCurrentStage():setFocus( event.target )
			target.isMoving = true
		elseif phase == "moved" then
			if target.isMoving then
				target.x = event.x
				target.y = event.y		
			end
		elseif phase == "ended" then
			local isTimeToCheckAnswer = true
			sound.play("pop")
			for indexAnswer = 1, #answerGroup do
				local currentSlot = answerGroup[indexAnswer]
				if target.x < (currentSlot.x + currentSlot.contentWidth * 0.5) and
					target.x > (currentSlot.x - currentSlot.contentWidth * 0.5) and
					target.y < (currentSlot.y + currentSlot.contentHeight * 0.5) and
					target.y > (currentSlot.y - currentSlot.contentHeight * 0.5) then
						if currentSlot.isEmpty then
							respuestaContestada[answerGroup[indexAnswer].id] = target.char.text
							currentSlot.isEmpty = false
							target.onSlot = true
							target.slot = currentSlot
						end
				end
				isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			end
			
			if target.slot then
				director.to(scenePath, target, {time = 200, x = target.slot.x, y = target.slot.y, xScale = 1.2, yScale = 1.2})
			else
				director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY, xScale = 1, yScale = 1})
			end
			
			if isTimeToCheckAnswer then
				tapsEnabled = false
				checarRespuestaCorrecta()
			end
			
			display.getCurrentStage():setFocus( nil )
		end
	end
end

local function crearOpciones(sceneGroup)
		
		local offsetX = tablero.x - (tablero.width*0.25)
		local offsetY = tablero.y  - ((tablero.height*0.75)*0.175) 
		
		lettersGroup = display.newGroup()
		
		for indexOption = 1, #respuestasAleatorias do
			
			optionGroup = display.newGroup()
			local optionBackground = display.newImage(assetPath .. "opcion.png")
			optionBackground:scale(0.25, 0.25)
			optionGroup:insert(optionBackground)
			
			local optionText = display.newText(respuestasAleatorias[indexOption], 0, 0, settings.fontName, 36)
			optionText:setFillColor(unpack(FONT_COLOR_OPCIONES))
			optionGroup:insert(optionText)
			
			optionGroup.char = optionText

			optionGroup.x = offsetX
			optionGroup.y = offsetY
			optionGroup.initX = offsetX
			optionGroup.initY = offsetY
			optionGroup.onSlot = false
			
			optionGroup:addEventListener("touch", letterTouched)
			
			if indexOption%5 == 0 then
				offsetX = tablero.x - (tablero.width*0.25)
				offsetY = offsetY + (optionGroup.contentHeight * 2)
			else
				offsetX = offsetX + (optionGroup.contentWidth * 2)
			end
			
			lettersGroup:insert(optionGroup)

		end
		sceneGroup:insert(lettersGroup)

		 
end
local function inicializar (sceneView, parameters)
	tapsEnabled = true
	parameters = parameters or {}
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsScrabble_009")
	grupoRespuesta = display.newGroup( )
	preguntaTxt.text = parameters.question
	--local answerText = parameters.answer
	answerText = "correct"
	for indexSubString = 1, string.len(answerText) do
		answerSplit[indexSubString] = string.upper(answerText:sub(indexSubString, indexSubString))
	end
	generarRespuestasAleatorias()
		
	local respuestaImg
	for indexR = 1, #answerSplit do
		respuestaImg = display.newImage( assetPath .. "respuesta.png" )
		respuestaImg:scale( 0.3, 0.3 )
		respuestaImg.x = ((((display.screenOriginX + (display.viewableContentWidth)) - (((respuestaImg.width*0.35))* #answerSplit))/2))-50+((respuestaImg.width*0.35))*indexR
		respuestaImg.y = display.screenOriginY + (display.viewableContentHeight*0.3)
		respuestaImg.isEmpty = true
		respuestaImg.id = indexR
		answerGroup[indexR] = respuestaImg
		grupoRespuesta:insert(respuestaImg)
	end
		
	sceneView:insert(grupoRespuesta)
	crearOpciones(sceneView)

end
------------------------------------ Module functions
function game.getInfo()
	return {
		-- TODO fill correct info -- Only in spanish
		available = false,
		correctDelay = 400,
		wrongDelay = 400,
		
		name = "Geo Scrabble",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 0},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
		
	local background = display.newRect(display.contentCenterX,display.contentCenterY, display.viewableContentWidth + 2 ,display.viewableContentHeight + 2)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	sceneView:insert(background)
		
	local fondoPregunta = display.newImage( assetPath .. "pregunta.png" )
	fondoPregunta.x = display.contentCenterX
	fondoPregunta.y = display.screenOriginY + (display.contentHeight * 0.125)
	fondoPregunta:scale(0.75, 0.8)
	sceneView:insert(fondoPregunta)
		
	local opcionesPreguntaTxt = {
		text = "QUESTION",
		x = 0,
		y = 0,
		width = fondoPregunta.width*0.75*0.9,
		height = 0,
		font = settings.fontName,
		fontSize = 25,
		align = "center"
	}
		
	preguntaTxt = display.newText( opcionesPreguntaTxt )
	preguntaTxt:setFillColor( unpack( FONT_COLOR_PREGUNTA ) )
	preguntaTxt.x = display.contentCenterX
	preguntaTxt.y = display.screenOriginY + (display.viewableContentHeight*0.125)
	sceneView:insert(preguntaTxt)
	
	tablero = display.newImage( assetPath .. "tablero.png", display.contentCenterX, display.screenOriginY + (display.viewableContentHeight*0.7 ))
	tablero:scale(0.75, 0.75)
	sceneView:insert(tablero)

	instructions = display.newText("",  display.screenOriginX+(display.viewableContentWidth*0.5), display.screenOriginY+(display.viewableContentHeight*0.425), settings.fontName, 36)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end

function game:show(event)
	local phase = event.phase
	manager = event.parent
	if( phase == "will") then
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
		display.remove(lettersGroup)
		display.remove(grupoRespuesta)
		tutorials.cancel(gameTutorial)
		playerWon = true
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

function game:destroy()

end
------------------------------------ Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game