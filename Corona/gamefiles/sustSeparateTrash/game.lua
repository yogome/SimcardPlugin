 ------------------------------------ Separar Basura
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene()
------------------------------------ Variables
local manager
local background
local basuraGrupo
local tapas = {}
local botesTexto = {}
local respuestasContestadas = {}
local esCorrecta = true
local respuestasAleatoriasGeneradas = {}
local colorBote = {}
local tiposGenerados = {}
local timerTutorial
local isFirstTime
local currentTrash
local botesGrupo
local instructions
local gameTutorial
local dynamicAnswersLayer
local possibleAnswer
local respuestaCorrecta
local correctAnswer
local offsetX = {}
local choosenTypes
------------------------------------ Constantes
local BACKGROUND_COLOR = {107/255, 208/255, 238/255}
local FONT_COLOR = {1, 1, 1}
local FONT_SIZE = 50
local FONT_FACE = "VAGRounded"
local OFFSET_X_TAPA = 80
local NUMERO_BASURA = 4
local NUMERO_BOTES = 2
local TIPOS_BASURA = {
	[1] = "Vidrio",
	[2] = "Plásticos",
	[3] = "Pet",
	[4] = "Papel",
	[5] = "Orgánicos",
	[6] = "Latas"
}

local TRASH_TRANSLATE = {
	["es"] = {
		["Vidrio"] = "Vidrio",
		["Plásticos"] = "Plásticos",
		["Pet"] = "PET",
		["Papel"] = "Papel",
		["Orgánicos"] = "Orgánicos",
		["Latas"] = "Latas"
	},
	["en"] = {
		["Vidrio"] = "Glass",
		["Plásticos"] = "Plastic",
		["Pet"] = "PET",
		["Papel"] = "Paper",
		["Orgánicos"] = "Organic",
		["Latas"] = "Cans"
	},
	["pt"] = {
		["Vidrio"] = "Vidro",
		["Plásticos"] = "plástico",
		["Pet"] = "PET",
		["Papel"] = "Papel",
		["Orgánicos"] = "orgânico",
		["Latas"] = "Lata"
	}
}

local NOMBRE_IMAGEN_BASURA = {}
local NOMBRE_IMAGEN_BOTES ={}
local NOMBRE_IMAGEN_TAPA_BOTES = {}
------------------------------------ Functions
local function crearRespuestaCorrecta()
	respuestaCorrecta = display.newGroup( )

	for indexText = 1, NUMERO_BOTES do
		local tipoTexto = display.newText(TRASH_TRANSLATE[localization.getLanguage()][tiposGenerados[indexText]],0, 100*(indexText-1)-50, FONT_FACE, FONT_SIZE*0.75) 
		respuestaCorrecta:insert(tipoTexto)
	end

	for indexGroup = 1, NUMERO_BASURA do
		for indexTrashType = 1, NUMERO_BOTES do
			if respuestasAleatoriasGeneradas[indexGroup].type == tiposGenerados[indexTrashType] then
				local basuraImg = display.newImage( respuestasAleatoriasGeneradas[indexGroup].file)
				basuraImg:scale(0.25, 0.25)
				basuraImg.x = offsetX[indexTrashType]
				basuraImg.y = (100*indexTrashType)-100
				offsetX[indexTrashType] = offsetX[indexTrashType] + (basuraImg.width*0.25) + 15
				respuestaCorrecta:insert(basuraImg)
				correctAnswer = respuestaCorrecta
				--TO DO the answer doesn't show properly
				respuestaCorrecta.alpha = 0
			end
		end
	end
end

local function mostrarTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {}
		}
		if respuestasAleatoriasGeneradas[1].type == tiposGenerados[1] then
			tutorialOptions.steps[1] = {id = "drag", delay = 1000, time = 2500, x = display.screenOriginX+(display.viewableContentWidth*0.5), y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_BASURA+1))*(1*0.75) + display.viewableContentHeight*0.25, toX = (display.screenOriginX+display.viewableContentWidth)/4, toY = display.screenOriginY+(display.viewableContentHeight*0.75)}
		else
			tutorialOptions.steps[1] = {id = "drag", delay = 1000, time = 2500, x = display.screenOriginX+(display.viewableContentWidth*0.5), y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_BASURA+1))*(1*0.75) + display.viewableContentHeight*0.25, toX =((display.screenOriginX+display.viewableContentWidth)/(2))*(1.5), toY = display.screenOriginY+(display.viewableContentHeight*0.75)}
		end
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end

