------------------------------------ Post-it_001
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )

local game = director.newScene()
------------------------------------ Variables
local isFirstTime, gameTutorial
local instructions
local questions, answers, wrongAnswer, shuffleAnswers, shuffleQuestions
local manager
local preguntas
local answerGroup
local esCorrecta
local primeraVez
local respuestaSeleccionada = {}
local tapsEnabled
local ocupado = {
	[1] = {drag= false, estado=false},
	[2] = {drag= false, estado=false},
	[3] = {drag= false, estado=false}
}
------------------------------------ Constantes
local BACKGROUND_COLOR = { 9/255, 99/255, 86/255 }
local FONT_SIZE = 100
local FONT_FACE = "VAGRounded"
local FONT_COLOR_ANSWERS = {0, 0, 0}
local NUMERO_PREGUNTAS = 3
local NUMERO_RESPUESTAS = 4
local IMAGENES_RESPUESTAS = 
{
	[1] = {file = "", id=1},
	[2] = {file = "", id=2},
	[3] = {file = "", id=3},
	[4] = {file = "", id=4}
}


------------------------------------ Functions
local function showTutorial()
	if isFirstTime then
		local pos
		local posXQuestion = display.screenOriginX+(display.viewableContentWidth*0.3)
		local posYQuestion = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))
		local posXAnswer = display.screenOriginX+(display.viewableContentWidth*0.75)
		local posYAnswer

		for indexCorrectAnswertutorial = 1, NUMERO_RESPUESTAS do
			if shuffleQuestions[1].answer == shuffleAnswers[indexCorrectAnswertutorial] then
				posYAnswer = display.screenOriginY+(display.viewableContentHeight/(NUMERO_RESPUESTAS+1))*indexCorrectAnswertutorial
			end
		end

		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1500, time = 1450, x = posXAnswer, y = posYAnswer, toX = posXQuestion, toY = posYQuestion},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function checarRespuestaCorrecta()
	local data = {}
	esCorrecta = true
	for i = 1, NUMERO_PREGUNTAS do
		if respuestaSeleccionada[i] ~= shuffleQuestions[i].answer then
			esCorrecta = false
		end
	end
	if esCorrecta then
		manager.correct(data)
	else
		manager.wrong({
						id = "text",
						text = shuffleQuestions[1].answer.."\n"..
						shuffleQuestions[2].answer.."\n"..
						shuffleQuestions[3].answer,
						fontSize = 40
		})
	end
end

