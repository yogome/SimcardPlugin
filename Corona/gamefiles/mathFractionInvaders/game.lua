----------------------------------------------- MathShip
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local widget = require( "widget" ) 
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local sound = require( "libs.helpers.sound" )
local extracollision = require( "libs.helpers.extracollision" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local backgroundLayer
local answersLayer
local textLayer
local nave
local bulletList
local isFirstTime
local gameTutorial
local tutorialText
local nubesGroup
local nubeList
local boton
local respuestasGeneradas
local respuestasOrdenadas
local manager
local correctSequence
local numTopList
local numBotList
----------------------------------------------- Constants

local COLOR_INSTRUCTIONS = {1, 1, 1}
local COLOR_NUMBERS = {48/255, 128/255, 182/255}
local DESPAWN_Y_BULLET = display.screenOriginY-50
local TIME_BULLET_TRANSITION = 900
local SIZE_TEXT = 38
local OFFSET_TOP_NUMBER = {x=0, y=-35}
local OFFSET_BOTTOM_NUMBER = {x=0, y=8}
local RADIUS_BULLET = 40
local RADIUS_NUBE = 50
local TOTAL_NUBES = 3
local PADDING_OBJECTS = 250
local VELOCIDAD_ESTRELLAS = 0.03


----------------------------------------------- Functions

local function dragShip(event)
	local nave = event.target
	local phase = event.phase
	
	if "began" == phase then
		display.getCurrentStage():setFocus( nave, event.id )
		nave.isFocus = true
		
		tutorials.cancel(gameTutorial,300)
		sound.play("dragtrash")
		nave.x0 = event.x - nave.x
		
	elseif nave.isFocus then
		if "moved" == phase then
			if event.x > nave.width*0.6 and event.x < (boton.x - boton.width) then
				nave.x = event.x - nave.x0
			end
		elseif "ended" == phase or "cancelled" == phase then
			sound.play("pop")
			display.getCurrentStage():setFocus(nave, nil)
			nave.isFocus = false			
		end
	end
	return true
end

local function disparo()
	tutorials.cancel(gameTutorial,300)
	local bullet = display.newImage( assetPath.."bala.png" )
	bullet.x = nave.x 
	bullet.y = nave.y 
	bullet.radius = RADIUS_BULLET
	backgroundLayer:insert(bullet)
	sound.play("minigamesLaser")
	nave:toFront()

	director.to(scenePath, bullet, { y = DESPAWN_Y_BULLET , time = TIME_BULLET_TRANSITION, onComplete = function()
		bullet.removeFlag = true
	end})

	bulletList[#bulletList+1] = bullet
end

local function verificaRespuesta(nube)
	if nube.division ~= respuestasOrdenadas[1] then
		manager.wrong({id = "text", text = correctSequence, fontSize = 48})
	end
	table.remove( respuestasOrdenadas, 1 )
	if respuestasOrdenadas[#respuestasOrdenadas] == nil then
		
		manager.correct()
	end
end

local function updateGame()
	for bulletIndex = #bulletList, 1, -1 do
		local bullet = bulletList[bulletIndex]
		for nubeIndex = 1, #nubeList do
			local nube = nubeList[nubeIndex]
			if extracollision.checkCircleCollision(bullet, nube) and not nube.hasBeenShot then
				sound.play("minigamesPortal")
				--transition.fadeOut( nube, {time = 300}) 
				transition.to(nube, {alpha = 0, time = 400, transition = easing.outInBack})
				nube.hasBeenShot = true
				bullet.removeFlag = true
				verificaRespuesta(nube)
			end
		end
		
		if bullet.removeFlag then
			display.remove(bullet)
			table.remove(bulletList, bulletIndex)
		end
	end
end

local function generateRespuestas()
	local respuestaAleatoria
	local respuestaAleatoriaIndex = 1
	local repetido = false

	repeat 
		respuestaAleatoria = math.random( 1, 7 )
		for revisaRespuesta = 1, TOTAL_NUBES do
			if respuestaAleatoria == respuestasGeneradas[revisaRespuesta] then
				repetido = true
			end
		end
		if not repetido then
			respuestasGeneradas[#respuestasGeneradas+1] = respuestaAleatoria
		end
		repetido = false
		respuestaAleatoriaIndex = respuestaAleatoriaIndex +1 
	until #respuestasGeneradas == TOTAL_NUBES
end

local function generateNubes()
	nubesGroup = display.newGroup()
	answersLayer:insert(nubesGroup)
	nubeList = {}
	numTopList = {}
	numBotList = {}
	
	local yMinima = display.viewableContentHeight*0.25
	local yMaxima = nave.y - nave.height
	
	local totalWidth = (TOTAL_NUBES - 1) * PADDING_OBJECTS
	local startX = (display.viewableContentWidth - boton.width)*0.5 - totalWidth * 0.5

	for indexNubes = 1, TOTAL_NUBES do
		local numeroTop = respuestasGeneradas[indexNubes]
		local nube = display.newGroup()
		nube.x = startX + (indexNubes - 1) * PADDING_OBJECTS
		nube.y = math.random( yMinima, yMaxima)
		nube.radius = RADIUS_NUBE
		nubesGroup:insert( nube )

		local nubeBg = display.newImage( assetPath.."fraccionBg.png")
		nubeBg.xScale = 0.9
		nubeBg.yScale = 0.9
		nube:insert( nubeBg )

		nube.topNumber = display.newText(numeroTop, OFFSET_TOP_NUMBER.x, OFFSET_TOP_NUMBER.y, settings.fontName, SIZE_TEXT)
		nube.topNumber:setFillColor(unpack(COLOR_NUMBERS))
		nube:insert( nube.topNumber )
		local numTop = numeroTop
		
		local numBot = math.random(1,6)
		nube.bottomNumber = display.newText(numBot, OFFSET_BOTTOM_NUMBER.x, OFFSET_BOTTOM_NUMBER.y, settings.fontName, SIZE_TEXT)
		nube.bottomNumber:setFillColor(unpack(COLOR_NUMBERS))
		nube:insert( nube.bottomNumber )
		
		nube.division = (numTop / numBot)
		numTopList[#numTopList + 1] = numTop
		numBotList[#numBotList + 1] = numBot
		nube.hasBeenShot = false

		respuestasOrdenadas[#respuestasOrdenadas+1]= nube.division

		nubeList[#nubeList+1] = nube

		local function compare( a, b )
			return a < b
		end

		table.sort( respuestasOrdenadas, compare )
		
		local function movimientoY(answerGroup)
			local toY
			repeat 
				toY = math.random(yMinima, yMaxima)
			until math.abs(answerGroup.y - toY) > (yMinima-yMaxima)*0.25

			local duracion = math.abs(answerGroup.y - toY) / VELOCIDAD_ESTRELLAS
			director.to(scenePath, answerGroup, { delay = 0, time = duracion, y = toY, onComplete = function()
				movimientoY(answerGroup)
			end})			
		end

		movimientoY(nube)

	end
	
	correctSequence = ""
	local targetNumberTop = {}
	local targetNumberBot = {}

	for outIndex = 1, TOTAL_NUBES do
		for inIndex = 1, #respuestasOrdenadas do
			if respuestasOrdenadas[outIndex] == numTopList[inIndex]/numBotList[inIndex] then
				targetNumberTop[outIndex] = numTopList[inIndex]
				targetNumberBot[outIndex] = numBotList[inIndex]
			end
		end
		correctSequence = correctSequence..targetNumberTop[outIndex].."/"..targetNumberBot[outIndex]..", "
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	
	tutorialText.text = localization.getString("instructionMathship")
	
	bulletList = {}
	respuestasGeneradas = {}
	respuestasOrdenadas = {}
	generateRespuestas()
	generateNubes()
	
	nave.x = (display.viewableContentWidth - boton.width)*0.5
end

local function tutorial()
	if isFirstTime then
		local nubeMenor
		for index=1, #respuestasOrdenadas do
			if nubeList[index].division == respuestasOrdenadas[1] then
				nubeMenor = nubeList[index]
			end
		end
		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = nave.x, y = nave.y, toX = nubeMenor.x, toY = nave.y},
				[2] = {id = "tap", delay = 800, time = 2500, x = boton.x, y = boton.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false,
		correctDelay = 400,
		wrondDelay = 400,
		
		name = "Math ship",
		category = "math",
		subcategories = {"fractions"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "fractions", amount = 3, unique = true},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	
	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	local background = display.newImage( assetPath.."fondo.png" )
	local backgroundScale = display.viewableContentWidth / background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = backgroundScale
	background.yScale = backgroundScale
	backgroundLayer:insert(background)
		
	local instructionOptions = {
		text = "",	 
		x = (display.viewableContentWidth*0.5),
		y = (display.viewableContentHeight * 0.1),
		width = display.viewableContentWidth*0.8,
		font = settings.fontName,  
		fontSize = 32,
		align = "center"
	}
		
	tutorialText = display.newText(instructionOptions)
	tutorialText:setFillColor( unpack(COLOR_INSTRUCTIONS) ) 
	textLayer:insert(tutorialText)
	
	nave = display.newImage(assetPath.."nave.png")
	nave.x = display.contentCenterX
	nave.y = display.viewableContentHeight * 0.8
	nave.xScale = 0.8
	nave.yScale = 0.8
	nave:addEventListener("touch", dragShip)
	backgroundLayer:insert(nave)
	
	local buttonOptions = {
		width = 128,
		height = 128,
		defaultFile = assetPath.."btnUp.png",
		overFile = assetPath.."btnDown.png",
		onPress = function()
			disparo()
		end
	}

	boton = widget.newButton(buttonOptions)
	boton.x = display.viewableContentWidth-120
	boton.y = display.viewableContentHeight-120
	backgroundLayer:insert(boton)

end

function game:destroy()
	
end
function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		
		initialize(event)
		tutorial()

		Runtime:addEventListener( "enterFrame", updateGame )
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
	
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		Runtime:removeEventListener( "enterFrame", updateGame )
		for bulletIndex=1, #bulletList do
			display.remove(bulletList[bulletIndex])
		end
		display.remove( nubesGroup )
	end
end
----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
