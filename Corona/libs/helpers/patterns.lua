-------------------------------------------- Patterns
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extrajson = require( folder.."extrajson" )
local director = require( folder.."director" )
local logger = require( folder.."logger" )
local colors = require( folder.."colors" )

local patterns = {}
-------------------------------------------- Variables
local loadedPatterns 
local initialized
local lastPattern
local captureMode
-------------------------------------------- Constants
local MODE_CAPTURE_DEFAULT = false 
local PATH_DATA = string.gsub(folder,"[%.]","/").."data/" 
local DEFAULT_SIZE_DETECTOR_BLOCKS = 25
local COLUMNS = 15
local ROWS = 20
local DEFAULT_PATTERNS_FILEPATH = PATH_DATA.."patterns.json"
-------------------------------------------- Local functions
local function onKeyEvent(event)
	if captureMode then
		if event.phase == "up" then
			lastPattern.value = event.keyName
			logger.log(lastPattern)
		end
	end
end

local function initialize()
	if not initialized then
		initialized = true
		
		loadedPatterns = {}
		patterns.loadPatternFile(DEFAULT_PATTERNS_FILEPATH, system.ResourceDirectory)
		
		captureMode = MODE_CAPTURE_DEFAULT
		Runtime:addEventListener("key", onKeyEvent)
	end
end

local function recognizePattern(event)
	local phase = event.phase
	local target = event.target
	if "began" == phase then
		display.getCurrentStage():setFocus( target, event.id )
		target.isFocus = true
		if target.timer then
			timer.cancel(target.timer)
			target.timer = nil
		end
	elseif target.isFocus then
		if "moved" == phase then
			target:activateBlock(event.x, event.y)
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( target, nil )
			target.isFocus = false
			
			if target.timer then
				timer.cancel(target.timer)
				target.timer = nil
			end
			target.timer = timer.performWithDelay(target.liftTime, function()
				local calculatedValue = target:calculatePattern()
				
				if target.onComplete and "function" == type(target.onComplete) then
					target.onComplete({value = calculatedValue, target = target})
				end
				target:resetBlocks()
			end)
		end
	end

	return true
end

local function lowerMatrixResolution(matrix, staticPatternRows, staticPatternColumns)
	local upscaledDrawnPattern = {}
	for row = 1, ROWS do
		local patternRow = math.ceil((staticPatternRows / ROWS) * row)
		upscaledDrawnPattern[patternRow] = upscaledDrawnPattern[patternRow] or {}
		for column = 1, COLUMNS do
			local patternColumn = math.ceil((staticPatternColumns / COLUMNS) * column)

			if matrix[row][column].isActive == 1 then
				if upscaledDrawnPattern[patternRow][patternColumn] ~= 1 then
					upscaledDrawnPattern[patternRow][patternColumn] = 1
				end
			else
				if upscaledDrawnPattern[patternRow][patternColumn] ~= 1 then
					upscaledDrawnPattern[patternRow][patternColumn] = 0
				end
			end
		end
	end
	return upscaledDrawnPattern
end

local function destroyPatternRecongniezer(event)
	if event.target.timer then
		timer.cancel(event.target.timer)
		event.target.timer = nil
	end
end

