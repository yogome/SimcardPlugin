------------------------------------ GraphFracciones
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local screen = require( "libs.helpers.screen" )
local settings = require( "settings" )
local sound = require( "libs.helpers.sound" )
local extratable = require("libs.helpers.extratable")
local game = director.newScene()
------------------------------------ Variables
local backgroundLayer
local answersLayer
local textLayer
local fractionsImg
local correctAnswerTable
local correctAnswer
local dynamicAnswersGroup
local answerQuestion
local gameTutorial
local tapsEnabled
local isFirstTime
local manager
local instructions
------------------------------------ Constantes
local SIZE_FONT = 40
local INSTRUCTIONS_COLOR = {0/255, 98/255, 65/255}
local NUMERO_PAYS = 4
local NUMBERS_COLOR = {255/255, 253/255, 199/255}
------------------------------------ Functions
local function tutorial()
	if isFirstTime then
		local correctAnswerX
		local correctAnswerY = display.viewableContentHeight*0.8
		for indexPosition = 1, NUMERO_PAYS do
			if fractionsImg[indexPosition].id == correctAnswer.id then
				correctAnswerX = indexPosition
			end
		end
		local tutorialOptions = {
			iterations = 4,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 800, time = 2500, x = display.screenOriginX+(display.viewableContentWidth/(NUMERO_PAYS +1))*correctAnswerX, y = correctAnswerY, toX = answerQuestion.x, toY = answerQuestion.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function removeDynamicAnswers()
	display.remove(dynamicAnswersGroup)
	dynamicAnswersGroup = nil
end

local function onFractionTouched(event)
	if tapsEnabled then
		local phase = event.phase
		local target = event.target
		if phase == "began" then
			target:toFront( )
			target.x = event.x
			target.y = event.y
			tutorials.cancel(gameTutorial,300)

			sound.play("dragtrash")
			target.onSlot = false
			if target.slot then
				target.slot.isEmpty = true
				target.slot = nil
			end
			display.getCurrentStage():setFocus( event.target )
			transition.cancel(target)
			target:toFront()
		elseif phase == "moved" then
			target.x = event.x
			target.y = event.y
				
		elseif phase == "ended" then
			local isTimeToCheckAnswer = true
			sound.play("pop")

				local currentSlot = answerQuestion
				if target.x < (currentSlot.x + currentSlot.contentWidth * 0.5) and
					target.x > (currentSlot.x - currentSlot.contentWidth * 0.5) and
					target.y < (currentSlot.y + currentSlot.contentHeight * 0.5) and
					target.y > (currentSlot.y - currentSlot.contentHeight * 0.5) then
						if currentSlot.isEmpty then
							currentSlot.isEmpty = false
							target.onSlot = true
							target.slot = currentSlot
						end
				end
				isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
			
			if target.slot then
				director.to(scenePath, target, {time = 200, x = target.slot.x, y = target.slot.y})
			else
				director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY})
			end
			
			if isTimeToCheckAnswer then
				tapsEnabled = false
				if manager then
					if answerQuestion.id == target.id then
						manager.correct()
					else
						manager.wrong({id = "image", image = assetPath .. correctAnswer.img .. ".png" , xScale=0.75, yScale=0.75})
					end
				end
				--checkingAnswer()
				--target:removeEventListener("touch", onOptionTouched)
			end
			display.getCurrentStage():setFocus( nil )
		end
	end
	return true
end

local function createDynamicAnswers()
	dynamicAnswersGroup = display.newGroup( )
	answersLayer:insert(dynamicAnswersGroup)
	for indexPays = 1, NUMERO_PAYS do
		local fractionImage = display.newImage( assetPath .. fractionsImg[indexPays].img ..".png" )
		fractionImage:scale( 0.75, 0.75 )
		fractionImage.x = display.screenOriginX+(display.viewableContentWidth/(NUMERO_PAYS +1))*indexPays
		fractionImage.y = display.viewableContentHeight*0.8
		fractionImage.initX = display.screenOriginX+(display.viewableContentWidth/(NUMERO_PAYS +1))*indexPays
		fractionImage.initY = display.viewableContentHeight*0.8
		fractionImage.onSlot = false
		fractionImage.id = fractionsImg[indexPays].id
		fractionImage:addEventListener("touch", onFractionTouched)
		dynamicAnswersGroup:insert(fractionImage)
	end

	local questionGroup = display.newGroup( )
	local questionImg = display.newImage( assetPath .. "recuadro.png" )
	local division = display.newImage( assetPath .. "fraccion.png" )
	local dividendo = display.newText( correctAnswer.dividendo, 0, -(questionImg.height*0.2), settings.fontName, SIZE_FONT*2 )
	local divisor = display.newText(correctAnswer.divisor, 0, questionImg.height*0.2, settings.fontName, SIZE_FONT * 2 )
	dividendo:setFillColor( unpack( NUMBERS_COLOR ) )
	divisor:setFillColor( unpack( NUMBERS_COLOR ) )
	questionGroup:insert(questionImg)
	questionGroup:insert( division )
	questionGroup:insert(dividendo)
	questionGroup:insert(divisor)
	questionGroup.x = display.viewableContentWidth * 0.3
	questionGroup.y = display.viewableContentHeight * 0.25
	dynamicAnswersGroup:insert(questionGroup)

	answerQuestion = display.newImage( assetPath .. "respuesta.png" )
	answerQuestion:scale(0.75, 0.75)
	dynamicAnswersGroup:insert(answerQuestion)
	answerQuestion.x = display.viewableContentWidth * 0.7
	answerQuestion.y = display.viewableContentHeight * 0.25
	answerQuestion.isEmpty = true
	answerQuestion.id = correctAnswer.id

