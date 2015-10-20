----------------------------------------------- FoodTypes
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local widget = require( "widget" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables
local plate 
local difficulty 
local gemGroup
local totalGems
local gemsLeft
local foodArray
local categories
local language
local wrongAnswers
local firstGem = {}
local manager
local isFirstTime
local instructions
local gameTutorial
local categoryCount
local correctAnswerGroup
----------------------------------------------- Constantss
local CORRECT_PERCENTAGE = 0.8

local gemData = {
	[1] = {name = "Bananas", category = 1, language = false, },
	[2] = {name = "Cherry", category = 1, language = false, },
	[3] = {name = "Strawberry", category = 1, language = false, },
	[4] = {name = "Kiwi", category = 1, language = false, },
	[5] = {name = "Apple", category = 1, language = false, },
	[6] = {name = "Orange", category = 1, language = false, },
	[7] = {name = "Pear", category = 1, language = false, },
	[8] = {name = "Grapes", category = 1, language = false, },
	[9] = {name = "Broccoli", category = 2, language = false, },
	[10] = {name = "Mushroom", category = 2, language = false, },
	[11] = {name = "Corn", category = 2, language = false, },
	[12] = {name = "Lettuce", category = 2, language = false, },
	[13] = {name = "Carrot", category = 2, language = false, },
	[14] = {name = "Cereal", category = 3, language = false, },
	[15] = {name = "Rice", category = 3, language = false, },
	[16] = {name = "Spaghetti", category = 3, language = false, },
	[17] = {name = "Oatmeal", category = 3, language = false, },
	[18] = {name = "Cookie", category = 3, language = false, },
	[19] = {name = "Nut", category = 3, language = false, },
	[20] = {name = "Bread", category = 3, language = false, },
	[21] = {name = "Bean", category = 4, language = false, },
	[22] = {name = "Chicken", category = 4, language = false, },
	[23] = {name = "Egg", category = 4, language = false, },
	[24] = {name = "Salmon", category = 4, language = false, },
	[25] = {name = "Steak", category = 4, language = false, },
	[26] = {name = "Walnut", category = 4, language = false, },
	[27] = {name = "Cheese", category = 5, language = false, },
	[28] = {name = "Snowcone", category = 5, language = false, },
	[29] = {name = "Milk", category = 5, language = false, },
	[30] = {name = "FlavoredMilk", category = 5, language = false, },
	[31] = {name = "Yoghurt", category = 5, language = false, },
	[32] = {name = "Cheese", category = 5, language = false, },
}

local difficultyTable = {
	[1] = {gemsNumber = 8, categories = {1}, gems = {1,2,3,4,5,6,7,8}},
	[2] = {gemsNumber = 8, categories = {2}, gems = {9,10,11,12,13}},
	[3] = {gemsNumber = 8, categories = {3}, gems = {14,15,16,17,18,19,20}},
	[4] = {gemsNumber = 8, categories = {4}, gems = {21,22,23,24,25,26}},
	[5] = {gemsNumber = 8, categories = {5}, gems = {27,28,29,30,31,32}},
	[6] = {gemsNumber = 12, categories = {1,2,3,4,5}, gems = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32}},
}

local categoryData = {
	[1] = {name = { en = "fruits", id = "foodPlateFruits"}, x = -75, y = -69, textOffset = 40},
	[2] = {name = { en = "vegetables", id = "foodPlateVegetables"}, x = -75, y = 88, textOffset = -55},
	[3] = {name = { en = "grains", id = "foodPlateGrains"}, x = 82, y = -51, textOffset = 50},
	[4] = {name = { en = "protein", id = "foodPlateProtein"}, x = 81, y = 102, textOffset = -45},
	[5] = {name = { en = "dairy", id = "foodPlateDairy"}, x = 187, y = -140, textOffset = 0},
}

----------------------------------------------- Functions

local function generatePlate(sceneView)
	plate = display.newGroup( )

	local plateBg = display.newImage(assetPath.."types/background.png")
	plateBg.xScale = 0.5
	plateBg.yScale = 0.5
	plateBg.x = display.contentCenterX + 35
	plateBg.y = display.contentCenterY
	plate:insert(plateBg)

	categories = {}
	
	for index = 1, #categoryData do
		local category = display.newImage(assetPath.."types/"..categoryData[index].name.en..".png")

		category.categoryName = display.newText(localization.getString(categoryData[index].name.id), (display.contentCenterX+categoryData[index].x), (display.contentCenterY+categoryData[index].y+categoryData[index].textOffset), settings.fontName, 20) 

		category.xScale = 0.5
		category.yScale = 0.5
		category.index = index
		category.x = display.contentCenterX + categoryData[index].x
		category.y = display.contentCenterY + categoryData[index].y
		category:toFront( )
		plate:insert(category)
		plate:insert(category.categoryName)
		categories[index] = category
	end
	sceneView:insert( plate )
