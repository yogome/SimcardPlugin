----------------------------------------------- Test minigame
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local tutorials = require( "libs.helpers.tutorials" )
local settings = require( "settings" )
local screen = require( "libs.helpers.screen" )
local logger = require( "libs.helpers.logger" )
local extratable = require("libs.helpers.extratable")
local sound = require( "libs.helpers.sound" )

local game = director.newScene()
----------------------------------------------- Variables
local tilesLayer
local pipeAnimation
local backgroundLayer
local textLayer, questionText
local manager
local isFirstTime
local correctBox, wrongBox
local gameTutorial
local objectEditing, moveFlag, editingText
local spacing, grid
local gridData
local pipeList
local startCoordenate
local tileOccupied
local answers
local textAnswers
local correctAnswer
local pipeTutorial
local pipeIndexSelected
----------------------------------------------- Constants

local NUMBER_COLUMNS = 21
local OFFSET_TEXT = {x = 0, y = -200}
local MOVE_PIXELS = 5
local HAND_OFFSET = 92


local COLOR_BACKGROUND = {197/255, 232/255, 196/255}
local COLOR_GRID = {1, 249/255, 204/255}
local NUMBER_ROWS = 15
local NUMBER_QUESTIONS = 3
local SIZE_FONT = 24

--NOTES pipes connections per grid
-- 1 = 1
--     1
--
--2 = 1 1
--
--3 = 1 1
--    1
--
--4 = 1 1
--      1
--
--5 = 1
--    1 1
--
--6 =   1
--    1 1

local PIPES = {
    { image = assetPath .. "llave.png", rotationImage = 0, width = 4, height = 3,
        data = {{0, 'N', 1}, {0, 'N', 0}, {0, 'N', 0}, {0, 'N', 0}},
        position = {col = 9, row = -4},
        edge = true,
        start = true,
    },
    { image = assetPath .. "2.png", rotationImage = 90, width = 1, height = 2,
        data = {{2},{2}},
        position = {col = -6, row = -4}
    },
    { image = assetPath .. "2.png", rotationImage = 90, width = 1, height = 2,
        data = {{2},{2}},
        position = {col = -3, row = -4}
    },
    { image = assetPath .. "2.png", rotationImage = 90, width = 1, height = 2,
        data = {{2},{2}},
        position = {col = 0, row = -4}
    },
    { image = assetPath .. "2.png", rotationImage = 90, width = 1, height = 2,
        data = {{2},{2}},
        position = {col = 3, row = -4}
    },
    { image = assetPath .. "2.png", rotationImage = 0, width = 1, height = 2,
        data = {{1,1}},
        position = {col = -7, row = -1}
    },
    { image = assetPath .. "2.png", rotationImage = 0, width = 1, height = 2,
        data = {{1,1}},
        position = {col = -5, row = -1}
    },
    { image = assetPath .. "2.png", rotationImage = 90, width = 1, height = 1,
        data = {{2}},
        position = {col = -1, row = -1}
    },
    { image = assetPath .. "2.png", rotationImage = 0, width = 1, height = 1,
        data = {{1}},
        position = {col = 1, row = -1}
    },
    { image = assetPath .. "3.png", rotationImage = 0, width = 2, height = 2,
        data = {{3,1},
                {2,0}},
        position = {col = -6, row = 2}
    },
    { image = assetPath .. "3.png", rotationImage = 90, width = 2, height = 2,
        data = {{2,0},
                {4,1}},
        position = {col = -4, row = 2}
    },
    { image = assetPath .. "3.png", rotationImage = -90, width = 2, height = 2,
        data = {{1,5},
                {0,2}},
        position = {col = -1, row = 2}
    },
    { image = assetPath .. "3.png", rotationImage = 180, width = 2, height = 2,
        data = {{0,2},
                {1,6}},
        position = {col = 1, row = 2}
    },
    { image = assetPath .. "3.png", rotationImage = 180, width = 2, height = 2,
        data = {{0,2},
                {1,6}},
        tutorial = true,
        position = {col = 4, row = 2}
    },
    { image = assetPath .. "3.png", rotationImage = 0, width = 2, height = 2,
        data = {{3,1},
                {2,0}},
        position = {col = 7, row = 2}
    },
    { image = assetPath .. "opcion.png", rotationImage = 0, width = 5, height = 3,
        data = {{0,'N','N'},
                {0,'N','N'},
                {'E','1','N'},
                {0,'N','N'},
                {0,'N','N'}},
        position = {col = 0, row = math.round(NUMBER_ROWS / 2) - 3},
        edge = true,
        idQuestion = 1
    },
    { image = assetPath .. "opcion.png", rotationImage = 0, width = 5, height = 3,
        data = {{0,'N','N'},
                {0,'N','N'},
                {'E','2','N'},
                {0,'N','N'},
                {0,'N','N'}},
        position = {col = 0, row = math.round(NUMBER_ROWS / 2) - 3},
        edge = true,
        idQuestion = 2
    },
    { image = assetPath .. "opcion.png", rotationImage = 0, width = 5, height = 3,
        data = {{0,'N','N'},
                {0,'N','N'},
                {'E','3','N'},
                {0,'N','N'},
                {0,'N','N'}},
        position = {col = 0, row = math.round(NUMBER_ROWS / 2) - 3},
        edge = true,
        idQuestion = 3
    },
}
----------------------------------------------- Functions
local function colorObject(object, color)
	if object.setFillColor then
        object:setFillColor(unpack(color))
	else
		for objectIndex = 1, object.numChildren do
			colorObject(object[objectIndex], color)
		end
	end