local function generarRespuestasAleatorias()
	local trashType = extratable.shuffle(TIPOS_BASURA)
	possibleAnswer = {}
	for indexTipos = 1, NUMERO_BOTES do
		tiposGenerados[indexTipos] = trashType[indexTipos]
		offsetX[indexTipos] = -40
	end

	for indexTrash = 1, #NOMBRE_IMAGEN_BASURA do
		for indexType = 1, NUMERO_BOTES do
			if NOMBRE_IMAGEN_BASURA[indexTrash].type == tiposGenerados[indexType] then
				possibleAnswer[#possibleAnswer + 1] = NOMBRE_IMAGEN_BASURA[indexTrash]
			end
		end
	end

	possibleAnswer = extratable.shuffle(possibleAnswer)
	for indexRandomAnswers = 1, NUMERO_BASURA do
		respuestasAleatoriasGeneradas[#respuestasAleatoriasGeneradas+1] = possibleAnswer[indexRandomAnswers]
	end
end

local function crearBasura(nombreImagen, tipo)
	local basura = display.newImage(nombreImagen)
	basura:scale( 0.7, 0.7 )
	currentTrash = basura

	function basura:touch( event )
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			display.getCurrentStage():setFocus( self, event.id )
			sound.play("dragtrash")
			self.isFocus = true
			self.markX = self.x	
			self.markY = self.y 
			currentTrash = self
		elseif self.isFocus then
			if event.phase == "moved" then
		   		self.x = (event.x - event.xStart) + self.markX
		   		self.y = (event.y - event.yStart) + self.markY
			elseif event.phase == "ended" or event.phase == "cancelled" then
		  		display.getCurrentStage():setFocus( self, nil )
				sound.play("pop")
		  		self.isFocus = false
		  		if self.x > display.screenOriginX+(display.viewableContentWidth*0.125) and self.x <display.screenOriginX+(display.viewableContentWidth*0.375) and self.y > display.screenOriginY+(display.viewableContentHeight*0.5) and self.y < display.screenOriginY+(display.viewableContentHeight*0.875) then
		  			basura:removeSelf()
		  			if (tipo ~= tiposGenerados[1] ) then
		  				esCorrecta = false
		  			end
		  			respuestasContestadas[#respuestasContestadas+1] = esCorrecta
		  		elseif self.x > display.screenOriginX+(display.viewableContentWidth*0.625) and self.x <display.screenOriginX+(display.viewableContentWidth*0.875) and self.y > display.screenOriginY+(display.viewableContentHeight*0.5) and self.y < display.screenOriginY+(display.viewableContentHeight*0.875) then
		  			basura:removeSelf()
		  			if (tipo ~= tiposGenerados[2] ) then
		  				esCorrecta = false
		  			end
		  			respuestasContestadas[#respuestasContestadas+1] = esCorrecta
		  		end
		  		if #respuestasContestadas == NUMERO_BASURA then
		  			
		  			if esCorrecta then 
		  				manager.correct(data)
		  			else
		  				crearRespuestaCorrecta()
		  				director.to(scenePath, respuestaCorrecta, {time = 100, delay=950, alpha = 1})
		  				manager.wrong({id = "group", group = correctAnswer})
		  			end
		  		else
		  			self.x = self.markX;
		  			self.y = self.markY;
		  		end
		  		director.to(scenePath, tapas[1], {rotation = 0, time= 500, transition=easing.inOutCubic })
		  		director.to(scenePath, tapas[2], {rotation = 0, time= 500, transition=easing.inOutCubic })
		  	end
		end
		
		return true
	end
	basura:addEventListener("touch")
	return basura
end

local function generarColorBotes()
	local colorAleatorio
	local estaRepetido
	colorBote = {
		[1] = math.random(1, #NOMBRE_IMAGEN_BOTES )
	}
	repeat
		colorAleatorio = math.random(1, #NOMBRE_IMAGEN_BOTES )
		for checarRespuestaRepetida = 1, #colorBote do
			if colorAleatorio == colorBote[checarRespuestaRepetida] then
				estaRepetido = true
			end
		end
		if estaRepetido == false then
			colorBote[#colorBote+1] = colorAleatorio
		end
		estaRepetido = false
	until #colorBote == NUMERO_BOTES
end

local function moverTapa(eje)
	local rotarBote = {}
	if eje ~= nil then
		rotarBote[1] = ((((display.viewableContentWidth+display.screenOriginX)/2)-eje)*-45)/((display.viewableContentWidth+display.screenOriginX)/4)
		rotarBote[2] = ((eje-((display.viewableContentWidth+display.screenOriginX)/2))*-45)/((display.viewableContentWidth+display.screenOriginX)/4)

		for rotarBoteIndex = 1, #rotarBote do
			if rotarBote[rotarBoteIndex] < -45 then
				rotarBote[rotarBoteIndex] = -45
			end
			if rotarBote[rotarBoteIndex] > 0 then
				rotarBote[rotarBoteIndex] = 0
			end
			director.to(scenePath,  tapas[rotarBoteIndex], { rotation=rotarBote[rotarBoteIndex], time=0, transition=easing.inOutCubic } )
		end
	end
end

local function updateGame()
	moverTapa(currentTrash.x)
end

local function createDynamicAnswers()
	local grupoRespuesta = display.newGroup( )

	basuraGrupo = display.newGroup( )
	dynamicAnswersLayer:insert( basuraGrupo)

	for basuraIndex = 1, NUMERO_BASURA do
		local numeroImagen = respuestasAleatoriasGeneradas[basuraIndex]
		local basura = crearBasura(numeroImagen.file, numeroImagen.type)
		basura:scale(0.75, 0.75)
		basura.x = display.screenOriginX+(display.viewableContentWidth*0.5)
		basura.y = display.screenOriginY+(display.viewableContentHeight/(NUMERO_BASURA+1))*(basuraIndex*0.75) + display.viewableContentHeight*0.25
		basuraGrupo:insert(basura)
	end

	botesGrupo = display.newGroup( )
	dynamicAnswersLayer:insert(botesGrupo)

	local botes = {}
	generarColorBotes()

	for botesIndex = 1, NUMERO_BOTES do
		local side = botesIndex * 2 - 3
		
		botes[botesIndex] = display.newImage( NOMBRE_IMAGEN_BOTES[colorBote[botesIndex]])
		botes[botesIndex].y = display.screenOriginY+(display.viewableContentHeight*0.75)
		botes[botesIndex]:toFront()
		botesGrupo:insert(botes[botesIndex])

		botesTexto[botesIndex] = display.newText(TRASH_TRANSLATE[localization.getLanguage()][tiposGenerados[botesIndex]],botes[botesIndex].x, display.screenOriginY+(display.viewableContentHeight*0.92), FONT_FACE, FONT_SIZE)
		botesTexto[botesIndex]:setFillColor( unpack(FONT_COLOR))
		botesTexto[botesIndex].x = display.contentCenterX + (display.viewableContentWidth/4) * side
		botesGrupo:insert(botesTexto[botesIndex])

		tapas[botesIndex] = display.newImage( NOMBRE_IMAGEN_TAPA_BOTES[colorBote[botesIndex]])
		tapas[botesIndex].y = display.screenOriginY+(display.viewableContentHeight*0.65)
		tapas[botesIndex].anchorX = 0.2
		tapas[botesIndex].anchorY = 0.75
		botesGrupo:insert(tapas[botesIndex])
		
		botes[botesIndex].x = display.contentCenterX + (display.viewableContentWidth/4) * side
		tapas[botesIndex].x = (display.contentCenterX + (display.viewableContentWidth/4) * side) - OFFSET_X_TAPA
		
	end
end

local function inicializar(event)

	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	
	instructions.text = localization.getString("instructionsSepararBasura")
	
	NOMBRE_IMAGEN_BASURA = {
		{file=assetPath .. "Vidrio-01.png", type="Vidrio"}, 
		{file=assetPath .. "Vidrio-02.png", type="Vidrio"},
		{file=assetPath .. "Vidrio-03.png", type="Vidrio"},
		{file=assetPath .. "Vidrio-04.png", type="Vidrio"},
		{file=assetPath .. "Vidrio-05.png", type="Vidrio"},
		{file=assetPath .. "Plasticos-01.png", type="Plásticos"}, 
		{file=assetPath .. "Plasticos-02.png", type="Plásticos"},
		{file=assetPath .. "Plasticos-03.png", type="Plásticos"},
		{file=assetPath .. "Plasticos-04.png", type="Plásticos"},
		{file=assetPath .. "Plasticos-05.png", type="Plásticos"}, 
		{file=assetPath .. "pet-01.png", type="Pet"},
		{file=assetPath .. "pet-02.png", type="Pet"},
		{file=assetPath .. "pet-03.png", type="Pet"},
		{file=assetPath .. "pet-04.png", type="Pet"}, 
		{file=assetPath .. "pet-05.png", type="Pet"},
		{file=assetPath .. "Papel-01.png", type="Papel"},
		{file=assetPath .. "Papel-02.png", type="Papel"},
		{file=assetPath .. "Papel-03.png", type="Papel"}, 
		{file=assetPath .. "Papel-04.png", type="Papel"},
		{file=assetPath .. "Papel-05.png", type="Papel"},
		{file=assetPath .. "Organicos-01.png", type="Orgánicos"},
		{file=assetPath .. "Organicos-02.png", type="Orgánicos"}, 
		{file=assetPath .. "Organicos-03.png", type="Orgánicos"},
		{file=assetPath .. "Organicos-04.png", type="Orgánicos"},
		{file=assetPath .. "Organicos-05.png", type="Orgánicos"},
		{file=assetPath .. "latas-01.png", type="Latas"},
		{file=assetPath .. "latas-02.png", type="Latas"}, 
		{file=assetPath .. "latas-03.png", type="Latas"},
		{file=assetPath .. "latas-04.png", type="Latas"},
		{file=assetPath .. "latas-05.png", type="Latas"}
	}
	NOMBRE_IMAGEN_BOTES ={
		[1] = assetPath .. "minigame-RecycleH-02.png",	
		[2] = assetPath .. "minigame-RecycleH-04.png",
		[3] = assetPath .. "minigame-RecycleH-06.png",
		[4] = assetPath .. "minigame-RecycleH-08.png"
	}
	NOMBRE_IMAGEN_TAPA_BOTES = {
		[1] = assetPath .. "minigame-RecycleH-01.png", 	
		[2] = assetPath .. "minigame-RecycleH-03.png", 
		[3] = assetPath .. "minigame-RecycleH-05.png", 
		[4] = assetPath .. "minigame-RecycleH-07.png" 
	}

	local trashType = extratable.shuffle(TIPOS_BASURA)
	possibleAnswer = {}
	for indexTipos = 1, NUMERO_BOTES do
		tiposGenerados[indexTipos] = trashType[indexTipos]
		offsetX[indexTipos] = -40
	end

	for indexTrash = 1, #NOMBRE_IMAGEN_BASURA do
		for indexType = 1, NUMERO_BOTES do
			if NOMBRE_IMAGEN_BASURA[indexTrash].type == tiposGenerados[indexType] then
				possibleAnswer[#possibleAnswer + 1] = NOMBRE_IMAGEN_BASURA[indexTrash]
			end
		end
	end

	possibleAnswer = extratable.shuffle(possibleAnswer)
	for indexRandomAnswers = 1, NUMERO_BASURA do
		respuestasAleatoriasGeneradas[#respuestasAleatoriasGeneradas+1] = possibleAnswer[indexRandomAnswers]
	end
end
------------------------------------ Module functions
function game.getInfo()
	return {
		available = true,
		correctDelay = 400,
		wrongDelay = 400,
		
		name = "Garbage collection",
		category = "sustainability",
		subcategories = {"recycle"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "classify",
		requires = {
			{id = "randomTrash", amount = 2, groups = 2},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local background = display.newImage(assetPath .. "fondo.png")
	background.anchorY = 0.75
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight*0.75
	background:scale(backgroundScale, backgroundScale)
	sceneView:insert(background)

	local barraElementos = display.newImage( assetPath .. "barraelementos.png" ) 
	--barraElementos:scale(0.65, 1)
	barraElementos.x = display.contentCenterX
	barraElementos.y = display.viewableContentHeight * 0.625
	sceneView:insert(barraElementos)

	local instruccionesImg = display.newImage( assetPath .. "instruccion.png" )
	instruccionesImg.anchorY = 0
	instruccionesImg.y = display.screenOriginY
	instruccionesImg.x = display.contentCenterX
	sceneView:insert(instruccionesImg)
	
	local instructionsOptions = 
	{
		text = "",     
		x = display.contentCenterX,
		y = display.screenOriginY + 75,
		font = settings.fontName,   
		fontSize = 32,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(0/255, 161/255, 215/255)
	sceneView:insert(instructions)

	dynamicAnswersLayer = display.newGroup( )
	sceneView:insert(dynamicAnswersLayer)
end

function game:show(event)
	local phase = event.phase
	if( phase == "will") then
		inicializar(event)
		createDynamicAnswers()
		Runtime:addEventListener( "enterFrame", updateGame )
		mostrarTutorial()
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		Runtime:removeEventListener( "enterFrame", updateGame )
		display.remove( botesGrupo )
		display.remove(basuraGrupo)
		tutorials.cancel(gameTutorial)
		for indexT = 1, #respuestasContestadas do
			respuestasContestadas[indexT] = nil
		end
		for indexPA = 1, #possibleAnswer do
			possibleAnswer[indexPA] = nil
		end 
		for indexRA = 1, #respuestasAleatoriasGeneradas do
			respuestasAleatoriasGeneradas[indexRA] = nil
		end
		esCorrecta = true
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