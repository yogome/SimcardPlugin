----------------------------------------------- Test minigame
local scenePath = ... 
local folder = scenePath:match("(.-)[^%.]+$") 
local assetPath = string.gsub(folder,"[%.]","/") 
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" ) 

local game = director.newScene() 
----------------------------------------------- Variables
local answersLayer, wrongAnswersGroup, correctAnswersGroup, answersGroup
local backgroundLayer, backgroundImg
local basket
local mask
local isTouched
local questionId
local result, totalObjects
local textLayer, instructions, instructionsBg
local manager
local tapsEnabled
local isFirstTime
local correctBox, wrongBox
local gameTutorial
----------------------------------------------- Constants
local CENTER_X  = display.contentCenterX
local CENTER_Y  = display.contentCenterY
local MAX_X     = display.contentWidth
local MAX_Y     = display.contentHeight
local BACKGROUND_SCALE = 1.25
local INSTRUCTIONSBG_SCALE_X = MAX_X * 0.8
local INSTRUCTIONSBG_SCALE_Y = 1.3
local ANSWER_SCALE = 0.50
local ANSWER_BG_SCALE = 0.60
local CORRECT_GROUP_SCALE = 0.2
local OFFSET_X_CORRECT_GROUP = MAX_X * 0.12
local POS_X_CORRECT_GROUP = MAX_X * 0.2
local OFFSET_X_ANSWERS = {
	[1] = MAX_X / 5,
	[2] = MAX_X / 2,
	[3] = MAX_X * 4 / 5,
	}
local POS_Y_ANSWER = CENTER_Y * 1.1
local OFFSET_Y_ANSWER = MAX_Y * 0.1
local TIME_LIMIT = 6000
local SIZE_FONT = MAX_Y * 0.045

local TIME_BOX_ANIMATION = 500

local PADDING_WRONG_ANSWERS = 140
local OFFSET_Y_WRONG_ANSWERS = 200