end

local function moveObject( event )
 	if moveFlag then
		if event.phase == "began" then
			if objectEditing then
				colorObject(objectEditing, {1})
			end
			objectEditing = event.target
			colorObject(objectEditing, {0, 1, 0})
			display.getCurrentStage():setFocus( objectEditing )
			objectEditing.isFocus = true
			objectEditing.deltaX = event.x - objectEditing.x
			objectEditing.deltaY = event.y - objectEditing.y
		elseif objectEditing.isFocus then
			if event.phase == "moved" then
				objectEditing.x = event.x - objectEditing.deltaX
				objectEditing.y = event.y - objectEditing.deltaY
			elseif event.phase == "ended" or event.phase == "cancelled" then
				display.getCurrentStage():setFocus( nil )
				objectEditing.isFocus = nil
			end
		end
		return true
	end
end 

local function removeDynamicElements()
    for indexPipe = 1, #pipeList do
        local pipe = pipeList[indexPipe]
        display.remove(pipe)
        pipeList[indexPipe] = nil
    end
    for indexAnswer = 1, #textAnswers do
        display.remove(textAnswers[indexAnswer])
        textAnswers[indexAnswer] = nil
        answers[indexAnswer] = nil
    end
end

local function setText()
    for indexText = 1, #textAnswers do
        local textAnswer = textAnswers[indexText]
        textAnswer.text = answers[indexText].text
    end
end

local function animatePipes()
    local function rotate()
        director.to(scenePath, pipeAnimation, {time = 600, xScale = 1, yScale =1})
        director.to(scenePath, pipeAnimation, {delay = 600, time = 600, xScale = 1.01, yScale = 1.01, onComplete = function()
            rotate(pipeAnimation)
        end})
    end
    rotate()
end

local function dropPipes()
    transition.cancel(pipeAnimation)
    director.to(scenePath, pipeAnimation, {time = 900, y = display.viewableContentHeight, transition = easing.inQuad})
    sound.play("generalCrash")
end

local function vibratePipes()
    transition.cancel(pipeAnimation)
    local function rotate()
        local referenceX = pipeAnimation.x
        director.to(scenePath, pipeAnimation, {time = 100, x = referenceX - 5, transition = easing.outQuad})
        director.to(scenePath, pipeAnimation, {delay = 100, time = 200, x = referenceX + 5, transition = easing.outQuad})
        director.to(scenePath, pipeAnimation, {delay = 300, time = 100, x = referenceX, transition = easing.outQuad, onComplete = function()
            rotate(pipeAnimation)
        end})
    end
    rotate()
    sound.play("minigamesFlush")
end

local function checkConnect(coordenates, color)
    local function addPipeAnimation()
        if gridData[coordenates.column][coordenates.row].pipeIndex > 0 then
            local pipeIndex = gridData[coordenates.column][coordenates.row].pipeIndex
            local pipe = pipeList[pipeIndex]
            pipeAnimation:insert(pipe)
            if pipeIndexSelected == pipeIndex then
                sound.play("hitMetal")
            end
        end
    end
    if gridData[coordenates.column][coordenates.row] then
        local value = gridData[coordenates.column][coordenates.row].number
