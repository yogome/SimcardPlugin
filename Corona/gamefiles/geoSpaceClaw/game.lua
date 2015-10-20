----------------------------------------------- SpaceClaw
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )
local extramath = require ( "libs.helpers.extramath" )

local game = director.newScene()
----------------------------------------------- Variables
local manager 

local backgroundLayer
local dynamicLayer

local claw, rope
local ship
local explosionShip

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

local SPACESHIP_Y = CENTERY
local SPACESHIP_X = CENTERX

local SNAP_TRESHOLD = 50

local NUMBER_OF_ANSWERS = 3

local ANSWERS_X = {SCREEN_WIDTH * 0.85 , SCREEN_WIDTH * 0.85 , SCREEN_WIDTH * 0.15}
local ANSWERS_Y = {SCREEN_HEIGHT * 0.3 , SCREEN_HEIGHT * 0.8 , CENTERY}

local ANSWERBOX_INDEX = 1
local ANSWER_INDEX = 2
-----------------------------------------------Cached functions
local mathSqrt = math.sqrt
 
----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1500, time = 2500, x = claw.x, y = claw.y, toX = correctOption.x, toY = correctOption.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end 

local function flyAway(object)
	director.to(scenePath, ship, {
		x = SCREEN_WIDTH + 20,
		xScale=0.05, yScale=0.05,
		delay = 500,
		time = 2000,
		transition = easing.inBack ,})
	director.to(scenePath, ship, {alpha = 0, delay = 2400, time = 100, onComplete = function() ship:removeSelf() end})
end

local function explosion()
	director.to(scenePath, ship, {delay = 500, time = 100, rotation = 45, onComplete = function()
		director.to(scenePath, ship, {time = 100, rotation = -45, onComplete = function()
			director.to(scenePath, ship, {time = 100, rotation = 45, onComplete = function()
				director.to(scenePath, ship, {time = 100, rotation = -45, onComplete = function()
					director.to(scenePath, ship, {time = 100, rotation = 0, onComplete = function()
						explosionShip.alpha = 1
						explosionShip:toFront()
						
						director.to(scenePath, explosionShip,{time = 1000, xScale = 2, yScale = 2,})
						director.to(scenePath, explosionShip, {time = 50, x = explosionShip.x + 10, iterations = -1,})
						director.to(scenePath, explosionShip, {time = 200, delay = 600, alpha = 0,})
						director.to(scenePath, ship, {time = 400, rotation = 360, iterations = -1})
						director.to(scenePath, ship, {
								x = SCREEN_WIDTH + 20,
								xScale=0.05, yScale=0.05, 
								time = 1500,
								transition = easing.outBack,})
						director.to(scenePath, ship, {alpha = 0, delay = 600, time = 500, onComplete = function() ship:removeSelf() end})
					end})
				end})
			end})
		end})
	end})
end

local function distanceTwoObjects(object1, object2)
	local dx = object1.x - object2.x
	local dy = object1.y - object2.y

	local distance = mathSqrt( dx*dx + dy*dy )
	return distance
end

local function clawMove()
	local dx = claw.x - SPACESHIP_X
	local dy = claw.y - SPACESHIP_Y

	local distance = mathSqrt( dx*dx + dy*dy )
	local angle = extramath.getFullAngle(dx, dy)
	
	rope.rotation = angle
	rope.height = distance
	rope.xScale = claw.xScale
	
	claw.rotation = angle
end

local function clawTouch( event )
	local self = event.target
	local object
	
	if event.phase == "began" then
		tutorials.cancel(gameTutorial,300)
		display.getCurrentStage():setFocus( self )
		self.isFocus = true
		claw.deltaX = event.x - claw.x
		claw.deltaY = event.y - claw.y
	elseif self.isFocus then
		if event.phase == "moved" then
			claw.x = event.x - claw.deltaX
			claw.y = event.y - claw.deltaY
		elseif event.phase == "ended" or event.phase == "cancelled" then
			display.getCurrentStage():setFocus( nil )
			self.isFocus = nil
			
			local previousDistance = 1000
			local distance
			
			for index = 1, NUMBER_OF_ANSWERS do	
				distance = distanceTwoObjects(claw, dynamicLayer[index][ANSWERBOX_INDEX])
				if distance < previousDistance then
					previousDistance = distance
					object = dynamicLayer[index]
				end
			end
			
			local objectSize = object[ANSWERBOX_INDEX].contentWidth*0.3 + SNAP_TRESHOLD
			if ( previousDistance < objectSize ) then
				claw:removeEventListener("touch", clawTouch)
				director.to(scenePath, claw, {x = object[ANSWERBOX_INDEX].x, y = object[ANSWERBOX_INDEX].y, time = 100, onComplete = function()
					ship:toFront()
					director.to(scenePath, object[ANSWERBOX_INDEX], {x = CENTERX, y = CENTERY - 15, time = 420, xScale=0.3, yScale=0.3,})
					director.to(scenePath, claw, {time = 100, delay = 300, alpha = 0})
					director.to(scenePath, object, {time = 300, alpha = 0})
					director.to(scenePath, claw, {x = CENTERX, y = CENTERY - 15, time = 400, xScale=0.3, yScale=0.3, onComplete = function()
						Runtime:removeEventListener("enterFrame", clawMove)
						rope.alpha = 0
					end})
				end})
			
				if object.isCorrect then
					manager.correct()
					flyAway()
				else
					manager.wrong({id = "text", text = correctAnswer, fontSize = 80})
					explosion()
				end
			end

		end
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