local DINAMIC_OBJECTS = {
	[1] = {
		object = "1.png",
		posX = MAX_X / 8,
		posY = MAX_Y / 7 * 2.2,
		scaleObj = 1,
		typeObj = 2
		},
	[2] = {
		object = "2.png",
		posX = MAX_X / 8 * 2.1,
		posY = MAX_Y / 7 * 2.2,
		scaleObj = 1,
		typeObj = 2
		},
	[3] = {
		object = "3.png",
		posX = MAX_X / 8 * 2.1,
		posY = MAX_Y / 7 * 3.4,
		scaleObj = 1,
		typeObj = 2
		},
	[4] = {
		object = "4.png",
		posX = MAX_X / 8,
		posY = MAX_Y / 7 * 4.2,
		scaleObj = 1,
		typeObj = 2
		},
	[5] = {
		object = "5.png",
		posX = MAX_X / 8 * 0.5,
		posY = MAX_Y / 7 * 6.3,
		scaleObj = 1.2,
		typeObj = 2
		},
	[9] = {
		object = "6.png",
		posX = MAX_X / 8 * 5,
		posY = MAX_Y / 7 * 6.8,
		scaleObj = 1,
		typeObj = 2
		},
	[7] = {
		object = "7.png",
		posX = MAX_X / 8 * 6,
		posY = MAX_Y / 7 * 2.6,
		scaleObj = 1.2,
		typeObj = 2
		},
	[8] = {
		object = "8.png",
		posX = MAX_X / 8 * 7,
		posY = MAX_Y / 7 * 2.6,
		scaleObj = 1.2,
		typeObj = 2
		},
	[6] = {
		object = "9.png",
		posX = MAX_X / 8 * 4.6,
		posY = MAX_Y / 7 * 6.2,
		scaleObj = 1,
		typeObj = 2
		},
	[10] = {
		object = "transparente1.png",
		posX = MAX_X / 8 * 1.5,
		posY = MAX_Y / 7 * 2.35,
		scaleObj = 1,
		typeObj = 3
		},
	[11] = {
		object = "transparente2.png",
		posX = MAX_X / 8,
		posY = MAX_Y / 7 * 3.2,
		scaleObj = 1,
		typeObj = 3
		},
	[12] = {
		object = "transparente3.png",
		posX = MAX_X / 8 * 6,
		posY = MAX_Y / 7 * 4.25,
		scaleObj = 0.8,
		typeObj = 3
		},
	[13] = {
		object = "traslucido1.png",
		posX = CENTER_X,
		posY = MAX_Y / 7 * 3.9,
		scaleObj = 1,
		typeObj = 4
		},
	[19] = {
		object = "traslucido2.png",
		posX = MAX_X / 8 * 3.6,
		posY = MAX_Y / 7 * 6.7,
		scaleObj = 1,
		typeObj = 4
		},
	[17] = {
		object = "reflector1.png",
		posX = MAX_X / 8 * 2,
		posY = MAX_Y / 7 * 4.25,
		scaleObj = 1,
		typeObj = 1
		},
	[16] = {
		object = "reflector2.png",
		posX = MAX_X / 8 * 6.8,
		posY = MAX_Y / 7 * 4,
		scaleObj = 1,
		typeObj = 1
		},
	[15] = {
		object = "reflector3.png",
		posX = MAX_X / 8 * 1.2,
		posY = MAX_Y / 7 * 6.9,
		scaleObj = 1,
		typeObj = 1
		},
	[20] = {
		object = "opaco1.png",
		posX = MAX_X / 5 * 1.2,
		posY = MAX_Y / 7 * 5.5,
		scaleObj = 1,
		typeObj = 2
		},
	[14] = {
		object = "opaco2.png",
		posX = MAX_X / 8 * 3,
		posY = MAX_Y / 7 * 6.3,
		scaleObj = 1,
		typeObj = 2
		},
	[18] = {
		object = "opaco3.png",
		posX = MAX_X / 8 * 2.5,
		posY = MAX_Y / 7 * 6.9,
		scaleObj = 1,
		typeObj = 2
		}
}
local OBJECTS_BG = {
	[1] = {
		object = "estante.png",
		posX = MAX_X / 5,
		posY = MAX_Y / 7 * 2.2,
		scaleObj = 1.2
		},
	[2] = {
		object = "estante.png",
		posX = MAX_X / 5,
		posY = MAX_Y / 7 * 3.2,
		scaleObj = 1.2 
		},
	[3] = {
		object = "estante.png",
		posX = MAX_X / 5,
		posY = MAX_Y / 7 * 4.2,
		scaleObj = 1.2 
		},
	[4] = {
		object = "estante.png",
		posX = MAX_X / 5 * 4,
		posY = MAX_Y / 7 * 4.2,
		scaleObj = 1.2
		},
	[5] = {
		object = "ventana.png",
		posX = CENTER_X,
		posY = MAX_Y / 7 * 3,
		scaleObj = 1 
		},
	[6] = {
		object = "10.png",
		posX = MAX_X / 5 * 1.1,
		posY = MAX_Y / 7 * 5.5,
		scaleObj = 1 
		},
	[7] = {
		object = "canastadetras.png",
		posX = MAX_X / 5 * 4,
		posY = MAX_Y / 7 * 6,
		scaleObj = 1
	}
		
}
local dragZone = {
	xLeft = MAX_X / 5 * 4 - MAX_X / 10,
	xRight = MAX_X / 5 * 4 + MAX_X / 10,
	yTop = MAX_Y / 7 * 5.5 - MAX_X / 10,
	yBottom = MAX_Y / 7 * 5.5 + MAX_X / 10
}
----------------------------------------------- Functions
local function onObjectTouched(event)
	if isTouched == false then
		event.target:toFront()
		mask.x, mask.y = event.target.x,event.target.y
		if event.phase == "began" then
			event.target.markX = event.target.x   
			event.target.markY = event.target.y
			display.getCurrentStage():setFocus(event.target)
			event.target.isFocus = true
		elseif event.target.isFocus then
			if event.phase == "moved" then
				local x = (event.x - event.xStart) + event.target.markX
				local y = (event.y - event.yStart) + event.target.markY
				event.target.x, event.target.y = x, y   
			elseif event.phase == "ended" then
				event.target.hasFocus = false
				display.getCurrentStage():setFocus(nil)
				if event.target.x > dragZone.xLeft and event.target.x < dragZone.xRight and event.target.y > dragZone.yTop and event.target.y < dragZone.yBottom then
					director.to(scenePath,event.target,{time = 500 , x = basket.x, y = basket.y - MAX_Y * 0.2,xScale = 0.8, yScale = 0.8, onComplete = function()
						basket:toFront()
						director.to(scenePath,event.target,{time = 500 , x = basket.x, y = basket.y - MAX_Y * 0.05})	
					end})
					totalObjects = totalObjects + 1
					event.target.x, event.target.y = basket.x, basket.y
					event.target:removeEventListener("touch",onObjectTouched)
					if event.target.typeObj == questionId then
						result = result + 1
					end
					if result == 3 or (result == 2 and questionId == 4) then
						director.to(scenePath,correctAnswersGroup,{delay = 500, onComplete = function()
							manager.correct()
						end})
					elseif totalObjects == 3 or (totalObjects == 2 and questionId == 4) then
						director.to(scenePath,correctAnswersGroup,{delay = 500, onComplete = function()
							manager.wrong({id = "group", group = correctAnswersGroup})
						end})
					end
				else
					director.to(scenePath,event.target,{time = 500, x = event.target.originX, y = event.target.originY})
				end
			elseif event.phase == "cancel" then
				director.to(scenePath,event.target,{time = 500, x = event.target.originX, y = event.target.originY})
			end
		end
		return true
	end