--        local tile = gridData[coordenates.column][coordenates.row].tile
--        tile:setFillColor(unpack(color))
--        tile.alpha = 0.6
        if coordenates.direction == "down" then
            if value == 1 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row + 1,
                    direction = "down"
                }
                checkConnect(coordenates, color)
            elseif value == 5 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column + 1,
                    row = coordenates.row,
                    direction = "right"
                }
                checkConnect(coordenates, color)
            elseif value == 6 then
                coordenates = {
                    column = coordenates.column - 1,
                    row = coordenates.row,
                    direction = "left"
                }
                addPipeAnimation()
                checkConnect(coordenates, color)
            elseif value == 'E' then
                addPipeAnimation()
                local id = tonumber(gridData[coordenates.column][coordenates.row + 1].number)
                if answers[id].correct then
                    vibratePipes()
                    manager.correct()
                else
                    dropPipes()
                    manager.wrong({id = "text", text = correctAnswer, fontSize = 48})
                end
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row - 1,
                    direction = "up"
                }
                color = {0,1,0}
                checkConnect(coordenates, color)
            end
        elseif coordenates.direction == "up" then
            if value == 1 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row - 1,
                    direction = "up"
                }
                checkConnect(coordenates, color)
            elseif value == 3 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column + 1,
                    row = coordenates.row,
                    direction = "right"
                }
                checkConnect(coordenates, color)
            elseif value == 4 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column - 1,
                    row = coordenates.row,
                    direction = "left"
                }
                checkConnect(coordenates, color)
            end
        elseif coordenates.direction == "left" then
            if value == 2 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column - 1,
                    row = coordenates.row,
                    direction = "left"
                }
                checkConnect(coordenates, color)
            elseif value == 3 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row + 1,
                    direction = "down"
                }
                checkConnect(coordenates, color)
            elseif value == 5 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row - 1,
                    direction = "up"
                }
                checkConnect(coordenates, color)
            end
        elseif coordenates.direction == "right" then
            if value == 2 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column + 1,
                    row = coordenates.row,
                    direction = "right"
                }
                checkConnect(coordenates, color)
            elseif value == 4 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row + 1,
                    direction = "down"
                }
                checkConnect(coordenates, color)
            elseif value == 6 then
                addPipeAnimation()
                coordenates = {
                    column = coordenates.column,
                    row = coordenates.row - 1,
                    direction = "up"
                }
                checkConnect(coordenates, color)
            end
        end
    end
end

local function setDataToGrid(pipe)
    local options = pipe.options
    local column =  options.column - (math.round((pipe.spacingWidth - 1) * 0.5) + 1)
    local data = pipe.data
    for colIndex = 1, #data do
        column = column + colIndex - (colIndex - 1)
        local row = options.row - (math.round((pipe.spacingHeight - 1) * 0.5) + 1)
        for rowIndex = 1, #data[colIndex] do
            row = row + rowIndex - (rowIndex - 1)
            if gridData[column] and gridData[column][row] then
                local number = gridData[column][row].number
                if  number ~= 0 and data[colIndex][rowIndex] ~= 0 then
                    tileOccupied = true
                else
                    gridData[column][row].number = data[colIndex][rowIndex]
                    gridData[column][row].pipeIndex = pipe.pipeIndex
                end
            end
        end
    end
end

local function resetGrid()
    for cols = 1, NUMBER_COLUMNS do
        for rows = 1, NUMBER_ROWS do
            gridData[cols][rows].number = 0
            gridData[cols][rows].pipeIndex = 0
            local tile = gridData[cols][rows].tile
            tile.alpha = 0
        end
    end
    for pipeIndex = #pipeList, 1, -1 do
        local pipe = pipeList[pipeIndex]
        grid:insert(pipe)
        if pipe.options then
            setDataToGrid(pipe)
        end
    end
    checkConnect(startCoordenate, {1, 0, 0})
end

