----------------------------------------------- Test minigame - comentless file in same folder - template.lua
local scenePath = ... -- we receive the require scenePath in the 3 dots "gamefiles.testminigame.game"
local folder = scenePath:match("(.-)[^%.]+$") -- We strip the lua filename "gamefiles.testminigame."
local assetPath = string.gsub(folder,"[%.]","/") -- We convert dots to slashes "gamefiles/testminigame/" so we can load files in our directory
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" ) -- This is the only module that is not a library that can be included in minigames.

local game = director.newScene() -- PLEASE FOLLOW the dev guide!
----------------------------------------------- Variables - Variables are declared BUT not initialized
local answersLayer, wrongAnswersGroup
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabled
local isFirstTime
local correctBox, wrongBox
local gameTutorial
----------------------------------------------- Constants
local OFFSET_X_ANSWERS = 200
local OFFSET_TEXT = {x = 0, y = -200}
local SIZE_BOXES = 100
local COLOR_WRONG = colors.red
local COLOR_CORRECT = colors.green
local WRONG_ANSWERS = 6
local SIZE_FONT = 40

local TIME_BOX_ANIMATION = 500

local PADDING_WRONG_ANSWERS = 140
local OFFSET_Y_WRONG_ANSWERS = 200
----------------------------------------------- Functions - Local functions ONLY.
local function onAnswerTapped(event)
	local answer = event.target -- Target will always be the object that was tapped
	if tapsEnabled then
		tapsEnabled = false -- Simple lock, this prevents the answer from being tapped too many times
		if answer.isCorrect then -- This sentence even makes sense when read out loud - readable code
			if manager then -- Manager could not be present, this makes our code modular. we do not even need the manager for this scene to work
				local options = {delay = nil} -- We can specify a custom delay that overrides the one at getInfo. This can be used for custom timed animations
				manager.correct(options) -- options is OPTIONAL
			end
		else
			if manager then -- We will send a group as what was the correct answer.
				local correctGroup = display.newGroup() -- There are other types of correctAnswer, text, group, and image
				correctGroup.isVisible = false
				
				local box = display.newRect(0, 0, SIZE_BOXES, SIZE_BOXES)
				box:setFillColor(unpack(COLOR_CORRECT))
				correctGroup:insert(box)
				
				local options = {delay = nil} -- We can specify a custom delay that overrides the one at getInfo. This can be used for custom timed animations
				manager.wrong({id = "group", group = correctGroup}, options) -- Must send what the correct answer was, options is optional
			end
		end
	end
end

local function removeDynamicAnswers()
	display.remove(wrongAnswersGroup) -- if wrongAnswersGroup is nil, nothing will happen, so we can call this method wherever we want
	wrongAnswersGroup = nil
end

local function createDynamicAnswers()
	-- We call this also in our did hide event, but we call it again here just in case there was an error and the did hide event was not fired
	removeDynamicAnswers() -- We remove the whole group, with all its children. it's easier, cleaner and faster. 
	
	wrongAnswersGroup = display.newGroup() -- we create the group again
	answersLayer:insert(wrongAnswersGroup) -- And insert it in the layer
	
	-- We calculate totalWidth to align boxes to the middle with a simple center to center padding
	local totalWidth = (WRONG_ANSWERS - 1) * PADDING_WRONG_ANSWERS
	local startX = display.contentCenterX - totalWidth * 0.5 -- Starting X will be the center minus half the total width
	
	local function boxAnimation(box) -- Recursive animation, we use director.to, it is similar to transition.to, but it self cancels when the did hide event fires
		local originalY = box.y
		local targetY = originalY - 50
		director.to(scenePath, box, {time = TIME_BOX_ANIMATION, y = targetY, transition = easing.outQuad, onComplete = function()
			director.to(scenePath, box, {time = TIME_BOX_ANIMATION, y = originalY, transition = easing.inQuad, onComplete = function()
				boxAnimation(box)
			end})
		end})
	end
	
	for index = 1, WRONG_ANSWERS do
		local wrongBox = display.newRect(startX + (index - 1) * PADDING_WRONG_ANSWERS, display.contentCenterY + OFFSET_Y_WRONG_ANSWERS, SIZE_BOXES, SIZE_BOXES)
		wrongBox.isCorrect = false -- We will use this property in the tap function to check if the answer is wrong. All of these will be wrong
		wrongBox:addEventListener("tap", onAnswerTapped)
		wrongAnswersGroup:insert(wrongBox)
		wrongBox:setFillColor(unpack(COLOR_WRONG)) -- Unpack, a powerfull function, learn how it can be used
		boxAnimation(wrongBox)
	end
	
	director.to(scenePath, wrongAnswersGroup, {time = 20000, alpha = 0.2}) -- director.to is a transition.to wrapper that is cancelled when the scene is hided
