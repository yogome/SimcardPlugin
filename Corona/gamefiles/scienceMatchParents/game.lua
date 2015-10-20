----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" ) 
local extratable = require( "libs.helpers.extratable" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene() 

----------------------------------------------- Variables
local answersLayer, wrongAnswersGroup
local backgroundLayer
local textLayer, instructions
local manager
local tapsEnabled
local isFirstTime
local correctBox, wrongBox
local gameTutorial
-----------------------------------------------
local background
local answerContainer
local childGroup
local parentGroup
local optionGroup
local option1, option2, option3
----------------------------------------------- Constants
local OFFSET_X_ANSWERS = 200
local OFFSET_TEXT = {x = 0, y = - 225}
local SIZE_BOXES = 100
local COLOR_WRONG = colors.red
local COLOR_CORRECT = colors.green
local WRONG_ANSWERS = 6
local SIZE_FONT = 25

local TIME_BOX_ANIMATION = 500

local PADDING_WRONG_ANSWERS = 140
local OFFSET_Y_WRONG_ANSWERS = 200
-----------------------------------------------
local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenLeft = display.screenOriginX
local screenWidth = display.viewableContentWidth - screenLeft * 2
local screenRight = screenLeft + screenWidth
local screenTop = display.screenOriginY
local screenHeight = display.viewableContentHeight - screenTop * 2
local screenBottom = screenTop + screenHeight 
local mRandom = math.random
local mAbs = math.abs
local OPTION_SPACINGX = -10

local IMAGES = {
	parents = {
		[1] = {
			image = assetPath.."papascaballo.png",
			positionY = -55,
			family = 1
		},
		[2] = {
			image = assetPath.."papasflores.png",
			positionY = 90,
			family = 2
		},
		[3] = {
			image = assetPath.."papaspatitos.png",
			positionY = 235,
			family = 3
		}
	},
	children = {
		[1] = {
			image = assetPath.."hijocaballo.png",
			positionX = -90,
			family = 1
		},
		[2] = {
			image = assetPath.."hijoflor.png",
			positionX = 0,
			family = 2
		},
		[3] = {
			image = assetPath.."hijopato.png",
			positionX = 90,
			family = 3
		}
	}
}
----------------------------------------------- Functions
local function onAnswerTapped(event)
	local answer = event.target 
	if tapsEnabled then
		tapsEnabled = false 
		if answer.isCorrect then 
			if manager then 
				manager.correct()
			end
		else
			if manager then 
				local correctGroup = display.newGroup() 
				correctGroup.isVisible = false
				
				local box = display.newRect(0, 0, SIZE_BOXES, SIZE_BOXES)
				box:setFillColor(unpack(COLOR_CORRECT))
				correctGroup:insert(box)
				
				manager.wrong({id = "group", group = correctGroup}) 
			end
		end
	end
end

local function onTouch( event )
	local object = event.target
	local answerPosX, answerPosY = answer.x, answer.y
	print("touch")
	
	if object.isTouchable then
		if event.phase == "began" then
			object.markX = object.x
			object.markY = object.y
			display.getCurrentStage():setFocus( object )
		elseif event.phase == "moved" then 
			local x = (event.x - event.xStart) + object.markX
			local y = (event.y - event.yStart) + object.markY

			object.x, object.y = x, y

		elseif event.phase == "ended" then
			local objPosX, objPosY = object.x, object.y
			local distanceToPointX, distanceToPointY = math.abs( answerPosX - objPosX ), math.abs( answerPosY - objPosY )

			if object.total == result and distanceToPointX < 100 and distanceToPointY < 100 then 
				object.x = answer.x
				object.y = answer.y

				if manager then 
					manager.correct()
				end
			else
				object.isTouchable = false
				transition.to( object,{ time = 500, x = object.markX, y = object.markY, onComplete = function () object.isTouchable = true end})
				display.getCurrentStage():setFocus(nil)
			end
		end
	end
	return true
end

local function displayImages( createImages, group, parents )
	local indexToUse = { 1, 2, 3 }
	
	createImages = extratable.shuffle(createImages)
	
	for index = 1, #createImages do
		local indexPos = mRandom( #indexToUse )
		local image = display.newImage( createImages[index].image)
		
		image:scale( 0.8, 0.8 )
		
		if parents then
			image.y = createImages[indexToUse[indexPos]].positionY
		else
			image.x = createImages[indexToUse[indexPos]].positionX
			image:addEventListener( "touch",  onTouch )
		end
		
		table.remove( indexToUse, indexPos )
		group:insert( image )
	end
	
end

local function initialize(event)
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	local operation = params.operation 
	local wrongAnswers = params.wrongAnswers
	
	displayImages( IMAGES.parents, parentGroup, true )
	displayImages( IMAGES.children, childGroup, false )
	
	instructions.text = localization.getString("testMinigameInstructions")
end

local function enableButtons()
	tapsEnabled = true
end

local function disableButtons()
	tapsEnabled = false
end

local function tutorial()
	if isFirstTime then 
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap", delay = 1500, time = 1500, x = correctBox.x, y = correctBox.y},
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
		
		name = "Minigame tester", 
		category = "math", 
		subcategories = {"addition", "subtraction"}, 
		age = {min = 0, max = 99}, 
		grade = {min = 0, max = 99}, 
		gamemode = "findAnswer", 
		requires = { 
			{id = "operation", operands = 2, maxAnswer = 10, minAnswer = 1, maxOperand = 10, minOperand = 1},
			{id = "wrongAnswer", amount = 5},
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
	
	background = display.newImage( assetPath.."fondocaminos.png" )
	background.x = centerX
	background.y = centerY
	background.width = screenWidth
	background.height = screenHeight
	backgroundLayer:insert(background)
	
	answerContainer = display.newImage( assetPath.."contenedor.png" )
	answerContainer.x = centerX
	answerContainer.y = centerY - centerY * 0.8
	backgroundLayer:insert( answerContainer )
	
	optionGroup = display.newGroup()
	optionGroup.x = centerX - centerX * 0.8
	optionGroup.y = centerY
	answersLayer:insert( optionGroup )
	
	option1 = display.newImage(assetPath.."opcion.png")
	option1.x = OPTION_SPACINGX
	option1.y = -75
	optionGroup:insert( option1 )
	
	option2 = display.newImage(assetPath.."opcion.png")
	option2.x = OPTION_SPACINGX
	option2.y = 70
	optionGroup:insert( option2 )
	
	option3 = display.newImage(assetPath.."opcion.png")
	option3.x = OPTION_SPACINGX
	option3.y = 210
	optionGroup:insert( option3 )
	
	childGroup = display.newGroup()
	childGroup.x = centerX
	childGroup.y = centerY - centerY * 0.8
	answersLayer:insert( childGroup )
	
	parentGroup = display.newGroup()
	parentGroup.x = centerX + centerX * 0.8
	parentGroup.y = centerY
	answersLayer:insert( parentGroup )
	
	instructions = display.newText("", display.contentCenterX + OFFSET_TEXT.x, display.contentCenterY + OFFSET_TEXT.y, settings.fontName, SIZE_FONT)
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
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then 
		
	elseif phase == "did" then 
		
		disableButtons()
		tutorials.cancel(gameTutorial)
		
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game


