----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local sound = require( "libs.helpers.sound" )
local localization = require( "libs.helpers.localization" )

local game = director.newScene()
----------------------------------------------- Variables

local backgroundLeft
local backgroundRight
local numbersList
local numberBackground
local objectsTotal
local objectsList
local objectsGroup
local manager
local dragImageGroup
local answerBlockBg
local dragImageList
local countedObjects
local countIndicator
local finalAnswer
local isFirstTime
local gameTutorial
local instructionsText
local backgroundLayer, answersLayer, textLayer
local abletoTouch
local xOption, yOption
local answerNumberGroup

----------------------------------------------- Constants

local BACKGROUND_COLOR_LEFT = {170/255, 199/255, 167/255}
local BACKGROUND_COLOR_RIGHT = {107/255, 168/255, 167/255}
local NUMBERS_BACKGROUND = {105/255, 37/255, 93/255}
local DRAG_POSITION_COLOR = {0/255, 63/255, 115/255}
local NUMBERS_COLOR = {16/255, 111/255, 153/255}
local INDICATOR_OFFSET_Y = 10

local COUNT_OBJECTS = {
	[1] = {name = "apple", objectQuantity = 1, indicatorOffset = 55},
	[2] = {name = "carrot", objectQuantity = 1, indicatorOffset = 55},
	[3] = {name = "bread", objectQuantity = 1, indicatorOffset = 65},
	[4] = {name = "juice", objectQuantity = 1, indicatorOffset = 50}
}

----------------------------------------------- Functions

local function checkAnswer(obj)
	
	local finalAnswerNumber = ""
	for index = 1, #finalAnswer do
		
		finalAnswerNumber = finalAnswerNumber..finalAnswer[index]
	end
	
	if tonumber(finalAnswerNumber) == objectsTotal then
		manager.correct()
	else
		manager.wrong({id = "text", text = objectsTotal, fontSize = 80})
	end
	timer.performWithDelay(500, function()
		obj.x, obj.y = obj.xPos, obj.yPos
		obj.xScale, obj.yScale = 0.8, 0.8
		obj.alpha = 1
	end)
	