end

local function verifyState()
	if gemsLeft == 0 then
		if (wrongAnswers/totalGems) > (1 - CORRECT_PERCENTAGE) then
			director.to(scenePath, correctAnswerGroup, {delay = 500, time= 1000, alpha = 1})
			manager.wrong({id = "group", group = correctAnswerGroup, fontSize = 26})
		else
			manager.correct()
		end
	end
end

local function drag( event )
	local gem = event.target

	if gem.canTouch then
		local phase = event.phase
		if "began" == phase then
			local parent = gem.parent
			tutorials.cancel(gameTutorial, 300)
			parent:insert( gem )
			sound.play("dragtrash")
			display.getCurrentStage():setFocus( gem )

			gem.isFocus = true

			gem:setSequence("happy")
			gem:play()

			gem.x0 = event.x - gem.x
			gem.y0 = event.y - gem.y
		elseif gem.isFocus then
			if "moved" == phase then
				gem.x = event.x - gem.x0
				gem.y = event.y - gem.y0
			elseif "ended" == phase or "cancelled" == phase then
				display.getCurrentStage():setFocus( nil )
				gem.isFocus = false
				sound.play("pop")
				local x,y = event.x,event.y

				local isInCategory = false

				for index = 1, #categories do
					local category = categories[index]
					local bounds = category.stageBounds
					local isWithinBounds = bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
					if isWithinBounds == true then
						isInCategory = true
						if gem.category ~= category.index then
							gem:setSequence("sad")
							gem:play()
							wrongAnswers = wrongAnswers + 1
						else
						end
						gemsLeft = gemsLeft - 1
						
						gem.canTouch = false
						director.to(scenePath, gem, {alpha = 0, xScale = 0.05, yScale = 0.05, transition = easing.inQuad, onComplete = function()
							display.remove(gem)
							gem = nil
						end})	

						verifyState()
						break
					end
				end
				if not isInCategory then 
					gem:setSequence("idle")
					gem:play()
				end
			end
		end
	end
	return true
end

local function newGem(gemType)
	local gem = display.newGroup()
	local languageAx
	
	gem.gemType = gemType
	gem.category = gemData[gemType].category
	
	--categoryCount[gem.category] = categoryCount[gem.category] + 1
	
	local gemData = { width = 128, height = 128, numFrames = 32 }
	local gemSheet = graphics.newImageSheet( assetPath.."gems/gem_"..gemType..".png", gemData )
	if not gemSheet then
		if	 language == "pt" or language == "en" then
			languageAx = "en"
		else 
			languageAx = "es"
		end
		gemSheet = graphics.newImageSheet( assetPath.."gems/gem_"..gemType.."_"..languageAx..".png", gemData )
	end

	local gemAnimations = {
		{ name="idle", sheet = gemSheet, frames = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,1,2,3,4,5,6,7,8,9,10,11,12}, time = 2000 },
		{ name="happy", sheet = gemSheet, start = 17, count = 8, time = 600},
		{ name="sad", sheet = gemSheet, start = 25, count = 8, time = 600, loopCount = 0,},
	}

	local realGem = display.newSprite( gemSheet, gemAnimations )
	gem:insert( realGem )
	gem.xScale = 1
	gem.yScale = 1
	gem.sprite = realGem
	
	function gem:setSequence( sequence )
		self.sprite:setSequence(sequence)
	end

	function gem:play()
		self.sprite:play()
	end

	gem.addListener = gem.addEventListener
	
	function gem:addEventListener(eventName, listener)
		if eventName == "sprite" then
			self.sprite:addEventListener(eventName, listener)
		else
			self:addListener(eventName, listener)
		end
	end

	function gem:setFrame( frame )
		self.sprite:setFrame(frame)
	end

	return gem
end

