----------------------------------------------- Empty scene
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local sound = require( "libs.helpers.sound" )
local director = require( "libs.helpers.director" )
local settings = require( "settings" )

local game = director.newScene() 
----------------------------------------------- Variables

local plate
local correctPieces
local categoryName
local categoryList
local language
local gameCompleted
local manager
local instructions
local gameTutorial
local isFirstTime

----------------------------------------------- Constants
local categoryData = {
	[1] = {name = { en = "fruits", id = "foodPlateFruits"}, x = -75, y = -69, textOffset = 40},
	[2] = {name = { en = "vegetables", id = "foodPlateVegetables"}, x = -75, y = 88, textOffset = -55},
	[3] = {name = { en = "grains", id = "foodPlateGrains"}, x = 82, y = -51, textOffset = 50},
	[4] = {name = { en = "protein", id = "foodPlateProtein"}, x = 81, y = 102, textOffset = -45},
	[5] = {name = { en = "dairy", id = "foodPlateDairy"}, x = 187, y = -140, textOffset = 0},
}

----------------------------------------------- Functions
function game:verifyState()
	if correctPieces >= 5 and not gameCompleted then
		gameCompleted = true
		manager.correct()
	end
end

local function drag( event )
	local piece = event.target
	if piece.canTouch then
		local phase = event.phase
		if "began" == phase then
			local parent = piece.parent
			parent:insert( piece )
			tutorials.cancel(gameTutorial, 300)
			display.getCurrentStage():setFocus( piece )

			sound.play("dragtrash")
			piece.isFocus = true
			piece.x0 = event.x - piece.x
			piece.y0 = event.y - piece.y
		elseif piece.isFocus then
			if "moved" == phase then
				piece.x = event.x - piece.x0
				piece.y = event.y - piece.y0
			elseif "ended" == phase or "cancelled" == phase then
				display.getCurrentStage():setFocus( nil )
				piece.isFocus = false
				sound.play("pop")
				local x,y = event.x,event.y

				local isInCategory = false
				local bounds = categoryData[piece.index]
				local isWithinBounds = display.contentCenterX + bounds.x - 70 <= x and display.contentCenterX + bounds.x + 70 >= x and display.contentCenterY +bounds.y - 70 <= y and display.contentCenterY +bounds.y + 70 >= y
				if isWithinBounds == true then
					isInCategory = true
					correctPieces = correctPieces + 1
					
					director.to(scenePath, piece, {time = 500, x = display.contentCenterX + bounds.x, y = display.contentCenterY + bounds.y, transition = easing.outQuad})
					game:verifyState()
					piece.canTouch = false
				end
			end
		end
	end

	return true
end

local function generatePlate(sceneView)
	display.remove(plate)
	plate = display.newGroup( )

	local plateBg = display.newImage(assetPath.."background.png")
	plateBg.xScale = 0.5
	plateBg.yScale = 0.5
	plateBg.x = display.contentCenterX + 35
	plateBg.y = display.contentCenterY
	plate:insert(plateBg)

	for index = 1, #categoryData do

		local categoryGroup = display.newGroup( )
		local category = display.newImage(assetPath..categoryData[index].name.en..".png")
		
		category.xScale = 0.5
		category.yScale = 0.5
		categoryGroup.index = index
		categoryGroup.x = display.contentCenterX + categoryData[index].x
		categoryGroup.y = display.contentCenterY + categoryData[index].y
		categoryGroup.x0 = categoryGroup.x
		categoryGroup.y0 = categoryGroup.y
		categoryGroup:insert(category)

		categoryName = display.newText(localization.getString(categoryData[index].name.id), (category.x), (category.y+categoryData[index].textOffset), settings.fontName, 20) 
		categoryGroup:insert(categoryName)
		
		plate:insert(categoryGroup)

		local randomX = display.contentCenterX + (math.random(1,2)*2 - 3) * math.random(260,(display.viewableContentWidth/2 - 80))
		local randomY = display.contentCenterY + math.random(-220,320)
		director.to(scenePath, categoryGroup, {delay = 500 + 100 * index, time = 800, y = randomY, transition = easing.outBack})
		director.to(scenePath, categoryGroup, {delay = 500 + 100 * index, time = 800, x = randomX, transition = easing.inOutQuad, onStart = function()
			categoryGroup.canTouch = true
		end})
		categoryGroup.randomX = randomX
		categoryGroup.randomY = randomY
		categoryList[#categoryList+1] = categoryGroup
		categoryGroup:addEventListener("touch", drag)
	end

	sceneView:insert( plate )
end

local function tutorial()
	if isFirstTime then
	
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.5,
			steps = {
				[1] = {id = "drag", delay = 1000, time = 2500, x = categoryList[1].randomX, y = categoryList[1].randomY, toX = categoryList[1].x0, toY = categoryList[1].y0},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
----------------------------------------------- Module functions
function game.getInfo()
	return {
		available = true,
		wrongDelay = 500,
		correctDelay = 600,
				
		name = "Food plate",
		category = "health",
		subcategories = {"myplate"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "puzzle",
		requires = {
			--{id = ""},
		},
	}
end

function game:create(event)
	local sceneView = self.view

	language = "es"

	local background = display.newImage(assetPath.."bg_1.png")
	local backgroundScale = display.viewableContentWidth / background.width
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	background.xScale = backgroundScale
	background.yScale = backgroundScale
	background.alpha = 0.9
	sceneView:insert(background)

	instructions = display.newText( "", display.contentCenterX, 50, settings.fontName, 40 )
	instructions:setFillColor( 0.05,0.04,0.29 )
	sceneView:insert(instructions)
end

function game:destroy()
	
end

function game:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		manager = event.parent
		local params = event.params or {}
		isFirstTime = params.isFirstTime
		
		categoryList = {}
		correctPieces = 0
		gameCompleted = false
		instructions.text = localization.getString("instructionsFoodplate")
		
		generatePlate(sceneView)
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
	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game

