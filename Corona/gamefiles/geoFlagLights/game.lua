----------------------------------------------- MathShip
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local director = require( "libs.helpers.director" )
local extratable = require( "libs.helpers.extratable" )
local sound = require("libs.helpers.sound")
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local manager
local lampGroup
local lampOn
local lampOff
local light
local flagsGroup
local flagsList, flags
local answerGroup
local answerList
local currentAnswer
local selectedAnswerList 
local isTimeToEvaluate
local timerTurnOff
local answerOrder
local instructions, gameTutorial, isFirstTime
local canvasGroup
----------------------------------------------- Constants
local COLOR_BACKGROUND = {12/255, 26/255, 86/255}
----------------------------------------------- Functions
local function createLamp()
	lampGroup = display.newGroup( )

	lampOn = display.newImage( assetPath.."lamp1.png" )
	lampOn.x = display.contentCenterX
	lampOn.xScale = 1.25
	lampOn.y = 129
	lampOn.isVisible = true
	lampGroup:insert( lampOn )

	lampOff = display.newImage( assetPath.."lamp2.png" )
	lampOff.x = display.contentCenterX
	lampOff.xScale = 1.25
	lampOff.y = 129
	lampOff.isVisible = false
	lampGroup:insert( lampOff )

	light = display.newImage( assetPath.."light.png" )
	light.x = display.contentCenterX
	light.width = display.viewableContentWidth + 10
	light.y = display.contentCenterY + 80
	light.height = display.viewableContentHeight - 150
	lampGroup:insert(light)

	light:toBack( )

	canvasGroup:insert(lampGroup)
end

local function switchLights(electricity)
	if electricity == 0 then
		director.to(scenePath, lampOn, {delay = 10, time = 100, onComplete = function() 
			lampOn.isVisible = false
			lampOff.isVisible = true 
			light.isVisible = false 
			flagsGroup.isVisible = false
		end})
	else 
		director.to(scenePath, lampOn, {delay = 10, time = 100, onComplete = function() 
			lampOn.isVisible = true
			lampOff.isVisible = false 
			light.isVisible = true 
			flagsGroup.isVisible = true
		end})
	end
end

local function lightsOff()
	director.to(scenePath, lampOn, {delay= 7500, time = 100, onComplete = function()
		sound.play("minigamesBreakGlass")
		director.performWithDelay(scenePath, 100, switchLights(0) )
		director.to(scenePath, lampOn, {delay = 100, time = 100, onComplete = function() 
			director.performWithDelay(scenePath, 500, switchLights(1) )
			director.to(scenePath, lampOn, {delay = 100, time = 100, onComplete = function() 
				director.performWithDelay(scenePath, 1000, switchLights(0) )
			end})
		end})
	end})
end

local function addMark(status, position)
	local mark
	if status == 1 then
		mark = display.newImage(assetPath.."correct.png")
	else
		mark = display.newImage(assetPath.."incorrect.png")
	end

	mark.x = position.x + 90
	mark.y = position.y + 20
	mark.xScale = 0.1
	mark.yScale = 0.1
	answerGroup:insert(mark)
	mark.alpha = 0
		
	director.to(scenePath, mark, {time = 500, alpha = 1, xScale = 0.5, yScale = 0.5, transition = easing.inOutBounce})
end

local function checkAnswers() 
	switchLights(1)
	local correctAnswers = true
	for checkIndex = 1, 3 do
		if selectedAnswerList[checkIndex].flagName.text == flagsList[checkIndex].name then 
			addMark(1, selectedAnswerList[checkIndex])
			correctAnswers = (correctAnswers and true)
		else 
			addMark(0, selectedAnswerList[checkIndex])
			correctAnswers = (correctAnswers and false)
		end
	end
		
	if correctAnswers then
		manager.correct()
	else
		local correctFlags = ""
		for index=1, #flagsList do
			correctFlags = correctFlags..flagsList[index].name..", "
		end
		manager.wrong({id = "text", text = correctFlags, fontSize = 48})
	end
end

local function moveAnswer( answer )
	if currentAnswer >= 3 then
		isTimeToEvaluate =  true
	end

	director.to(scenePath, answer, {time = 300, x = flagsList[currentAnswer].x, y = flagsList[currentAnswer].y + 140, onComplete = function()
		if isTimeToEvaluate then
			checkAnswers()
		end
	end})
	
	return true
