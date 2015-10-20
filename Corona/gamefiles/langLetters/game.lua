----------------------------------------------- lenguaje
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

local game = director.newScene()
----------------------------------------------- Variables
local answersLayer
local backgroundLayer
local manager
local isFirstTime
local gameTutorial
local answerSplit = {}
local words
local indexQuestion = 5
local correctAnswer
local dynamicAnswers
local instructionText
local answerGroup = {}
local answeredQuestion = {}
local playerWon
local isDemo
----------------------------------------------- Constants
local WRONG_ANSWERS = 6
local SIZE_FONT = 35
local DEFAULT_WORDS = {"amigo", "bosque", "libro", "manzana", "perro"}
local DEFAULT_WORDS_EN = {"friend", "forest", "book", "apple", "dog"}
local DEFAULT_WORDS_PT = {"amigo", "floresta", "livro", "fruto","mascote"}
local WORDS_COLOR = {7/255, 147/255, 133/255}
----------------------------------------------- Functions
local function checkingAnswer()
	playerWon = true
	for indexCheckAnswer = 1, #answerSplit do
		if string.upper(answeredQuestion[indexCheckAnswer]) ~= answerSplit[indexCheckAnswer] then
			playerWon = false
		end
	end

	if playerWon then
		if manager then
			manager.correct()
		end
	else
		if manager then
			manager.wrong({id = "text", text = words[indexQuestion], fontSize = 80})
		end
	end
end

local function onOptionTouched(event)
	local phase = event.phase
	local target = event.target
	if phase == "began" then
		tutorials.cancel(gameTutorial,300)
		transition.cancel(target)
		target:toFront( )
		target.x = event.x
		target.y = event.y
		sound.play("dragtrash")
		target.onSlot = false
		if target.slot then
			target.slot.isEmpty = true
			target.slot = nil
		end
		display.getCurrentStage():setFocus( event.target )
		target.isMoving = true
	elseif phase == "moved" then
		if target.isMoving then
			target.x = event.x
			target.y = event.y
		end
	elseif phase == "ended" then
		local isTimeToCheckAnswer = true
		sound.play("pop")
		for indexAnswer = 1, #answerGroup do
			local currentSlot = answerGroup[indexAnswer]
			if target.x < (currentSlot.x + currentSlot.contentWidth * 0.5) and
				target.x > (currentSlot.x - currentSlot.contentWidth * 0.5) and
				target.y < (currentSlot.y + currentSlot.contentHeight * 0.5) and
				target.y > (currentSlot.y - currentSlot.contentHeight * 0.5) then
					if currentSlot.isEmpty then
						answeredQuestion[answerGroup[indexAnswer].id] = target.char.text
						currentSlot.isEmpty = false
						target.onSlot = true
						target.slot = currentSlot
					end
			end
			isTimeToCheckAnswer = isTimeToCheckAnswer and not currentSlot.isEmpty
		end
		
		if target.slot then
			director.to(scenePath, target, {time = 200, x = target.slot.x, y = target.slot.y})
		else
			director.to(scenePath, target, {time = 500, x = target.initX, y = target.initY})
		end
		
		if isTimeToCheckAnswer then
			checkingAnswer()
			target:removeEventListener("touch", onOptionTouched)
		end
		display.getCurrentStage():setFocus( nil )
	end
end


local function removeDynamicAnswers()
	display.remove(dynamicAnswers)
	dynamicAnswers = nil
	for IndexRemoveAnswerSplit=1, #correctAnswer do
		answerSplit[IndexRemoveAnswerSplit] = nil
		answerGroup[IndexRemoveAnswerSplit] = nil

	end
end

