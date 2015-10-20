----------------------------------------------- animales_ruidosos
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local manager 

local backgroundLayer
local dynamicLayer

local isFirstTime
local gameTutorial
local correctOption
local optionChosen

local question
local correctAnswer
local wrongAnswers
local answers
----------------------------------------------- Constants
local CENTERX = display.contentCenterX
local CENTERY = display.contentCenterY
local SCREEN_LEFT = display.screenOriginX
local SCREEN_WIDTH = display.viewableContentWidth - SCREEN_LEFT * 2
local SCREEN_TOP = display.screenOriginY
local SCREEN_HEIGHT = display.viewableContentHeight - SCREEN_TOP * 2

local PLANET_X = SCREEN_WIDTH * 0.2
local PLANET_Y = SCREEN_HEIGHT * 0.35

local SPACESHIP_Y = SCREEN_HEIGHT * 0.65
local FLAME_Y = SPACESHIP_Y + 120
local SPACESHIP_ANSWER_BOX_Y = SCREEN_HEIGHT * 0.9

local NUMBER_OF_SHIPS = 3

local ANSWERBOX_INDEX = 1
local ANSWER_INDEX = 2
local SHIPFLAMES_INDEX = 3
local FLAMES_INDEX = 4
local SHIP_INDEX = 5
----------------------------------------------- Cached functions
 
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 3000, x = correctOption.x, y = correctOption.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end 

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	isFirstTime = params.isFirstTime
	manager = event.parent
	optionChosen = false
	
	question = params.question
	correctAnswer = params.answer
	wrongAnswers = params.wrongAnswers
	answers = {}
	answers[1] = correctAnswer
	answers[2] = wrongAnswers[1]
	answers[3] = wrongAnswers[2]
	
	answers = extratable.shuffle(answers)
end

local function takeOff(object,flame)
	local ship = display.newGroup()
	ship:insert(flame)
	ship:insert(object)
	sound.play("minigamesRocketLaunch")
	director.to(scenePath, ship, {time = 50, x = ship.x + 10, iterations = 50, onComplete = function()
		flame.alpha = 1
		sound.play("minigamesLaser")
		director.to(scenePath, ship, {
			x = PLANET_X, y = PLANET_Y,
			xScale=0.05, yScale=0.05,
			time = 800, rotation = object.angle,
			transition = easing.inBack,})
		director.to(scenePath, ship, {alpha = 0, delay = 700, time = 100, onComplete = function() ship:removeSelf() end})
	end})
end

local function sinkShip(object, objectFlames)
	sound.play("minigamesRocketLaunch")
	director.to(scenePath, object, {time = 50, x = object.x + 10, iterations = 50, onComplete = function()
		object.alpha = 0
		objectFlames.alpha = 1
		sound.play("minigamesFallSplash")
		director.to(scenePath, objectFlames, {
			y = SCREEN_HEIGHT * 1.3,
			time = 500, rotation = object.angle,
			transition = easing.inBack,})
	end})
end

local function onTap(event)
	local target = event.target
	local object = dynamicLayer[target.id]
	tutorials.cancel(gameTutorial,300)

	target:removeEventListener("tap", onTap)
	
	if not optionChosen then
		optionChosen = true
		if object.isCorrect then
			manager.correct()
			takeOff(object[SHIP_INDEX], object[FLAMES_INDEX])
		else
			manager.wrong({id = "text", text = correctAnswer, fontSize = 80})
			sinkShip(object[SHIP_INDEX], object[SHIPFLAMES_INDEX])
		end
		return true
	end
end

