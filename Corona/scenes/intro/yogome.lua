----------------------------------------------- Yogome logo intro
local director = require( "libs.helpers.director" )
local sound = require( "libs.helpers.sound" )

local game = director.newScene() 
----------------------------------------------- Variables
local logoSprite
local pitch
----------------------------------------------- Constants

----------------------------------------------- Functions
local function logoTapped()
	pitch = pitch + 0.1
	sound.setPitch(pitch)
end

local function initialize()
	pitch = 1
	logoSprite:setSequence("still")
	logoSprite:play()
	
	sound.playPitch("yogomekids", 1)
	transition.to(logoSprite, {time = 400, alpha = 1, transition = easing.outQuad, onComplete = function()
		logoSprite:setSequence("logo")
		logoSprite:play()
	end})
	
	transition.to(logoSprite, {delay = 2800, time = 800, alpha = 0, transition = easing.inQuad, onComplete = function()
		sound.stopPitch()
		director.gotoScene("scenes.menus.home", {effect = "fade", time = 600})
	end})
end
----------------------------------------------- Module functions 
function game:create(event)
	local sceneView = self.view
	
	local whiteRect = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	whiteRect:setFillColor(1)
	sceneView:insert(whiteRect)
	
	local logoSheet = graphics.newImageSheet("images/intro/yogologoanim.png", { width = 375, height = 150, numFrames = 40 })
	local logoSequenceData = {
		{ name = "still", sheet = logoSheet, start = 1, count = 1, time = 800, loopCount = 0},
		{ name = "logo", sheet = logoSheet, start = 1, count = 36, time = 2000, loopCount = 1},
	}
	logoSprite = display.newSprite(sceneView, logoSheet, logoSequenceData)
	logoSprite.xScale = 1.2
	logoSprite.yScale = 1.2
	logoSprite.x = display.contentCenterX
	logoSprite.y = display.contentCenterY
	
	logoSprite:addEventListener("tap", logoTapped)
	
	logoSprite:setSequence("still")
	logoSprite:play()
end

function game:destroy()
	
end

function game:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		initialize()
	elseif ( phase == "did" ) then
		
	end
end

function game:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	
	elseif ( phase == "did" ) then
		
	end
end

----------------------------------------------- Execution
game:addEventListener( "create", game )
game:addEventListener( "destroy", game )
game:addEventListener( "hide", game )
game:addEventListener( "show", game )

return game