end

local function initialize(event)
	event = event or {} -- if event is missing it will use an empty table
	local params = event.params or {} -- the same goes for params. The only way this could crash is if event was not nil but not a table
	
	isFirstTime = params.isFirstTime -- This parameter is sent by manager. we should show the tutorial depending on it.
	manager = event.parent -- We save our parent (Minigames manager) to call its functions
	
	local operation = params.operation -- We ask for an operation on getInfo, we receive it here
	local wrongAnswers = params.wrongAnswers-- We ask for wrong answers on getInfo, we receive it here
	
	--params.topic -- a string specifying which topic was selected. addition, subtraction, multiplication, etc.
	
	--operation.operands -- an indexed table with operands in order
	--operation.result
	--operation.operator
	--operation.operationString
	
	--wrongAnswers -- an indexed table with wrong answers in order
	
	-- We can reset tables, set strings, reset counters and other stuff here
	instructions.text = localization.getString("testMinigameInstructions")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial()
	if isFirstTime then -- Super important. Tutorial only the first time. 
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 1500, x = correctBox.x, y = correctBox.y},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions) -- Use the tutorial library, it is simple, fast and efficient, see how it works.
	end
end
----------------------------------------------- Module functions 
function game.getInfo() -- This is the minigame header. The manager will ask the minigame what it does and what it needs
	return {
		available = false, -- If false, manager will not choose it, only manually
		correctDelay = 500, -- Delay given to complete animation or actions after the player has answered correctly
		wrongDelay = 500, -- Delay given to complete animation or actions after the player has failed to answer
		-- NOTE: These delays exist so the animation after the player has answered can complete and for us to only count the time it takes to answer
		name = "Minigame tester", -- Reference name, server purposes
		category = "math", -- Category/Subject
		subcategories = {"addition", "subtraction"}, -- available subcategories
		age = {min = 0, max = 99}, -- Minimum and max age for this game
		grade = {min = 0, max = 99}, -- Min and max grade for this game
		gamemode = "findAnswer", -- Gamemode (How the game is played)
		requires = { -- What the game needs from the manager. We will ask for an operation and some wrong answers
			{id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 5},
		},
	}
end  

function game:create(event) -- This will be fired the first time you load the scene. If you deload the scene this can get called again. The best practice is to make your scenes without memory leaks.
	local sceneView = self.view
	
	-- These groups make up a layered scene, this way dynamic objects can always appear behind any text. These layers will NEVER be removed
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)
	
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	-- Using the layered scene, we can build the scene in any order
	correctBox = display.newRect(display.contentCenterX + -OFFSET_X_ANSWERS, display.contentCenterY, SIZE_BOXES, SIZE_BOXES)
	correctBox.isCorrect = true -- We will use the isCorrect flag to check answers NO COMPARING TEXT VALUES
	correctBox:setFillColor(unpack(COLOR_CORRECT))
	correctBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(correctBox)
	
	wrongBox = display.newImageRect(assetPath.."ninja.png", SIZE_BOXES, SIZE_BOXES) -- Here we use assetPath, it is the relative scenePath to our folder
	wrongBox.x, wrongBox.y = display.contentCenterX + OFFSET_X_ANSWERS, display.contentCenterY
	wrongBox.isCorrect = false
	wrongBox:setFillColor(unpack(COLOR_WRONG))
	wrongBox:addEventListener("tap", onAnswerTapped)
	answersLayer:insert(wrongBox)
	
	-- Instructions are text. Will always be present
	-- We dont need text here, we will set it depending on language.
	instructions = display.newText("", display.contentCenterX + OFFSET_TEXT.x, display.contentCenterY + OFFSET_TEXT.y, settings.fontName, SIZE_FONT)
	textLayer:insert(instructions)
	
end

function game:destroy() -- We never add anything here. This gets called if a scene is forced to unload
	
end

-- The show and hide listeners are complex as they are, with an if inside. DO NOT nest more logic, use functions or one liners inside
function game:show( event ) -- This will be called with two phases. First the "will" phase, then the "did"
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- Initialize game variables, language stuff, receive params
		initialize(event)
		createDynamicAnswers() -- Just an example to create dynamic stuff
		tutorial() -- We always call the tutorial. Whether or not it is drawn depends on the function inside, not outside
	elseif phase == "did" then -- Start music, start game, enable control
		enableButtons()
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then -- We dont usually use this part now, but you can disable game stuff here
		
	elseif phase == "did" then -- Remove all dynamic stuff, remove Runtime event listeners, disable physics, multitouch.
		-- Remove transitions, cancel timers, etc.
		disableButtons()
		removeDynamicAnswers()
		tutorials.cancel(gameTutorial)
		-- We did not include the transition made with director, director cancels it automatically once we leave the scene.
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
