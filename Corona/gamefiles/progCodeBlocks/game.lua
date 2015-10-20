----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local extracollision = require( "libs.helpers.extracollision" )
local widget = require( "widget" )
local sound = require( "libs.helpers.sound" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene() 
----------------------------------------------- Variables
local codeBlockGroup
local codeBlockList
local playButton
local queueBg
local manager
local instructionsBg
local dragGroup
local codeblockQueue
local queueBeginTag
local lockGame
local levelStuffGroup
local bananas
local validFloorTiles
local isMonkeyAlive
local isFirstTime
local currentLoop
local monkey
local queueBeginTagText
local queueHeaderText
local instructionHeader
local banana
local levelGroup
local language
local gameTutorial
local instructionsetPositions
local selectedStage
local instructionsText
----------------------------------------------- Constants
local WIDTH_QUEUE_BG = 300
local HEIGHT_INSTRUCTION_BG = 150
local HEIGHT_QUEUE_HEADER = 60
local HEIGHT_INSTRUCTIONS = 52

local OFFSET_Y_QUEUE_BEGIN_TAG = 45
local OFFSET_Y_PLAY_BUTTON = 65
local OFFSET_CODEBLOCK_TEXT = {x = 20, y = -5}
local OFFSET_CODEBLOCK_ICON = {x = -65, y = -5}

local THICKNESS_BORDER = 4
local COLOR_BG = colors.convertFrom256({255, 236, 189})
local COLOR_QUEUEBG = colors.convertFrom256({255,114,95})
local COLOR_INSTRUCTION_BG = colors.convertFrom256({255, 150, 64})
local COLOR_QUEUE_HEADER = colors.convertFrom256({255,187,136})
local COLOR_CODEBLOCK = colors.convertFrom256({124,6,63})
local COLOR_CODEBLOCK_ACTIVE = colors.convertFrom256({10,165,62})
local COLOR_CODEBLOCK_DONE = colors.convertFrom256({86,86,86})
local PATH_COLOR = colors.convertFrom256({73, 193, 193})

local SIZE_FONT_CODEBLOCKS = 18

local SCALE_CODEBLOCK_ICON = 0.25
local SCALE_MONKEY = 0.65
local RADIUS_MONKEY = 20

local TILE_DESCRIPTORS = {
	["empty"] = 0,
	["floor"] = 1,
	["spawn"] = 2,
	["banana"] = 3,
}
local STAGES = {
	[0] = {
		[1] = {0,0,0},
		[2] = {2,1,3},
		[3] = {0,0,0},
		["correctAnswer"] = {"moveRight", "moveRight"},
	},
	[1] = {
		[1] = {0,0,1,0},
		[2] = {2,1,1,3},
		[3] = {0,1,0,0},
		["correctAnswer"] = {"moveRight", "moveRight", "moveRight"},
	},
	[2] = {
		[1] = {2,0,0,0},
		[2] = {1,0,3,0},
		[3] = {1,1,1,0},
		["correctAnswer"] = {"moveDown", "moveDown", "moveRight", "moveRight", "moveUp"},
	},
	[3] = {
		[1] = {2,1,0,0},
		[2] = {0,1,3,0},
		[3] = {0,0,0,0},
		["correctAnswer"] = {"moveRight", "moveDown", "moveRight"},
	},
	[4] = {
		[1] = {2,1,1,1},
		[2] = {0,1,0,1},
		[3] = {1,1,3,1},
		["correctAnswer"] = {"moveRight", "moveDown", "moveDown", "moveRight"},
	},
	[5] = {
		[1] = {1,2,1,1},
		[2] = {1,0,0,1},
		[3] = {3,1,3,1},
		["correctAnswer"] = {"moveLeft", "moveDown", "moveDown", "moveRight", "moveRight"},
	},
	[6] = {
		[1] = {2,1,0,0},
		[2] = {0,1,0,0},
		[3] = {0,3,1,3},
		["correctAnswer"] = {"moveRight", "moveDown", "moveDown", "moveRight", "moveRight"},
	},
	[7] = {
		[1] = {0,0,1,3},
		[2] = {2,0,1,0},
		[3] = {1,1,1,0},
		["correctAnswer"] = {"moveDown", "moveRight", "moveRight", "moveUp", "moveUp", "moveRight"},
	},
	[8] = {
		[1] = {2,1,1,1},
		[2] = {0,0,0,1},
		[3] = {0,0,3,1},
		["correctAnswer"] = {"moveRight", "moveRight", "moveRight", "moveDown", "moveDown", "moveLeft"},
	}
}

local TAG_TRANSITION_REARRANGE = "transitionCodeblockRearrange"
local MAX_CODEBLOCKS = 6
local DELAY_MONKEY_WALK = 200
local TIME_MONKEY_WALK = 500
local DISTANCE_MONKEY_WALK = 160
local SIZE_FLOOR = DISTANCE_MONKEY_WALK

local WALK_DISTANCES = {
	["moveUp"] = {x = 0, y = -DISTANCE_MONKEY_WALK},
	["moveDown"] = {x = 0, y = DISTANCE_MONKEY_WALK},
	["moveLeft"] = {x = -DISTANCE_MONKEY_WALK, y = 0},
	["moveRight"] = {x = DISTANCE_MONKEY_WALK, y = 0},
}

local AVAILABLE_INSTRUCTIONS = {
	[1] = {id = "moveUp", icon = "up.png"},
	[2] = {id = "moveDown", icon = "down.png"},
	[3] = {id = "moveLeft", icon = "left.png"},
	[4] = {id = "moveRight", icon = "right.png"},
} 

local INSTRUCTION_OFFSET_Y = 6

local texts = {	
	moveUp = { en = "Move Up", es = "Arriba", pt = "Acima"},
	moveDown = { en = "Move Down", es = "Abajo", pt = "Baixo"},
	moveLeft = { en = "Move Left", es = "Izquierda", pt = "Esquerda"},
	moveRight = { en = "Move Right", es = "Derecha", pt = "Direito"}
}

----------------------------------------------- Functions
local function tutorial()
	if isFirstTime then
	
		local tutorialOptions = {
			iterations = 5,
			scale = 0.6, 
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 1500, time = 2500, x = instructionsetPositions[4].x, y = instructionsetPositions[4].y, toX = queueBg.x, toY = queueBg.height/3},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function grabBannana(banana)
	sound.play("minigamesHumanBite")
	director.to(scenePath, banana, {time = 800, rotation = 3000, alpha = 0, transition = easing.inOutQuad, onComplete = function()
		display.remove(banana)
	end})
end

local function updateGame()
	if isMonkeyAlive then
		currentLoop = currentLoop + 1
		if currentLoop % 10 == 0 then

			local isMonkeySafe = false
			if validFloorTiles then
				for floorIndex = 1, #validFloorTiles do
					local floorTile = validFloorTiles[floorIndex]

					if extracollision.checkCircleCollision(monkey, floorTile) then
						isMonkeySafe = true
						if floorTile.banana then
							grabBannana(floorTile.banana)
							bananas = bananas - 1
							floorTile.banana = nil
						end
					end
				end
			end

			if not isMonkeySafe then
				isMonkeyAlive = false
				transition.cancel(monkey)
				sound.play("minigamesFalling")
				director.to(scenePath, monkey, {time = 800, alpha = 0, xScale = 0.01, yScale = 0.01, rotation = -600, transition = easing.inOutQuad})
				if manager then
					local correctAnswerText = ""
					for index = 1, #selectedStage.correctAnswer do
						correctAnswerText = correctAnswerText..texts[selectedStage.correctAnswer[index]][localization.getLanguage()]
						if index < #selectedStage.correctAnswer then
							correctAnswerText = correctAnswerText..", "
						end
					end
					manager.wrong({id = "text", text = correctAnswerText, fontSize = 36})
				end
			end
		end
	end
end

local function rearrangeRewardBlocks()
	transition.cancel(TAG_TRANSITION_REARRANGE)
	for index = 1, #codeblockQueue do
		local rewardBlock = codeblockQueue[index]
		rewardBlock.index = index
		local toY = queueBeginTag.y + (index * HEIGHT_INSTRUCTIONS)
		director.to(scenePath, rewardBlock, {tag = TAG_TRANSITION_REARRANGE, time = 600, y = toY, transition = easing.inOutCubic, onComplete = function()
			rewardBlock.lock = false
		end})
	end
end

local function executeQueue()
	sound.play("pop")
	if not lockGame then
		lockGame = true
			
		local function executeQueueStep(index)
			if index <= #codeblockQueue then
				transition.cancel(monkey)
				local instructionID = codeblockQueue[index].instructionParams.id
				local targetX = monkey.x + WALK_DISTANCES[instructionID].x
				local targetY = monkey.y + WALK_DISTANCES[instructionID].y
				codeblockQueue[index]:setFillColor(unpack(COLOR_CODEBLOCK_ACTIVE))
				director.to(scenePath, monkey, {delay = DELAY_MONKEY_WALK, time = TIME_MONKEY_WALK, x = targetX, y = targetY, onComplete = function()
					codeblockQueue[index]:setFillColor(unpack(COLOR_CODEBLOCK_DONE))
					executeQueueStep(index + 1)
					sound.play("flipCard")
				end})
			else
				if manager then
					if bananas <= 0 then
						manager.correct()
					else
						local correctAnswerText = ""
						for index = 1, #selectedStage.correctAnswer do
							correctAnswerText = correctAnswerText..texts[selectedStage.correctAnswer[index]][localization.getLanguage()]
							if index < #selectedStage.correctAnswer then
								correctAnswerText = correctAnswerText..", "
							end
						end
						manager.wrong({id = "text", text = correctAnswerText, fontSize = 36})
					end
				end
			end
		end
		
		executeQueueStep(1)
	end
end

local function createCodeBlock(instructionParams)
	local codeBlock = display.newGroup()
	codeBlock.instructionParams = instructionParams
	codeBlock.canSpawnNew = true
	
	local codeBlockBackground = display.newImage(assetPath.."CodeHInstructions.png")
	codeBlockBackground:setFillColor(unpack(COLOR_CODEBLOCK))
	codeBlock:insert(codeBlockBackground)

	local codeBlockText = display.newText(texts[instructionParams.id][language], OFFSET_CODEBLOCK_TEXT.x, OFFSET_CODEBLOCK_TEXT.y, settings.fontName, SIZE_FONT_CODEBLOCKS)
	codeBlock:insert(codeBlockText)

	local codeBlockIcon = display.newImage(assetPath..instructionParams.icon)
	codeBlockIcon.x = OFFSET_CODEBLOCK_ICON.x
	codeBlockIcon.y = OFFSET_CODEBLOCK_ICON.y
	codeBlockIcon:scale(SCALE_CODEBLOCK_ICON, SCALE_CODEBLOCK_ICON)
	codeBlock:insert(codeBlockIcon)
	
	function codeBlock:setFillColor(...)
		codeBlockBackground:setFillColor(...)
	end
	
	return codeBlock
end

local function dragCodeblockSpawnNew(event)
	local codeblock = event.target
	local phase = event.phase
	
	local cantMove = (#codeblockQueue >= MAX_CODEBLOCKS) and codeblock.canSpawnNew
	
	if not codeblock.lock and not cantMove and not lockGame then
		if "began" == phase then
			dragGroup:insert( codeblock )
			tutorials.cancel(gameTutorial, 300)
			
			if codeblock.canSpawnNew then
				codeblock.canSpawnNew = false
				local newCodeblock = createCodeBlock(codeblock.instructionParams)
				newCodeblock.x = codeblock.x
				newCodeblock.y = codeblock.y
				newCodeblock:addEventListener("touch", dragCodeblockSpawnNew)
				codeBlockGroup:insert(newCodeblock)
			end
			
			if codeblock.index then
				table.remove(codeblockQueue, codeblock.index)
				rearrangeRewardBlocks()
			end

			display.getCurrentStage():setFocus( codeblock, event.id )
			codeblock.isFocus = true
			sound.play("dragUnit")

			codeblock.x0 = event.x - codeblock.x
			codeblock.y0 = event.y - codeblock.y
		elseif codeblock.isFocus then
			if "moved" == phase then
				codeblock.x = event.x - codeblock.x0
				codeblock.y = event.y - codeblock.y0
			elseif "ended" == phase or "cancelled" == phase then
				display.getCurrentStage():setFocus( codeblock, nil )
				codeblock.isFocus = false

				if codeblock.x < display.screenOriginX + WIDTH_QUEUE_BG and codeblock.y < display.screenOriginY + display.viewableContentHeight - HEIGHT_INSTRUCTION_BG then
					codeblockQueue[#codeblockQueue + 1] = codeblock
					codeblock.index = #codeblockQueue
					codeblock.lock = true
					local targetX = display.screenOriginX + WIDTH_QUEUE_BG * 0.5
					local targetY = queueBeginTag.y + (#codeblockQueue * HEIGHT_INSTRUCTIONS)
					director.to(scenePath, codeblock, {time = 500, x = targetX, y = targetY, onComplete = function()
						codeblock.lock = false
						sound.play("dropDraggedUnit")
					end})
				else
					codeblock.lock = true
					director.to(scenePath, codeblock, {time = 500, alpha = 0, transition = easing.inQuad, onComplete = function()
						display.remove(codeblock)
					end})
				end
			end
		end
	end

	return true
end

local function addCodeBlocks(sceneView)
	
	display.remove(codeBlockGroup)
	codeBlockGroup = display.newGroup()
	sceneView:insert(codeBlockGroup)
	
	instructionsetPositions = {}
	
	local spacingX = display.viewableContentWidth / (#AVAILABLE_INSTRUCTIONS + 1)
	
	for index = 1, #AVAILABLE_INSTRUCTIONS do
		local instructionParams = AVAILABLE_INSTRUCTIONS[index]
		
		local codeBlock = createCodeBlock(instructionParams)
		codeBlock.x = display.screenOriginX + index * spacingX
		codeBlock.y = display.screenOriginY + display.viewableContentHeight - HEIGHT_INSTRUCTION_BG * 0.5
		codeBlock:addEventListener("touch", dragCodeblockSpawnNew)
		instructionsetPositions[#instructionsetPositions+1] = codeBlock
		codeBlockGroup:insert(codeBlock)
	end
	
	display.remove(dragGroup)
	dragGroup = display.newGroup()
	sceneView:insert(dragGroup)
end

local function setupLevel(sceneView)
	display.remove(levelStuffGroup)
	levelStuffGroup = display.newGroup()
	levelGroup:insert(levelStuffGroup)
	
	local levelCenterX = display.screenOriginX + WIDTH_QUEUE_BG + (display.viewableContentWidth - WIDTH_QUEUE_BG) * 0.5
	local levelCenterY = display.screenOriginY + (display.viewableContentHeight - HEIGHT_INSTRUCTION_BG) * 0.5
	
	local selectedStageIndex = isFirstTime and 0 or math.random(1, #STAGES)
	selectedStage = STAGES[selectedStageIndex]
	local stageColumns = #selectedStage[1]
	local stageRows = #selectedStage
	
	local function addFloor(x, y, tileID)
		local floorRect = display.newRect(x, y, SIZE_FLOOR, SIZE_FLOOR)
		floorRect:setFillColor(unpack(PATH_COLOR))
		floorRect.stroke = {1,1,1}
		floorRect.strokeWidth = 2
		floorRect.radius = SIZE_FLOOR * 0.5
		floorRect.tileID = tileID
		levelStuffGroup:insert(floorRect)
		
		validFloorTiles[#validFloorTiles + 1] = floorRect
		
		return floorRect
	end
	
	local function addBanana(x, y)
		local banana = display.newImage(assetPath.."CodeHBanana.png")
		banana.xScale, banana.yScale = 0.5, 0.5
		banana.x, banana.y = x, y
		levelStuffGroup:insert(banana)
		bananas = bananas + 1
		
		return banana
	end
	
	for rowIndex = 1, stageRows do
		for columnIndex = 1, stageColumns do
			local tileNumber = selectedStage[rowIndex][columnIndex]
			
			local x = levelCenterX - ((stageColumns + 1) * SIZE_FLOOR) * 0.5 + columnIndex * SIZE_FLOOR
			local y = levelCenterY - ((stageRows + 1) * SIZE_FLOOR) * 0.5 + rowIndex * SIZE_FLOOR
			
			if tileNumber == TILE_DESCRIPTORS["floor"] then
				addFloor(x, y, tileNumber)
			elseif tileNumber == TILE_DESCRIPTORS["spawn"] then
				addFloor(x, y, tileNumber)
				monkey.x, monkey.y = x, y
			elseif tileNumber == TILE_DESCRIPTORS["banana"] then
				local bananaFloor = addFloor(x, y, tileNumber)
				bananaFloor.banana = addBanana(x, y)
			end
		end
	end
	
	monkey:toFront()
	
end

local function initialize(event)
	event = event or {}
	local params = event.params or  {}
	isFirstTime = params.isFirstTime
	
	language = localization.getLanguage()
	
	isMonkeyAlive = true
	currentLoop = 0
	manager = event.parent
	codeblockQueue = {}
	codeBlockList = {}
	bananas = 0
	validFloorTiles = {}
	lockGame = false
	
	queueBeginTagText.text = localization.getString("instructionsCodeBlocksBeginTag")
	queueHeaderText.text = localization.getString("instructionsCodeBlocks")
	playButton:setLabel(localization.getString("instructionsCodeBlocksQueueButton"))
	instructionHeader.text.text = localization.getString("instructionsCodeBlocksHeader")
	instructionsText.text = localization.getString("instructionsCodeBlocksText")

	monkey.rotation = 0
	monkey.xScale = SCALE_MONKEY
	monkey.yScale = SCALE_MONKEY
	monkey.alpha = 1
end

----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = true,
		wrongDelay = 1000,
		correctDelay = 500,
		
		name = "Code blocks monkey",
		category = "programming",
		subcategories = {"functions"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			--{id = "difficulty"},
		},
	}
end

function game.enableButtons()
	playButton:setEnabled(true)
end

function game.disableButtons()
	playButton:setEnabled(false)
end

function game:create(event)
	local sceneView = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight )
	background:setFillColor( unpack(COLOR_BG) )
	sceneView:insert(background)
	
	levelGroup = display.newGroup()
	sceneView:insert(levelGroup)

	queueBg = display.newRect( 0, 0, WIDTH_QUEUE_BG, display.viewableContentHeight - HEIGHT_INSTRUCTION_BG - THICKNESS_BORDER)
	queueBg.anchorY = 0
	queueBg:setFillColor(unpack(COLOR_QUEUEBG))
	queueBg.x = display.screenOriginX + WIDTH_QUEUE_BG * 0.5
	queueBg.y = display.screenOriginY
	sceneView:insert(queueBg)

	local queueHeader = display.newRect(display.screenOriginX + WIDTH_QUEUE_BG * 0.5, display.screenOriginY + HEIGHT_QUEUE_HEADER * 0.5, WIDTH_QUEUE_BG, HEIGHT_QUEUE_HEADER)
	queueHeader:setFillColor(unpack(COLOR_QUEUE_HEADER))
	sceneView:insert(queueHeader)

	queueHeaderText = display.newText( "", queueHeader.x, queueHeader.y, settings.fontName, 26 )
	queueHeaderText:setFillColor(unpack(COLOR_CODEBLOCK))
	sceneView:insert(queueHeaderText)

	queueBeginTag = display.newImage(assetPath.."CodeHHeader.png")
	queueBeginTag.x = queueHeader.x 
	queueBeginTag.y = queueHeader.y + queueHeader.height * 0.5 + OFFSET_Y_QUEUE_BEGIN_TAG
	sceneView:insert(queueBeginTag)

	queueBeginTagText = display.newText("", queueBeginTag.x, queueBeginTag.y - INSTRUCTION_OFFSET_Y, settings.fontName, 24)
	sceneView:insert(queueBeginTagText)
	
	instructionsText = display.newText("", display.contentCenterX, display.screenOriginY+20, settings.fontName, 24)
	instructionsText:setFillColor(unpack(COLOR_CODEBLOCK))
	sceneView:insert(instructionsText)
	
	local buttonOptions = {
		defaultFile = assetPath.."CodeHPlayUp.png",
		overFile = assetPath.."CodeHPlayDown.png",
		onRelease = function()
			executeQueue()
		end,
		label = "",
		labelColor = {default = {1}, over = {1} },
		font = settings.fontName,
		fontSize = 36,
	}

	playButton = widget.newButton(buttonOptions)
	playButton.xScale, playButton.yScale = 0.85, 0.85
	playButton.x = queueBg.x
	playButton.y = display.screenOriginY + queueBg.height - OFFSET_Y_PLAY_BUTTON
	sceneView:insert(playButton)
	
	instructionsBg = display.newRect( display.contentCenterX, display.screenOriginY + display.viewableContentHeight - HEIGHT_INSTRUCTION_BG * 0.5, display.viewableContentWidth, HEIGHT_INSTRUCTION_BG)
	instructionsBg:setFillColor(unpack(COLOR_INSTRUCTION_BG))
	sceneView:insert(instructionsBg)
	

	instructionHeader = display.newGroup( )
	instructionHeader.x = instructionsBg.contentBounds.xMin
	instructionHeader.y = instructionsBg.contentBounds.yMin
	local instructionHeaderBg = display.newRect(70, 15, 140, 30)
	instructionHeaderBg:setFillColor( 0, 0, 0, 0.20 )
	instructionHeader:insert(instructionHeaderBg)

	instructionHeader.text = display.newText("", instructionHeaderBg.x, instructionHeaderBg.y, settings.fontName, 24)
	instructionHeader.text:setFillColor(unpack(COLOR_CODEBLOCK))
	instructionHeader:insert(instructionHeader.text)
	sceneView:insert(instructionHeader)
	
	monkey = display.newImage(assetPath.."CodeHMonkey.png")
	monkey.x = display.contentCenterX
	monkey.y = display.contentCenterY
	monkey.radius = RADIUS_MONKEY
	monkey:scale(SCALE_MONKEY, SCALE_MONKEY)
	levelGroup:insert(monkey)
end

function game:destroy()
	
end

function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		addCodeBlocks(sceneView)
		setupLevel(sceneView)
		tutorial()
		Runtime:addEventListener( "enterFrame", updateGame )
	elseif phase == "did" then
		game.enableButtons()
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		
	elseif phase == "did" then
		Runtime:removeEventListener( "enterFrame", updateGame )
		game.disableButtons()
		tutorials.cancel(gameTutorial)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