end
--
local function createDragIndicator()
	
	dragImageList = {}
	dragImageGroup = display.newGroup()
	answersLayer:insert(dragImageGroup)
	
	if objectsTotal < 10 then
		local dragPosition = display.newImage(assetPath.."answerPosition.png")
		dragPosition.xScale = 0.8
		dragPosition.yScale = 0.8
		dragPosition.x = answerBlockBg.x
		dragPosition.y = answerBlockBg.y
		dragPosition.isEmpty = true
		dragPosition.id = 1
		dragImageList[#dragImageList + 1] = dragPosition
		dragImageGroup:insert(dragPosition)
	else
		for index=1, 2 do
			local dragPosition = display.newImage(assetPath.."answerPosition.png")
			dragPosition.xScale = 0.8
			dragPosition.yScale = 0.8
			if index == 1 then
				dragPosition.x = (answerBlockBg.width/3 * index) - 10 + backgroundLeft.width
			else
				dragPosition.x = (answerBlockBg.width/3 * index) + 10 + backgroundLeft.width
			end
			dragPosition.y = answerBlockBg.y
			dragPosition.isEmpty = true
			dragPosition.id = index
			dragImageList[#dragImageList + 1] = dragPosition
			dragImageGroup:insert(dragPosition)
		end
	end
	
	dragImageGroup:toBack()
end
--
local function countingTap(event)
	local countObject = event.target
	local objectQuantity = countObject.objectQuantity
	local phase = event.phase
	
	if "began" == phase then
		tutorials.cancel(gameTutorial, 300)
		sound.play("dragtrash")
		display.getCurrentStage():setFocus( countObject, event.id )
		countObject.isFocus = true
		
		countObject.normalImage.isVisible = false
		countObject.touchedImage.isVisible = false
		countObject.onclickImage.isVisible = true
		
		if not countObject.alreadyCounted then
			countedObjects = countedObjects + objectQuantity
		end
		
		countIndicator.isVisible = true
		countIndicator.x = countObject.x
		countIndicator.y = countObject.y - countObject.indicatorOffset
		countIndicator.number.text = countedObjects
		
	elseif countObject.isFocus then
		if "moved" == phase then
			
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus(countObject, nil)
			countObject.isFocus = false
			
			countObject.alreadyCounted = true
			countObject.onclickImage.isVisible = false
			countObject.touchedImage.isVisible = true
			
			countIndicator.isVisible = false
		end
	end
	
	return true
end
--
local function generateObjectsToCount()
	local selectedObject = COUNT_OBJECTS[math.random(1, #COUNT_OBJECTS)]
	local selectedObjectName = selectedObject.name
	
	countIndicator = display.newGroup()
	countIndicator.bg = display.newImage(assetPath.."countIndicator.png")
	countIndicator.number = display.newText("0", countIndicator.x, countIndicator.y - INDICATOR_OFFSET_Y, settings.fontName, 30 )
	countIndicator.xScale = 0.8
	countIndicator.yScale = 0.8
	countIndicator:insert(countIndicator.bg)
	countIndicator:insert(countIndicator.number)
	objectsGroup:insert(countIndicator)
	
	countIndicator.isVisible = false
	objectsList = {}
	for objectIndex = 1, objectsTotal do
		local countingObject = display.newGroup()
		countingObject.normalImage = display.newImage(assetPath..selectedObjectName..".png")
		countingObject.onclickImage = display.newImage(assetPath..selectedObjectName.."Down"..".png")
		countingObject.touchedImage = display.newImage(assetPath..selectedObjectName.."Touched"..".png")
		countingObject.xScale = 0.7
		countingObject.yScale = 0.7
		countingObject.objectQuantity = selectedObject.objectQuantity
		countingObject.alreadyCounted = false
		countingObject.indicatorOffset = selectedObject.indicatorOffset
		countingObject:insert(countingObject.normalImage)
		countingObject:insert(countingObject.onclickImage)
		countingObject:insert(countingObject.touchedImage)
		
		countingObject.onclickImage.isVisible = false
		countingObject.touchedImage.isVisible = false
		
		if objectsTotal <= 5 then
			countingObject.y = backgroundLeft.y
			countingObject.x = (backgroundLeft.width/6*objectIndex)
		else
			if objectIndex<=5 then
				countingObject.y = backgroundLeft.y - countingObject.height/2
				countingObject.x = (backgroundLeft.width/6*objectIndex)
			else
				countingObject.y = backgroundLeft.y + countingObject.height/2
				countingObject.x = backgroundLeft.width/6*(objectIndex-5) 
			end
		end
		
		countingObject:addEventListener("touch", countingTap)
		
		objectsGroup:insert(countingObject)
		objectsList[#objectsList] = countingObject
	end
end

local function createNumber(number)
	local numberButton = display.newGroup()
	numberButton.numberButtonBg = display.newImage(assetPath.."button.png")
	numberButton.xScale = 0.8
	numberButton.yScale = 0.8
	numberButton.onSlot = false
	numberButton.canSpawn = true
	numberButton:insert(numberButton.numberButtonBg)
	
	local textNumberOptions = 
	{
		text = number.numChar.text,	 
		x = numberButton.numberButtonBg.x,
		y = numberButton.numberButtonBg.y,
		font = settings.fontName,   
		fontSize = 60,
		align = "center"
	}

	numberButton.numChar = display.newText( textNumberOptions )
	numberButton.char = textNumberOptions.text
	numberButton.numChar:setFillColor( unpack(NUMBERS_COLOR))
	local currentPos = tonumber(number.numChar.text)+1
	numbersList[currentPos] = numberButton
	numberButton:insert(numberButton.numChar)

	return numberButton
	
end

local function dragNumber(event)
	local phase = event.phase
	local target = event.target
	local xOrigin = target.x
	local yOrigin = target.y
	if not abletoTouch then
		return
	end
	if phase == "began" and abletoTouch then
		sound.play("dragtrash")
		if target.slot then
			target.slot.isEmpty = true
			target.slot = nil
		end
		target:toFront()
		display.getCurrentStage():setFocus( event.target )
	elseif phase == "moved" then
			target.x = event.x
			target.y = event.y		
	elseif phase == "ended" then
		abletoTouch = false
		local isTimeToCheckAnswer = true
		sound.play("pop")
		for indexAnswer = 1, #dragImageList do
			
			local currentSlot = dragImageList[indexAnswer]
			local xCurrentSlot, yCurrentSlot = currentSlot:localToContent( 0, 0 )			
			currentSlot.xCS = xCurrentSlot
			currentSlot.yCS = yCurrentSlot
			if target.x < (currentSlot.xCS + currentSlot.contentWidth * 0.5) and
				target.x > (currentSlot.xCS - currentSlot.contentWidth * 0.5) and
				target.y < (currentSlot.yCS + currentSlot.contentHeight * 0.5) and
				target.y > ( currentSlot.yCS - currentSlot.contentHeight * 0.5) then
					if currentSlot.isEmpty then
						xOption = currentSlot.xCS
						yOption = currentSlot.yCS
						finalAnswer[currentSlot.id] = target.char
						currentSlot.isEmpty = false
						target.onSlot = true
						target.slot = currentSlot
					end
			end
			isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
		end
		
		if target.slot then
			target.canSpawn = false
			director.to(scenePath, target, {time = 200, x = xOption, y = yOption, xScale = 1.63, yScale = 1.63})
			if isTimeToCheckAnswer then
				checkAnswer(target)
			end
--			answerNumberGroup:insert(target)
		else
			director.to(scenePath, target, {time = 500, x = target.xPos, y = target.yPos, onComplete = function() 
				abletoTouch = true 
--				target.onSlot = false
--				target:removeSelf()
			end})
		end
		
		display.getCurrentStage():setFocus( nil )
	end
end
--
local function createNumbers()
	numbersList = {}

	for numberIndex = 1, 10 do
		local numberButton = display.newGroup()
		numberButton.numberButtonBg = display.newImage(assetPath.."button.png")
		numberButton.xScale = 0.8
		numberButton.yScale = 0.8
		numberButton.onSlot = false
		numberButton.canSpawn = true
		numberButton:insert(numberButton.numberButtonBg)

		if numberIndex<=5 then
			numberButton.y = numberBackground.height*0.25 + 10
			numberButton.x = (numberBackground.width/5.5*numberIndex)-(numberBackground.width/5.5)*0.25 + display.viewableContentWidth*0.5
		else
			numberButton.y = numberBackground.height*0.75 - 10
			numberButton.x = numberBackground.width/5.5*(numberIndex-5)-(numberBackground.width/5.5)*0.25 + display.viewableContentWidth*0.5
		end 

		local textNumberOptions = {
			text = numberIndex-1,	 
			x = numberButton.numberButtonBg.x,
			y = numberButton.numberButtonBg.y,
			font = settings.fontName,   
			fontSize = 60,
			align = "center" 
		}

		numberButton.numChar = display.newText( textNumberOptions )
		numberButton.numChar:setFillColor( unpack(NUMBERS_COLOR))
		numberButton.id = numberIndex
		numberButton.char = textNumberOptions.text
		numberButton:insert(numberButton.numChar)
		numberButton:addEventListener("touch", dragNumber)
		numberButton.xPos = numberButton.x
		numberButton.yPos = numberButton.y
		numbersList[#numbersList+1] = numberButton
		answersLayer:insert(numberButton)
	end	
end
	
local function initialize(event)
	event = event or {}
	local params = event.params or {}
	manager = event.parent
	
	isFirstTime = params.isFirstTime
	abletoTouch = true
	finalAnswer = {}
	answerNumberGroup = display.newGroup()
	answersLayer:insert(answerNumberGroup)
	
	objectsGroup = display.newGroup()
	answersLayer:insert(objectsGroup)
	
	instructionsText.text = localization.getString("instructionsCountingMath")
	
	objectsTotal = params.numbers and params.numbers[1] or math.random(1,9)
	
	createDragIndicator()
	generateObjectsToCount()
	
	countedObjects = 0
	
end

local function tutorial()
	if isFirstTime then
		local correctAnswer

		if #dragImageList == 1 then
			for answerIndex = 1, 9 do
				if objectsTotal == numbersList[answerIndex].id then
					correctAnswer = numbersList[answerIndex+1]
				end
			end
		else
			correctAnswer = numbersList[2]
		end

		local tutorialOptions = {
			iterations = 5,
			scale = 0.6,
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 3400, x = correctAnswer.x, y = correctAnswer.y, toX = dragImageList[1].x , toY = dragImageList[1].y},
			}
		}

		gameTutorial = tutorials.start(tutorialOptions)
	end
end

----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = false,
		correctDelay = 500,
		wrongDelay = 500,
		
		name = "Math counting",
		category = "math",
		subcategories = {"counting"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "number", minimum = 2, maximum = 9},
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
	
	backgroundRight = display.newRect( display.contentCenterX*1.5, display.contentCenterY, display.viewableContentWidth/2, display.viewableContentHeight )
	backgroundRight:setFillColor( unpack(BACKGROUND_COLOR_RIGHT))
	backgroundLayer:insert(backgroundRight)
	
	answerBlockBg = display.newImage(assetPath.."answerBlock.png")
	answerBlockBg.width = backgroundRight.width
	answerBlockBg.height = backgroundRight.height*0.45
	answerBlockBg.x = backgroundRight.x
	answerBlockBg.y = backgroundRight.height*0.66
	backgroundLayer:insert(answerBlockBg)
	
	numberBackground = display.newRect( backgroundRight.x, backgroundRight.height/6.4, backgroundRight.width, backgroundRight.height/3.2)
	numberBackground:setFillColor( unpack(NUMBERS_BACKGROUND))
	backgroundLayer:insert(numberBackground)
	
	backgroundLeft = display.newRect( display.contentCenterX*0.5, display.contentCenterY, display.viewableContentWidth/2, display.viewableContentHeight )
	backgroundLeft:setFillColor( unpack(BACKGROUND_COLOR_LEFT))
	backgroundLayer:insert(backgroundLeft)
	
	createNumbers()
	
	local instructionOptions = {
		text = "",	 
		x = display.viewableContentWidth*0.25,
		y = display.viewableContentHeight*0.1,
		width = display.viewableContentWidth*0.4,
		font = settings.fontName,  
		fontSize = 32,
		align = "center"
	}

	instructionsText = display.newText(instructionOptions)
	instructionsText:setFillColor(0, 0, 0)
	textLayer:insert(instructionsText)
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		
		initialize(event)
		tutorial()
		
    elseif phase == "did" then
        
    end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
        
    elseif phase == "did" then
        tutorials.cancel(gameTutorial)
		display.remove(objectsGroup)
		display.remove(answerNumberGroup)
		display.remove(dragImageGroup)
    end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game