local function createGems(sceneGroup, difficulty)
	display.remove(gemGroup)
	gemGroup = display.newGroup()
	sceneGroup:insert(gemGroup)
	totalGems = difficultyTable[difficulty].gemsNumber
	gemsLeft = totalGems

	foodArray = {}
	for index = 1, totalGems do
		local fruitId = math.random(1, #difficultyTable[difficulty].gems)
		local gem = newGem(difficultyTable[difficulty].gems[fruitId])
		gem.category = gemData[difficultyTable[difficulty].gems[fruitId]].category
		categoryCount[gem.category] = categoryCount[gem.category] + 1
		
		local answerGem = newGem(difficultyTable[difficulty].gems[fruitId])
		answerGem.category = gemData[difficultyTable[difficulty].gems[fruitId]].category
		
		if answerGem.category == 1 then
			answerGem.x = correctAnswerGroup.x + 60*categoryCount[gem.category]
			answerGem.y = correctAnswerGroup.y - 100
		elseif answerGem.category == 2 then
			answerGem.x = correctAnswerGroup.x + 60*categoryCount[gem.category]
			answerGem.y = correctAnswerGroup.y - 50
		elseif answerGem.category == 3 then
			answerGem.x = correctAnswerGroup.x + 60*categoryCount[gem.category]
			answerGem.y = correctAnswerGroup.y
		elseif answerGem.category == 4 then
			answerGem.x = correctAnswerGroup.x + 60*categoryCount[gem.category]
			answerGem.y = correctAnswerGroup.y + 50
		elseif answerGem.category == 5 then
			answerGem.x = correctAnswerGroup.x + 60*categoryCount[gem.category]
			answerGem.y = correctAnswerGroup.y + 100
		end
		answerGem.xScale = 0.5
		answerGem.yScale = 0.5
		correctAnswerGroup:insert(answerGem)
		
		gemGroup:insert(gem)
		gem:setSequence("idle")
		gem:play()
		gem.canTouch = false
		
		gem.x = display.contentCenterX + categoryData[gem.category].x + math.random(-50,50)
		gem.y = display.contentCenterY + categoryData[gem.category].y + math.random(-50,50)
		gem.xScale = 0.5
		gem.yScale = 0.5
		
		local randomX = display.contentCenterX + (math.random(1,2)*2 - 3) * math.random(260,display.viewableContentWidth/2 - 80)
		local randomY = display.contentCenterY + math.random(-220,320)
		director.to(scenePath, gem, {delay = 500 + 100 * index, time = 800, y = randomY, transition = easing.outBack})
		director.to(scenePath, gem, {delay = 500 + 100 * index, time = 800, x = randomX, xScale = 1, yScale = 1, transition = easing.inOutQuad, onStart = function()
			gem.canTouch = true
		end})

		if index == totalGems then
			firstGem[1] = randomX
			firstGem[2] = randomY
			firstGem[3] = display.contentCenterX + categoryData[gem.category].x
			firstGem[4] = display.contentCenterY + categoryData[gem.category].y
		end
		
		gem:addEventListener("touch", drag)
		
		foodArray[index] = gem
	end
end

local function tutorial()
	if isFirstTime then
	
		local tutorialOptions = {
			iterations = 4,
			scale = 0.6,
			parentScene = game.view,
			steps = {
				[1] = {id = "drag", delay = 2000, time = 3000, getObject = function() return foodArray[#foodArray] end, toX = firstGem[3], toY = firstGem[4]},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end

local function initialize(event)
	event = event or {}
	manager = event.parent
	local params = event.params or {}
	isFirstTime = params.isFirstTime
	difficulty = params.difficulty or 6
	wrongAnswers = 0
	language = localization.getLanguage()
	
	categoryCount = {}
	correctAnswerGroup = display.newGroup()
	correctAnswerGroup.alpha = 0
	correctAnswerGroup.y = correctAnswerGroup.y +30
	categoryCount = {}
	
	for index = 1, 5 do
		categoryCount[index] = 0
		
		local categoryText
		
		categories[index].categoryName.text = localization.getString(categoryData[index].name.id)
		categoryText = display.newText(localization.getString(categoryData[index].name.id), 0, correctAnswerGroup.y-10*index, settings.fontName, 26 )
		
		categoryText.x = correctAnswerGroup.x - 40
		
		if index < 3 then 
			categoryText.y = correctAnswerGroup.y - 50*index
		elseif index == 3 then
			categoryText.y = correctAnswerGroup.y
		else
			categoryText.y = correctAnswerGroup.y + 50*(index-3)
		end
		correctAnswerGroup:insert(categoryText)
	end
	
	instructions.text = localization.getString("instructionsFoodTypes")
end
----------------------------------------------- Module functions 
function game.getInfo()
	return {
		-- TODO check subcategory
		available = true,
		correctDelay = 300,
		wrongDelay = 300,
		
		name = "Food types",
		category = "health",
		subcategories = {"myplate"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "classify",
		requires = {
			{id = "foods", amount = 15, groups = 5},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	local background = display.newImage(assetPath.."bg_1.png")
	local backgroundScale = display.viewableContentWidth / background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = backgroundScale
	background.yScale = backgroundScale
	background.alpha = 0.9
	sceneView:insert(background)
	
	instructions = display.newText( "", display.contentCenterX, display.screenOriginY + 50, settings.fontName, 40 )
	instructions:setFillColor( 0.05,0.04,0.29 )
	sceneView:insert(instructions)

	plate = generatePlate(sceneView)

end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createGems(sceneGroup, difficulty)
		tutorial()
	elseif phase == "did" then
	
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
	
	elseif phase == "did" then
		tutorials.cancel(gameTutorial)
		--display.remove(correctAnswerGroup)
	end
end
----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game