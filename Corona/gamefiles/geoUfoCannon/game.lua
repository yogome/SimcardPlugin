----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local sound = require("libs.helpers.sound")
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require( "libs.helpers.extratable" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables

local cannon
local question 
local correctAnswer
local wrongAnswers
local answers
local ufosGroup
local bulletList
local ufosList
local movementYMin
local movementYMax
local manager
local collisionFlag
local questionText
local timePassed, lastTime
local firstUpdate
local instructions
local isFirstTime, gameTutorial
local isInExecution
local executionTimer

----------------------------------------------- Constants
local SCALE_CANNON = 0.55
local QUESTION_COLOR = {103/255, 132/255, 144/255}
local ANSWER_COLOR = {42/255, 128/255, 185/255}
local RADIUS_BULLET = 40
local RADIUS_UFO = 50
local GAME_STATUS

local SHIFT_TIME = 200
local UFO_SPEED = 0.9
local BULLET_SPEED = 4

local DIRECTION_ENUM = {
	[1] = "left",
	[2] = "right",
	[3] = "up",
	[4] = "down"
}

----------------------------------------------- Functions

local function generateCannon(sceneView)
	local board = display.newImage( assetPath.."board.png" )
	board.x = display.contentCenterX - 1
	board.y = display.viewableContentHeight - 45
	board.xScale = 0.5
	board.yScale = 0.5
	sceneView:insert( board )
	cannon = display.newImage(assetPath.."cannon.png")
	cannon.x = display.contentCenterX
	cannon.y = display.viewableContentHeight - 28
	cannon.xScale = SCALE_CANNON
	cannon.yScale = SCALE_CANNON
	cannon.anchorY = 0.76
	cannon:toFront( )
	sceneView:insert( cannon )
	movementYMax = board.y - 200

	function cannon:shoot(toX, toY)

		local bullet = display.newImage(assetPath.."bullet.png")
		local rotationDegrees 

		bullet.x = cannon.x
		bullet.y = cannon.y 
		bullet.xScale = 0.15
		bullet.yScale = 0.15
		bullet.radius = RADIUS_BULLET
		
		local differenceX = toX - bullet.x
		local differenceY = toY - bullet.y
		
		if self.parent then
			self.parent:insert( bullet )
		end
		self:toFront()

		local hypotenuse = math.sqrt(differenceX * differenceX + differenceY * differenceY)
		local catOp = display.contentCenterX - toX
		local sin = catOp / hypotenuse

		rotationDegrees = math.deg(math.asin(sin))*-1
		
		bullet.normalX = differenceX / hypotenuse
		bullet.normalY = differenceY / hypotenuse
		
		function bullet:update()
			self.x = self.x + self.normalX * BULLET_SPEED
			self.y = self.y + self.normalY * BULLET_SPEED
		end

		director.to(scenePath, cannon, {delay = 100, time = 500, rotation = rotationDegrees, onComplete = function()
			bulletList[#bulletList+1] = bullet
			cannon.xScale = SCALE_CANNON * 1.5
			transition.cancel(cannon)
			sound.play("superLightBeamGun")
			director.to(scenePath, cannon, {time = 500, xScale = SCALE_CANNON, transition = easing.outElastic})
		end})
	end
end

local function setQuestion(sceneView) 
	local questionBg = display.newImage(assetPath.."questionBg.png")
	questionBg.x = display.contentCenterX
	questionBg.y = questionBg.height / 2
	questionBg.xScale = 0.7
	questionBg.yScale = 0.7
	sceneView:insert(questionBg)
	movementYMin = questionBg.y + 200

	local questionOptions = 
	{
		text = "",	 
		x = questionBg.x,
		y = questionBg.y,
		width = questionBg.width/1.5,
		font = settings.fontName,   
		fontSize = 26,
		align = "center"
	}

	questionText = display.newText(questionOptions)
	sceneView:insert(questionText)
	questionText:setFillColor( unpack( QUESTION_COLOR ) )

end

local function hasCollided( object1, object2 )
	if object1 and object2 then
		local distanceX = object1.x - object2.x
		local distanceY = object1.y - object2.y

		local distanceSquared = distanceX * distanceX + distanceY * distanceY
		local radiusSum = object2.radius + object1.radius
		local radii = radiusSum * radiusSum

		if distanceSquared < radii then
			transition.fadeOut( object1, {time = 100}) 
			return true
		end
	end
	return false
end

local function checkAnswer(ufo)
	if ufo.isCorrect then
		GAME_STATUS = "Correct"
		manager.correct()

	else
		GAME_STATUS = "Incorrect"
		manager.wrong({id = "text", text = correctAnswer, fontSize = 40})
	end
end

local function updateGame(event)
	if firstUpdate or lastTime > SHIFT_TIME then
		timePassed = event.time
		firstUpdate = false
	end
	lastTime = event.time - timePassed
	for ufoIndex = #ufosList, 1, -1 do
		--if timeElapsed > SHIFT_TIME
		local ufo = ufosList[ufoIndex]
		--ufo.timeElapsed = ufo.timeElapsed + lastTime
		if lastTime >= SHIFT_TIME then
			ufo:changeDirection()
		end
		if ufo.x < ufo.minX or ufo.x > ufo.maxX then
			ufo.direction.x = ufo.direction.x * -1
		end
		if ufo.y < ufo.minY or ufo.y > ufo.maxY then
			ufo.direction.y = ufo.direction.y * -1
		end
		ufo.x = ufo.x + (ufo.direction.x * UFO_SPEED)
		ufo.y = ufo.y + (ufo.direction.y * UFO_SPEED)
		for bulletIndex = #bulletList, 1, -1 do
			local bullet = bulletList[bulletIndex]
			bullet:update()
			local limitsX = bullet.x > display.viewableContentWidth + 10 or bullet.x < display.screenOriginX - 10
			local limitsY = bullet.y > display.viewableContentHeight + 10 or bullet.y < display.screenOriginY - 10
			if limitsX or limitsY then
				bullet.removeFlag = true
			end
			if hasCollided(bullet, ufo) and not collisionFlag then
				collisionFlag = true
				bullet.removeFlag = true
				ufo.removeFlag = true
				checkAnswer(ufo)
			end
			if bullet.removeFlag then
				display.remove(bulletList[bulletIndex])
				table.remove(bulletList, bulletIndex)
			end
		end
		if ufo.removeFlag then
			display.remove(ufosList[ufoIndex])
			table.remove(ufosList, ufoIndex)
			sound.play("pop")
		end
	end
	
end

local function tap( event )
	local eventX = event.x 
	local eventY = event.y
	tutorials.cancel(gameTutorial,300)
	if not isInExecution then
		isInExecution = true
		cannon:shoot(eventX, eventY)
		executionTimer = director.performWithDelay(scenePath, 600, function()
			isInExecution = false
			executionTimer = nil
		end)
	end

	return true
end

local function createUfos(sceneGroup)
	answers = extratable.shuffle(answers)

	local function addUfo(ufoIndex)
		local ufo = display.newGroup()
		ufo.x = (display.viewableContentWidth/4)*ufoIndex
		if isFirstTime then
			ufo.y = display.contentCenterY
		else
			ufo.y = math.random( movementYMin, movementYMax)		
		end

		local ufoBg = display.newImage(assetPath.."ufo.png")
		ufo:insert(ufoBg)

		local answerOptions = {
			text = answers[ufoIndex],	 
			x = ufoBg.x,
			y = ufoBg.y-15,
			width = ufoBg.width/2.3,
			font = settings.fontName,   
			fontSize = 20,
			align = "center"
		}
		ufo.answer = display.newText( answerOptions )
		ufo.answer:setFillColor( unpack (ANSWER_COLOR))
		ufo.value = answers[ufoIndex]
		ufo:insert(ufo.answer)
		ufo.radius = RADIUS_UFO
		ufo.direction = {x = 0, y = 0}
		ufo.minX = ufo.x - 70
		ufo.maxX = ufo.x + 70
		ufo.minY = ufo.y - 70
		ufo.maxY = ufo.y + 70
		
		function ufo:changeDirection()
			self.direction.x = math.random(0, 2) - 1
			self.direction.y = math.random(0, 2) - 1
		end
		
		ufo:changeDirection()
		ufosList[#ufosList+1] = ufo

		ufosGroup:insert(ufo)
	end

	for ufoIndex = 1, 3 do
		addUfo(ufoIndex)
	end
end

local function showTutorial()
	local correctUfo
	for ufoIndex = 1, #ufosList, 1 do
		if ufosList[ufoIndex].answer.text == correctAnswer then
			correctUfo = ufosList[ufoIndex]
			ufosList[ufoIndex].isCorrect = true
		else
			ufosList[ufoIndex].isCorrect = false
		end
	end
	
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap",delay = 1500, time = 2500, x = correctUfo.x, y = correctUfo.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

----------------------------------------------- Module functions
function game.getInfo()
	return {
		-- TODO questions are only in spanish
		available = false,
		correctDelay = 700,
		wrongDelay = 700,
		
		name = "Geo UFO",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 2},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	local background = display.newImage( assetPath.."background.png")
	local backgroundScale = display.viewableContentWidth / background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = backgroundScale
	background.yScale = backgroundScale
	background:toBack()
	sceneView:insert(background)

	generateCannon(sceneView)
	setQuestion(sceneView)
	
	instructions = display.newText("",  display.contentCenterX, display.screenOriginY + 120, settings.fontName, 26)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		isInExecution = true
		manager = event.parent
		
		isFirstTime = event.params.isFirstTime
		instructions.text = localization.getString("instructionsGeoUfo")

		ufosList = {}
		bulletList = {}
		collisionFlag = false
		firstUpdate = true
		display.remove(ufosGroup)
		ufosGroup = display.newGroup()
		sceneGroup:insert(ufosGroup)
		
		question = event.params.question
		questionText.text = question
		correctAnswer = event.params.answer
		wrongAnswers = event.params.wrongAnswers
		answers = {}
		answers[1] = correctAnswer
		answers[2] = wrongAnswers[1]
		answers[3] = wrongAnswers[2]
		
		createUfos(ufosGroup)
		showTutorial()
		Runtime:addEventListener("tap", tap)
		Runtime:addEventListener( "enterFrame", updateGame )
		
		isInExecution = false
		
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		Runtime:removeEventListener("tap", tap)
		Runtime:removeEventListener( "enterFrame", updateGame )
		for bulletIndex = #bulletList, 1, -1 do
			display.remove(bulletList[bulletIndex])
			bulletList[bulletIndex] = nil
		end
		for ufoIndex = #ufosList, 1, -1 do
			display.remove(ufosList[ufoIndex])
			ufosList[ufoIndex] = nil
		end
		display.remove( ufosGroup )
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
