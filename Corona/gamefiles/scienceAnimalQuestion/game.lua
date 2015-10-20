----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local localization = require( "libs.helpers.localization" )
local extratable = require( "libs.helpers.extratable" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" ) 
local sound = require( "libs.helpers.sound" )

local game = director.newScene() 
----------------------------------------------- Variables
local answersLayer, wrongAnswersGroup, correctAnswerGroup
local backgroundLayer, backgroundImg
local textLayer, instructions, instructionsBg
local manager
local tapsEnabled
local isFirstTime
local gameTutorial
local category
local correctId 
local totalAnswers 
local correctAnswer, correctAnswerX, correctAnswerY
local correctAnswerImg
local questionsShuffle
local indexQuestion
local result
local isReadyForNextQuestion
local timerBubble
local correctGroup
----------------------------------------------- Constants
local CENTER_X  = display.contentCenterX
local CENTER_Y  = display.contentCenterY
local MAX_X     = display.contentWidth
local MAX_Y     = display.contentHeight
local BACKGROUND_SCALE = 1.3
local INSTRUCTIONSBG_SCALE_X = MAX_X * 0.8
local INSTRUCTIONSBG_SCALE_Y = 1.3
local ANSWER_SCALE = 0.50
local ANSWER_BG_SCALE = 0.60
local CORRECT_GROUP_SCALE = 0.2
local OFFSET_X_CORRECT_GROUP = MAX_X * 0.1
local POS_X_CORRECT_GROUP = MAX_X * 0.2
local OFFSET_X_ANSWERS = {
	[1] = MAX_X / 5,
	[2] = MAX_X / 2,
	[3] = MAX_X * 4 / 5,
	}
local POS_Y_ANSWER = CENTER_Y * 1.1
local OFFSET_Y_ANSWER = MAX_Y * 0.1
local TIME_LIMIT = 6000
local SIZE_FONT = MAX_Y * 0.06
local QUESTIONS = {
	[1] = {
		question = localization.getString("animalQuestions1"),
		category = "flor_",
		correctId = 3,
		totalAnswers = {
			[1] = "luna",
			[2] = "planeta",
			[3] = "sol",
		},
	},
	[2] = {
		question = localization.getString("animalQuestions2"),
		category = "perro_",
		correctId = 3,
		totalAnswers = {
			[1] = "cola",
 			[2] = "dormido",
			[3] = "enojado",
		},
	},
	[3] = {
		question = localization.getString("animalQuestions3"),
		category = "pez_",
		correctId = 3,
		totalAnswers = {
			[1] = "dientes",
 			[2] = "karateca",
			[3] = "globo",
		},		
	},
}
----------------------------------------------- Functions
local function nextQuestion (event)
	isReadyForNextQuestion = true
	indexQuestion = indexQuestion + 1
end

local function onAnswerTapped(event)
	local answer = event.target 
	if tapsEnabled then
		transition.cancel(timerBubble)
		--transition.cancel("shakeBubble")
		transition.cancel("blinkBubbleCo")
		timerBubble = nil
		director.to(scenePath,wrongAnswersGroup,{time = 10, alpha = 0})
		director.to(scenePath,wrongAnswersGroup,{time = 1500, onComplete = nextQuestion})
		tapsEnabled = false 
		if answer.isCorrect then 
			sound.play("pop")
			result = result + 1
			local correctImg = display.newImage(correctAnswerImg,indexQuestion * OFFSET_X_CORRECT_GROUP - POS_X_CORRECT_GROUP,0)
			correctImg.xScale = CORRECT_GROUP_SCALE
			correctImg.yScale = CORRECT_GROUP_SCALE
			correctGroup:insert(correctImg)
			correctGroup.isVisible = false
			if manager and result == 3 then 
				isReadyForNextQuestion = false
				manager.correct()
			elseif manager and indexQuestion == 3 then
				isReadyForNextQuestion = false
				manager.wrong({id = "group", group = correctGroup}) 
			end
		else
			sound.play("pop")
			local correctImg = display.newImage(correctAnswerImg,indexQuestion * OFFSET_X_CORRECT_GROUP - POS_X_CORRECT_GROUP,0)
			correctImg.xScale = CORRECT_GROUP_SCALE
			correctImg.yScale = CORRECT_GROUP_SCALE
			correctGroup:insert(correctImg)
			correctGroup.isVisible = false
			if indexQuestion == 3 then
				if manager then 
					isReadyForNextQuestion = false
					manager.wrong({id = "group", group = correctGroup}) 
				end
			end
		end
	end
end

local function timeOut (event)
	sound.play("pop")
	tapsEnabled = false
	local correctImg = display.newImage(correctAnswerImg,indexQuestion * OFFSET_X_CORRECT_GROUP - POS_X_CORRECT_GROUP,0)
	correctImg.xScale = CORRECT_GROUP_SCALE
	correctImg.yScale = CORRECT_GROUP_SCALE
	correctGroup:insert(correctImg)
	correctGroup.isVisible = false
	if indexQuestion == 3 then
		if manager then 
			isReadyForNextQuestion = false
			manager.wrong({id = "group", group = correctGroup}) 
		end
	end
	--transition.cancel("shakeBubble")
	--transition.cancel("blinkBubbleWr")
	--transition.cancel("blinkBubbleCo")
	--correctAnswerGroup.alpha = 1
	--director.to(scenePath,correctAnswerGroup,{time = 10, alpha = 1})
	director.to(scenePath,wrongAnswersGroup,{time = 10, alpha = 0})
	director.to(scenePath,wrongAnswersGroup,{time = 1500, onComplete = nextQuestion})
	event.target = nil
end

local function removeDynamicAnswers()
	display.remove(wrongAnswersGroup) 
	wrongAnswersGroup = nil
	display.remove(correctAnswerGroup) 
	correctAnswerGroup = nil
end

local function createDynamicAnswers()
	
	removeDynamicAnswers()

	totalAnswers = extratable.shuffle(totalAnswers)
	wrongAnswersGroup = display.newGroup()
	correctAnswerGroup = display.newGroup()
	for index = 1, #totalAnswers do
		local answer = display.newImage(assetPath..category..totalAnswers[index]..".png",OFFSET_X_ANSWERS[index], (POS_Y_ANSWER) + (OFFSET_Y_ANSWER * ((index + 1) % 2)))
		correctAnswerImg = assetPath..category..correctAnswer..".png"
		answer.xScale = ANSWER_SCALE
		answer.yScale = ANSWER_SCALE
		local answerBg = display.newImage(assetPath.."burbuja.png",OFFSET_X_ANSWERS[index], (POS_Y_ANSWER) + (OFFSET_Y_ANSWER * ((index + 1) % 2)))
		answerBg.xScale = ANSWER_BG_SCALE
		answerBg.yScale = ANSWER_BG_SCALE
		--answerBg.dir = math.pow(-1,index)
		
		local xDist = 20
		director.to(scenePath, answerBg, { rotation = -360, time = TIME_LIMIT + 1000, transition=easing.inOutElastic })
		director.to(scenePath, answerBg, { xScale = ANSWER_BG_SCALE * 1.4, yScale = ANSWER_BG_SCALE * 1.4, time = TIME_LIMIT, transition=easing.outInBounce})
		
		--director.to(scenePath, answerBg, { delay = TIME_LIMIT - TIME_LIMIT * 0.18, time = 23, iterations = 1000 ,x = answerBg.x + xDist * answerBg.dir, dir = -answerBg.dir })
		
		local bubble = display.newGroup()
		bubble:insert(answer)
		bubble:insert(answerBg)
		bubble.dir = math.pow(-1,index)
		--director.to(scenePath, bubble, { tag = "shakeBubble", delay = TIME_LIMIT - TIME_LIMIT * 0.15, time = 30, iterations = 1000 ,x = bubble.x + xDist * bubble.dir, dir = -bubble.dir })
		transition.to( bubble, { tag = "blinkBubbleCo", delay = TIME_LIMIT - TIME_LIMIT * 0.19, time=250, alpha = 0.5 ,iterations = 6, } )
		if(totalAnswers[index] ~= correctAnswer) then
			bubble.isCorrect = false
			wrongAnswersGroup:insert(bubble)
		else
			bubble.isCorrect = true
			correctAnswerX = answerBg.x
			correctAnswerY = answerBg.y
			correctAnswerGroup:insert(bubble)
		end
		--transition.blink( correctAnswerGroup, { tag = "blinkBubbleWr", delay = TIME_LIMIT - TIME_LIMIT * 0.2, time=300 } )
		--transition.blink( wrongAnswersGroup, { tag = "blinkBubbleCo", delay = TIME_LIMIT - TIME_LIMIT * 0.2, time=300 } )

		bubble:addEventListener("tap", onAnswerTapped)
	end
	timerBubble = display.newGroup()
	director.to(scenePath, timerBubble, { time = TIME_LIMIT, onComplete = timeOut })
	answersLayer:insert(correctAnswerGroup)
	answersLayer:insert(wrongAnswersGroup)

end
local function showQuestion()
	if isReadyForNextQuestion and indexQuestion < 4 then
		isReadyForNextQuestion = false
		tapsEnabled = true
		category = questionsShuffle[indexQuestion].category
		correctId = questionsShuffle[indexQuestion].correctId
		totalAnswers = questionsShuffle[indexQuestion].totalAnswers
		correctAnswer = questionsShuffle[indexQuestion].totalAnswers[correctId]
		instructionsBg.isVisible = true
		instructions.text = questionsShuffle[indexQuestion].question
		createDynamicAnswers()
	end
end
local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime 
	manager = event.parent
	
	result = 0
	questionsShuffle = extratable.shuffle(QUESTIONS)
	isReadyForNextQuestion = true
	indexQuestion = 1
	correctGroup = display.newGroup() 
	showQuestion()
end
	
local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial()
	if isFirstTime then 
	print("x "..correctAnswerX.."y "..correctAnswerY)
		local tutorialOptions = {
			iterations = 1,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 1500, x = correctAnswerX, y = correctAnswerY},
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
		
		name = "Animal Questions", 
		category = "science", 
		subcategories = {"addition", "subtraction"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = {
		},
	}
end  

function game:create(event) 
	local question = {
		text     = "",
		x        = CENTER_X,
		y        = MAX_Y * 0.16,
		width    = MAX_X * 0.7,
		height   = MAX_Y * 0.16,
		align    = "center",
		font	 = settings.fontName,
		fontSize = SIZE_FONT
	}
	local sceneView = self.view
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	backgroundImg = display.newImage(assetPath.."fondo.png",CENTER_X ,CENTER_Y)
	backgroundImg.xScale = BACKGROUND_SCALE
	backgroundImg.yScale = BACKGROUND_SCALE
	backgroundLayer:insert(backgroundImg)
	
	instructionsBg = display.newImage(assetPath.."pregunta.png",CENTER_X ,MAX_Y * 0.15)
	instructionsBg.xScale = INSTRUCTIONSBG_SCALE_X / instructionsBg.width
	instructionsBg.yScale = INSTRUCTIONSBG_SCALE_Y
	instructionsBg.isVisible = false
	instructions = display.newText(question)
	textLayer:insert(instructionsBg)
	textLayer:insert(instructions)
	
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
		enableButtons()
		local tmr = director.performWithDelay(scenePath,100, showQuestion, 0)

	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		
		disableButtons()
		removeDynamicAnswers()
		tutorials.cancel(gameTutorial)
		correctGroup = nil
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