local function createDynamicAnswers()
	
	dynamicAnswers = display.newGroup( )
	local questionImage = display.newImage(assetPath .. DEFAULT_WORDS[indexQuestion] .. ".png")
	questionImage.x = display.contentCenterX
	questionImage.y = display.viewableContentHeight*0.35
	questionImage:scale(0.85, 0.85)
	dynamicAnswers:insert(questionImage)

	for indexSubstring = 1, string.len(words[indexQuestion]) do
		answerSplit[indexSubstring] = string.upper(words[indexQuestion]:sub(indexSubstring, indexSubstring))
	end

	correctAnswer = extratable.deepcopy(answerSplit)
	correctAnswer = extratable.shuffle(correctAnswer)

	for indexCreateOptions = 1, #correctAnswer do
		local answerOption = display.newImage( assetPath .. "casilla.png" )
		answerOption.x =  display.screenOriginX+(display.viewableContentWidth/(#correctAnswer +1))*indexCreateOptions
		answerOption.y = display.viewableContentHeight*0.7
		answerOption.isEmpty = true
		answerOption.id = indexCreateOptions
		answerGroup[indexCreateOptions] = answerOption
		dynamicAnswers:insert(answerOption)
		local optionGroup = display.newGroup( )
		local optionImg = display.newImage(assetPath .. "letra.png")
		local optionText = display.newText( correctAnswer[indexCreateOptions], 0, 0, settings.fontName, SIZE_FONT  )
		optionText:setFillColor( unpack(WORDS_COLOR) )
		optionGroup:insert(optionImg)
		optionGroup:insert(optionText)
		local offsetX = display.screenOriginX+(display.viewableContentWidth/(#correctAnswer +1))*indexCreateOptions
		local offsetY = display.viewableContentHeight*0.9
		optionGroup.x = offsetX
		optionGroup.y = offsetY
		optionGroup.initX = offsetX
		optionGroup.initY = offsetY
		optionGroup.onSlot = false
		optionGroup.char = optionText
		optionGroup:addEventListener("touch", onOptionTouched)
		dynamicAnswers:insert(optionGroup)
	end

	answersLayer:insert(dynamicAnswers)
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	isDemo = params.isDemo or false
	manager = event.parent

	if localization.getLanguage() == "es" then
		words = DEFAULT_WORDS
	elseif localization.getLanguage() == "pt" then
		words = DEFAULT_WORDS_PT
	else
		words = DEFAULT_WORDS_EN
	end

	if not isDemo then
		indexQuestion = math.random(1,#words)
	end
	instructionText.text = localization.getString("instructionsLenguaje")
end

local function tutorial()
	if isFirstTime then
		local positionTutorialX
		local positionTutorialY = display.viewableContentHeight*0.875
		for indexTutorial = 1, #answerSplit do
			if correctAnswer[indexTutorial] == answerSplit[1] then
				positionTutorialX = display.screenOriginX+(display.viewableContentWidth/(#correctAnswer +1))*indexTutorial
			end
		end
		local tutorialOptions = {
			iterations = 4,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1400, time = 1600, x = positionTutorialX, y = positionTutorialY, toX = answerGroup[1].x, toY = answerGroup[1].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		correctDelay = 500,
		wrongDelay = 500,	
		
		name = "Minigame lenguaje",
		category = "languages",
		subcategories = {"spelling"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "words", amount = 5},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)

	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)

	local background = display.newImage(assetPath .. "fondo.png")
	local backgroundScale = display.viewableContentWidth/background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background:scale(backgroundScale, backgroundScale)
	backgroundLayer:insert(background)

	local instructionGroup = display.newGroup()
	local instructionImg = display.newImage(assetPath .. "instruccion.png")
	instructionImg.width = display.viewableContentWidth*0.9
	instructionText = display.newText("", 0, 0, settings.fontName, SIZE_FONT)
	instructionText:setFillColor( 1 )
	instructionGroup:insert(instructionImg)
	instructionGroup:insert(instructionText)
	instructionGroup.x = display.viewableContentWidth*0.4
	instructionGroup.y = display.viewableContentHeight*0.1
	backgroundLayer:insert(instructionGroup)
end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createDynamicAnswers()
		tutorial()
	elseif phase == "did" then
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
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