end
local function removeDynamicAnswers()
	display.remove(wrongAnswersGroup) 
	display.remove(answersGroup)
	wrongAnswersGroup = nil
	answersGroup = nil
	basket = nil
end
local function onTouchScene (event)
	mask.x = event.x
	mask.y = event.y
	if event.phase == "began" then
		isTouched = true
	elseif event.phase == "moved" then
			
	elseif event.phase == "ended" then
			isTouched = false
	elseif event.phase == "cancel" then
			isTouched = false
	end
    return true
end
local function createObjectsBg ()
	--local recta = display.newRect(MAX_X / 5 * 4,MAX_Y / 7 * 5.5,MAX_X / 5,MAX_X / 5)
	--local recta = display.newRect(100,100,MAX_X / 10,MAX_Y / 14)
	--backgroundLayer:insert(recta)
	for index = 1, #OBJECTS_BG do
		local objectBgImg = display.newImage(assetPath..OBJECTS_BG[index].object,OBJECTS_BG[index].posX,OBJECTS_BG[index].posY)
		objectBgImg.xScale = OBJECTS_BG[index].scaleObj
		objectBgImg.yScale = OBJECTS_BG[index].scaleObj
		backgroundLayer:insert(objectBgImg)
	end
	--backgroundLayer:addEventListener("touch", onTouchScene)