local function createBackgroundElements()
	local backgroundElements = display.newGroup()
	
	local background = display.newImage(assetPath .. "fondo.png")
	background.x = CENTERX
	background.y = CENTERY
    background.width = SCREEN_WIDTH
    background.height = SCREEN_HEIGHT
	backgroundElements:insert(background)

	local instructions = director.newLocalizedText(scenePath, "instructionsGeoGalaxies",{
		text = "",
		x = CENTERX,
		y = SCREEN_TOP + 200,
		fontSize = 24,
		font = settings.fontName,
		width = 400,
		height = 0,
		align = "center"
	 })
	instructions:setFillColor(123/255, 156/255, 175/255)
	backgroundElements:insert(instructions)
	
	local questionContainer = display.newImage(assetPath .. "pregunta.png")
	questionContainer.x = CENTERX
	questionContainer.y = SCREEN_TOP + questionContainer.height * 0.5
	backgroundElements:insert(questionContainer)
	
	local planet = display.newImage(assetPath .. "saturno.png")
	planet.x = PLANET_X
	planet.y = PLANET_Y
	backgroundElements:insert(planet)
	
	return backgroundElements
end

local function createDynamicElements()
	local dynamicElements = display.newGroup()
	
	local xPosition = 100 / (NUMBER_OF_SHIPS + 1) * 0.01
		
	for index = 1, NUMBER_OF_SHIPS do	
		local element = display.newGroup()
				
		local answerBox = display.newImage(assetPath .. "opcion.png")
		answerBox.x = SCREEN_WIDTH * xPosition * index
		answerBox.y = SPACESHIP_ANSWER_BOX_Y
		answerBox.id = index
		answerBox:addEventListener( "tap", onTap )
		element:insert(answerBox)
		
		local answerOptions = {
			text = answers[index],	 
			x = answerBox.x,
			y = answerBox.y,
			width = answerBox.width * 0.75,
			font = settings.fontName,   
			fontSize = 20,
			align = "center"
		}
		local answer = display.newText(answerOptions)
		answer.text = answers[index]
		element:insert(answer)
		
		if answer.text == correctAnswer then
			correctOption = answerBox
		end

		local shipFlames = display.newImage(assetPath .. "incendiada.png")
		shipFlames.x = SCREEN_WIDTH * xPosition * index
		shipFlames.y = SPACESHIP_Y
		shipFlames.alpha = 0
		element:insert(shipFlames)
		
		local Flames = display.newImage(assetPath .. "flama.png")
		Flames.x = SCREEN_WIDTH * xPosition * index
		Flames.y = FLAME_Y
		Flames.alpha = 0
		element:insert(Flames)		
				
		local ship = display.newImage(assetPath .. "nave1.png")
		ship.x = SCREEN_WIDTH * xPosition * index
		ship.y = SPACESHIP_Y
		ship.angle = -25 * index
		element:insert(ship)
		
		if answer.text == correctAnswer then
			element.isCorrect = true
		else
			element.isCorrect = false
		end

		dynamicElements:insert(element)
	end	
	
	local options = {
		text = question,
		x = CENTERX,
		y = SCREEN_TOP + 90,
		width = 500,
		font = native.systemFont,
		fontSize = 20,
		align = "center"
	}
	local questionText = display.newText(options)
	questionText:setFillColor(206/255, 6/255, 102/255)
	
	dynamicElements:insert(questionText)
	
	return dynamicElements
end

----------------------------------------------- 
function game.getInfo()
	return {
		available = true,
		wrongDelay = 5000,
		correctDelay = 3500,
		
		name = "geoGalaxies",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		musicVolume = 0.25,
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 2},
		},
	}
end

function game:create(event)
	local sceneGroup = self.view
	
	backgroundLayer = createBackgroundElements()
	sceneGroup:insert(backgroundLayer)
end

function game:show(event)
    local sceneGroup = self.view
	local phase = event.phase
	
    if phase == "will" then
		initialize(event)
		dynamicLayer = createDynamicElements()
		sceneGroup:insert(dynamicLayer)
		showTutorial()
	elseif phase == "did" then
		
    end
end

function game:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    if phase == "will" then
		
	elseif phase == "did" then
		display.remove(dynamicLayer)
    end
end

function game:destroy()
	display.remove(backgroundLayer)
end
----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game