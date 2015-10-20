----------------------------------------------- Gallery
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local extrastring = require( "libs.helpers.extrastring" )
local extrafile = require( "libs.helpers.extrafile" )
local colors = require( "libs.helpers.colors" )
local widget = require("widget")
local localization = require( "libs.helpers.localization" )
local screen = require( "libs.helpers.screen" )
local sound = require( "libs.helpers.sound" )
local creditsService = require("services.credits")

local scene = director.newScene() 
----------------------------------------------- Variables 
local grid, header
local currentSubject
local selectedMinigames
local params
local showUnavailable
local scrollViewLayer, scrollView
----------------------------------------------- Constants
local PADDING = 20
local PADDING_SIDES = 100
local COLOR_BACKGROUND_SCROLLVIEW = colors.convertFrom256({236,238,244})
local SIZE_IMAGE_THUMBNAIL = {width = 164 * 1.2, height = 128 * 1.2} 

local SHOW_GAME_NAMES = true
local SHOW_UNAVAILABLE_DEFAULT = true 

local PATH_IMAGES = "images/manager/gallery/"
local FILENAME_THUMBNAIL = "thumbnail.png"
local DIMENSIONS_THUMBNAILS = {widht = 95, height = 75}
local POSITIONS = {
	back = {
		x = display.screenOriginX + 84,
		y = display.screenOriginY + 84,
	},
	titulo = {
		y = screen.getPositionY(0.12),
	},
}
----------------------------------------------- Functions 
local function backReleased()
	sound.play("onboardingClick")
	creditsService.addCredits(1)
	director.gotoScene("scenes.minigames.subjects", {time = 600, effect = "fade", params = params})
end

local function createHeader(sceneGroup)
	display.remove(header)
	local headerOptions = {
		text = string.format(localization.getString("subjectMinigames"),extrastring.firstToUpper(localization.getString(currentSubject))),
		x = display.contentCenterX,
		y = display.screenOriginY + 70,
		font = settings.fontName,   
		fontSize = 42,
		align = "center"
	}

	header = display.newText(headerOptions)
	header:setFillColor(unpack(colors.white))
	sceneGroup:insert(header)
end

