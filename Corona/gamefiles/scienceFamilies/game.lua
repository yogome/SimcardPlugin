----------------------------------------------- Test minigame - comentless file in same folder - template.lua
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require( "libs.helpers.extratable" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene()

----------------------------------------------- Variables - Variables are declared BUT not initialized
local background1
local background2
local sun
local boat
local frontWater
local familyGroup
local answerText
local numCorrect
local tapped
local Boat2
local Boat3
local totalQuestions
local answersLayer
local backgroundLayer
local backgroundLayer2
local sunLayer
local textLayer, instructions
local correctAnswerGroup
local manager
local isFirstTime
local correctBox
local gameTutorial
local answerPosX
local familyRandom
local tapEnabled
local frontWaterTween
local answers
local correctAnswer

----------------------------------------------- Constants
local NUMBER_SPAWN = 3
local BOAT_START_POSX = display.contentWidth * 0.85
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenLeft = display.screenOriginX
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenRight = screenLeft + screenWidth
local screenTop = display.screenOriginY
local screenHeight = display.viewableContentHeight - screenTop * 2
local screenBottom = screenTop + screenHeight 
local mRandom = math.random
local mAbs = math.abs
local OFFSET_TEXT = {x = 0, y = -200}
local SIZE_FONT = 40
local ANSWER_SIZE_FONT = 50

local OPTIONS = {
	text = "",
	x = centerX,
	y = centerY + centerY * 0.53,
	width = 600,
	height = 120,
	fontSize = SIZE_FONT,
	align = "center",
	font = settings.fontName
}

local SUN_IMAGES = {
	[1] = {
		assetPath.."normal.png", 
		assetPath.."feliz.png", 
		assetPath.."triste.png" 
		}
}

local FAMILY_IMAGES = {
	[1] = { 
		[1] = {
			image = assetPath.."persona1.png",
			position = {x = centerX - 190, y = centerY + 30},
			isDiferent = false
		},
		[2] = {
			image = assetPath.."persona2.png",
			position = {x = centerX, y = centerY + 30 },
			isDiferent = false
		},
		[3] = {
			image = assetPath.."changuito.png",
			position = {x = centerX + 190, y = centerY + 30},
			isDiferent = true
		},
	},
	[2] = { 
		[1] = {
			image = assetPath.."dalmata1.png",
			position = {x = centerX - 215, y = centerY + 50},
			isDiferent = false
		},
		[2] = {
			image = assetPath.."dalmata2.png",
			position = {x = centerX, y = centerY + 50 },
			isDiferent = false
		},
		[3] = {
			image = assetPath.."pug.png",
			position = {x = centerX + 215, y = centerY + 50},
			isDiferent = true
		},
	},	
	[3] = { 
		[1] = {
			image = assetPath.."flor1.png",
			position = {x = centerX - 230, y = centerY + 50},
			isDiferent = false
		},
		[2] = {
			image = assetPath.."flor2.png",
			position = {x = centerX - 80, y = centerY + 50},
			isDiferent = false
		},
		[3] = {
			image = assetPath.."girasol.png",
			position = {x = centerX + 80, y = centerY + 50},
			isDiferent = true
		},
		[4] = {
			image = assetPath.."flor2.png",
			position = {x = centerX + 230, y = centerY + 50},
			isDiferent = false
		},
	},
	[4] = { 
		[1] = {
			image = assetPath.."hormiga1.png",
			position = {x = centerX - 230, y = centerY + 50},
			isDiferent = false
		},
		[2] = {
			image = assetPath.."hormiga2.png",
			position = {x = centerX - 80, y = centerY + 50},
			isDiferent = false
		},
		[3] = {
			image = assetPath.."catarina.png",
			position = {x = centerX + 80, y = centerY + 50},
			isDiferent = true
		},
		[4] = {
			image = assetPath.."hormiga2.png",
			position = {x = centerX + 230, y = centerY + 50},
			isDiferent = false
		},
	},
}																														                                 

----------------------------------------------- Functions - Local functions ONLY.
local function totalAnswers()
		if numCorrect < NUMBER_SPAWN then
			if manager then
				local correctGroup = display.newGroup()
				correctGroup.isVisible = false
				
				for index = 1, #correctAnswer do
					local family = correctAnswer[index]
					local image = display.newImage( familyRandom[family][3].image)
					
					if #correctAnswer == 3 then 
						image.x = answerPosX
						answerPosX = answerPosX + 200
					elseif #correctAnswer == 2 then
						image.x = answerPosX + 100
						answerPosX = answerPosX + 200
					else
						image.x = answerPosX + 200 
					end
					
					correctGroup:insert( image )
				end
				
				manager.wrong({id = "group", group = correctGroup})
			end
		else
			if manager then
				manager.correct()
			end
		end
end

local function sunChange( num )
	display.remove(sun)
	sun = nil
	
	sun = display.newImage(SUN_IMAGES[1][num])
	sun:scale( 0.75, 0.75 )
	
	if num ~= 3 then
		sun.x, sun.y = centerX - centerX * 0.15, centerY - centerY * 0.75
	else
		sun.x, sun.y = centerX - centerX * 0.15, centerY - centerY * 0.52
	end
	
	sunLayer:insert(sun)
end

local function removeDynamicAnswers()
	timer.cancel(Boat2)
	timer.cancel(Boat3)
	
	display.remove(familyGroup)
	familyGroup = nil
	
	display.remove(sun)
	sun = nil
	
	answerText.text = nil
end

local function enableTap()
	tapEnabled = true
end

local function disableTap()
	tapEnabled = false
end

local function checkTotal( value ) 
	if totalQuestions >= NUMBER_SPAWN then
		if value then	
			director.performWithDelay( scenePath, 2500, totalAnswers, 1 )
		else
			director.performWithDelay( scenePath, 1000, totalAnswers, 1 )
		end
	end
end

local function wrongAnswer ()
	local correctImage
	local correctText
	
	timer.pause( Boat2 )
	timer.pause( Boat3 )
	
	correctAnswerGroup = display.newGroup()
	textLayer:insert( correctAnswerGroup )
	
	correctImage = display.newImage( familyRandom[totalQuestions][3].image)
	correctImage.x, correctImage.y = centerX, centerY
	correctAnswerGroup:insert( correctImage )
	
	table.insert( correctAnswer, totalQuestions )
	
	correctText = display.newText("", centerX , centerY - centerY * 0.35  ,settings.fontName, ANSWER_SIZE_FONT)
	correctText.text = localization.getString("instructionsVariationOfTraitsCorrectAnswer")
	correctAnswerGroup:insert( correctText )
end

local function wrongAnswerChange ()
	answerText.text = localization.getString("instructionsVariationOfTraitsIncorrect")
	sunChange( 3 )
end

local function onTap( event )	
	if tapEnabled then
		tapEnabled = false
		local answer = event.target

		tapped = true

		if answer.isCorrect then
			sound.play("pop")
			answerText.text = localization.getString("instructionsVariationOfTraitsCorrect")
			sunChange( 2 )
			answers = true
		else
			sound.play("pop")
			wrongAnswerChange()
			answers = false
		end
	end
end

local function removeAnswer()
	display.remove(correctAnswerGroup)
	correctAnswerGroup = nil
	
	timer.resume( Boat2 )
	timer.resume( Boat3 )
end

local function removeObjects()
	display.remove(familyGroup)
	familyGroup = nil
	
	if tapped == false or answers == false then
		wrongAnswerChange()
		wrongAnswer()
		checkTotal( true )
	else
		numCorrect = numCorrect + 1
		checkTotal( false )
	end
	
	director.performWithDelay ( scenePath, 2500, removeAnswer, 1 )
	
	tapped = false
end

local function finalMovement()
	director.to (scenePath, answersLayer, { time = 3000, x = answersLayer.x + display.contentWidth * 0.85, y = answersLayer.y, onComplete = removeObjects})
end

local function inicialMovement()
	director.to (scenePath, answersLayer, { time = 3000, x = answersLayer.x + display.contentWidth * 0.85, y = answersLayer.y, onComplete = {director.performWithDelay (scenePath, 6000, finalMovement, 1)} })
end

local function createBoat()
	boat = display.newImage( assetPath.."barco.png" )
	boat.x = centerX
	boat.y = centerY + centerY * 0.45
	familyGroup:insert(boat)
	
	tapEnabled = true
	inicialMovement()
end

local function createFamilies()
	local indexToUse
		
	familyGroup = display.newGroup()
	answersLayer:insert(familyGroup)
	
	totalQuestions = totalQuestions + 1
	
	answerText.text = " "
	
	answersLayer.x = - BOAT_START_POSX
	
	if #familyRandom[totalQuestions] < 4 then
		indexToUse = { 1, 2, 3 }
	else
		indexToUse = { 1, 2, 3, 4 }
	end

	for index = 1, #familyRandom[totalQuestions] do
		local indexPos = mRandom( #indexToUse )
		local image = display.newImage( familyRandom[totalQuestions][index].image)
		
		if index == 3 then 
			correctBox = image
		end
		
		image.x = familyRandom[totalQuestions][indexToUse[indexPos]].position.x
		image.y = familyRandom[totalQuestions][indexToUse[indexPos]].position.y
		image.isCorrect = familyRandom[totalQuestions][index].isDiferent
		image:addEventListener("tap", onTap)
		familyGroup:insert( image )
		table.remove( indexToUse, indexPos )
	end
	
	createBoat()
end

local function frontWaterAnimation( )
    local scaleUp = function( )
        frontWaterTween = director.to( scenePath, frontWater, {tag = "WATER_MOVE", yScale = 1, onComplete = frontWaterAnimation } ) --Escala el texto a tamaño normal
    end
    
   frontWaterTween = director.to( scenePath, frontWater, {tag = "WATER_MOVE", yScale = 1.1, onComplete = scaleUp } ) --Escala el texto para hacerlo mas pequeño
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {}
	
	isFirstTime = params.isFirstTime 
	manager = event.parent
	
	answerPosX = -200
	numCorrect = 0
	totalQuestions = 0
	tapped = false
	familyRandom = FAMILY_IMAGES
	familyRandom = extratable.shuffle(familyRandom)
	instructions.text = localization.getString("instructionsVariationOfTraits")
	sunChange( 1 )
	correctAnswer = {}
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 3000, time = 2000, x = correctBox.x, y = correctBox.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) -- Use the tutorial library, it is simple, fast and efficient, see how it works.
	end
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = false, 
		correctDelay = 500, 
		wrongDelay = 500,
		name = "Minigame tester",
		category = "science", 
		subcategories = {"variation of traits"},
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99},
		gamemode = "findAnswer", 
		requires = { 
		},
	}
