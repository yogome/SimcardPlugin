--------------------------------------------- Sopa de letras
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )
local extratable = require( "libs.helpers.extratable" )
local settings = require( "settings" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )

local game = director.newScene()

-- START VARIABLES --

local manager
local isFirstTime
local crayonGroup, innerGroup
local sortedWordList
local individualWord
local individualLetter
local myTouchListener
local randomFlag
local shuffledNumbers
local randomGuide
local savedLetter
local selectedWord
local correctAnswers
local correctFlag
local instructions
local instance, instanceManager
local gameTutorial, tutorialX, tutorialY
local wordSize, tileSize
local words, shuffledWordTable, shuffledWordList
local answerGroup, answerSpaceGroup
local event1Flag, eventXCalc1, eventXCalc2, eventYCalc1, eventYCalc2, cheaterFlag
local managerGroup

-- START CONSTANTS --

local BACKGROUND_COLOR = { 242/255, 200/255, 95/255 }
local WORD_FONT_COLOR = { 57/255, 108/255, 23/255 }
local TUTORIAL_INSTRUCTIONS_FONT_COLOR = { 178/255, 110/255, 0/255 }
local LETTER_FONT_COLOR = { 57/255, 88/255, 129/255 }
local FONT_NAME = settings.fontName
local LETTERS = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}
local L1MAP = {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}}
			   
local L2MAP = {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
			   {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}}

local WORD_NUMBER = 5

------------------------------------- START FUNCTIONS --------------------------------------