local function crearRespuestas(nombreImagen, textoR)
	nombreImagen.texto = textoR
	nombreImagen.idR = id
	local respuestas = display.newImage( nombreImagen.file)
	local options =
	{
		text = textoR,
		x = 0,
		y = 0,
		width = respuestas.width*0.35,
		height = 0,
		font = FONT_FACE,
		fontSize = FONT_SIZE/5,
		align = "center"
	}
	local textoR = display.newText( options)
	textoR:setFillColor(unpack(FONT_COLOR_ANSWERS))
	respuestas:scale(0.85, 0.85)
	local respuestaCompleta = display.newGroup( )
	respuestaCompleta: insert(respuestas)
	respuestaCompleta: insert(textoR)

	function respuestaCompleta:touch( event )
		if tapsEnabled then
			if event.phase == "began" then
				self:toFront()
				tutorials.cancel(gameTutorial)
				display.getCurrentStage():setFocus( self, event.id )
				self.isFocus = true
				sound.play("dragtrash")
				self.markX = self.x	
				self.markY = self.y 
				for i=1, NUMERO_PREGUNTAS do
					if self.y == display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))*i then
						ocupado[i].drag = true
					end
				end

			elseif self.isFocus then
				if event.phase == "moved" then
					self.x = (event.x - event.xStart) + self.markX
			   		self.y = (event.y - event.yStart) + self.markY
				
				elseif event.phase == "ended" or event.phase == "cancelled" then
			  		display.getCurrentStage():setFocus( self, nil )
			  		self.isFocus = false
					sound.play("pop")
			  		if self.x > display.screenOriginX+(display.viewableContentWidth*0.2) and self.x <display.screenOriginX+(display.viewableContentWidth*0.4) and self.y > display.screenOriginY+(display.viewableContentHeight*0.15) and self.y < display.screenOriginY+(display.viewableContentHeight*0.3) and ocupado[1].estado == false then
			  			self.x = display.screenOriginX+(display.viewableContentWidth*0.3)
			  			self.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))
			  			for i=1, NUMERO_PREGUNTAS do
			  				if i == 1 then
			  					ocupado[i].estado = true
			  					respuestaSeleccionada[i] = nombreImagen.texto
			  				else
			  					if ocupado[i].drag then
			  						ocupado[i].estado = false
			  						ocupado[i].drag = false
			  						respuestaSeleccionada[i] = ""
			  					end
			  				end
			  			end
			  		elseif self.x > display.screenOriginX+(display.viewableContentWidth*0.2) and self.x <display.screenOriginX+(display.viewableContentWidth*0.4) and self.y > display.screenOriginY+(display.viewableContentHeight*0.2)*2 and self.y < display.screenOriginY+(display.viewableContentHeight*0.3)*2 and ocupado[2].estado == false then
			  			self.x = display.screenOriginX+(display.viewableContentWidth*0.3)
			  			self.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))*2
			  			for i=1, NUMERO_PREGUNTAS do
				  			if i == 2 then
				  				ocupado[i].estado = true
				  				respuestaSeleccionada[i] = nombreImagen.texto
				  			else
				  				if ocupado[i].drag then
			  						ocupado[i].estado = false
			  						ocupado[i].drag = false
			  						respuestaSeleccionada[i] = ""
				  				end
				  			end
				  		end
			  		elseif self.x > display.screenOriginX+(display.viewableContentWidth*0.2) and self.x <display.screenOriginX+(display.viewableContentWidth*0.4) and self.y > display.screenOriginY+(display.viewableContentHeight*0.2)*3 and self.y < display.screenOriginY+(display.viewableContentHeight*0.3)*3 and ocupado[3].estado == false then
			  			self.x = display.screenOriginX+(display.viewableContentWidth*0.3)
			  			self.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))*3
			  			for i=1, NUMERO_PREGUNTAS do
				  			if i == 3 then
			  					ocupado[i].estado = true
			  					respuestaSeleccionada[i] = nombreImagen.texto
			  				else
			  					if ocupado[i].drag then
			  						ocupado[i].estado = false
			  						ocupado[i].drag = false
			  						respuestaSeleccionada[i] = ""
			  					end
			  				end
			  			end
			  		elseif self.x > display.screenOriginX+(display.viewableContentWidth*0.4) or self.x < display.screenOriginX+(display.viewableContentWidth*0.2) or  self.y < display.screenOriginY+(display.viewableContentHeight*0.15) or self.y > display.screenOriginY+(display.viewableContentHeight*0.3)*3 then
			  			for i=1, NUMERO_PREGUNTAS do
			  				if ocupado[i].drag then
				  				ocupado[i].estado = false
				  				ocupado[i].drag = false
				  				respuestaSeleccionada[i] = ""
			  				end
			  			end
			  			self.x = display.screenOriginX+(display.viewableContentWidth*0.75)
			  			self.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_RESPUESTAS+1))*nombreImagen.id
			  		else
			  			self.x = self.markX;
			  			self.y = self.markY;
			  			for i=1, NUMERO_PREGUNTAS do
			  				if ocupado[i].drag then
				  				ocupado[i].estado = false
				  				ocupado[i].drag = false
				  				respuestaSeleccionada[i] = ""
			  				end
			  			end
			  		end
			  		if ocupado[1].estado == true and ocupado[2].estado == true and ocupado[3].estado == true then
			  			tapsEnabled = false
						checarRespuestaCorrecta()
					end	
			  	end
			end
			
			return true
		end
	end
	respuestaCompleta:addEventListener("touch")
	return respuestaCompleta
