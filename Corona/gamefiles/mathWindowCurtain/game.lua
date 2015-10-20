----------------------------------------------- WindowMath
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer, answersGroup, imageGroup, blindGroup
local backgroundLayer, background
local textLayer, textGroup, instructions, question
local manager
local isFirstTime
local gameTutorial
local correctAnswer, correctAnswerTutoX
local answerBox
local answerStrings
local randomElement, randomElementText
----------------------------------------------- Constants
local OFFSET_TUTORIAL_TEXT = {x = 0, y = -350}
local SIZE_FONT = 40
local ELEMENT_SIZE_FONT = 15
local ANSWERS_NUMBER = 3
local FONT_NAME = settings.fontName

local PADDING_ANSWERS_NUMBER = 250
local OFFSET_Y_ANSWERS_NUMBER = 300

local INSTRUCTIONS_FONT_COLOR = { 9/255, 109/255, 61/255 }
local QUESTION_FONT_COLOR = { 9/255, 109/255, 61/255 }

local ANSWER_FONT_COLOR = { 255/255, 255/255, 255/255 }
local ANSWER_TEXT_FONT_COLOR = { 255/255, 255/255, 255/255 }


local POS_NUMBER_OBJECTS = {
	[1] = {{x=0,y=0},},
	[2] = {{x=-0.5,y=0},{x=0.5,y=0},},
	[3] = {{x=-1,y=0},{x=0,y=0},{x=1,y=0},},
	[4] = {{x=-0.8,y=-0.8},{x=0.8,y=0.8},{x=-0.8,y=0.8},{x=0.8,y=-0.8},},
	[5] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=0,y=0},},
	[6] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},},
	[7] = {{x=-1,y=-1},{x=0,y=-1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},{x=0,y=0},},
	[8] = {{x=-1,y=-1},{x=0,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},{x=0,y=0},{x=0,y=-1},},
	[9] = {{x=-1,y=-1},{x=1,y=1},{x=-1,y=1},{x=1,y=-1},{x=-1,y=0},{x=1,y=0},{x=0,y=0},{x=0,y=-1},{x=0,y=1},},
}

local FIGURES = {
	[1] = {scenePath = "1.png", stringID = "fruitWatermelons"},
	[2] = {scenePath = "2.png", stringID = "fruitCherries"},
	[3] = {scenePath = "3.png", stringID = "fruitApples"},
	[4] = {scenePath = "4.png", stringID = "fruitGrapes"}
}

local TIME_SHOWING_FRUITS = 7000
----------------------------------------------- Functions
local function removeDynamicAnswers()
	display.remove(answersGroup)
	answersGroup = nil
	
	display.remove(textGroup)
	textGroup = nil
end

local function removeDynamicQuestionImage()
	display.remove(imageGroup)
	imageGroup = nil
end

local function createImageAnswerGroup(number, pX, pY)
	local imageAnswerGroup = display.newGroup()
	number = number <= #POS_NUMBER_OBJECTS and number or #POS_NUMBER_OBJECTS
	local tablePos = POS_NUMBER_OBJECTS[number]
		
	for index = 1, #tablePos do
		local object = display.newImage(assetPath .. randomElement.scenePath)
		object.x = pX + tablePos[index].x * object.width * 0.95
		object.y = pY + tablePos[index].y * object.height * 0.95
		imageAnswerGroup:insert(object)
		
		local timeTransition1 = math.random(700,900)
		local timeTransition2 = math.random(700,900)
		local totalTime = timeTransition1 + timeTransition1
		local transition = 
		function() 
			director.to(scenePath, object, {timeTransition1, xScale= 1.0, yScale=0.9, onComplete=function() 
				director.to(scenePath, object, {timeTransition2, xScale= 0.9, yScale=1.0})
			end})
		end
		transition()
		director.performWithDelay(scenePath, totalTime, transition, 0)
	end
	
	return imageAnswerGroup
end

local function contains(tableToCheck, valueToCompare)
	for  _, value in ipairs(tableToCheck) do
		if (value == valueToCompare) then
			return false
		end
	end	
	return true
end

