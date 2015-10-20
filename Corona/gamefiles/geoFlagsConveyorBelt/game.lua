----------------------------------------------- Math Claw
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local gameView
local flags
local yaRespondio
local correctAnswer
local correctAnswerImage
local casa
local correctFlag
local isFirstTime, gameTutorial
local banderas
local dynamicGroup
local backgroundGroup
----------------------------------------------- Constants
local CENTERX = display.contentCenterX
local CENTERY = display.contentCenterY
local SCREEN_LEFT = display.screenOriginX
local SCREEN_WIDTH = display.viewableContentWidth - SCREEN_LEFT * 2
local SCREEN_TOP = display.screenOriginY
local SCREEN_HEIGHT = display.viewableContentHeight - SCREEN_TOP * 2

local TAG_TRANSITION_BANDA = "tagBanda"
local SPEED_BAND = 0.25
local OFFSET_FLAG = {x = 15, y = 10}
local SCALE_FLAGS = 0.55
----------------------------------------------- Functions

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 3000, x = correctFlag.x, y = correctFlag.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function diplayCountryBanner(pais)
	local banner = display.newImage(gameView, assetPath .. "banner.png")
	banner.x = display.contentCenterX
	banner.y = display.screenOriginY
	banner.anchorY = 0
	
	local text = display.newText(pais, display.contentCenterX, 120, settings.fontName, 50)
	text:setFillColor(1)
	gameView:insert(text)
	
	local instructionOptions = {
		text = localization.getString("instructionsGeoFlags"),     
		x = banner.x,
		y = banner.height*1.1,
		width = banner.width,
		font = settings.fontName,   
		fontSize = 24,
		align = "center"  
	}
	local instructions = display.newText(instructionOptions)
	gameView:insert(instructions)
end

local function displayCountryBoxes()
	local correctIndex = math.random(1, 3)
	if banderas and #banderas > 0 then
		local margin = 100
		local espacio = (display.viewableContentWidth -2*margin) / 4 

		local language = localization.getLanguage()
		flags = {}
		for i = 1, 3 do
			local flagData = banderas[i]
			local pais = flagData[language]			
			
			local flagBox = display.newGroup()
			gameView:insert(flagBox)

			display.newImage(flagBox, assetPath.."box.png")
			local flagImage = display.newImage(flagBox, flagData.image)
			flagImage.x = OFFSET_FLAG.x
			flagImage.y = OFFSET_FLAG.y
			flagImage:scale(SCALE_FLAGS,SCALE_FLAGS)
			flagBox.image = flagData.image
			flagBox.pais = pais
			flagBox.x = margin + espacio * i
			flagBox.y = CENTERY
			flagBox.delay = 1700 * i
			
			if i == correctIndex then
				flagBox.isCorrect = true
			else	
				flagBox.isCorrect = false
			end
			
			flagBox:addEventListener("touch", function()
				tutorials.cancel(gameTutorial)
				if yaRespondio then
					return
				end		
				sound.play("pop")
				
				yaRespondio = true
				if flagBox.isCorrect then
					manager.correct({delay = flagBox.delay})
				else	
					manager.wrong({id = "image", image = correctAnswerImage},{delay = flagBox.delay})
				end
				
				director.to(scenePath, flagBox, {time=500, y=display.contentHeight -130, tag = TAG_TRANSITION_BANDA, onComplete = function()
					local dist = flagBox.x - display.screenOriginX
					director.to(scenePath, flagBox, {time=dist/SPEED_BAND, x=display.screenOriginX -100, tag = TAG_TRANSITION_BANDA})
				end})			
			end)
			flags[i] = flagBox
		end

		correctFlag = flags[correctIndex]
		correctAnswer = correctFlag.pais
		correctAnswerImage = correctFlag.image
		diplayCountryBanner(correctAnswer)
	end
	casa:toFront()
end

local function displayEndlessBand()
	display.remove(gameView)
	gameView = display.newGroup()
	dynamicGroup:insert(gameView)
	
	local puerta = display.newImage(gameView, assetPath .. "puerta.png")
	puerta.x = display.screenOriginX 
	puerta.anchorX = 0
	puerta.y = display.contentHeight
	puerta.anchorY = 1
	
	casa = display.newImage(gameView, assetPath .. "casa.png")
	casa.x = display.screenOriginX
	casa.anchorX = 0
	casa.y = display.contentHeight
	casa.anchorY = 1
	
	local posX = puerta.width
	repeat
		local banda = display.newImage(gameView, assetPath .. "banda.png")
		banda.x = posX
		posX = posX + banda.width
		banda.anchorX = 0
		banda.y = display.contentHeight
		banda.anchorY = 1
	until posX > display.viewableContentWidth
	
	posX = puerta.width / 2
	repeat
		local diagonal = display.newImage(gameView, assetPath .. "diagonal.png")
		diagonal.x = posX + 15
		posX = posX + 120
		diagonal.y = display.contentHeight -12
		diagonal.anchorY = 1
		
		diagonal.moverse = function()
			local dist = diagonal.x - display.screenOriginX
			director.to(scenePath, diagonal, {time=dist/SPEED_BAND, x=display.screenOriginX -100, tag = TAG_TRANSITION_BANDA,
			onComplete = function() 
				diagonal.x = display.contentWidth + 10
				diagonal.moverse()
			end})
		end
		diagonal.moverse()
	until posX > display.viewableContentWidth +100
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	
	manager = event.parent
	yaRespondio = false
	isFirstTime = parameters.isFirstTime
	banderas = parameters.flags or {}
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {		
		available = true,
		wrongDelay = 2000,
		correctDelay = 2000,
		
		name = "Geo flags 1",
		category = "geography",
		subcategories = {"countries"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "flags", amount = 3},
		},
	}
end 

function game:create(event)
	local sceneGroup = game.view
	
	backgroundGroup = display.newGroup()
		
	local background = display.newImage(assetPath .. "fondo.png")
	background.x = CENTERX
	background.y = CENTERY
    background.width = SCREEN_WIDTH
    background.height = SCREEN_HEIGHT
	backgroundGroup:insert(background)
	
	sceneGroup:insert(backgroundGroup)
	
	dynamicGroup = display.newGroup()
	sceneGroup:insert(dynamicGroup)
end

function game:destroy(event)

end

function game:show( event )
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)
		displayEndlessBand()
		displayCountryBoxes()
		showTutorial()
	elseif ( phase == "did" ) then
	
	end
end

function game:hide( event )
	local phase = event.phase
	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		if flags then
			for index = 1, #flags do
				display.remove(flags[index])
			end
		end
		transition.cancel(TAG_TRANSITION_BANDA)
		display:remove(backgroundGroup)
		display:remove(gameView)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game

