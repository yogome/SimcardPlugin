----------------------------------------------- Test minigame
local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local tutorials = require( "libs.helpers.tutorials" )
local widget = require( "widget" )
local colors = require( "libs.helpers.colors" )
local settings = require( "settings" )
local sound = require("libs.helpers.sound")

local game = director.newScene()
----------------------------------------------- Variables

local backgroundLayer
local answersLayer
local textLayer
local manager
local isFirstTime
local paintingImage
local gameLevel
local snapshot
local colorsGroup
local colorsList
local eraser
local gameTutorial
local topLayer
local drawingLayer
local colorsPosition
local previousX, previousY
local threshold = 0
local thresholdSq = threshold*threshold
local o
local fillColor
local instructionsText
local checkButton
----------------------------------------------- Constants
local mathRandom = math.random

local COLOR_BG = colors.convertFrom256({235, 237, 244})
local CIRCLE_RADIUS = 16

local levelSetUp = {
	[1] = {paintingImage = "oona.png",
		paintingColors = {
			[1] = colors.convertFrom256({236, 83, 135}),
			[2] = colors.convertFrom256({245, 219, 214}),
			[3] = colors.convertFrom256({255, 0, 0}),
			[4] = colors.convertFrom256({255, 224, 0}),
			[5] = colors.convertFrom256({141, 204, 50}),
			[6] = colors.convertFrom256({132, 165, 255}),
			[7] = colors.convertFrom256({191, 143, 58}),
			[8] = colors.convertFrom256({174, 222, 255})
		},
		answerImage = "oona_color.png"
	},
	[2] = {paintingImage = "oof.png",
		paintingColors = {
			[1] = colors.convertFrom256({0, 123, 214}),
			[2] = colors.convertFrom256({255, 170, 0}),
			[3] = colors.convertFrom256({255, 255, 0}),
			[4] = colors.convertFrom256({0, 204, 0}),
			[5] = colors.convertFrom256({255, 0, 0}),
			[6] = colors.convertFrom256({232, 206, 163}),
			[7] = colors.convertFrom256({168, 114, 36}),
			[8] = colors.convertFrom256({114, 72, 9}),
			[9] = colors.convertFrom256({242, 224, 136}),
		},
		answerImage = "oof_color.png"
	},
	[3] = {paintingImage = "dinamita.png",
		paintingColors = {
			[1] = colors.convertFrom256({255, 0, 0}),
			[2] = colors.convertFrom256({51, 204, 0}),
			[3] = colors.convertFrom256({255, 255, 0}),
			[4] = colors.convertFrom256({127, 81, 66}),
			[5] = colors.convertFrom256({237, 185, 143})
		},
		answerImage = "dinamita_color.png"
	}
}

local PADDING_COLORS = 70
----------------------------------------------- Functions
local function colorTapped(event)
	CIRCLE_RADIUS = 16
	local color = event.target
	
	sound.play("pop")
	
	if color.isActive then
		
	else
		eraser.x = eraser.originX
		eraser.isActive = false
		
		for index = 1, #colorsList do
			transition.cancel(colorsList[index])
			colorsList[index].x = colorsPosition
			colorsList[index].isActive = false
		end
		
		director.to(scenePath, color, {delay = 0, time = 300, x = color.x -40})
		color.isActive = true
		fillColor = color.color
	end
	return true
end

local function eraserTapped(event)
	CIRCLE_RADIUS = 32
	fillColor = colors.convertFrom256({255,255,255})
	
	sound.play("pop")
	
	if not event.target.isActive then
		event.target.isActive = true
		director.to(scenePath, event.target, {delay = 0, time = 300, x = eraser.x + 35})
	end
	
	for index = 1, #colorsList do	
		colorsList[index].x = colorsPosition
		colorsList[index].isActive = false
	end
end

local function draw( x, y )
	o = display.newCircle(x, y, CIRCLE_RADIUS)
	o:setFillColor(unpack(fillColor)) 

	snapshot.canvas:insert( o )
	snapshot:invalidate( "canvas" ) -- accumulate changes w/o clearing
