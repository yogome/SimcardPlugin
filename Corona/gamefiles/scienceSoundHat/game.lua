----------------------------------------------- Test minigame
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )

local game = director.newScene()
----------------------------------------------- Variables

local backgroundLayer
local answersLayer
local textLayer
local manager
local isFirstTime
local gameTutorial
local gameTutorial2
local magicHat
local magicHatBase
local wand
local soundWave
local selectedSound
local shuffledSounds
local soundObjectsGroup
local soundObjectsList
local hiddenObject
local playerSelection
local isAbleToDrag
local instructionsText, instructions2Text
local canTapHat
local canCallTut2

----------------------------------------------- Constants

local TOTAL_OBJECTS = 3
local PADDING_OBJECTS = 270

local soundObjects = {
	[1] = {name = "bird", image = "bird.png", sound = "minigamesBird"},
	[2] = {name = "bell", image = "bell.png", sound = "minigamesBell"},
	[3] = {name = "bike", image = "bike.png", sound = "minigamesmotorcycle"},
	[4] = {name = "cricket", image = "cricket.png", sound = "minigamescricket"},
	[5] = {name = "doorBell", image = "doorBell.png", sound = "minigamesDoorBell"},
	[6] = {name = "drill", image = "drill.png", sound = "minigamesDrill"},
	[7] = {name = "lion", image = "lion.png", sound = "minigameslion"},
	[8] = {name = "scream", image = "scream.png", sound = "minigamesHumanScream"},
	[9] = {name = "tambourine", image = "tambourine.png", sound = "minigamesTambourine"}
}

----------------------------------------------- Functions
local function tutorial2()
	if isFirstTime then
		local correctObject
		for index = 1, TOTAL_OBJECTS do
			if soundObjectsList[index].name == hiddenObject.name then
				correctObject = soundObjectsList[index]
			end
		end
		local tutorialOptions2 = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = wand.x, y = wand.y, toX = correctObject.x, toY = correctObject.y},
			}
		}
		gameTutorial2 = tutorials.start(tutorialOptions2)
	end
end

local function playSound()
	tutorials.cancel(gameTutorial,300)
	
	if canCallTut2 then
		tutorial2()
		canCallTut2 = false
	end
	
	if canTapHat then
		canTapHat = false
		sound.play(selectedSound)
		
		director.to(scenePath, soundWave, {delay = 0, time = 300, y = magicHat.y - magicHat.height*0.5, alpha = 1, onComplete = function()
			director.to(scenePath, soundWave, {delay = 0, time = 300, alpha = 0, onComplete = function() 
				soundWave.y = magicHat.y
				director.to(scenePath, soundWave,{delay = 0, time = 3000, onComplete = function() canTapHat = true end})
			end})
		end})
	end
	
	director.to(scenePath, instructionsText, {delay = 100, time = 700, alpha=0})
	director.to(scenePath, instructions2Text, {delay = 100, time = 700, alpha=1})
end

local function checkAnswer()
	if hiddenObject.name == playerSelection then
		manager.correct()
	else
		manager.wrong({id = "image", image = hiddenObject.root, xScale = 0.7, yScale = 0.7})
		magicHat.idle.isVisible = false
		magicHat.incorrect.isVisible = true
	end
end

local function changeHatFace()
	if hiddenObject.name == playerSelection then
		magicHat.correct.isVisible = true
	else
		magicHat.incorrect.isVisible = true
	end
end

local function revealAnimation()
	magicHat:toFront()
	local function showShine()
		for index = 1, 4 do
			local randomX = math.random(hiddenObject.x - hiddenObject.width*0.5, hiddenObject.x + hiddenObject.width*0.5 )
			local randomY = math.random(hiddenObject.y - hiddenObject.height*0.3, hiddenObject.y )

			local shine = display.newImage(assetPath.."shine.png")
			shine.x = randomX
			shine.y = randomY
			shine.xScale = 0.5
			shine.yScale = 0.5
			shine.alpha = 0
			shine:toFront()
			soundObjectsGroup:insert(shine)

			director.to(scenePath, shine, {delay = 200*index, time = 200, alpha = 1, onComplete = function()
				director.to(scenePath, shine, {delay = 200*index, time = 200, alpha = 0, onComplete = function() 
					display.remove(shine)
				end})
			end})
			
			if index == 4 then
				checkAnswer()
				sound.play("minigamesAscendence")
				director.to(scenePath, hiddenObject, {delay = 1000, time = 200})
			end
		end
	end
	
	director.to(scenePath, hiddenObject, {delay = 0, time = 400, y = magicHat.y - magicHat.height*0.5, alpha = 1, onComplete = function() 
		changeHatFace()
		showShine()
	end})
	
end

local function grabWand(event)
	local wand = event.target
	local phase = event.phase
	
	if "began" == phase and isAbleToDrag then
		
		display.getCurrentStage():setFocus( wand, event.id )
		wand.isFocus = true
		
		sound.play("dragtrash")

		wand.x0 = event.x - wand.x
		wand.y0 = event.y - wand.y
		
		wand:toFront()

		tutorials.cancel(gameTutorial2,300)
		
	elseif wand.isFocus then
		if "moved" == phase then
			wand.x = event.x - wand.x0
			wand.y = event.y - wand.y0
		elseif "ended" == phase or "cancelled" == phase then
			sound.play("pop")
			display.getCurrentStage():setFocus(wand, nil)
			wand.isFocus = false
			
			for indexAnswer = 1, #soundObjectsList do
				local soundOption = soundObjectsList[indexAnswer]
				if wand.x < (soundOption.x + soundOption.contentWidth * 0.5) and
					wand.x > (soundOption.x - soundOption.contentWidth * 0.5) and
					wand.y < (soundOption.y + soundOption.contentHeight * 0.5) and
					wand.y > (soundOption.y - soundOption.contentHeight * 0.5) then
						
						playerSelection = soundOption.name
						revealAnimation()
						isAbleToDrag = false
				end
			end
		end
	end
	return true
