----------------------------------------------- Hipo_024
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )
local uifx = require( "libs.helpers.uifx" )

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabled
local isFirstTime
local gameTutorial
local questionText
local answerSplit = {}
local correctAnswerTable
local correctAnswer
local randomAnswers
local hippoGroup
local dynamicAnswers
----------------------------------------------- Constants
local TOTAL_ANSWERS = 3
local QUESTION_COLOR = {214/255,107/255,9/255}
local INSTRUCTIONS_COLOR = {73/255,119/255,0/255}
local OPTIONS_COLOR = {87/255, 135/255, 132/255}
local SIZE_FONT = 40
----------------------------------------------- Functions
local function onAnswerTapped(event)
	local answer = event.target
	if tapsEnabled then
		tutorials.cancel(gameTutorial,300)
		tapsEnabled = false
		for indexTransitions = 2, TOTAL_ANSWERS+1 do
			local yPosition
			local xPosition = (((display.viewableContentWidth*0.90)/(TOTAL_ANSWERS +2))*indexTransitions) + (display.viewableContentWidth*0.10)
			if indexTransitions % 2 == 0 then
				yPosition = display.viewableContentHeight*0.675
			else
				yPosition = display.viewableContentHeight*0.775
			end
			director.to(scenePath, hippoGroup, {delay = 1000*(indexTransitions-2)
				,onComplete = function()
					if answer.id+1 == indexTransitions then
						checkingAnswer()
					end
				end,
				onStart = function()
					uifx.jump(hippoGroup, {x = xPosition, y = yPosition, height = 100, time = 200})
					sound.play("pop")
				end
			})
			if answer.id+1 == indexTransitions then
				break
			end
		end
		function checkingAnswer()
			if answer.isCorrect then
				if manager then
					manager.correct()
				end
			else
				if manager then
					director.to(scenePath,  answer, {time= 1000, y = display.viewableContentWidth, yScale = 0, xScale = 0, 
						onStart= function()
							sound.play("minigamesBubblesSurface")
							hippoGroup[1].isVisible = true
							hippoGroup[2].isVisible = false
							director.to(scenePath, hippoGroup, {time = 1000, y = display.viewableContentWidth, yScale=0, xScale=0 })
						end
					 ,onComplete = function() 
						 manager.wrong({id = "text", text = answerSplit[1] , fontSize = 54})
					end})
				end
			end
		end
		
	end
end

local function removeDynamicAnswers()
	display.remove(dynamicAnswers)
	dynamicAnswers = nil
	for IndexRemoveAnswerSplit=1, #answerSplit do
		answerSplit[IndexRemoveAnswerSplit] = nil
	end
end

local function generateRandomAnswers()
	correctAnswerTable = extratable.deepcopy(answerSplit)

	correctAnswerTable = extratable.shuffle(correctAnswerTable)
	
	randomAnswers = correctAnswerTable
end

local function createDynamicAnswers()
	dynamicAnswers = display.newGroup( )
	hippoGroup = display.newGroup()
	local hippoWin = display.newImage(assetPath .. "hipo1.png")
	local hippoLose = display.newImage(assetPath .. "hipo2.png")
	hippoLose.isVisible = false
	hippoGroup:insert(hippoLose)
	hippoGroup:insert(hippoWin)
	hippoGroup.x = display.viewableContentWidth * 0.15
	hippoGroup.y = display.viewableContentHeight * 0.70
	

	for indexOptions = 2, TOTAL_ANSWERS+1 do
		local optionsGroup = display.newGroup( )
		local randomOption = math.random( 1, 3 )
		local optionsImage = display.newImage(assetPath .. "opcion" .. randomOption .. ".png")
		local optionsTextOptions = 
		{
			text = randomAnswers[indexOptions-1],
			x = 0,
			y = -20,
			width = optionsImage.width*0.9,
			height = 0,
			font = settings.fontName,
			fontSize = SIZE_FONT*0.75,
			align = "center"
		}
		local optionsText = display.newText(optionsTextOptions)
		optionsText:setFillColor( unpack( OPTIONS_COLOR ) )
		optionsGroup:insert( optionsImage )
		optionsGroup:insert(optionsText)
		optionsGroup.x = (((display.viewableContentWidth*0.90)/(TOTAL_ANSWERS +2))*indexOptions) + (display.viewableContentWidth*0.10)
		if indexOptions % 2 == 0 then
			optionsGroup.y = display.viewableContentHeight*0.8
		else
			optionsGroup.y = display.viewableContentHeight*0.9
		end
		optionsGroup.text = randomAnswers[indexOptions-1]
		
		if optionsGroup.text == correctAnswer then
			optionsGroup.isCorrect = true
		else
			optionsGroup.isCorrect = false
		end
		
		optionsGroup.id = indexOptions-1
		dynamicAnswers:insert(optionsGroup)
		optionsGroup:addEventListener("tap", onAnswerTapped)
	end

	dynamicAnswers:insert(hippoGroup)
	answersLayer:insert(dynamicAnswers)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent

	questionText.text = params.question 
	answerSplit[1] = params.answer
	correctAnswer = params.answer
	for indexWrongAnswers = 1, TOTAL_ANSWERS-1 do
		answerSplit[#answerSplit+1] = params.wrongAnswers[indexWrongAnswers]
	end
	instructions.text = localization.getString("instructionsHipo_024")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial()
	if isFirstTime then
		local correctAnswerPosition
		for indexCorrectAnswerPosition = 1, TOTAL_ANSWERS do
			if answerSplit[1] == randomAnswers[indexCorrectAnswerPosition] then
				correctAnswerPosition = indexCorrectAnswerPosition
			end
		end
		local tutorialOptions = {
			iterations = 4,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap",delay = 1200, time = 1500, x = (((display.viewableContentWidth*0.90)/(TOTAL_ANSWERS +2))*(correctAnswerPosition+1)) + (display.viewableContentWidth*0.10), y = display.viewableContentHeight*0.85},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = false,
		name = "Geo Hipo",
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

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	local background = display.newImage(assetPath .. "fondo.png")
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:scale(backgroundScale, backgroundScale)
	backgroundLayer:insert(background)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	local questionGroup = display.newGroup( )
	local questionImage = display.newImage( assetPath .. "pregunta.png" )
	local questionOptions = 
	{
		text = "Movimiento de la Tierra que da origen al día y la noche:",
		x = 0,
		y = 25,
		width = questionImage.width*0.9,
		height = 0,
		font = settings.fontName,
		fontSize = SIZE_FONT*0.75,
		align = "center"
	}
	questionText = display.newText(questionOptions)
	questionText:setFillColor( unpack(QUESTION_COLOR) )
	questionGroup:insert(questionImage)
	questionGroup:insert( questionText )
	sceneView:insert(questionGroup)
	questionGroup.x = display.contentCenterX
	questionGroup.y = display.viewableContentHeight*0.1

	instructions = display.newText("", display.contentCenterX , display.viewableContentHeight*0.35, settings.fontName, SIZE_FONT*0.75)
	instructions:setFillColor( unpack(INSTRUCTIONS_COLOR) )
	textLayer:insert(instructions)

end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		generateRandomAnswers()
		createDynamicAnswers()
		tutorial()
	elseif phase == "did" then
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		disableButtons()
	elseif phase == "did" then
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