local function movePipes( event )
    local target = event.target
    if event.phase == "began" then
        tutorials.cancel(gameTutorial)
        display.getCurrentStage():setFocus( target )
        target.isFocus = true
        target.deltaX = event.x - target.x
        target.deltaY = event.y - target.y
        target.prevX = target.x
        target.prevY = target.y
        target.prevCol = target.referenceCol
        target.prevRow = target.referenceRow
        grid:insert(target)
        target.rotation = target.originalRotation
        pipeIndexSelected = target.pipeIndex
    elseif target.isFocus then
        if event.phase == "moved" then
            target.x = event.x - target.deltaX
            target.y = event.y - target.deltaY
        elseif event.phase == "ended" or event.phase == "cancelled" then
            display.getCurrentStage():setFocus( nil )
            target.isFocus = nil
            
            local colsMoved = math.round((target.prevX - target.x) / spacing)
            local rowsMoved = math.round((target.prevY - target.y) / spacing)
            target.referenceCol = target.referenceCol - colsMoved
            target.referenceRow = target.referenceRow - rowsMoved
            target.x = target.referenceCol * spacing - target.referenceWidth
            target.y = target.referenceRow * spacing - target.referenceHeight
            
            local centerColumn = math.round(NUMBER_COLUMNS / 2)
            local centerRow = math.round(NUMBER_ROWS / 2)
            local column = centerColumn + target.referenceCol
            local row = centerRow + target.referenceRow
            local options = {
                row = row,
                column = column
            }
            target.options = options
            
            resetGrid()
            if tileOccupied then
                tileOccupied = false
                target.referenceCol = target.prevCol
                target.referenceRow = target.prevRow
                target.x = target.prevX
                target.y = target.prevY
                column = centerColumn + target.referenceCol
                row = centerRow + target.referenceRow
                local options = {
                    row = row,
                    column = column
                }
                target.options = options
                resetGrid()
            end
            
--            local result = ""
--            for indexRow = 1, NUMBER_ROWS do
--                for indexCol = 1, NUMBER_COLUMNS do
--                    result = result .. gridData[indexCol][indexRow].number
--                end
--                result = result .. "\n"
--            end
--            logger.log(result)
        end
    end
    return true
end 

local function createPipes()
    
    textAnswers = {}
    for pipeIndex = 1, #PIPES do
        local pipeData = PIPES[pipeIndex]
        local pipe = display.newGroup()
        local pipeImage = display.newImageRect(pipeData.image, pipeData.width * spacing, pipeData.height * spacing)
        pipe:insert(pipeImage)
        grid:insert(pipe)
        pipe.rotation = pipeData.rotationImage
        pipe.originalRotation = pipeData.rotationImage
        pipe.spacingWidth = pipe.rotation > 0 and pipeData.height or pipeData.width
        pipe.spacingHeight = pipe.rotation > 0 and pipeData.width or pipeData.height
        pipe.referenceWidth = pipe.spacingWidth % 2 == 0 and spacing * 0.5 or 0
        pipe.referenceHeight = pipe.spacingHeight % 2 == 0 and spacing * 0.5 or 0
        local row = pipeData.position and pipeData.position.row or 0
        local column
        if pipeData.idQuestion then
            local sections = math.round(NUMBER_COLUMNS / NUMBER_QUESTIONS)
            column = - math.round(NUMBER_COLUMNS * 0.5) + math.round(sections * 0.5) + sections * (pipeData.idQuestion - 1)
            local textOptions = {
                text = "",
                x = 0,
                y = 0,
                font = settings.fontName,
                fontSize = 18,
                width = pipe.width - 80,
                height = 0,
                align = "center"
            }
            local textAnswer = display.newText(textOptions)
            textAnswer.y = 20
            textAnswer:setFillColor(1,0,0)
            pipe:insert(textAnswer)
            textAnswers[pipeData.idQuestion] = textAnswer
        else
            column = pipeData.position and pipeData.position.col or 0
        end
        pipe.referenceCol = column
        pipe.referenceRow = row
        pipe.pipeIndex = pipeIndex
        pipe.x = column * spacing - pipe.referenceWidth
        pipe.y = row * spacing - pipe.referenceHeight
        pipe.data = pipeData.data
        if pipeData.tutorial then
            pipeTutorial = {
                x = pipe.x + display.contentCenterX,
                y = pipe.y + display.contentCenterY
            }
        end
        
        local options = {
            row = math.round(NUMBER_ROWS/2) + row,
            column = math.round(NUMBER_COLUMNS/2) + column,
            referenceHeight = pipe.referenceWidth,
            referenceWidth = pipe.referenceHeight
        }
        pipe.options = options
        if not pipeData.edge then
            pipe:addEventListener("touch", movePipes)
        else
            pipe.edge = true
            if pipeData.start then
                local data = pipeData.data
                local startCol = options.column - (math.round((pipe.spacingWidth - 1) * 0.5) + 1)
                for colIndex = 1, #data do
                    startCol = startCol + colIndex - (colIndex - 1)
                    local startRow = options.row - (math.round((pipe.spacingHeight - 1) * 0.5) + 1)
                    for rowIndex = 1, #data[colIndex] do
                        startRow = startRow + rowIndex - (rowIndex - 1)
                        local number = tonumber(data[colIndex][rowIndex])
                        if  number == 1 then
                            startCoordenate = {column = startCol, row = startRow, direction = "down"}
                        end
                    end
                end
            end
        end
        pipeList[pipeIndex] = pipe
    end
    resetGrid()