local function createDynamicAnswers()
	removeDynamicAnswers()
	
	textGroup = display.newGroup()
	answersGroup = display.newGroup()

	local isCorrectAnswerSetted = false
	local answersSettedTable = {correctAnswer, 0}
	local hasAnswered = false

	local totalWidth = (ANSWERS_NUMBER - 1) * PADDING_ANSWERS_NUMBER
	local startX = display.contentCenterX - totalWidth * 0.50
	local answerScale = 0.70

	for index = 1, ANSWERS_NUMBER do		
		answerBox = display.newImage(assetPath.."respuesta.png")
		answerBox:scale(answerScale, answerScale)
		answerBox.x = startX + (index - 1) * PADDING_ANSWERS_NUMBER
		answerBox.y = display.contentCenterY + OFFSET_Y_ANSWERS_NUMBER
		answersGroup:insert(answerBox)
		
		local fakeAnswer
		
		repeat 
			fakeAnswer = math.abs( math.random(correctAnswer-3, correctAnswer+3) )
		until contains(answersSettedTable, fakeAnswer)
		
		local optionsAnswerText = 
		{
			text = fakeAnswer,     
			x = startX + (index - 1) * PADDING_ANSWERS_NUMBER,
			y = display.contentCenterY + OFFSET_Y_ANSWERS_NUMBER - 10,
			font = FONT_NAME,   
			fontSize = SIZE_FONT,
		}
		
		local answerText = display.newText(optionsAnswerText)
		answerText:setFillColor(unpack(ANSWER_FONT_COLOR))
		textGroup:insert(answerText)
		textLayer:insert(textGroup)
			
		local optionsAnswerDetailedText = 
		{
			text = randomElementText,     
			x = startX + (index - 1) * PADDING_ANSWERS_NUMBER,
			y = display.contentCenterY + OFFSET_Y_ANSWERS_NUMBER + 20,
			font = FONT_NAME,   
			fontSize = ELEMENT_SIZE_FONT,
		}
		
		local answerDetailedText = display.newText(optionsAnswerDetailedText)
		answerDetailedText:setFillColor(unpack(ANSWER_TEXT_FONT_COLOR))
		textGroup:insert(answerDetailedText)
		textLayer:insert(textGroup)
		
		local onAnswerTapped
		
		local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == ANSWERS_NUMBER)
		local correcto = false
		if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) then
			correctAnswerTutoX = answerBox.x
			answerText.text = correctAnswer
			isCorrectAnswerSetted = true
			correcto = true
		else
			table.insert(answersSettedTable, fakeAnswer)
		end
		
		onAnswerTapped = function(event)
			if hasAnswered then return end
			hasAnswered = true
			tutorials.cancel(gameTutorial,300)
			sound.play("pop")
			answerBox:removeEventListener("tap", onAnswerTapped)
			
			if manager and manager.wrong then			
				answerStrings = {answerText.text}
				if correcto then
					manager.correct()
				else
					manager.wrong({id = "text", text = (correctAnswer.." "..randomElementText), fontSize = 50})
				end
			end
		end	
		
		answerBox:addEventListener("tap", onAnswerTapped)
		answersLayer:insert(answersGroup)
	end
end