end

local function inicializar(sceneView, parameters)
	tapsEnabled = true
	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime
	instructions.text = localization.getString("instructionsPostit_001")

	IMAGENES_RESPUESTAS[1].file = assetPath .. "MinigamesGeo-09.png"
	IMAGENES_RESPUESTAS[2].file = assetPath .. "MinigamesGeo-10.png"
	IMAGENES_RESPUESTAS[3].file = assetPath .. "MinigamesGeo-11.png"
	IMAGENES_RESPUESTAS[4].file = assetPath .. "MinigamesGeo-12.png"
	
	questions = parameters.questions
	answers = parameters.answers
	wrongAnswer = parameters.wrongAnswers[1]
	
	shuffleQuestions = {
		[1] = {question = questions[1], answer = answers[1]},
		[2] = {question = questions[2], answer = answers[2]},
		[3] = {question = questions[3], answer = answers[3]}
	}
	
	shuffleAnswers = {}
	shuffleAnswers[1] = answers[1]
	shuffleAnswers[2] = answers[2]
	shuffleAnswers[3] = answers[3]
	shuffleAnswers[4] = wrongAnswer
	
	shuffleAnswers = extratable.shuffle(shuffleAnswers)
		
	answerGroup = display.newGroup()
	sceneView:insert(answerGroup)

	local imagenPregunta = {}
	preguntas = display.newGroup( )
	sceneView:insert(preguntas)
	
	for i = 1, NUMERO_PREGUNTAS do
		imagenPregunta[i] = display.newImage(assetPath .. "MinigamesGeo-08.png")
		imagenPregunta[i]:scale(0.8, 0.8)
		imagenPregunta[i].x = display.screenOriginX+(display.viewableContentWidth*0.3)
		imagenPregunta[i].y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))*i
		local options = {
			text = shuffleQuestions[i].question,
			x = display.screenOriginX+(display.viewableContentWidth*0.3),
			y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_PREGUNTAS+1))*i,
			width = imagenPregunta[i].width*0.6,
			height = 0,
			font = FONT_FACE,
			fontSize = FONT_SIZE/5,
			align = "center"
		}
		local textoP = display.newText(options)
		local preguntaCompleta = display.newGroup( )
		preguntaCompleta:insert(imagenPregunta[i])
		preguntaCompleta:insert(textoP)
		preguntas:insert(preguntaCompleta)
	end

	for respuestasIndex = 1 , NUMERO_RESPUESTAS do
		local respuestas  = crearRespuestas(IMAGENES_RESPUESTAS[respuestasIndex], shuffleAnswers[respuestasIndex]  )
		respuestas.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_RESPUESTAS+1))*respuestasIndex
		respuestas.x = display.screenOriginX+(display.viewableContentWidth*0.75)
		answerGroup:insert(respuestas)
	end
	sceneView:insert(answerGroup)
	
	showTutorial()
end
------------------------------------ Module functions
function game.getInfo()
	return {
		-- TODO verify info -- Answers only in spanish
		available = false,
		correctDelay = 400,
		wrongDelay = 400,
		
		
		name = "Geo Post it",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 3},
			{id = "wrongAnswer", amount = 1},
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
		x = display.screenOriginX+(display.viewableContentWidth*0.3),
		y = display.screenOriginY+(display.viewableContentHeight*0.07),
		width = 450,
		font = settings.fontName,   
		fontSize = 32,
		align = "center"
	}

	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end

function game:show(event)
	local phase = event.phase
	if( phase == "will") then
		manager = event.parent
		inicializar(self.view, event.params)
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		display.remove( preguntas )
		display.remove( answerGroup )
		ocupado = {
			[1] = {drag= false, estado=false},
			[2] = {drag= false, estado=false},
			[3] = {drag= false, estado=false}
		}
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