--    local result = ""
--    for indexRow = 1, NUMBER_ROWS do
--        for indexCol = 1, NUMBER_COLUMNS do
--            result = result .. gridData[indexCol][indexRow].number
--        end
--        result = result .. "\n"
--    end
--    logger.log(result)
    
end

local function createBackground()
    local rectColor = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
    rectColor:setFillColor(unpack(COLOR_BACKGROUND))
    backgroundLayer:insert(rectColor)
    
    spacing = math.round((display.screenOriginY + display.viewableContentHeight) / NUMBER_ROWS)
--    NUMBER_COLUMNS = math.round((display.screenOriginX + display.viewableContentWidth) / spacing)
--    NUMBER_COLUMNS = NUMBER_COLUMNS % 2 == 0 and NUMBER_COLUMNS + 1 or NUMBER_COLUMNS
    grid = screen.newGrid(NUMBER_ROWS + 1, NUMBER_COLUMNS + 1, spacing)
    grid.x = display.contentCenterX
    grid.y = display.contentCenterY
    grid:setFillColor(unpack(COLOR_GRID))
    backgroundLayer:insert(grid)
    
    local leftSide = display.newImage(assetPath .. "ladrillos.png")
    leftSide.x = display.screenOriginX + grid.x - grid.width * 0.5 - leftSide.width * 0.5 + spacing * 0.5
    leftSide.y = display.contentCenterY
    backgroundLayer:insert(leftSide)
    
    local rightSide = display.newImage(assetPath .. "ladrillos.png")
    rightSide.x = display.viewableContentWidth - grid.x + grid.width * 0.5 + leftSide.width * 0.5 - spacing * 0.5
    rightSide.y = display.contentCenterY
    backgroundLayer:insert(rightSide)
    
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	manager = event.parent
    
    objectEditing = nil
    moveFlag = false
    for cols = 1, NUMBER_COLUMNS do
        for rows = 1, NUMBER_ROWS do
            gridData[cols][rows].number = 0
            gridData[cols][rows].tile.alpha = 0
        end
    end
    pipeList = {}
    correctAnswer = params.answer
    answers = {
        [1] = {
            text = params.answer,
            correct = true
        }
    }
        
    for index = 1, #params.wrongAnswers do
        local wrongAnswer = params.wrongAnswers[index]
        answers[#answers + 1] = {
            text = wrongAnswer,
            correct = false
        }
    end
    
    answers = extratable.shuffle(answers)

	questionText.text = params.question
    pipeAnimation.xScale = 1
    pipeAnimation.yScale = 1
    pipeAnimation.x = 0
    pipeAnimation.y = 0
end

