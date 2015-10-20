----------------------------------------------- Math Slider
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )
local settings = require( "settings" )
local tutorials = require( "libs.helpers.tutorials" )
local screen = require( "libs.helpers.screen" )
local game = director.newScene() 
----------------------------------------------- Variables
local manager
local posSliderXInit
local respuestaCorrectaX
local isFirstTime
local background
local colorRGB
local questionString
local answerStrings
local objectsToBeRemoved
local gameTutorial
local instructions
----------------------------------------------- Constants
local FONT_NAME = settings.fontName
local FONT_SIZE = 100
local DEFAULT_COLOR_BACKGROUND = {255/255,170/255,0/255}

----------------------------------------------- Functions
local function generateEquation(operand1, operand2, nameImageOperator)
	local sceneView = game.view
	local offsetX = display.contentCenterX - 300
	local posY = display.viewableContentHeight * 0.3
	
	local operand1Group = display.newGroup()
	objectsToBeRemoved[#objectsToBeRemoved + 1] = operand1Group
	local operand1Bg = display.newImage(assetPath.."minigames-elements-35.png")
	local operand1Text = display.newText(operand1, 0, -10, FONT_NAME, FONT_SIZE)
	operand1Text:setFillColor(14/255,120/255,153/255)
	operand1Group:insert(operand1Bg)
	operand1Group:insert(operand1Text)
	operand1Group.x = offsetX
	operand1Group.y = posY
	sceneView:insert(operand1Group)

	local operator = display.newImage(nameImageOperator)
	objectsToBeRemoved[#objectsToBeRemoved + 1] = operator
	operator.x = offsetX + 150
	operator.y = posY
	sceneView:insert(operator)
	
	local operand2Group = display.newGroup()
	objectsToBeRemoved[#objectsToBeRemoved + 1] = operand2Group
	local operand2Bg = display.newImage(assetPath.."minigames-elements-35.png")
	local operand2Text = display.newText(operand2, 0, -10, FONT_NAME, FONT_SIZE)
	operand2Text:setFillColor(14/255,120/255,153/255)
	operand2Group:insert(operand2Bg)
	operand2Group:insert(operand2Text)
	operand2Group.x = offsetX + 300
	operand2Group.y = posY
	sceneView:insert(operand2Group)

	local equalsSign = display.newImage(assetPath.."equalsWhite.png")
	equalsSign.x = offsetX + 450
	equalsSign.y = posY
	sceneView:insert(equalsSign)
	objectsToBeRemoved[#objectsToBeRemoved + 1] = equalsSign
	
	local questionMarkGroup = display.newGroup()
	objectsToBeRemoved[#objectsToBeRemoved + 1] = questionMarkGroup
	local questionMarkBg = display.newImage(assetPath.."minigames-elements-36.png")
	local questionMarkText = display.newText("?", 0, -10, FONT_NAME, FONT_SIZE)
	questionMarkText.isVisible = false
	questionMarkText:setFillColor(0,0,0)
	questionMarkGroup:insert(questionMarkBg)
	questionMarkGroup:insert(questionMarkText)
	questionMarkGroup.x = offsetX + 600
	questionMarkGroup.y = posY
	sceneView:insert(questionMarkGroup)
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = posSliderXInit, y = screen.getPositionY(0.85), toX = respuestaCorrectaX, toY = screen.getPositionY(0.85)},
			},
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function generateAnswerSlider(correctAnswer)
	local sceneView = game.view
	
	local slider = display.newImage(assetPath .. "slider.png")
	objectsToBeRemoved[#objectsToBeRemoved + 1] = slider
	slider.x = display.contentCenterX
	slider.y = screen.getPositionY(0.8)
	sceneView:insert(slider)
	
	posSliderXInit = slider.x - slider.width *0.471
	local posXFinal = slider.x + slider.width *0.46
	local deltaDistance = (posXFinal - posSliderXInit)  / 10
	local halfDeltaDist = deltaDistance * 0.5
	
	respuestaCorrectaX = posSliderXInit + deltaDistance * (correctAnswer)
	
	local pinSlider = display.newImage(assetPath .. "minigames-elements-38.png")
	objectsToBeRemoved[#objectsToBeRemoved + 1] = pinSlider
	pinSlider.x = posSliderXInit 
	pinSlider.y = slider.y + 100
	sceneView:insert(pinSlider)
	
	local numberIndicatorGroup = display.newGroup()
	objectsToBeRemoved[#objectsToBeRemoved + 1] = numberIndicatorGroup
	local numberIndicatorImage = display.newImage(assetPath .. "minigames-elements-37.png")
	numberIndicatorImage.anchorY = 1
	numberIndicatorImage.y = -40
	numberIndicatorGroup:insert(numberIndicatorImage)
	local numberText = display.newText("0", 0, -160, FONT_NAME, FONT_SIZE)
	numberText:setFillColor(14/255, 120/255, 153/255)
	numberIndicatorGroup:insert(numberText)
	numberIndicatorGroup.x = pinSlider.x
	numberIndicatorGroup.y = slider.y - 20
	sceneView:insert(numberIndicatorGroup)
	
	function pinSlider:touch( event )
		if event.phase == "began" then
			tutorials.cancel(gameTutorial,300)
			display.getCurrentStage():setFocus( self )
			self.isFocus = true
			sound.play("dragtrash")
			pinSlider.deltaX = event.x - pinSlider.x
			
			if numberIndicatorGroup.transition then
				transition.cancel(numberIndicatorGroup.transition)
			end
			
			if pinSlider.transition then
				transition.cancel(pinSlider.transition)
			end
				
		elseif self.isFocus then
			if event.phase == "moved" then
				pinSlider.x = event.x - pinSlider.deltaX
				pinSlider.x = pinSlider.x < posSliderXInit and posSliderXInit or pinSlider.x
				pinSlider.x = pinSlider.x > posXFinal and posXFinal or pinSlider.x

				numberIndicatorGroup.x = pinSlider.x

				for index = 0, 10 do
					local posMiddlePoint = posSliderXInit + deltaDistance*(index)
					local leftBoundPoint = posMiddlePoint - halfDeltaDist
					local rightBoundPoint = posMiddlePoint + halfDeltaDist
					if pinSlider.x >= leftBoundPoint and pinSlider.x < rightBoundPoint then
						local deltaLocalDistance = math.abs(posMiddlePoint - pinSlider.x)
						local scale = 1 - deltaLocalDistance / halfDeltaDist
						numberIndicatorGroup.xScale = scale
						numberIndicatorGroup.posMiddlePoint = posMiddlePoint
						numberText.text = index
						break
					end
				end

			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				self.isFocus = nil
				sound.play("pop")
				pinSlider:removeEventListener("touch")
				numberIndicatorGroup.transition = director.to(scenePath, numberIndicatorGroup, {time=500, x=numberIndicatorGroup.posMiddlePoint, xScale=1, yScale=1, transition=easing.Quad})
				pinSlider.transition = director.to(scenePath, pinSlider, {time=300, x=numberIndicatorGroup.posMiddlePoint, transition=easing.Quad, onComplete=function()
					if tonumber(numberText.text) == correctAnswer then
						answerStrings = {numberText.text}
						local data = {questionString = questionString, answerStrings = answerStrings}
						if manager and manager.correct then
							manager.correct(data)
						end
					else
						if manager and manager.wrong then
							manager.wrong({id = "text", text = questionString})
						end
						--pinSlider:addEventListener("touch")
					end
				end})
			end
		end
		return true
	end
	pinSlider:addEventListener("touch")
end

local function initialize(event)
	event = event or {}
	local parameters = event.params or {}
	
	manager = event.parent
	
	instructions.text = localization.getString("instructionsMathslider")

	objectsToBeRemoved = {}
	colorRGB = parameters.colorBg or DEFAULT_COLOR_BACKGROUND
	isFirstTime = parameters.isFirstTime
	background:setFillColor(unpack(colorRGB))
	
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
	local equalityString = operation.operationString or "0+0=?"
	
	questionString = equalityString
	
	generateEquation(operand1, operand2, nameImageOperator)
	generateAnswerSlider(correctAnswer)
end

----------------------------------------------- Module functions  
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Math slider",
		category = "math",
		subcategories = {"addition", "subtraction", "multiplication", "division"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "operation", operands = 2, minAnswer = 0, maxAnswer = 10, minOperand = 1, maxOperand = 10},
			{id = "wrongAnswer", amount = 10},
		},
	}
end 

function game:create(event)
	local sceneView = self.view
	
	background = display.newRect(sceneView, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	
	local instructionOptions = {
		text = "",	 
		x = display.viewableContentWidth*0.5,
		y = display.viewableContentHeight*0.45,
		width = display.viewableContentWidth*0.7,
		font = FONT_NAME,  
		fontSize = 32,
		align = "center"
	}
	
	instructions = display.newText(instructionOptions)
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
	end
end


function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	
	elseif ( phase == "did" ) then
		tutorials.cancel(gameTutorial)
		for index = 1, #objectsToBeRemoved do
			display.remove(objectsToBeRemoved[index])
		end
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
