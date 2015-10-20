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
local doors
local yogotar
local answerGroup
local tapsEnabled
local questionText
local correctAnswer
local answerList
local answerListSet
local wrongAnswers
local gameTutorial

----------------------------------------------- Constants

local TOTAL_ANSWERS = 3
local PADDING_ANSWERS = 170
local COLOR_ANSWERS = {204/255, 46/255, 151/255}
local COLOR_INSTRUCTIONS = {60/255, 115/255, 124/255}

----------------------------------------------- Functions

local function closeDoor()
	doors.closed.isVisible = true
	doors.opened.isVisible = false
	yogotar.safe.isVisible = true
	yogotar.inDanger.isVisible = false
	
	yogotar.y = yogotar.y - 50
	
	manager.correct()
	
	director.to(scenePath, yogotar, {delay = 0, time = 250, y = yogotar.y - 40, onComplete = function()
		director.to(scenePath, yogotar, {delay = 0, time = 200, y = yogotar.y +40, onComplete = function()
			director.to(scenePath, yogotar, {delay = 0, time = 250, y = yogotar.y - 40, onComplete = function()
				director.to(scenePath, yogotar, {delay = 0, time = 200, y = yogotar.y +40,})
			end})
		end})
	end})
end

local function byeYogotar()
	yogotar.gone.isVisible = true
	yogotar.inDanger.isVisible = false
	manager.wrong({id = "text", text = correctAnswer, fontSize = 80})
	director.to(scenePath, yogotar, {delay = 0, time = 1000, x = doors.x + doors.opened.width*0.25, y = doors.y, rotation = 640, xScale = 0.3, yScale = 0.3,})
end

local function answerTap(event)
	sound.play("pop")
	
	tutorials.cancel(gameTutorial,300)
	local answer = event.target 
	if tapsEnabled then
		tapsEnabled = false
		if answer.isCorrect then
			closeDoor()
		else
			byeYogotar()			
		end
	end
end

local function removeAnswers()
	display.remove(answerGroup)
	answerGroup = nil
end

local function createAnswers()
	removeAnswers() 
	
	answerGroup = display.newGroup()
	answersLayer:insert(answerGroup)
	answerListSet = {}
	
	local totalHeight = (TOTAL_ANSWERS - 1) * PADDING_ANSWERS
	local startY = display.contentCenterY - totalHeight * 0.5 
	
	for index = 1, TOTAL_ANSWERS do
		local answerBox = display.newGroup()
		local answerBoxBg = display.newImage(assetPath.."answer.png")
		answerBox.x = display.viewableContentWidth * 0.85
		answerBox.y = startY + (index - 1) * PADDING_ANSWERS
		answerBox:insert(answerBoxBg)
		local answerOptions = {
			text = answerList[index],     
			x = answerBoxBg.x,
			y = answerBoxBg.y,
			width = answerBoxBg.width*0.7,
			font = settings.fontName,   
			fontSize = 24,
			align = "center"  
		}
		answerBox.text = display.newText(answerOptions)
		answerBox.text:setFillColor(unpack(COLOR_ANSWERS))
		answerBox:insert(answerBox.text)
		answerBox:addEventListener("tap", answerTap)
		answerGroup:insert(answerBox)
		answerListSet[#answerListSet + 1] = answerBox
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	
	local question = params.question
	correctAnswer = params.answer
	wrongAnswers = params.wrongAnswers
	
	answerList = {}
	answerList[1] = correctAnswer
	answerList[2] = wrongAnswers[1]
	answerList[3] = wrongAnswers[2]
	answerList = extratable.shuffle(answerList)
	
	yogotar.x = doors.x + 50
	yogotar.y = doors.y + doors.height*0.25
	
	doors.opened.isVisible = true
	doors.closed.isVisible = false
	
	yogotar.inDanger.isVisible = true
	yogotar.safe.isVisible = false
	yogotar.gone.isVisible = false
	
	tapsEnabled = true
	
	questionText.text = question
	createAnswers()

end

local function tutorial()
	if isFirstTime then
		local correctBox
		for index = 1, #answerList do
			if answerListSet[index].text.text == correctAnswer then
				correctBox = answerListSet[index]
				answerListSet[index].isCorrect = true
			else
				answerListSet[index].isCorrect = false
			end
		end
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap",delay = 1000, time = 2500, x = correctBox.x, y = correctBox.y},
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
		
		
		name = "Open Door",
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
	
	local questionBg = display.newImage(assetPath.."questionBg.png")
	questionBg.x = display.contentCenterX
	questionBg.y = display.viewableContentHeight*0.1
	backgroundLayer:insert(questionBg)
	
	local questionTextOptions = {
		text = "",
		x = questionBg.x,
		y = questionBg.y,
		width = questionBg.width * 0.8,
		font = settings.fontName,
		fontSize = 26,
		align = "center"
	}
	
	questionText = display.newText(questionTextOptions)
	textLayer:insert(questionText)
	
	local instructionsOptions = {
		text = localization.getString("instructionsPuertaAbierta"),     
		x = display.viewableContentWidth*0.4,
		y = display.viewableContentHeight*0.93,
		width = display.viewableContentWidth*0.5, 
		font = settings.fontName,   
		fontSize = 22,
		align = "center" 
	}

	local instructionsText =  display.newText( instructionsOptions )
	instructionsText:setFillColor(unpack(COLOR_INSTRUCTIONS))
	textLayer:insert(instructionsText)
	
	doors = display.newGroup()
	doors.closed = display.newImage(assetPath.."closedDoor.png")
	doors:insert(doors.closed)
	doors.opened = display.newImage(assetPath.."openDoor.png")
	doors:insert(doors.opened)
	doors.x = display.viewableContentWidth*0.4
	doors.y = display.contentCenterY+10
	backgroundLayer:insert(doors)
	
	yogotar = display.newGroup()
	yogotar.inDanger = display.newImage(assetPath.."yogotar1.png")
	yogotar:insert(yogotar.inDanger)
	yogotar.safe = display.newImage(assetPath.."yogotar2.png")
	yogotar:insert(yogotar.safe)
	yogotar.gone = display.newImage(assetPath.."yogotar3.png")
	yogotar:insert(yogotar.gone)
	backgroundLayer:insert(yogotar)
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
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game




