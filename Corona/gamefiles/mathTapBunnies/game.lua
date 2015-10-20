----------------------------------------------- Math tap 5
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local screen = require( "libs.helpers.screen" )
local extratable = require("libs.helpers.extratable")

local game = director.newScene()
----------------------------------------------- Variables
local manager
local isGameAnswered
local questionString
local answerStrings
local lightgrassgen
local isFirstTime, correctObject
local instructions
local gameTutorial
local answersGroup
local contentGroup, equationGroup, grassGroup
local wrongAnswers
local answersSettedTable
local operationResult
----------------------------------------------- Constants
local RATIO_Y_ANSWERS = 0.27

local FONT_COLOR_OPERANDS = {175/255, 39/255, 49/255}
local FONT_COLOR_CHOICES = {230/255, 106/255, 108/255}

local SIZE_TEXT = 72
local SIZE_OPERANDS = 104
local DEFAULT_COLOR_BACKGROUND = {0.5,0.7,0.3}
----------------------------------------------- Functions
local function generateEquation(operand1, operand2, nameImageOperator)
	display.remove(equationGroup)
	equationGroup = display.newGroup()
	contentGroup:insert(equationGroup)
	local scaleSigns = 1

	local offsetX = display.contentCenterX - 300
	local posY = display.contentCenterY + 240
	local bgOp1 = display.newImage(assetPath.."minigames-elements-29.png")
	bgOp1:scale(.75,.75)
	bgOp1.x = offsetX
	bgOp1.y = posY
	equationGroup:insert(bgOp1)
	local operand1Text = display.newText(operand1, offsetX, posY+20, settings.fontName, SIZE_OPERANDS)
	operand1Text:setFillColor(unpack( FONT_COLOR_OPERANDS ))
	equationGroup:insert(operand1Text)

	local operator = display.newImage(nameImageOperator)
	operator.x = offsetX + 150
	operator.y = posY + 10
	operator.xScale = scaleSigns
	operator.yScale = scaleSigns
	equationGroup:insert(operator)

	local bgOp2 = display.newImage(assetPath.."minigames-elements-29.png")
	bgOp2:scale(.75,.75)
	bgOp2.x = offsetX + 300
	bgOp2.y = posY
	equationGroup:insert(bgOp2)
	local operand2Text = display.newText(operand2, bgOp2.x, posY+20, settings.fontName, SIZE_OPERANDS)
	operand2Text:setFillColor(unpack( FONT_COLOR_OPERANDS ))
	equationGroup:insert(operand2Text)

	local equalsSign = display.newImage(assetPath.."igual.png")
	equalsSign:scale(.50,.50)
	equalsSign.x = offsetX + 450
	equalsSign.y = posY + 10
	equationGroup:insert(equalsSign)

	local bgQuestionMark = display.newImage(assetPath.."minigames-elements-30.png")
	bgQuestionMark:scale(.75,.75)
	bgQuestionMark.x = offsetX + 600
	bgQuestionMark.y = posY
	equationGroup:insert(bgQuestionMark)
end