end  

function game:create(event) -- This will be fired the first time you load the scene. If you deload the scene this can get called again. The best practice is to make your scenes without memory leaks.
	local sceneView = self.view
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	sunLayer = display.newGroup()
	sceneView:insert(sunLayer)
	
	backgroundLayer2 = display.newGroup()
	sceneView:insert( backgroundLayer2 )
	
	answersLayer = display.newGroup()
	answersLayer.x = -BOAT_START_POSX
	sceneView:insert(answersLayer)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	background1 = display.newImage( assetPath.."fondo1.png" )
	background1.x = centerX
	background1.y = centerY
	background1.width = screenWidth
	background1.height = screenHeight
	backgroundLayer:insert(background1)
	
	background2 = display.newImage( assetPath.."fondo2.png" )
	background2.x = centerX
	background2.y = centerY
	background2.height = screenHeight
	background2.width = screenWidth
	backgroundLayer2:insert(background2)
	
	answerText = display.newText( "", centerX + centerX * 0.46, centerY - centerY * 0.6,settings.fontName, ANSWER_SIZE_FONT)
	textLayer:insert( answerText )
	
	frontWater = display.newImage( assetPath.."aguafrontal.png" )
	frontWater.x = centerX
	frontWater.y = screenBottom
	frontWater.width = screenWidth
	frontWater.height = centerY
	textLayer:insert(frontWater)

	instructions = display.newText(OPTIONS)
	textLayer:insert(instructions)
	
end

function game:destroy()
	
end

function game:show( event ) 
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		initialize(event)
		disableTap()
	elseif phase == "did" then
		frontWaterAnimation( )
		enableTap()
		createFamilies()
		tutorial()
		Boat2 = timer.performWithDelay( 12000, createFamilies, 1 )
		Boat3 = timer.performWithDelay( 24000, createFamilies, 1 )
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		removeDynamicAnswers()
	elseif phase == "did" then 
		disableTap()
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