end

local function tap( event )
	sound.play("pop")
	local answer = event.target
	event.target:removeEventListener("tap", tap)
	tutorials.cancel(gameTutorial,300)
	if not isTimeToEvaluate then
		currentAnswer = currentAnswer + 1
		selectedAnswerList[#selectedAnswerList+1] = answer
		moveAnswer(answer)
	end
	return true
end

local function setFlags()
	flagsGroup = display.newGroup()
	canvasGroup:insert(flagsGroup)
	
	local language = localization.getLanguage()

	flagsList = {}
	for flagIndex = 1, (#flags - 1) do
		local flagData = flags[flagIndex]
		
		local flag = display.newImage(flagData.image)
		flag.name = flagData[language]
		
		flag.x = (display.contentCenterX - 265) + (265*(flagIndex-1))
		flag.y = display.contentCenterY + 70
		flagsList[#flagsList + 1] = flag
		flagsGroup:insert(flag)
	end
end

local function setAnswers()
	display.remove(answerGroup)
	answerGroup = display.newGroup()
	canvasGroup:insert(answerGroup)
	
	if flagsList and #flagsList > 0 then
	
		local answers = {
			[1] = {flagsList[1].name,1},
			[2] = {flagsList[2].name,2},
			[3] = {flagsList[3].name,3},
			[4] = {flags[4][localization.getLanguage()],4},
		}
		answers = extratable.shuffle(answers)

		answerOrder = {}
		for answerIndex = 1, #answers do
			local answer = display.newGroup( )
			local answerBg = display.newImage(assetPath.."button.png")
			answer.x = (display.viewableContentWidth/5)*answerIndex
			answer.y = display.viewableContentHeight - 70
			answerBg.xScale = 0.8
			answerBg.yScale = 0.5
			answer:insert(answerBg)

			local answerOptions = {
				text = answers[answerIndex][1],
				x = answerBg.x,
				y = answerBg.y,
				width = answerBg.width/1.5,
				font = settings.fontName,
				fontSize = 20,
				align = "center"
			}

			answer.flagName = display.newText( answerOptions)
			answer:insert(answer.flagName)
			answerList[#answerList+1] = answer 

			answer:addEventListener( "tap", tap )
			answerGroup:insert(answer)

			answerOrder[answers[answerIndex][2]] = answer
		end
	end
end

local function showTutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1000, time = 1500, x = answerOrder[1].x, y = answerOrder[1].y},
				[2] = {id = "tap", delay = 1000, time = 1500, x = answerOrder[2].x, y = answerOrder[2].y},
				[3] = {id = "tap", delay = 1000, time = 1500, x = answerOrder[3].x, y = answerOrder[3].y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}
	
	instructions.text = localization.getString("instructionsGeoflags2")
	
	manager = event.parent
	isFirstTime = params.isFirstTime
	
	flags = params.flags or {}
	
	answerList = {}
	currentAnswer = 0
	selectedAnswerList = {}
	isTimeToEvaluate = false
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		available = true,
		correctDelay = 1000,
		wrongDelay = 1000,
		
		name = "Geo flags 2",
		category = "geography",
		subcategories = {"countries"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "flags", amount = 4},
		},
	}
end 

function game:create(event)
	local sceneView = self.view

	local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight )
	bg:setFillColor( unpack( COLOR_BACKGROUND ) )
	sceneView:insert(bg)

	local instructionsOptions = {
		text = "",
		x = 200,
		y = 100,
		width = 300,
		font = settings.fontName,
		fontSize = 26,
		align = "center"
	}

	instructions = display.newText(instructionsOptions)
	sceneView:insert(instructions)
	
	canvasGroup = display.newGroup()
	sceneView:insert(canvasGroup)

	createLamp()
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		setFlags()
		setAnswers()
		showTutorial()
		switchLights(1)
		timerTurnOff = director.performWithDelay(scenePath, 3500, lightsOff )
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local phase = event.phase

	if phase == "will" then
		
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		switchLights(1)
		display.remove(flagsGroup)
		display.remove(answerGroup)
	end
end
----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