local function initialize(event)
	params = event.params or {}
	
	currentSubject = params.subject or ""
	if showUnavailable == nil then showUnavailable = SHOW_UNAVAILABLE_DEFAULT end
	
	local manager = require("scenes.minigames.manager")
	local allMinigames = manager.getMinigameDictionary()
	
	selectedMinigames = {}
	for index = 1, #allMinigames do
		local minigameData = allMinigames[index]
		
		if minigameData.category == currentSubject then
			if minigameData.available or showUnavailable then
				selectedMinigames[#selectedMinigames + 1] = minigameData
			end
		end
	end
end


local function createThumbnails()
	local maxRows = math.floor((scrollView.height - PADDING) / (SIZE_IMAGE_THUMBNAIL.height + PADDING))
	local startY = (scrollView.height - (maxRows * SIZE_IMAGE_THUMBNAIL.height + (maxRows - 1) * PADDING)) * 0.5

	local totalColumns = math.ceil(#selectedMinigames / maxRows)
	local totalWidth = PADDING + (totalColumns * (SIZE_IMAGE_THUMBNAIL.width + PADDING)) + PADDING_SIDES * 2
	local fillerRect = display.newRect(0, 0, totalWidth, scrollView.height)
	fillerRect.anchorX = 0
	fillerRect.anchorY = 0
	fillerRect.isVisible = false
	scrollView:insert(fillerRect)
	
	local currentThumbnailIndex = 0
	for indexColumn = 1, totalColumns do
		for indexRow = 1, maxRows do
			if currentThumbnailIndex < #selectedMinigames then
				currentThumbnailIndex = currentThumbnailIndex + 1
				local thumbnail = display.newGroup()
				thumbnail.x = PADDING_SIDES + PADDING + SIZE_IMAGE_THUMBNAIL.width * 0.5 + (indexColumn - 1) * (SIZE_IMAGE_THUMBNAIL.width + PADDING)
				thumbnail.y = startY + (indexRow - 1) * (SIZE_IMAGE_THUMBNAIL.height + PADDING) + SIZE_IMAGE_THUMBNAIL.height * 0.5
				thumbnail.index = currentThumbnailIndex
				thumbnail.data = selectedMinigames[currentThumbnailIndex]
				scrollView:insert(thumbnail)
				
				local iconFrame = display.newImageRect(PATH_IMAGES.."iconframe.png", SIZE_IMAGE_THUMBNAIL.width, SIZE_IMAGE_THUMBNAIL.height)
				thumbnail:insert(iconFrame)

				local thumbnailPath = string.gsub(string.sub(thumbnail.data.requirePath,1,-5),"[%.]","/")

				pcall(function()
					local filePath = thumbnailPath..FILENAME_THUMBNAIL
					if extrafile.exists(filePath) then
						local iconImage = display.newImageRect(filePath, DIMENSIONS_THUMBNAILS.widht, DIMENSIONS_THUMBNAILS.height)
						if iconImage then
							thumbnail:insert(iconImage)
						end
					end
				end)

				if not thumbnail.data.available then
					local unavailableTextOptions = {
						text = "UNAVAILABLE",	 
						font = settings.fontName,   
						fontSize = 22,
					}
					local unavailableText = display.newText(unavailableTextOptions)
					unavailableText:setFillColor(unpack(colors.orange))
					thumbnail:insert(unavailableText)
				end
				
				if SHOW_GAME_NAMES then
					local nameTextOptions = {
						x = 0, 
						y = 50,
						text = thumbnail.data.folderName,	 
						font = settings.fontName,   
						fontSize = 22,
					}
					local nameText = display.newText(nameTextOptions)
					nameText:setFillColor(unpack(colors.white))
					thumbnail:insert(nameText)
				end
				
				local function thumbnailTapped(event)
					params = params or {}
					sound.play("onboardingClick")
					params.minigames = {thumbnail.data.folderName, thumbnail.data.folderName}
					params.nextScene = "scenes.minigames.subjects"
					director.gotoScene("scenes.minigames.manager", {params = params, effect = "fade", time = 500})
				end
				thumbnail:addEventListener("tap", thumbnailTapped)
			end
		end
	end
	
	if totalWidth > display.viewableContentWidth then
		scrollView:scrollToPosition({x = -totalWidth + display.viewableContentWidth, time = 0, onComplete = function()
			scrollView:scrollToPosition({x = 0, time = 500})
		end})
	end
end

local function createScrollview()
	display.remove(scrollView)
	local scrollViewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight - 100,
		hideBackground = true,
		verticalScrollDisabled = true,
		isBounceEnabled = true,
	}
	
	scrollView = widget.newScrollView(scrollViewOptions)
	scrollViewLayer:insert(scrollView)
end
----------------------------------------------- Module functions 
function scene.showUnavailable(show)
	showUnavailable = show
end

function scene:create(event)
	local sceneView = self.view
	
	local bg = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	bg:setFillColor(unpack(colors.convertFromHex("00a4e4")))
	sceneView:insert(bg)

	scrollViewLayer = display.newGroup()
	sceneView:insert(scrollViewLayer)
	
	local buttonOptions = {
		width = 128,
		height = 128,
		defaultFile = "images/manager/gallery/back1.png",
		overFile = "images/manager/gallery/back2.png",
		onRelease = backReleased,
	}

	local buttonBack =  widget.newButton(buttonOptions)
	buttonBack.x = display.screenOriginX + 70
	buttonBack.y = display.screenOriginY + 70
	sceneView:insert(buttonBack)
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		initialize(event)
		createScrollview()
		createThumbnails()
		
		createHeader(sceneGroup)
	elseif phase == "did" then
	
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		
	elseif ( phase == "did" ) then
		display.remove(header)
		display.remove(grid)
	end
end
----------------------------------------------- Execution
scene:addEventListener( "create" )
scene:addEventListener( "destroy" )
scene:addEventListener( "hide" )
scene:addEventListener( "show" )

return scene