local function generateAnswers(correctAnswer)
	display.remove(answersGroup)
	answersGroup = display.newGroup()
	local totalWidthKittens = 750
	local offsetX = display.contentCenterX - totalWidthKittens * 0.5
	local paddingX = totalWidthKittens / 3
	contentGroup:insert(answersGroup)

	-- Function To Generate Answers
	local generatingAnswers = function()

		local lgGroup = display.newGroup()
		answersSettedTable = {correctAnswer, 0}
		
		local isCorrectAnswerSetted = false
		local totalAnswers = 4

		for index=1, totalAnswers do
			local answerGroup = display.newGroup()
			local kittenGroup = display.newGroup()
			--local boxGroup = display.newGroup()

			local kitten = display.newImage(assetPath.."minigames-elements-39.png")
			kitten:scale(1.10,1.10)
			kittenGroup:insert(kitten)

			-- Check if this answer was setted before, in order to not repeat answers.
			local fakeAnswer
			fakeAnswer = wrongAnswers[index]
			table.insert(answersSettedTable, fakeAnswer)
			
			local answerText = display.newText(fakeAnswer, 0, 80, settings.fontName, SIZE_TEXT)
			answerText:setFillColor(unpack( FONT_COLOR_CHOICES ))
			kittenGroup:insert(answerText)
			answerGroup:insert(kittenGroup)
			
			local mask = graphics.newMask(assetPath.."mask.png")
			kittenGroup.isHitTestMasked = false
			kittenGroup:setMask(mask)
			kittenGroup.maskY = 130
			kittenGroup.maskScaleX = 1.25
			kittenGroup.maskScaleY = 1.25

			local grassX = 0 --math.random(50, 100)

			if lightgrassgen == false then
				for i = 0, 4 do
					grassX = grassX + math.random(20, 280)
					local grassY = math.random(350, 425)
					local lightgrass = display.newImage(assetPath.."lightgrass.png", grassX, grassY)
					lgGroup:insert(lightgrass)
					lgGroup:toFront()
					answersGroup:insert(lgGroup)
					lightgrassgen = true
				end
			end

			local answerListenerFunction
			local correctAnswerNeedsToBeSetted = (fakeAnswer % 2 == 0 or index == totalAnswers)
			if (not isCorrectAnswerSetted and correctAnswerNeedsToBeSetted) or (fakeAnswer == correctAnswer) then
				answerText.text = correctAnswer
				isCorrectAnswerSetted = true
				correctObject = kittenGroup
				answerListenerFunction = function()
					if isGameAnswered then
						return
					end
					isGameAnswered = true
					sound.play("pop")
					tutorials.cancel(gameTutorial,300)
					kittenGroup:removeEventListener("tap",answerListenerFunction)
					if manager and manager.correct then
						answerStrings = {answerText.text }
						local data = {questionString = questionString, answerStrings = answerStrings}
						manager.correct(data)
					end
				end
			else
				answerListenerFunction = function()
					if isGameAnswered then
						return
					end
					isGameAnswered = true
					sound.play("pop")
					kittenGroup:removeEventListener("tap",answerListenerFunction)
					if manager and manager.wrong then
						answerStrings = {answerText.text }
						local data = {questionString = questionString, answerStrings = answerStrings}
						manager.wrong({ id = "text", text = operationResult, fontSize = 80 })
					end
				end
			end
			kittenGroup:addEventListener("tap",answerListenerFunction)

			answerGroup.x = offsetX + paddingX * (index-1)
			answerGroup.y = screen.getPositionY(RATIO_Y_ANSWERS)
			kittenGroup.y = 140
			
			local randomDelay = math.random(0,800)

			director.to(scenePath, kittenGroup, {delay=1000 + randomDelay, time = 1000, y=10, maskY = 270, transition=easing.outQuad, onComplete=function()
				director.to(scenePath, kittenGroup, {delay=3000 - randomDelay, time = 1000, y=140, maskY = 130, transition=easing.outQuad, onComplete=function()
					director.performWithDelay(scenePath, 1000, function() display.remove(answerGroup) end, 1)
				end})
			end})

			answersGroup:insert(answerGroup)
		end
	end

	generatingAnswers()
	director.performWithDelay(scenePath, 6000, generatingAnswers, 0)
end

local function generateGrass()
	display.remove(grassGroup)
	grassGroup = display.newGroup()
	contentGroup:insert(grassGroup)

	local grassX = 0 --math.random(50, 100)

	for i = 0, 8 do
		grassX = grassX + math.random(20, 280)
		local grassY = math.random(0, 350)
		local darkgrass = display.newImage(assetPath.."darkgrass.png", grassX, grassY)
		grassGroup:insert(darkgrass)
	end
end

local function initialize(event)
	event = event or {}
	
	local parameters = event.params or {}

	manager = event.parent

	isFirstTime = parameters.isFirstTime
	
	instructions.text = localization.getString("instructionsMathtap5")

	local operatorFilenames = {
		["addition"] = "images/minigames/plusWhite.png",
		["subtraction"] = "images/minigames/minusWhite.png",
		["multiplication"] = "images/minigames/multiplyWhite.png",
		["division"] = "images/minigames/divisionWhite.png",
	}

	local chosenCategory = parameters.topic or "addition"
	local operation = parameters.operation or {operands = {0,0}, result = 0, }
	
	local operand1 = operation.operands and operation.operands[1] or 0
	local operand2 = operation.operands and operation.operands[2] or 0
	local correctAnswer = operation.result or 0
	local nameImageOperator = operatorFilenames[chosenCategory]
	local equalityString = parameters.dataString or "0+0=?"
	questionString = equalityString
	operationResult = operation.operationString
	lightgrassgen = false

	wrongAnswers = parameters.wrongAnswers
	
	generateGrass()
	generateAnswers(correctAnswer)
	generateEquation(operand1, operand2, nameImageOperator)
end

local function getCorrectObject()
	return correctObject
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 10,
			parentScene = game.view,
			scale = 0.6,
			steps = {
				[1] = {id = "tap", y = 100, delay = 1500, time = 2000, getObject = getCorrectObject},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = true,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Math tap rabbits",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minOperand = 1},
			{id = "wrongAnswer", amount = 4, tolerance = 5, unique = true},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	local background = display.newImageRect(assetPath .. "fondo.png", display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	sceneView:insert(background)
	
	contentGroup = display.newGroup()
	sceneView:insert(contentGroup)
	
	local options = {
		text = "",
		x = display.contentCenterX,
		y = display.screenOriginY+30,
		font = settings.fontName,
		fontSize = 32,
		align = "center"
	}
	instructions = display.newText(options)
	instructions:setFillColor(255/255, 255/255, 255/255)
	sceneView:insert(instructions)
end


function game:destroy()

end


function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize(event)
		showTutorial()
	elseif ( phase == "did" ) then
		isGameAnswered = false
	end
end


function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		display.remove(answersGroup)
		display.remove(equationGroup)
		display.remove(grassGroup)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
