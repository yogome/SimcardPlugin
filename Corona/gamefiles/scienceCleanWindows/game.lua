----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" ) 

local game = director.newScene() 
----------------------------------------------- Variables
local answersLayer, correctWindowTable
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabled
local isFirstTime
local gameTutorial
local randomPositionTable
local gameMode
local selectedGameMode, remainingGameModes
local correctAnswers
local correctAnswerGroup
local shinyParticleGroup
local tutorialPosX, tutorialPosY
----------------------------------------------- Constants
local FONT_NAME = settings.fontName
local SIZE_FONT = 24
local INSTRUCTIONS_FONT_COLOR = { 8/255, 107/255, 188/255 }

local WINDOW_TOTAL_NUMBER = 13
local WINDOW_CORRECT_NUMBER = 5
local MAX_NUMBER_WINDOWS = 4
local WINDOW_SCALE = 0.78

local PADDING_WRONG_ANSWERS = 110

local POS_WINDOWS = {
	[1] = { x = display.contentCenterX * 0.82, y = display.contentCenterY * 0.40},
	[2] = { x = display.contentCenterX * 1.18, y = display.contentCenterY * 0.40},
	[3] = { x = display.contentCenterX * 0.43, y = display.contentCenterY * 0.82},
	[4] = { x = display.contentCenterX * 0.82, y = display.contentCenterY * 0.82},
	[5] = { x = display.contentCenterX * 1.18, y = display.contentCenterY * 0.82},
	[6] = { x = display.contentCenterX * 1.58, y = display.contentCenterY * 0.82},
	[7] = { x = display.contentCenterX * 0.43, y = display.contentCenterY * 1.25},
	[8] = { x = display.contentCenterX * 0.82, y = display.contentCenterY * 1.25},
	[9] = { x = display.contentCenterX * 1.18, y = display.contentCenterY * 1.25},
	[10] = { x = display.contentCenterX * 1.58, y = display.contentCenterY * 1.25},
	[11] = { x = display.contentCenterX * 0.43, y = display.contentCenterY * 1.66},
	[12] = { x = display.contentCenterX * 1.18, y = display.contentCenterY * 1.66},
	[13] = { x = display.contentCenterX * 1.58, y = display.contentCenterY * 1.66},
}

local POS_PARTICLES = {
	[1] = { x = -50, y = -50},
	[2] = { x = 50, y = 0},
	[3] = { x = -25, y = 50},
}

local screenLeft = display.screenOriginX
local screenTop = display.screenOriginY
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenHeight = display.viewableContentHeight - screenTop * 2

----------------------------------------------- Functions
local function onAnswerTapped(event)
	local answer = event.target 
	if tapsEnabled then
		if answer.hasBeenSelected == false then
			answer.hasBeenSelected = true
			if answer.isCorrect then 
				if manager then 
					sound.play("rightChoice")
					correctAnswers = correctAnswers + 1
					
					local shinyParticles = display.newImage(assetPath .. "destello.png")
					shinyParticles.alpha = 0
					shinyParticles:scale(0.60, 0.60)
					shinyParticles.x = answer.x + POS_PARTICLES[1].x
					shinyParticles.y = answer.y + POS_PARTICLES[1].y
					shinyParticleGroup:insert(shinyParticles)

					local shinyParticles2 = display.newImage(assetPath .. "destello.png")
					shinyParticles2.alpha = 0
					shinyParticles2:scale(0.60, 0.60)
					shinyParticles2.x = answer.x + POS_PARTICLES[2].x
					shinyParticles2.y = answer.y + POS_PARTICLES[2].y
					shinyParticleGroup:insert(shinyParticles2)

					local shinyParticles3 = display.newImage(assetPath .. "destello.png")
					shinyParticles3.alpha = 0
					shinyParticles3:scale(0.60, 0.60)
					shinyParticles3.x = answer.x + POS_PARTICLES[3].x
					shinyParticles3.y = answer.y + POS_PARTICLES[3].y
					shinyParticleGroup:insert(shinyParticles3)	
					answersLayer:insert(shinyParticleGroup)

					local function blinkParticleListener()
						transition.to( shinyParticles3, { alpha = 1, time = 1000, onComplete = function()
							transition.to( shinyParticles3, { alpha = 0, time = 1000 })
							transition.to( shinyParticles2, { alpha = 1, time = 1000, onComplete = function()
								transition.to( shinyParticles2, { alpha = 0, time = 1000 })
								transition.to( shinyParticles, { alpha = 1, time = 1000, onComplete = function()
									transition.to( shinyParticles, { alpha = 0, time = 1000, onComplete = blinkParticleListener })
								end })
							end })
						end })
					end

					blinkParticleListener()

					if correctAnswers == WINDOW_CORRECT_NUMBER then
						manager.correct()
					end
				end
			else
				if manager then 
					sound.play("wrongChoice")
					
					local totalWidth = (MAX_NUMBER_WINDOWS - 7) * PADDING_WRONG_ANSWERS
					local startX = totalWidth * 0.5
					
					for i = 1, MAX_NUMBER_WINDOWS do
						local correctWindows = display.newImage(assetPath .. selectedGameMode .. i..".png")
						correctWindows.x = startX + (i - 1) * PADDING_WRONG_ANSWERS
						correctWindows:scale(.50, .50)
						correctAnswerGroup:insert(correctWindows)
					end

					manager.wrong({id = "group", group = correctAnswerGroup}) 
				end
			end
		end
	end
