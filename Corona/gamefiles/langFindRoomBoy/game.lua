----------------------------------------------- animales_ruidosos
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )

local objectData = require("gamefiles.langFindRoomBoy.objectData")

local game = director.newScene()
----------------------------------------------- Variables
local manager 

local backgroundLayer
local dynamicLayer

local isFirstTime
local gameTutorial
local currentAnswer
local correctOption
local optionChosen
local optionsChosen
local correctCount

local wordText
local answers
----------------------------------------------- Constants
local CENTERX = display.contentCenterX
local CENTERY = display.contentCenterY
local SCREEN_LEFT = display.screenOriginX
local SCREEN_WIDTH = display.viewableContentWidth - SCREEN_LEFT * 2
local SCREEN_TOP = display.screenOriginY
local SCREEN_HEIGHT = display.viewableContentHeight - SCREEN_TOP * 2

----------------------------------------------- Functions
local function showTutorial()
	if isFirstTime then		
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 3000, x = correctOption.x, y = correctOption.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end 

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	isFirstTime = params.isFirstTime
	manager = event.parent
	
	answers = {}
	
	--wordText.text =""
	
	currentAnswer = 1
	optionChosen = false
	optionsChosen = 0
	correctCount = 0
end

local function nextOption()
	currentAnswer = currentAnswer + 1
	wordText.text = answers[currentAnswer].text
	optionChosen = false
end

local function correctAnswer(target)
	sound.play("minigamesFallSplash")
	if optionsChosen < 5 then
		nextOption()
	end
end

local function wrongAnswer(target)
	sound.play("minigamesFallSplash")
	if optionsChosen < 5 then
		nextOption()
	end
end

local function onTap(event)
	local target = event.target
	tutorials.cancel(gameTutorial,300)
	
	if not optionChosen then
		optionChosen = true
		optionsChosen = optionsChosen + 1
		if target.isCorrect and target.text == answers[currentAnswer].text then
			correctCount = correctCount + 1
			correctAnswer(target)
		else
			wrongAnswer(target)
		end
		if  optionsChosen == 5 then
			if correctCount >= 3 then
				manager.correct()
			else
				manager.wrong()
			end
		end
		return true
	end
end

local function createBackgroundElements()
	local backgroundElements = display.newGroup()
	
	local background = display.newImage(assetPath .. "fondo.png")
	background.x = CENTERX
	background.y = CENTERY
    background.width = SCREEN_WIDTH
    background.height = SCREEN_HEIGHT
	backgroundElements:insert(background)

	local instructionsContainer = display.newImage(assetPath .. "instrucciones.png")
	instructionsContainer.x = CENTERX
	instructionsContainer.y = SCREEN_TOP + instructionsContainer.height * 0.8
	backgroundElements:insert(instructionsContainer)
	
	local instructions = director.newLocalizedText(scenePath, "instructionsLangFindRoom",{
		text = "",
		x = instructionsContainer.x,
		y = instructionsContainer.y,
		fontSize = 24,
		font = settings.fontName,
		width = 400,
		height = 0,
		align = "center"
	 })
	instructions:setFillColor(147/255, 58/255, 242/255)
	backgroundElements:insert(instructions)

	return backgroundElements
end

local function createDynamicElements()
	local dynamicElements = display.newGroup()
	
	local wordContainer = display.newImage(assetPath .. "palabra.png")
	wordContainer.x = SCREEN_WIDTH - wordContainer.width * 0.6
	wordContainer.y = SCREEN_HEIGHT - wordContainer.height * 0.65
	dynamicElements:insert(wordContainer)

	for index = 1, #objectData.fixedElements do
		local currentObject = objectData.fixedElements[index]
		
		local object = display.newGroup()
		local imageObject = display.newImage(currentObject.asset)
		object:insert(imageObject)
		
		object.isCorrect = currentObject.isCorrect
		if object.isCorrect then
			answers[#answers + 1] = object
		end
		object.text = currentObject.text
		object.x = currentObject.x
		object.y = currentObject.y
		object:addEventListener("tap", onTap)

		dynamicElements:insert(object)
	end
	
	local objectPositions = objectData.positions
	objectPositions = extratable.shuffle(objectPositions)
	for index = 1, #objectData.movingElements do
		local currentObject = objectData.movingElements[index]
		local currentPosition = objectPositions[index]
		
		local object = display.newGroup()
		local imageObject = display.newImage(currentObject.asset)
		object:insert(imageObject)
		
		object.isCorrect = currentObject.isCorrect
		if object.isCorrect then
			answers[#answers + 1] = object
		end
		object.text = currentObject.text
		object.x = currentPosition.x
		object.y = currentPosition.y
		object:addEventListener("tap", onTap)
		
		dynamicElements:insert(object)
	end
	
	answers = extratable.shuffle(answers)
	correctOption = answers[currentAnswer]
	
	local textOptions = {
		text = answers[currentAnswer].text,
		x = wordContainer.x,
		y = wordContainer.y,
		width = 500,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	}
	wordText = display.newText(textOptions)
	wordText:setFillColor(206/255, 6/255, 102/255)
	dynamicElements:insert(wordText)
	
	return dynamicElements
end
----------------------------------------------- 
function game.getInfo()
	return {
		available = false,
		wrongDelay = 0,
		correctDelay = 0,
		
		name = "langFindRoomBoy",
		category = "languages",
		subcategories = {""},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		musicVolume = 0.25,
		gamemode = "findAnswer",
		requires = {
			{id = "wrongAnswer", amount = 3},
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
	elseif phase == "did" then
		
    end
end

function game:hide(event)
    local phase = event.phase
    if phase == "will" then
		
	elseif phase == "did" then
		display.remove(dynamicLayer)
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