end
local function createDynamicAnswers()
	
	removeDynamicAnswers() 
	
	wrongAnswersGroup = display.newGroup() 
	answersGroup = display.newGroup()
	correctAnswersGroup = display.newGroup()
	answersLayer:insert(wrongAnswersGroup) 
	answersLayer:insert(answersGroup) 
	answersLayer:insert(correctAnswersGroup) 
	local contAnswers = 0
	for index = 1, #DINAMIC_OBJECTS do
		local answersImg = display.newImage(assetPath..DINAMIC_OBJECTS[index].object,0,0)
		if DINAMIC_OBJECTS[index].typeObj == questionId then
			local row 
			local col 
			
			if questionId == 2 then
				row = math.floor(contAnswers / 4)
				col = contAnswers % 4 
			else
				row = 1
				col = contAnswers % 4 + 1
			end
			local answersImgCorrect = display.newImage(assetPath..DINAMIC_OBJECTS[index].object,col * OFFSET_X_CORRECT_GROUP - POS_X_CORRECT_GROUP,row * MAX_Y * 0.13 - MAX_Y * 0.08)
			answersImgCorrect.xScale = 0.7
			answersImgCorrect.yScale = 0.7
			correctAnswersGroup:insert(answersImgCorrect)
			contAnswers = contAnswers + 1
			--answersImgCorrect.isVisible = false
		end
		answersImg.xScale = DINAMIC_OBJECTS[index].scaleObj
		answersImg.yScale = DINAMIC_OBJECTS[index].scaleObj
		answersImg.typeObj = DINAMIC_OBJECTS[index].typeObj
		answersImg.x = DINAMIC_OBJECTS[index].posX
		answersImg.y = DINAMIC_OBJECTS[index].posY - answersImg.height / 2.5
		answersImg.y = answersImg.y 
		answersImg.originX = DINAMIC_OBJECTS[index].posX
		answersImg.originY = DINAMIC_OBJECTS[index].posY - answersImg.height / 2.5
		if DINAMIC_OBJECTS[index].typeObj == questionId then
			correctBox = answersImg
		end
		answersImg:addEventListener("touch",onObjectTouched)
		answersGroup:insert(answersImg)
	end
	correctAnswersGroup.isVisible = false
	basket = display.newImage(assetPath.."canastafrente.png", MAX_X / 5 * 4, MAX_Y / 7 * 6)
	mask.x = CENTER_X
	mask.y = CENTER_Y
	mask.xScale = MAX_X * 2.5 / mask.width
	mask.yScale = mask.xScale
	answersGroup:insert(basket)
end

local function initialize(event)
	math.randomseed(os.time())
	event = event or {} 
	local params = event.params or {} 
	
	isFirstTime = params.isFirstTime 
	manager = event.parent 
	
	local operation = params.operation 
	local wrongAnswers = params.wrongAnswers
	result = 0
	totalObjects = 0
	questionId = math.random(4)
	instructions.text = localization.getString("scienceFindObjects"..questionId)
	Runtime:addEventListener("touch",onTouchScene)
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
				[1] = {id = "drag", delay = 2000, time = 3000, getObject = function() return correctBox end, toX = basket.x , toY = basket.y},
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
		
		name = "scienceFindObjects", 
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
	
	local INFO_TEXT = {
	text     = "",
	x        = CENTER_X,
	y        = MAX_Y * 0.135,
	width    = MAX_X * 0.6,
	height   = MAX_Y * 0.2,
	align    = "center",
	font	 = settings.fontName,
	fontSize = SIZE_FONT
	}
	local sceneView = self.view
	
	
	backgroundLayer = display.newGroup() 
	sceneView:insert(backgroundLayer)

	
	answersLayer = display.newGroup()
	sceneView:insert(answersLayer)
	
	mask = display.newImage(assetPath.."mask.png",CENTER_X,CENTER_Y)
	sceneView:insert(mask)
	
	textLayer = display.newGroup()
	sceneView:insert(textLayer)
	
	backgroundImg = display.newImage(assetPath.."fondo.png",CENTER_X ,CENTER_Y - MAX_Y * 0.08)
	backgroundImg.xScale = BACKGROUND_SCALE
	backgroundImg.yScale = BACKGROUND_SCALE
	backgroundLayer:insert(backgroundImg)
	
	instructionsBg = display.newImage(assetPath.."instruccion.png", CENTER_X, MAX_Y * 0.09);
	instructionsBg.xScale = 1.6
	instructionsBg.yScale = 1.6
	instructions = display.newText(INFO_TEXT)
	instructions:setTextColor(8/255,107/255,187/255)
	--255, 0, 0
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
		createObjectsBg()
		createDynamicAnswers() 
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
