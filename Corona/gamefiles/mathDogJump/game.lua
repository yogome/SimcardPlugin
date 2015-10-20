----------------------------------------------- Math dog
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local colors = require( "libs.helpers.colors" )
local screen = require( "libs.helpers.screen" )

local game = director.newScene()
----------------------------------------------- Variables
local dynamicSceneGroup

local perro
local saltando
local perroCanJump
local resultadoOperacion
local huesitoA
local huesitoB

local dynamicBones

local huesitoRespuesta
local background
local manager
local isFirstTime
local mathData
local huesosTimer
local gameTutorial
local instructions
local wrongAnswers
local operationResult
----------------------------------------------- Constants
local TAG_HUESITO = "huesitovolador"
local TUTORIAL_INSTRUCTIONS_FONT_COLOR = colors.white
local positions = {
	operacion = {x = display.viewableContentWidth * 0.20, 
				 y = display.viewableContentHeight * 0.15},
	respuestas = {y = display.viewableContentHeight * 0.50},
	perrito = {x = display.viewableContentWidth * 0.20, 
			   y = display.viewableContentHeight * 0.80}
}
local COLOR_SKY = {0.3019, 0.6549, 0.9333}
local COLOR_GRASS = {0.4980, 0.6980, 0}
local DEFAULT_SUBCATEGORY = "addition"
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 2000, x = positions.perrito.x, y = positions.perrito.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function crearOperacion()
	local operando1Text = mathData.operand1
	local operadorText = mathData.operatorChar
	local operando2Text = mathData.operand2
	
	local operando1 = display.newText(operando1Text, huesitoA.x + 27.5, huesitoA.y - 10, 80, 60, settings.fontName, 60)
	operando1:setFillColor(89/255, 26/255, 26/255)
	local operador = display.newImage(operadorText)
	operador.x = display.viewableContentWidth*0.35
	operador.y = display.viewableContentHeight*0.25
	--operador:setFillColor(89/255, 26/255, 26/255)
	local operando2 = display.newText(operando2Text,  huesitoB.x + 27.5, huesitoB.y - 10, 80, 60,  settings.fontName, 60)
	operando2:setFillColor(89/255, 26/255, 26/255)
	local equal = display.newImage("images/minigames/equalsDarkBrown.png",  display.viewableContentWidth*0.65, display.viewableContentHeight*0.25, 60, 60,  settings.fontName, 60)
	dynamicSceneGroup:insert(operando1)
	dynamicSceneGroup:insert(operador)
	dynamicSceneGroup:insert(operando2)
	dynamicSceneGroup:insert(equal)
end

local function resetHueso(hueso)
	hueso.x = display.viewableContentWidth + 257 
	director.to(scenePath, hueso, {time = 8000, x = display.screenOriginX-257, tag = TAG_HUESITO , onComplete = function()
		resetHueso(hueso)
	end})
end