local function createBackgroundElements()
	local backgroundElements = display.newGroup()
	
	local background = display.newImage(assetPath .. "fondo.png")
	background.x = CENTERX
	background.y = CENTERY
    background.width = SCREEN_WIDTH
    background.height = SCREEN_HEIGHT
	backgroundElements:insert(background)

	local instructions = director.newLocalizedText(scenePath, "instructionsGeoSpaceClaw",{
		text = "",
		x = CENTERX,
		y = SCREEN_TOP + 170,
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
	questionContainer.y = SCREEN_TOP + 80
	backgroundElements:insert(questionContainer)
	
	return backgroundElements
end

local function createDynamicElements()
	local dynamicElements = display.newGroup()
	
	local function movementShip(element)			
		director.to(scenePath, element, {time = 1000, y = element.y + 10, transition = easing.inOutQuad, onComplete = function()
			director.to(scenePath, element, {time = 1000, y = element.y - 10, transition = easing.inOutQuad, onComplete = function()
				movementShip(element)
			end})
		end})			
	end
		
	for index = 1, NUMBER_OF_ANSWERS do	
		local element = display.newGroup()
				
		local answerBox = display.newImage(assetPath .. "caja" .. index .. ".png")
		answerBox.x = ANSWERS_X[index]
		answerBox.y = ANSWERS_Y[index]
		answerBox.id = index
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
		answer:setFillColor(64/255, 0/255, 79/255)
		element:insert(answer)
		
		if answer.text == correctAnswer then
			correctOption = answerBox
			element.isCorrect = true
		else
			element.isCorrect = false
		end
		
		dynamicElements:insert(element)
	end
	
	rope = display.newImage(assetPath .. "cuerda.png")
	rope.x = SPACESHIP_X
	rope.y = SPACESHIP_Y
	rope.anchorY = 0
	dynamicElements:insert(rope)	
	
	claw = display.newImage(assetPath .. "pinza.png")
	claw.x = SPACESHIP_X
	claw.y = SPACESHIP_Y + rope.height
	claw.anchorY = 0.35
	claw:scale(0.8, 0.8)
	dynamicElements:insert(claw)	
	
	ship = display.newImage(assetPath .. "nave.png")
	ship.x = SPACESHIP_X
	ship.y = SPACESHIP_Y
	movementShip(ship)
	dynamicElements:insert(ship)	
	
	explosionShip = display.newImage(assetPath .. "explosion.png")
	explosionShip.x = SPACESHIP_X
	explosionShip.y = SPACESHIP_Y
	explosionShip.alpha = 0
	dynamicElements:insert(explosionShip)
	
	local options = {
		text = question,
		x = CENTERX,
		y = SCREEN_TOP + 70,
		width = 500,
		font = native.systemFont,
		fontSize = 24,
		align = "center"
	}
	local questionText = display.newText(options)
	questionText:setFillColor(129/255, 74/255, 175/255)
	dynamicElements:insert(questionText)
	
	return dynamicElements
end

----------------------------------------------- 
function game.getInfo()
	return {
		available = true,
		wrongDelay = 2500,
		correctDelay = 3000,
		
		name = "geoSpaceClaw",
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
		
		claw:addEventListener("touch", clawTouch)
		Runtime:addEventListener("enterFrame", clawMove)
	elseif phase == "did" then
		
    end
end

function game:hide(event)
    local sceneGroup = self.view
    local phase = event.phase
    if phase == "will" then
		
	elseif phase == "did" then
		display.remove(dynamicLayer)
		tutorials.cancel(gameTutorial,300)
		Runtime:removeEventListener("enterFrame", clawMove)
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