end

local function setSoundObjects()
	local totalWidth = (TOTAL_OBJECTS - 1) * PADDING_OBJECTS
	local startX = display.contentCenterX - totalWidth * 0.5
	
	soundObjectsList = {}
	
	local selectedObjects = {}
	
	for index = 1, TOTAL_OBJECTS do
		selectedObjects[index] = shuffledSounds[index]
	end
	
	selectedObjects = extratable.shuffle(selectedObjects)
	
	for index = 1, TOTAL_OBJECTS do
		local soundObject = display.newImage(assetPath..selectedObjects[index].image)
		soundObject.x = startX + (index - 1) * PADDING_OBJECTS
		soundObject.y = display.viewableContentHeight * 0.75
		soundObject.xScale, soundObject.yScale = 0.85, 0.85
		soundObject.name = selectedObjects[index].name
		soundObjectsGroup:insert(soundObject)
		soundObjectsList[#soundObjectsList + 1] = soundObject
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	isAbleToDrag = true
	canCallTut2 = true
	
	soundObjectsGroup = display.newGroup()
	backgroundLayer:insert(soundObjectsGroup)
	
	shuffledSounds = extratable.shuffle(soundObjects)
	local selectedObject = shuffledSounds[1]
	selectedSound = selectedObject.sound
	
	hiddenObject = display.newImage(assetPath..selectedObject.image)
	hiddenObject.root = assetPath..selectedObject.image
	hiddenObject.x = magicHatBase.x
	hiddenObject.y = magicHatBase.y
	hiddenObject.xScale = 0.5
	hiddenObject.yScale = 0.5
	hiddenObject.alpha = 0
	hiddenObject.name = selectedObject.name
	soundObjectsGroup:insert(hiddenObject)
	
	magicHat.isVisible = true
	magicHat.idle.isVisible = true
	magicHat.correct.isVisible = false
	magicHat.incorrect.isVisible = false
	magicHat:addEventListener("tap", playSound)
	
	instructions2Text.text = localization.getString("instructions2SombreroMagico")
	instructionsText.text = localization.getString("instructionsSombreroMagico")
	
	instructionsText.alpha = 1
	instructions2Text.alpha = 0
	
	soundWave.alpha = 0
	canTapHat = true
	setSoundObjects()
	
	wand.x = magicHat.x + magicHat.idle.width*0.65
	wand.y = magicHat.y + 15
	backgroundLayer:insert(wand)

end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 2500, x = magicHat.x, y = magicHat.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		correctDelay = 1000,
		wrongDelay = 1000,
		
		name = "Magic Hat",
		category = "science",
		subcategories = {"sounds"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		musicVolume = 0.15,
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
	
	local background = display.newImage(assetPath.."background.png")
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.width = display.viewableContentWidth
	background.height = display.viewableContentHeight
	backgroundLayer:insert(background)
	
	magicHatBase = display.newImage(assetPath.."hat.png")
	magicHatBase.x = display.contentCenterX
	magicHatBase.y = display.contentCenterY - 60
	backgroundLayer:insert(magicHatBase)
	
	magicHat = display.newGroup()
	magicHat.idle = display.newImage(assetPath.."s1.png")
	magicHat:insert(magicHat.idle)
	magicHat.correct = display.newImage(assetPath.."s2.png")
	magicHat:insert(magicHat.correct)
	magicHat.incorrect = display.newImage(assetPath.."s3.png")
	magicHat:insert(magicHat.incorrect)
	magicHat.x = display.contentCenterX
	magicHat.y = display.contentCenterY - 60
	backgroundLayer:insert(magicHat)
	
	soundWave = display.newImage(assetPath.."sound.png")
	soundWave.x = magicHat.x
	soundWave.y = magicHat.y
	backgroundLayer:insert(soundWave)
	
	local instructionsOptions = 
	{
		text = "",     
		x = display.contentCenterX,
		y = display.viewableContentHeight*0.15,
		width = display.viewableContentWidth*0.8, 
		font = settings.fontName,   
		fontSize = 24,
		align = "center" 
	}

	instructionsText =  display.newText( instructionsOptions )
	textLayer:insert(instructionsText)
	
	local instructions2Options = 
	{
		text = "",     
		x = display.contentCenterX,
		y = display.viewableContentHeight*0.93,
		width = display.viewableContentWidth*0.8, 
		font = settings.fontName,   
		fontSize = 24,
		align = "center" 
	}

	instructions2Text =  display.newText( instructions2Options )
	instructions2Text:setFillColor(8/255,6/255,89/255)
	instructions2Text.alpha = 0
	textLayer:insert(instructions2Text)
	
	wand = display.newImage(assetPath.."wand.png")
	wand.xScale = 0.6
	wand.yScale = 0.6
	wand:addEventListener("touch", grabWand)
	
	
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
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		tutorials.cancel(gameTutorial2)
		display.remove(soundObjectsGroup)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game