local function generarRandom()
	return wrongAnswers[math.random(1, #wrongAnswers)]
end

local function generaHuesitos()
	local totalHuesos = 4
	local huesoRespuesta = math.random(totalHuesos)
	
	local randomTracker = {}
	for boneIndex=1, totalHuesos do
		local numero
		
		if boneIndex == huesoRespuesta then
			numero = resultadoOperacion
		else
			numero = generarRandom()
			randomTracker[#randomTracker + 1] = numero
			for trackerN = 1, boneIndex do
				if randomTracker[trackerN] == numero then
					numero = generarRandom()
				end
			end
		end
		
		local bone = display.newGroup()
		bone.x = display.viewableContentWidth + 257
		bone.y = positions.respuestas.y
		bone.numero = numero

		local offsetX = 0
		local offsetY = -10

		if bone.numero < 10 then
			offsetX = 27.5
		else
			offsetX = 17.5
		end

		local boneBackground = display.newImage(assetPath .. "minigames-elements2-01.png")
		local boneText = display.newText(numero, boneBackground.x + offsetX, boneBackground.y + offsetY, 80, 60, settings.fontName, 60)
		boneText:setFillColor(89/255, 26/255, 26/255)
		
		bone:insert(boneBackground)	
		bone:insert(boneText)
		dynamicSceneGroup:insert(bone)
		
		dynamicBones[boneIndex] = bone
	end
	
	local transisionIndex = 1
	huesosTimer = director.performWithDelay(scenePath, 2000, function()
		resetHueso(dynamicBones[transisionIndex])
		transisionIndex = transisionIndex + 1
	end, #dynamicBones)
end

local function checkAnswers(answer)
	if answer == resultadoOperacion then
		if manager and manager.wrong then
			manager.correct()
		end
	else
		if manager and manager.wrong then
			manager.wrong({id = "text", text = operationResult , fontSize = 75})
		end
	end
end

local function endGame(huesoScore)
	checkAnswers(huesoScore.numero)
end

local function checarColisionHueso()
	for boneIndex = 1, #dynamicBones do
		local bone = dynamicBones[boneIndex]
		local leftCollisionCheck = (perro.x - (perro.width * 0.5) + 100) >= (bone.x - (bone.width * 0.5) - 80)
		local rightCollisionCheck = (perro.x + (perro.width * 0.5)) <= (bone.x + (bone.width * 0.5) + 80)
		
		if leftCollisionCheck and rightCollisionCheck then
			perroCanJump = false
			transition.cancel(bone)
			endGame(bone)
			director.to(scenePath, bone, {time = 500, x = huesitoRespuesta.x, y = huesitoRespuesta.y, onStart= function() sound.play("pop") end,})
		end
	end
	return false
end

local function saltar()
	if saltando or not perroCanJump then
		return
	end
	sound.play("minigamesdog")
	tutorials.cancel(gameTutorial,300)
	saltando = true
	perro:setSequence("jump")
	perro:play()
	
	director.to(scenePath, perro, {time = 500, y = positions.respuestas.y, transition = easing.outQuad, onComplete = function()
		local colision = checarColisionHueso()--TODO: use result from function
		director.to(scenePath, perro, {time = 500, y = positions.perrito.y, transition = easing.inQuad, onComplete = function()
			perro:correr()
			saltando = false
		end})
	end})
end

local function generaPerro()
	
	local perroData = { width = 256, height = 256, numFrames = 8 }
	local perroSheet = graphics.newImageSheet( assetPath .. "Minigame21Dog.png", perroData )

	local sequenceData = {
		{name = "run", sheet = perroSheet, start = 1, count = 6, time = 500 },
		{name = "jump", sheet = perroSheet, start = 7, count = 2, time = 500 },
	}
	
	perro = display.newSprite(perroSheet, sequenceData)
	perro.x = positions.perrito.x
	perro.y = positions.perrito.y - 50
	 
	function perro:correr()
		self:setSequence("run")
		self:play()
	end
	
	perro:correr()
	perro:addEventListener("tap", saltar)
	dynamicSceneGroup:insert(perro)
end

local function initializeGameElements(sceneGroup)
	dynamicSceneGroup = display.newGroup()
	sceneGroup:insert(dynamicSceneGroup)
	
	crearOperacion()
	generaHuesitos()
	generaPerro()
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	
	saltando = false
	perroCanJump = true
	dynamicBones = {}

	manager = event.parent
	
	operationResult = parameters.operation.operationString
	
	instructions.text = localization.getString("instructionsMathdog")

	local operatorFilenames = {
		["addition"] = "images/minigames/plusDarkBrown.png",
		["subtraction"] = "images/minigames/minusDarkBrown.png",
		["multiplication"] = "images/minigames/multiplyDarkBrown.png",
		["division"] = "images/minigames/divisionDarkBrown.png",
	}

	local chosenCategory = parameters.topic or DEFAULT_SUBCATEGORY
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	mathData = {
		operand1 = operation.operands[1] or 0,
		operand2 = operation.operands[2] or 0,
		correctAnswer = operation.result or 0,
		operatorChar = operatorFilenames[chosenCategory],
	}
	
	resultadoOperacion = mathData.correctAnswer
	wrongAnswers = parameters.wrongAnswers
	
	isFirstTime = parameters.isFirstTime
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = false,
		wrongDelay = 800,
		correctDelay = 800,
		
		name = "Math dog",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minOperand = 1},
			{id = "wrongAnswer", amount = 8, tolerance = 10, minNumber = 2},
		},
	}
end 

function game:create( event )
	local sceneView = self.view
	
	background = display.newImage( assetPath .. "fondo.png" )
	background.anchorY = 1
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight
	local backgroundScale = display.viewableContentWidth/background.width
	background:scale( backgroundScale, backgroundScale )

	--local backgroundCielo = display.newRect(background, display.contentCenterX, display.contentCenterY * 0.80, display.viewableContentWidth + 2, (display.viewableContentHeight + 2) * 0.80)
	--local backgroundPasto = display.newRect(background, display.contentCenterX, display.contentCenterY * 1.80, display.viewableContentWidth + 2, (display.viewableContentHeight + 2) * 0.20)
	
	--backgroundCielo:setFillColor(unpack(COLOR_SKY))
	--backgroundPasto:setFillColor(unpack(COLOR_GRASS))
	
	sceneView:insert(background)
	--local x = positions.operacion.x
	--local operandoSize = 60
	huesitoA = display.newImage(assetPath .. "minigames-elements2-01.png", display.viewableContentWidth*0.20, display.viewableContentHeight*0.25)
	--x = x + huesitoA.width + operandoSize
	huesitoB = display.newImage(assetPath .. "minigames-elements2-01.png", display.viewableContentWidth*0.50 , display.viewableContentHeight*0.25)
	--x = x + huesitoB.width + operandoSize
	huesitoRespuesta = display.newImage(assetPath .. "minigames-elements2-02.png", display.viewableContentWidth*0.80 , display.viewableContentHeight*0.25)
	
	sceneView:insert(huesitoA)
	sceneView:insert(huesitoB)
	sceneView:insert(huesitoRespuesta)
	
	local instructionOptions = {
		text = "",	 
		x = display.contentCenterX,
		y = display.screenOriginY+100,
		width = display.contentWidth,
		height = 140,
		font = settings.fontName,   
		fontSize = 34,
		align = "center"
	}
	instructions = display.newText(instructionOptions)
	instructions:setFillColor(unpack(TUTORIAL_INSTRUCTIONS_FONT_COLOR))
	sceneView:insert(instructions)
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)
		initializeGameElements(sceneGroup)
		showTutorial()
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then 
		tutorials.cancel(gameTutorial)
		if huesosTimer then
			timer.cancel(huesosTimer)
		end
		display.remove(dynamicSceneGroup)
		dynamicSceneGroup = nil
	end
end

function game:destroy( event )
	local sceneGroup = self.view
	
end

game:addEventListener( "create", game )
game:addEventListener( "show", game )
game:addEventListener( "hide", game )
game:addEventListener( "destroy", game )

return game