end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
	tapsEnabled = true
	fractionsImg = {
		{img ="1", dividendo="1", divisor="1", id="1"},
		{img ="1_2", dividendo="1", divisor="2", id="2"},
		{img ="1_3", dividendo="1", divisor = "3", id="3"},
		{img ="1_4", dividendo="1", divisor="4", id="4"}
	}
	fractionsImg = extratable.shuffle(fractionsImg)
	correctAnswerTable = extratable.shuffle(fractionsImg)
	correctAnswer = correctAnswerTable[1]

	instructions.text = localization.getString("instructionsGraphFracciones")
end


------------------------------------ Module functions
function game.getInfo()
	return {
		available = true,
		correctDelay = 300,
		wrongDelay = 300,		
		
		name = "Math Fractions",
		category = "math",
		subcategories = {"fractions"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "fractions", amount = 4},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	textLayer = display.newGroup()
	sceneView:insert(textLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	
	local background = display.newImage( assetPath .. "fondo.png" )
	background.anchorY = 0.05
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.viewableContentHeight*0.05
	background:scale(backgroundScale, backgroundScale)
	backgroundLayer:insert(background)

	local pizzaBar = display.newImage( assetPath .. "barradepizzas.png")
	pizzaBar.width = display.viewableContentWidth * 0.85
	pizzaBar.x = display.contentCenterX
	pizzaBar.y = display.viewableContentHeight * 0.8
	backgroundLayer:insert(pizzaBar)

	local equals = display.newImage( assetPath .. "igual.png" )
	equals.x = display.contentCenterX
	equals.y = display.viewableContentHeight * 0.25
	backgroundLayer:insert(equals)

	--[[correctBox = display.newRect(display.contentCenterX + -OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	correctBox.isCorrect = true
	correctBox:setFillColor(unpack(COLOR_CORRECT))
	correctBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(correctBox)

	wrongBox = display.newRect(display.contentCenterX + OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	wrongBox.isCorrect = false
	wrongBox:setFillColor(unpack(COLOR_WRONG))
	wrongBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(wrongBox)]]--



	instructions = display.newText("", display.contentCenterX, display.contentCenterY, settings.fontName, SIZE_FONT)
	instructions:setFillColor( unpack(INSTRUCTIONS_COLOR) )
	textLayer:insert(instructions)
	--[[local sceneView = self.view


	background = display.newRect(display.contentCenterX,display.contentCenterY, display.viewableContentWidth + 2 ,display.viewableContentHeight + 2)
	background:setFillColor(unpack(BACKGROUND_COLOR))
	sceneView:insert(background)

	respuesta = display.newImage(assetPath .. "minigames-elements2-08.png")
	respuesta.x = display.screenOriginX+(display.viewableContentWidth*0.6)
	respuesta.y = display.screenOriginY+(display.viewableContentHeight*(1/8)*2.5)
	sceneView:insert(respuesta)
	
	local fraccion = display.newText("-", (display.viewableContentWidth*0.3), display.screenOriginY+(display.viewableContentHeight*(1/8)*2), FONT_FACE, FONT_SIZE)
	fraccion:setFillColor(unpack(FONT_COLOR))
	sceneView:insert(fraccion)
	
	local igual = display.newText("=", (display.viewableContentWidth*0.4), display.screenOriginY+(display.viewableContentHeight*(1/8)*2), FONT_FACE, FONT_SIZE)
	igual:setFillColor(unpack(FONT_COLOR))
	sceneView:insert(igual)
	
	local instructionOptions = {
		text = "",	 
		x = (display.viewableContentWidth*0.5),
		y = (display.viewableContentHeight * 0.5),
		width = display.viewableContentWidth*0.8,
		font = settings.fontName,  
		fontSize = 32,
		align = "center"
	}
		
	instructions = display.newText(instructionOptions)
	instructions:setFillColor( unpack(FONT_COLOR))
	sceneView:insert( instructions )

	answersLayer = display.newGroup( )
	sceneView:insert(answersLayer)]]--

end

function game:show(event)
	local phase = event.phase

	if( phase == "will") then
		-- TODO this is wrong, manager should be received inside initialize
		initialize(event)
		createDynamicAnswers()
		tutorial()
		--showTutorial()
	elseif(phase == "did") then
	end
end

function game:hide(event)
	local sceneGroup = self.view
	local phase = event.phase
	if(phase == "will") then
	elseif (phase == "did") then
		removeDynamicAnswers()
		tutorials.cancel(gameTutorial)
	end
end

function game:destroy()

end


------------------------------------ Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