end

local function removeDynamicAnswers()
	for i = 1, WINDOW_TOTAL_NUMBER do
		display.remove(correctWindowTable[i])
	end
end

local function selectGameMode()
	gameMode = math.random(1, 4)
	
	if gameMode == 1 then
		selectedGameMode = "Transparentes"
		remainingGameModes = {
			[1] = { mode = "Traslucido"},
			[2] = { mode = "Opaco"},
			[3] = { mode = "Reflector"},
			[4] = { mode = "VentanaRelleno"},
		}
	elseif gameMode == 2 then
		selectedGameMode = "Traslucido"
		remainingGameModes = {
			[1] = { mode = "Transparentes"},
			[2] = { mode = "Opaco"},
			[3] = { mode = "Reflector"},
			[4] = { mode = "VentanaRelleno"},
		}
	elseif gameMode == 3 then
		selectedGameMode = "Opaco"
		remainingGameModes = {
			[1] = { mode = "Transparentes"},
			[2] = { mode = "Traslucido"},
			[3] = { mode = "Reflector"},
			[4] = { mode = "VentanaRelleno"},
		}
	elseif gameMode == 4 then
		selectedGameMode = "Reflector"
		remainingGameModes = {
			[1] = { mode = "Transparentes"},
			[2] = { mode = "Traslucido"},
			[3] = { mode = "Opaco"},
			[4] = { mode = "VentanaRelleno"},
		}
	end	
end

local function shuffleTablePositions()
	math.randomseed( os.time() )
	local function shuffle(t)
		local iterations = #t
		local j

		for i = iterations, 2, -1 do
			j = math.random(i)
			t[i], t[j] = t[j], t[i]
		end
	end
	shuffle(randomPositionTable)
end