end

local function checkDraw()
	sound.play("pop")
	
	local snapshotArea = snapshot.width * snapshot.height
	local paintedArea = 0
	local snapshotStartWidth = (snapshot.x - snapshot.width/2)
	local snapshotStartHeight = (snapshot.y - snapshot.height/2)
	local snapshotWidthSample = snapshot.width/10
	local snapshotHeightSample = snapshot.height/10
	local i, j
	
	local function onColorSample( event )
		if event.r ~= 1 or event.g ~= 1 or event.b ~= 1 then
			paintedArea = paintedArea + 1
			--print(paintedArea)
		end
	end
	
	for i=1, 10 do
		for j=1, 10 do
			local pixelSample = display.colorSample(snapshotStartWidth+(snapshotWidthSample*i), snapshotStartHeight+(snapshotHeightSample*j), onColorSample)
		end
	end
	
	if paintedArea >= 50 then
		manager.correct()
	else
		manager.wrong({id = "image", image = assetPath..levelSetUp[gameLevel].answerImage, xScale = 0.3, yScale = 0.3})
	end
end

local function listener( event )
	local x,y = event.x - snapshot.x, event.y - snapshot.y

	if ( event.phase == "began" ) then
		sound.play("dragtrash")
		previousX,previousY = x,y
		draw( x, y )
		tutorials.cancel(gameTutorial,300)
	elseif ( event.phase == "moved" ) then
		local dx = x - previousX
		local dy = y - previousY
		local deltaSq = dx*dx + dy*dy
		if ( deltaSq > thresholdSq ) then
			draw( x, y )
			previousX,previousY = x,y
		end
	end
end