local function tutorial()
	if isFirstTime then
        local tutorialToX = grid.x + (startCoordenate.column * spacing) * 0.5 - HAND_OFFSET
        local tutorialToY = startCoordenate.row * spacing
		local tutorialOptions = {
            iterations = 4,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1400, time = 1600, x = pipeTutorial.x, y = pipeTutorial.y, toX = tutorialToX, toY = tutorialToY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function onKeyEvent( event )
	if event.phase == "down" then -- TODO add mac support
		if event.keyName == "space" or event.nativeKeyCode == 49 then
			moveFlag = not moveFlag
            if moveFlag then
                editingText = display.newText("Editor on", display.contentCenterX, display.contentCenterY, native.systemFontBold, 18)
            else
                display.remove(editingText)
            end
        end    
		if objectEditing then
			if event.keyName == "down" or event.nativeKeyCode == 125 then
			objectEditing.y = objectEditing.y + MOVE_PIXELS
			elseif event.keyName == "up" or event.nativeKeyCode == 126 then
				objectEditing.y = objectEditing.y - MOVE_PIXELS
			elseif event.keyName == "left" or event.nativeKeyCode == 123 then
				objectEditing.x = objectEditing.x - MOVE_PIXELS
			elseif event.keyName == "right" or event.nativeKeyCode == 124 then
				objectEditing.x = objectEditing.x + MOVE_PIXELS
			elseif event.keyName == "p" then
				logger.log("[Comic] Offset x with contentCenterX " .. display.contentCenterX + objectEditing.x)
				logger.log("[Comic] Offset y with contentCenterY " .. display.contentCenterY + objectEditing.y)
                logger.log("Width " .. objectEditing.width)
                logger.log("Height " .. objectEditing.height)
                logger.log("scale " .. objectEditing.xScale)
            elseif event.keyName == "d" then
                objectEditing.width = objectEditing.width + 10
            elseif event.keyName == "a" then
                objectEditing.width = objectEditing.width - 10
            elseif event.keyName == "w" then
                objectEditing.height = objectEditing.height + 10
            elseif event.keyName == "s" then
                objectEditing.height = objectEditing.height - 10
            elseif event.keyName == "-" then
                objectEditing.xScale = objectEditing.xScale - 0.1
                objectEditing.yScale = objectEditing.yScale - 0.1
            elseif event.keyName == "=" then
                objectEditing.xScale = objectEditing.xScale + 0.1
                objectEditing.yScale = objectEditing.yScale + 0.1
            end
        end
	end
	
    return false
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		correctDelay = 1200,
		wrongDelay = 1200,
		
		name = "Geo Pipe Maze",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "question", amount = 1},
			{id = "wrongAnswer", amount = 2},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	backgroundLayer = display.newGroup()
	sceneView:insert(backgroundLayer)
    
    createBackground()
    
    pipeAnimation = display.newGroup()
    grid:insert(pipeAnimation)
    
    tilesLayer = display.newGroup()
    tilesLayer.x = display.contentCenterX
    tilesLayer.y = display.contentCenterY
	sceneView:insert(tilesLayer)
    
    local questionGroup = display.newGroup()
    questionGroup.x = display.contentCenterX
    questionGroup.y = display.screenOriginY + 60
    sceneView:insert(questionGroup)
    
    local questionBg = display.newImage(assetPath .. "pregunta.png")
    questionGroup:insert(questionBg)
    
    questionText = display.newText("", 0, -5, settings.fontName, SIZE_FONT)
	questionGroup:insert(questionText)
    
    questionGroup:addEventListener("touch", moveObject)
    
    gridData = {}
    for cols = 1, NUMBER_COLUMNS do
        gridData[cols] = {}
        for rows = 1, NUMBER_ROWS do
            local tile = display.newRect(0,0, spacing, spacing)
            tile:setFillColor(1, 0, 0)
            local centerColumn = math.round(NUMBER_COLUMNS / 2)
            local centerRow = math.round(NUMBER_ROWS / 2)
            local column = cols - centerColumn
            local row = rows - centerRow
            tile.x = column * spacing
            tile.y = row * spacing
            tile.alpha = 0
            tilesLayer:insert(tile)
            gridData[cols][rows] = {
                number = 0,
                pipeIndex = 0,
                tile = tile
            }
        end
    end
    
end

function game:destroy()

end


function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
        createPipes()
		setText()
        Runtime:addEventListener("key", onKeyEvent)
		tutorial()
        animatePipes()
    elseif phase == "did" then
        
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
        
	elseif phase == "did" then
		removeDynamicElements()
		tutorials.cancel(gameTutorial)
        transition.cancel(pipeAnimation)
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game