function patterns.newRecognizer(options)
	options = options or {}
	
	local width = options.width or (COLUMNS * DEFAULT_SIZE_DETECTOR_BLOCKS)
	local height = options.height or (ROWS * DEFAULT_SIZE_DETECTOR_BLOCKS)
	
	local defaultColor = options.defaultColor or {1,1,1,0.2}
	local drawColor = options.drawColor or colors.green
	local recognizedColor = options.recognizedColor or colors.red
	
	local halfWidth = width * 0.5
	local halfHeight = height * 0.5
	
	local recognizeGroup = display.newGroup()
	recognizeGroup.isHitTestable = true
	
	recognizeGroup.rects = {}
	recognizeGroup.debugRects = {}
	recognizeGroup.onComplete = options.onComplete
	recognizeGroup.liftTime = options.liftTime or 800
	
	local recognizeRectWidth = width / COLUMNS
	local recognizeRectHeight = height / ROWS
	
	for rowIndex = 1, ROWS do
		recognizeGroup.rects[rowIndex] = {}
		recognizeGroup.debugRects[rowIndex] = {}
		for columnIndex = 1, COLUMNS do
			local recognizeRect = display.newRect(recognizeGroup, -halfWidth + (columnIndex - 1) * recognizeRectWidth, -halfHeight + (rowIndex - 1) * recognizeRectHeight, recognizeRectWidth, recognizeRectHeight)
			recognizeRect:setFillColor(unpack(defaultColor))
			local debugRect = display.newRect(recognizeGroup, -halfWidth + (columnIndex - 1) * recognizeRectWidth, -halfHeight + (rowIndex - 1) * recognizeRectHeight, recognizeRectWidth, recognizeRectHeight)
			debugRect:setFillColor(unpack(defaultColor))
			debugRect.isHitTestable = true
			
			recognizeGroup.rects[rowIndex][columnIndex] = recognizeRect
			recognizeGroup.debugRects[rowIndex][columnIndex] = debugRect
		end
	end
	
	function recognizeGroup:activateBlock(xContent, yContent)
		local localX, localY = self:contentToLocal(xContent, yContent)
		local column = math.ceil((localX + halfWidth) / recognizeRectWidth)
		local row = math.ceil((localY + halfHeight) / recognizeRectHeight)
		
		column = (column <= 0 and 1) or (column > COLUMNS and COLUMNS) or column
		row = (row <= 0 and 1) or (row > ROWS and ROWS) or row
		
		recognizeGroup.rects[row][column]:setFillColor(unpack(drawColor))
		recognizeGroup.rects[row][column].isActive = 1
	end
	
	function recognizeGroup:calculatePattern()
		-- Upscale pattern
		
		local drawStartRow = ROWS
		local drawEndRow = 0
		
		local drawStartColumn = COLUMNS
		local drawEndColumn = 0
		
		for row = 1, ROWS do
			for column = 1, COLUMNS do
				if self.rects[row][column].isActive == 1 then
					if row < drawStartRow then
						drawStartRow = row
					end
					if row > drawEndRow then
						drawEndRow = row
					end
					
					if column < drawStartColumn then
						drawStartColumn = column
					end
					if column > drawEndColumn then
						drawEndColumn = column
					end
				end
			end
		end
		
		local totalDrawnHeight = drawEndRow - drawStartRow
		local totalDrawnWidth = drawEndColumn - drawStartColumn
		
		local rectsCopy = {}
		for row = 1, ROWS do
			rectsCopy[row] = {}
			for column = 1, COLUMNS do
				rectsCopy[row][column] = {isActive = self.rects[row][column].isActive}
				self.rects[row][column].isActive = 0
				self.debugRects[row][column]:setFillColor(unpack(defaultColor))
			end
		end
		
		local scaleWidth = false
		if totalDrawnWidth > (COLUMNS * 0.25) then
			scaleWidth = true
		end
		
		-- Upscale first
		for row = 1, ROWS do
			local patternRow = math.floor(drawStartRow + (row / ROWS) * totalDrawnHeight)
			for column = 1, COLUMNS do
				local patternColumn = scaleWidth and math.floor(drawStartColumn + (column / COLUMNS) * totalDrawnWidth) or column
				if rectsCopy[patternRow][patternColumn].isActive == 1 then
					self.rects[row][column].isActive = 1
					self.debugRects[row][column]:setFillColor(unpack(recognizedColor))
				end
			end
		end
		
		if captureMode then
			lastPattern = lowerMatrixResolution(self.rects, math.floor(ROWS * 0.4), math.floor(COLUMNS * 0.4))
		end

		-- Lower resolution
		local staticPatternRows = #loadedPatterns[1]
		local staticPatternColumns = #loadedPatterns[1][1]
		local upscaledDrawnPattern = lowerMatrixResolution(self.rects, staticPatternRows, staticPatternColumns)
		
		local maxScore = -math.huge
		local maxScorePatternIndex = 1
		
		-- Comparison
		for patternIndex = 1, #loadedPatterns do 
			local currentScore = 0
			local selectedPattern = loadedPatterns[patternIndex]
			for row = 1, #selectedPattern do
				for column = 1, #selectedPattern[row] do
					if upscaledDrawnPattern[row][column] == selectedPattern[row][column] then
						currentScore = currentScore + 1
					else
						currentScore = currentScore - 2
					end
				end
			end
			
			if currentScore > maxScore then
				maxScore = currentScore
				maxScorePatternIndex = patternIndex
			end
		end

		return loadedPatterns[maxScorePatternIndex].value
	end
	
	function recognizeGroup:resetBlocks()
		for row = 1, ROWS do
			for column = 1, COLUMNS do
				recognizeGroup.rects[row][column]:setFillColor(unpack(defaultColor))
				recognizeGroup.rects[row][column].isActive = 0
				
				recognizeGroup.debugRects[row][column]:setFillColor(unpack(defaultColor))
				recognizeGroup.debugRects[row][column].isActive = 0
			end
		end
	end
	
	recognizeGroup:addEventListener("touch", recognizePattern)
	recognizeGroup:addEventListener("finalize", destroyPatternRecongniezer)
	
	return recognizeGroup
end

function patterns.resetPatternList()
	
end

function patterns.loadPatternFile(filename, baseDir)
	baseDir = baseDir or system.DocumentsDirectory
	local path = system.pathForFile(filename, baseDir )
	
	local newPatternData = {}
	if pcall(function()
		local languageFile = io.open( path, "r" )
		local savedData = languageFile:read( "*a" )
		newPatternData = extrajson.decodeFixed(savedData)
		io.close(languageFile)
	end) then
		logger.log([[Read pattern data.]])
	else
		logger.error([[Pattern data file was not found.]])
	end
	
	if not newPatternData then
		logger.error([[Pattern data file contains no data.]])
	else
		for index = 1, #newPatternData do
			loadedPatterns[#loadedPatterns + 1] = newPatternData[index]
		end
	end
end

function patterns.setCaptureMode(enable)
	captureMode = enable and enable
end

function patterns.test()
	patterns.setCaptureMode(true)
	local testPatternScene = director.newScene("testPatternScene")
	function testPatternScene:create(event)
		local debugText = display.newText("", display.contentCenterX, display.contentCenterY, native.systemFont, 500)
		self.view:insert(debugText)
		
		local testPatternRecognizer = patterns.newRecognizer({
			defaultColor = {0,0,0,0},
			onComplete = function(event)
				event.target:resetBlocks()
				debugText.text = event.value
			end
		})
		testPatternRecognizer.x = display.contentCenterX
		testPatternRecognizer.y = display.contentCenterY
		self.view:insert(testPatternRecognizer)
	end
	testPatternScene:addEventListener("create")
	director.gotoScene("testPatternScene")
end

initialize()

return patterns