local function createRandomWindows()
	correctWindowTable = {}
	for i = 1, WINDOW_TOTAL_NUMBER do
		correctWindowTable[i] = display.newGroup()
		if i <= 5 then
			local windowImage = display.newImage(assetPath .. selectedGameMode .. math.random(1, 4)..".png")
			windowImage:scale(WINDOW_SCALE, WINDOW_SCALE)
			correctWindowTable[i]:insert(windowImage)
			correctWindowTable[i].x = POS_WINDOWS[randomPositionTable[i]].x
			correctWindowTable[i].y = POS_WINDOWS[randomPositionTable[i]].y
			tutorialPosX = correctWindowTable[i].x
			tutorialPosY = correctWindowTable[i].y
			correctWindowTable[i].isCorrect = true
			correctWindowTable[i].hasBeenSelected = false
			correctWindowTable[i]:addEventListener( "tap", onAnswerTapped )
			answersLayer:insert(correctWindowTable[i])
		elseif i > 5 and i <= 7 then
			local windowImage = display.newImage(assetPath .. remainingGameModes[1].mode .. math.random(1, 4)..".png")
			windowImage:scale(WINDOW_SCALE, WINDOW_SCALE)
			correctWindowTable[i]:insert(windowImage)
			correctWindowTable[i].x = POS_WINDOWS[randomPositionTable[i]].x
			correctWindowTable[i].y = POS_WINDOWS[randomPositionTable[i]].y
			correctWindowTable[i].isCorrect = false
			correctWindowTable[i].hasBeenSelected = false
			correctWindowTable[i]:addEventListener( "tap", onAnswerTapped )
			answersLayer:insert(correctWindowTable[i])
		elseif i > 7 and i <= 9 then
			local windowImage = display.newImage(assetPath .. remainingGameModes[2].mode .. math.random(1, 4)..".png")
			windowImage:scale(WINDOW_SCALE, WINDOW_SCALE)
			correctWindowTable[i]:insert(windowImage)
			correctWindowTable[i].x = POS_WINDOWS[randomPositionTable[i]].x
			correctWindowTable[i].y = POS_WINDOWS[randomPositionTable[i]].y
			correctWindowTable[i].isCorrect = false
			correctWindowTable[i].hasBeenSelected = false
			correctWindowTable[i]:addEventListener( "tap", onAnswerTapped )
			answersLayer:insert(correctWindowTable[i])
		elseif i > 9 and i <= 11 then
			local windowImage = display.newImage(assetPath .. remainingGameModes[3].mode .. math.random(1, 4)..".png")
			windowImage:scale(WINDOW_SCALE, WINDOW_SCALE)
			correctWindowTable[i]:insert(windowImage)
			correctWindowTable[i].x = POS_WINDOWS[randomPositionTable[i]].x
			correctWindowTable[i].y = POS_WINDOWS[randomPositionTable[i]].y
			correctWindowTable[i].isCorrect = false
			correctWindowTable[i].hasBeenSelected = false
			correctWindowTable[i]:addEventListener( "tap", onAnswerTapped )
			answersLayer:insert(correctWindowTable[i])
		elseif i > 11 and i <= 13 then
			local windowImage = display.newImage(assetPath .. remainingGameModes[4].mode .. math.random(1, 4)..".png")
			windowImage:scale(WINDOW_SCALE, WINDOW_SCALE)
			correctWindowTable[i]:insert(windowImage)
			correctWindowTable[i].x = POS_WINDOWS[randomPositionTable[i]].x
			correctWindowTable[i].y = POS_WINDOWS[randomPositionTable[i]].y
			correctWindowTable[i].isCorrect = false
			correctWindowTable[i].hasBeenSelected = false
			correctWindowTable[i]:addEventListener( "tap", onAnswerTapped )
			answersLayer:insert(correctWindowTable[i])
		end	
	end
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime
	manager = event.parent 
		
	selectGameMode()
	
	correctAnswers = 0
	
	randomPositionTable = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}	
			
	instructions.text = localization.getString("instructionsScienceCleanWindows"..gameMode)
	
	display.remove(correctAnswerGroup)
	correctAnswerGroup = display.newGroup()
	correctAnswerGroup.isVisible = false
	
	display.remove(shinyParticleGroup)
	shinyParticleGroup = display.newGroup()
	
	shuffleTablePositions()
	createRandomWindows()
end

local function tutorial()
	if isFirstTime then 
		local tutorialOptions = {
			iterations = 2,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 2000, x = tutorialPosX, y = tutorialPosY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) 
	end
end
----------------------------------------------- Module functions
function game.getInfo() 
	return {
		available = false, 
		correctDelay = 500, 
		wrongDelay = 500, 
		
		name = "scienceCleanWindows", 
		category = "science", 
		subcategories = {"science"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = { 
		
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
	
	local background = display.newImage(assetPath.."fondo.png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.width = screenWidth
	background.height = screenHeight
	backgroundLayer:insert(background)
	
	local sun = display.newImage(assetPath.."sol.png")
	sun.x = display.contentCenterX * 1.70
	sun.y = display.contentCenterY * 0.30
	backgroundLayer:insert(sun)
	
	local instructionsOptions = 
	{
		text = "",	 
		x = display.contentCenterX,
		y = display.viewableContentHeight * 0.05,
		font = FONT_NAME,   
		fontSize = SIZE_FONT,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(unpack(INSTRUCTIONS_FONT_COLOR))
	textLayer:insert(instructions)
end

function game:destroy() 
	
end


function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize(event)
		tutorial() 
	elseif phase == "did" then 
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		disableButtons()
		removeDynamicAnswers()
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