local function setLevelImage()
	colorsGroup = display.newGroup ()
	backgroundLayer:insert(colorsGroup)
	
	colorsList = {}
	
	paintingImage = display.newImage(assetPath..levelSetUp[gameLevel].paintingImage)
	paintingImage.x = display.contentCenterX
	paintingImage.y = display.contentCenterY + 40
	topLayer:insert(paintingImage)
	
	local totalHeight = (#levelSetUp[gameLevel].paintingColors ) * PADDING_COLORS
	local startY = display.contentCenterY - totalHeight * 0.5 + 30
	
	for colorIndex = 1, #levelSetUp[gameLevel].paintingColors do
		local color = display.newGroup()
		local baseColor = display.newImage(assetPath.."color.png")
		baseColor:setFillColor(unpack(levelSetUp[gameLevel].paintingColors[colorIndex]))
		color:insert(baseColor)
		local colorDetails = display.newImage(assetPath.."base.png")
		colorDetails.x = colorDetails.x - 2
		color:insert(colorDetails)
		local colorNumber = display.newText(colorIndex, colorDetails.x + 10, colorDetails.y, settings.fontName, 26)
		colorNumber:setFillColor(colors.convertFrom256({0,0,0}))
		color:insert(colorNumber)
		color.x = display.viewableContentWidth - baseColor.width*0.2
		colorsPosition = color.x
		color.y = startY + (colorIndex - 1) * PADDING_COLORS
		color.color = levelSetUp[gameLevel].paintingColors[colorIndex]
		color.baseColor = baseColor.width
		color.isActive = false
		color:addEventListener("tap", colorTapped)
		colorsGroup:insert(color)
		colorsList[#colorsList + 1] = color
	end
end

local function initialize(event)
	event = event or {}
	local params = event.params or {}

	isFirstTime = params.isFirstTime
	gameLevel = params.level or mathRandom(1, 3)
	manager = event.parent
	eraser.x = eraser.originX
	setLevelImage()
	
	local w = paintingImage.width*0.895
	local h = paintingImage.height*0.845
	
	snapshot = display.newSnapshot( w, h)
	snapshot:translate(paintingImage.x-9, paintingImage.y-5)
	snapshot.canvasMode = "discard"
	drawingLayer:insert(snapshot)
	
	fillColor = colors.convertFrom256({255,255,255})
	
	Runtime:addEventListener( "touch", listener )
	instructionsText.text = localization.getString("instructionsPaintingGame")
	
	checkButton:setEnabled(true)
end

local function tutorial()
	if isFirstTime then
		local tutorialOptions = {
			iterations = 3,
			parentScene = game.view,
			scale = 0.7,
			steps = {
				[1] = {id = "tap",delay = 1500, time = 1500, x = colorsList[1].x, y = colorsList[1].y},
				[2] = {id = "drag", delay = 1500, time = 2500, x = display.contentCenterX - 100, y = display.contentCenterY, toX = display.contentCenterX + 100, toY = display.contentCenterY},
				[3] = {id = "drag", delay = 1500, time = 2500, x = display.contentCenterX + 100, y = display.contentCenterY + 50, toX = display.contentCenterX - 100, toY = display.contentCenterY + 50},
			}
		}
		gameTutorial = tutorials.start(tutorialOptions)
	end
end
---------------------------------------------
function game.getInfo()
	return {
		available = true,
		correctDelay = 400,
		wrongDelay = 400,		
		
		name = "Paint",
		category = "creativity",
		subcategories = {"colors"},
		age = {min = 0, max = 99},
		grade = {min = 0, max = 99},
		gamemode = "findAnswer",
		requires = {

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
	
	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	background:setFillColor(unpack(COLOR_BG))
	backgroundLayer:insert(background)
	
	local instructionsBg = display.newImage(assetPath.."instruction.png")
	instructionsBg.x = display.contentCenterX - 100
	instructionsBg.y = display.viewableContentHeight*0.06
	instructionsBg.width = display.viewableContentWidth
	backgroundLayer:insert(instructionsBg)
	
	local instructionsOptions = 
	{
		text = localization.getString("instructionsPaintingGame"),     
		x = instructionsBg.x,
		y = instructionsBg.y,
		width = instructionsBg.width*0.8, 
		font = settings.fontName,   
		fontSize = 24,
		align = "center" 
	}

	instructionsText =  display.newText( instructionsOptions )
	textLayer:insert(instructionsText)
	
	local whiteBg = display.newImage(assetPath.."whiteBg.png")
	whiteBg.x = display.contentCenterX
	whiteBg.y = display.contentCenterY + 40
	backgroundLayer:insert(whiteBg)
	
	local buttonOptions = {
		width = 128,
		height = 128,
		defaultFile = assetPath.."boton.png",
		overFile = assetPath.."boton2.png",
		onRelease = function()
			checkButton:setEnabled(false)
			checkDraw()
		end
	}

	checkButton =  widget.newButton(buttonOptions)
	checkButton.x = display.viewableContentWidth*0.1
	checkButton.y = display.viewableContentHeight*0.25
	checkButton:setEnabled(false)
	
	backgroundLayer:insert(checkButton)
	
	eraser = display.newImage(assetPath.."eraser.png")
	eraser.x = eraser.width*0.25
	eraser.y = display.viewableContentHeight*0.85
	eraser.originX = eraser.x
	eraser.isActive = false
	eraser:addEventListener("tap", eraserTapped)
	backgroundLayer:insert(eraser)
	
	drawingLayer = display.newGroup()
	sceneView:insert(drawingLayer)
	
	topLayer = display.newGroup()
	sceneView:insert(topLayer)
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
	end
end

function game:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
	elseif phase == "did" then
		display.remove(paintingImage)
		Runtime:removeEventListener("touch", listener)
		display.remove(snapshot)
		display.remove(colorsGroup)
		tutorials.cancel(gameTutorial)

	end
end

----------------------------------------------- Execution
game:addEventListener( "create" )
game:addEventListener( "destroy" )
game:addEventListener( "hide" )
game:addEventListener( "show" )

return game