local function createBlinds(correctAnswer)
	local onQuestionTapped
	local blindRolledFlag = false
	
	blindGroup = display.newGroup()
	
	local posYimageGroup = display.contentCenterY
	local posXimageGroup = display.contentCenterX
	
	imageGroup = display.newGroup()
	imageGroup = createImageAnswerGroup(correctAnswer, posXimageGroup, posYimageGroup)
	imageGroup.x = display.contentCenterX * 0.40
	imageGroup.y = display.contentCenterY * 0.39
	imageGroup:scale(.60, .60)
	blindGroup:insert(imageGroup)
	
	local blindThingie = display.newImage(assetPath.."element.png")
	blindThingie:scale(.75, .75)
	blindThingie.x = display.contentCenterX
	blindThingie.y = display.contentCenterY + 122
	blindGroup:insert(blindThingie)
	
	
	local container = display.newContainer( 330, 225 )
	container:translate( display.contentCenterX, display.contentCenterY - 125 )

	local blindImage = display.newImage(assetPath.."blind.png")
	container:insert( blindImage, true )
	container.anchorY = 0
	blindGroup:insert(container)
	
	local windowTop = display.newImage(assetPath.."blind3.png")
	windowTop:scale(.75, .75)
	windowTop.x = display.contentCenterX
	windowTop.y = display.contentCenterY - 127
	blindGroup:insert(windowTop)
	
	director.to(scenePath, blindThingie, {x = container.x, y = container.y + 30, time=0})
	director.to(scenePath, container, {height = 10, time=0})
	blindRolledFlag = true
	
	director.performWithDelay(scenePath, TIME_SHOWING_FRUITS, function()
		sound.play("minigamesWhoosh")
		director.to(scenePath, blindThingie, {x = container.x, y = container.y + 245, time=500})
		director.to(scenePath, container, {height = 225, time=500, onComplete=function() 
			blindRolledFlag = false
		end})
	end)
		
	--[[onQuestionTapped = function(event)
		sound.play("minigamesWhoosh")
		if blindRolledFlag == true then
			director.to(scenePath, blindThingie, {x = container.x, y = container.y + 245, time=500})
			director.to(scenePath, container, {height = 225, time=500, onComplete=function() 
				blindRolledFlag = false
			end})
		elseif blindRolledFlag == false then
			director.to(scenePath, blindThingie, {x = container.x, y = container.y + 30, time=500})
			director.to(scenePath, container, {height = 10, time=500, onComplete=function() 
			blindRolledFlag = true
			end})
		end
	end
	blindGroup:addEventListener("tap", onQuestionTapped)]]
	answersLayer:insert(blindGroup)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent

	
	correctAnswer = params.numbers and params.numbers[1] or 1
	
	local randomFruitNumber = math.random(1, 4)
	randomElement = FIGURES[randomFruitNumber]
	randomElementText = localization.getString(FIGURES[randomFruitNumber]["stringID"])
	
	imageGroup = display.newGroup()
	
	createBlinds(correctAnswer)
	createDynamicAnswers()

	instructions.text = localization.getString("instructionsWindowMath")
	question.text = localization.getString("instructionsWindowMathQuestion")
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 1500, x = correctAnswerTutoX, y = answerBox.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		-- TODO: The correct answer could be provided by the manager.
		available = false,
		correctDelay = 400,
		wrongDelay = 400,
		
		name = "Window Math",
		category = "math",
		subcategories = {"addition"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "number", minimum = 1, maximum = 9},
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

	background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	backgroundLayer:insert(background)
	
	local topBackground = display.newImageRect(assetPath .. "tablero.png", display.viewableContentWidth + 2, display.screenOriginY + 250 )
	topBackground.x = display.contentCenterX
	topBackground.y = display.screenOriginY + 125
	backgroundLayer:insert(topBackground)
	
	local questionBackground = display.newImage(assetPath .. "pregunta.png", display.contentCenterX, display.screenOriginY + 90)
	backgroundLayer:insert(questionBackground)
	
	local instructionsOptions = 
	{
		text = "",	 
		x = display.screenOriginX + 200,
		y = display.contentCenterY,
		width = 200,
		font = FONT_NAME,   
		fontSize = 24,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(unpack(INSTRUCTIONS_FONT_COLOR))
	textLayer:insert(instructions)
	
	local window = display.newImage(assetPath.."ventana.png")
	window:scale(.75, .75)
	window.x = display.contentCenterX
	window.y = display.contentCenterY
	backgroundLayer:insert(window)
	
	local questionOptions = 
	{
		text = "",	 
		x = display.contentCenterX,
		y = display.contentCenterY * 0.25,
		font = FONT_NAME,   
		fontSize = SIZE_FONT,
		align = "center"
	}
	
	question = display.newText(questionOptions)
	question:setFillColor(unpack(QUESTION_FONT_COLOR))
	textLayer:insert(question)
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
		removeDynamicQuestionImage()
		removeDynamicAnswers()
		display.remove(blindGroup)
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