local function sortWords()		
	table.sort(shuffledWordList, function(a,b) return #a.word < #b.word end)
	for i,v in ipairs(shuffledWordList) do
		table.insert(sortedWordList, v.word)
	end
end

local function randomGenerator()
	if randomFlag == false then	
		local NUMBERS = {1,2,3,4,5,6,7,8,9}

		local random1 = math.random(9)
		local random2 = math.random(9)
		NUMBERS[random1], NUMBERS[random2] = NUMBERS[random2], NUMBERS[random1]

		for i = 1, WORD_NUMBER do
			table.insert( shuffledNumbers, NUMBERS[i] )
		end

		randomFlag = true
	end
end

local function breakDownAndPlace()
	local xPosition = math.random(1, 9 - string.len(individualWord) + 1)
	local yPosition = shuffledNumbers[randomGuide]
	if not tutorialX then
		tutorialX, tutorialY = xPosition, yPosition
		wordSize = string.len(individualWord)
	end
	
		if(L1MAP[yPosition][xPosition] == 0) then
			for indexLetter = 1, string.len(individualWord) do 
				individualLetter[1] = string.sub(individualWord, indexLetter, indexLetter)
				L1MAP[yPosition][xPosition] = individualLetter[1]
				L2MAP[yPosition][xPosition] = individualLetter[1]
				xPosition = xPosition + 1
			end
		end
	randomGuide = randomGuide + 1
end

local function sendToTheShredder()	
	for innerIndex = 1, WORD_NUMBER do
		individualWord = sortedWordList[innerIndex]	
		randomGenerator()
		breakDownAndPlace()
	end
end

local function resetMatrix()
	for i = 1, 9 do
		for j = 1, 9 do
			L1MAP[j][i] = 0
			L2MAP[j][i] = 0
		end
	end
end

local function generateManagerWrongAnswer()
	for i = 1, 9 do
		instanceManager[i] = {}
		for j = 1, 9 do	
			local tfi = display.newImage(assetPath .. "letras.png")
			instanceManager[i][j] = display.newText('', 0, 0, FONT_NAME, 32)
			instanceManager[i][j]:setFillColor(unpack(LETTER_FONT_COLOR))
			
			tfi.width = 66
			tfi.height = 66
			tileSize = tfi.width
			tfi.x = math.floor(display.contentCenterX * 0.17 + (67 * i) - 400)
			tfi.y = math.floor(display.contentCenterY * 0.21 + (67 * j) - 320)
			
			instanceManager[i][j].width = 66
			instanceManager[i][j].height = 66
			instanceManager[i][j].x = math.floor(display.contentCenterX * 0.17 + (67 * i) - 400)
			instanceManager[i][j].y = math.floor(display.contentCenterY * 0.21 + (67 * j) - 320)
			
			if(L2MAP[j][i] == 0) then
				L2MAP[j][i] = " "
			end
			
			instanceManager[i][j].text = L2MAP[j][i]
			
			managerGroup:insert(tfi)
			managerGroup:insert(instanceManager[i][j])
		end
	end
	
	managerGroup:scale(.45, .45)
end

local function createSoupSpace()
	for i = 1, 9 do
		instance[i] = {}
		for j = 1, 9 do			
			local tfi = display.newImage(assetPath .. "letras.png")
			local tfactive = display.newImage(assetPath .. "activo.png")
			instance[i][j] = display.newText('', 0, 0, FONT_NAME, 32)
			instance[i][j]:setFillColor(unpack(LETTER_FONT_COLOR))
			
			tfi.width = 66
			tfi.height = 66
			tileSize = tfi.width
			tfi.x = math.floor(display.contentCenterX * 0.17 + (67 * i))
			tfi.y = math.floor(display.contentCenterY * 0.21 + (67 * j))
			
			tfactive.width = 66
			tfactive.height = 66
			tfactive.x = math.floor(display.contentCenterX * 0.17 + (67 * i))
			tfactive.y = math.floor(display.contentCenterY * 0.21 + (67 * j))
			
			instance[i][j].width = 66
			instance[i][j].height = 66
			instance[i][j].x = math.floor(display.contentCenterX * 0.17 + (67 * i))
			instance[i][j].y = math.floor(display.contentCenterY * 0.21 + (67 * j))
			
			if(L1MAP[j][i] == 0) then
				L1MAP[j][i] = LETTERS[math.floor(math.random() * table.maxn(LETTERS))+1]
			end
				 			
			instance[i][j].text = L1MAP[j][i]
			innerGroup:insert(tfi)
			innerGroup:insert(tfactive)
			tfactive.isVisible = false
			
			function myTouchListener(event)					
				if event.phase == "began" then				
				tutorials.cancel(gameTutorial,300)
				
				elseif event.phase == "moved" then
					if instance[i][j].text ~= savedLetter and instance[i][j].text ~= nil and tfactive.hasBeenSelected ~= true then
						table.insert(selectedWord, instance[i][j].text)
						savedLetter = instance[i][j].text
						sound.play("flipCard")
						
						if event1Flag == true then
							eventXCalc1 = event.target.x
							eventYCalc1 = event.target.y
							event1Flag = false
						elseif event1Flag == false then
							eventXCalc2 = event.target.x
							eventYCalc2 = event.target.y
							event1Flag = true
						end
						
						if eventXCalc2 - eventXCalc1 > 67 or eventYCalc2 - eventYCalc1 > 67 then
							cheaterFlag = true
							print("CHEAT")
						end
						
						tfactive.isVisible = true
						tfactive.hasBeenSelected = true
						tfi:removeEventListener("touch", myTouchListener)
					end

				elseif event.phase == "ended" then						
					for i = 1, WORD_NUMBER do
						if table.concat(selectedWord) == shuffledWordList[i].word and cheaterFlag ~= true then
							sound.play("pop")
							correctAnswers = correctAnswers + 1
							selectedWord = {}
							correctFlag = true
						elseif table.concat(selectedWord) ~= shuffledWordList[i].word and cheaterFlag == true and correctFlag == false or correctFlag == nil then
							correctFlag = false
						end
					end
					
					if correctAnswers == WORD_NUMBER then
						manager.correct()
						for i = 1, 9 do
							for j = 1, 9 do
								display.remove(instance[i][j])
							end
						end
						resetMatrix()
						
					elseif correctFlag == false and selectedWord ~= nil then
						generateManagerWrongAnswer()
						director.to(scenePath, managerGroup, {delay = 400, time = 1000, isVisible = true}) 
						manager.wrong({id = "group", group = managerGroup, fontSize = 32})
						for i = 1, 9 do
							for j = 1, 9 do
								display.remove(instance[i][j])
							end
						end
						resetMatrix()
					end	
					correctFlag = nil
					event1Flag = true
					eventXCalc1 = 0
					eventXCalc2 = 0
					eventYCalc1 = 0
					eventYCalc2 = 0
				end
			end
			
			tfi:addEventListener("touch", myTouchListener)
			innerGroup:insert(instance[i][j])
		end
	end
end

local function createAnswerSpace()	
	for i = 1, WORD_NUMBER do
		local options = 
		{
			text = shuffledWordList[i].word,	 
			x = display.viewableContentWidth * 0.86,
			y = display.viewableContentHeight * i * 0.06,
			width = 330,
			height = 140,
			font = FONT_NAME,   
			fontSize = 21,
			align = "center"
		}

		local wordText = display.newText(options)
		wordText:setFillColor(unpack(WORD_FONT_COLOR))

		answerGroup:insert(wordText)
		answerGroup:toFront()
	end
	
	answerGroup.y = display.viewableContentHeight * .25
end

local function createCrayons()
	local greenCrayon = display.newImage(assetPath .. "lapiz1.png")
	greenCrayon.x = display.viewableContentWidth * 0.8
	greenCrayon.y = display.viewableContentHeight * 0.75
	greenCrayon.xScale = 0.75
	greenCrayon.yScale = 0.75
	crayonGroup:insert(greenCrayon)

	local redCrayon = display.newImage(assetPath .. "lapiz2.png")
	redCrayon.x = display.viewableContentWidth * 0.85
	redCrayon.y = display.viewableContentHeight * 0.91
	redCrayon.xScale = 0.75
	redCrayon.yScale = 0.65
	redCrayon.rotation = 265
	crayonGroup:insert(redCrayon)

	local blueCrayon = display.newImage(assetPath .. "lapiz3.png")
	blueCrayon.x = display.viewableContentWidth * 0.89
	blueCrayon.y = display.viewableContentHeight * 0.73
	blueCrayon.xScale = 0.75
	blueCrayon.yScale = 0.70
	blueCrayon.rotation = 200
	crayonGroup:insert(blueCrayon)
end

local function shuffleWordTable()
	shuffledWordTable = {
		[1] = {word = words[1], id = 1},
		[2] = {word = words[2], id = 2},
		[3] = {word = words[3], id = 3},
		[4] = {word = words[4], id = 4},
		[5] = {word = words[5], id = 5},
	}
	
	shuffledWordTable = extratable.shuffle(shuffledWordTable)
	
	for index = 1, WORD_NUMBER do
		shuffledWordList[index] = shuffledWordTable[index]
	end	
end

local function createAnswerSpaceImage()	
	local answerSpace = display.newImage(assetPath .. "opciones.png")
	answerSpace.x = display.viewableContentWidth * 0.85
	answerSpace.y = display.viewableContentHeight * 0.35
	answerSpace.xScale = 0.90
	answerSpace.yScale = 0.95
	
	answerSpaceGroup:insert(answerSpace)
end

local function initialize(parameters)
	local sceneView = game.view

	parameters = parameters or {}
	
	isFirstTime = parameters.isFirstTime

	instructions.text = localization.getString("instructionsSopadeletras_0012")

	display.remove(innerGroup)
	innerGroup = display.newGroup()
	sceneView:insert(innerGroup)
	
	display.remove(answerSpaceGroup)
	answerSpaceGroup = display.newGroup()
	sceneView:insert(answerSpaceGroup)
	
	display.remove(answerGroup)
	answerGroup = display.newGroup()
	sceneView:insert(answerGroup)
	
	display.remove(managerGroup)
	managerGroup = display.newGroup()
	managerGroup.isVisible = false
	
	words = parameters.words

	correctAnswers = 0
	
	shuffledWordTable = {}
	shuffledWordList = {}
	
	sortedWordList = {}
	individualWord = {}
	individualLetter = {}
	selectedWord = {}
	shuffledNumbers = {}
	instance = {}
	instanceManager = {}
	
	cheaterFlag = nil
	correctFlag = nil
	randomFlag = false
	randomGuide = 1
	
	event1Flag = true
	eventXCalc1 = 0
	eventXCalc2 = 0
	eventYCalc1 = 0
	eventYCalc2 = 0
	
	shuffleWordTable()
	sortWords()
	sendToTheShredder()
	createAnswerSpaceImage()
	createAnswerSpace()
	createSoupSpace()
end

local function tutorial()
	if isFirstTime then 
		local tutoX = instance[tutorialX][tutorialY].x
		local tutoY = instance[tutorialX][tutorialY].y
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = tutoX, y = tutoY, toX = tutoX+(tileSize*wordSize), toY = tutoY},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

-------------------------------------- END FUNCTIONS ---------------------------------------

---------------------------------- START CLASS FUNCTIONS -----------------------------------

function game.getInfo()
	return {
		-- TODO check requires
		-- TODO answers in spanish, has bug where you drag outside the puzzle
		available = false,
		correctDelay = 400,
		wrongDelay = 400,
		
		name = "Sopa de letras",
		category = "geography",
		subcategories = {"universe"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {
			{id = "words", amount = 5, maxLength = 9},
		},
	}
end

function game:create(event)
	local sceneGroup = self.view

	local background = display.newRect( display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor( unpack( BACKGROUND_COLOR ) )
	sceneGroup:insert(background)
	
	crayonGroup = display.newGroup()
	sceneGroup:insert(crayonGroup)
	
	local instructionsOptions = 
	{
		text = "",	 
		x = display.contentCenterX * 0.75,
		y = display.viewableContentHeight * 0.10,
		font = FONT_NAME,   
		fontSize = 24,
		align = "center"
	}
	
	instructions = display.newText(instructionsOptions)
	instructions:setFillColor(unpack(TUTORIAL_INSTRUCTIONS_FONT_COLOR))
	sceneGroup:insert(instructions)
	
	createCrayons()
end

function game:show(event)
	local sceneGroup = self.view
	local phase = event.phase
		
	if ( phase == "will" ) then
		initialize(event.params)
		tutorial()
		manager = event.parent
	elseif ( phase == "did" ) then
	end
end

function game:destroy (event)

end

function game:hide ( event )
	local sceneGroup = self.view		
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then
		tutorialX = nil
		tutorials.cancel(gameTutorial)
		display.remove(innerGroup)
		display.remove(answerGroup)
		display.remove(answerSpaceGroup)
		resetMatrix()
		Runtime:removeEventListener("touch", myTouchListener)
	end
end

------------------------------------ END CLASS FUNCTIONS ------------------------------------

game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
-- END GAME TEMPLATE v1.0 --