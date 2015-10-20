----------------------------------------------- Comic
local path = ... 
local folder = path:match("(.-)[^%.]+$")
local json = require( "json" ) 
local logger = require( folder.."logger" ) 
local director = require( folder.."director" )
local mixpanel = require( folder.."mixpanel" )
local uifx = require( folder.."uifx" )
local music = require( folder.."music" )
local sound = require( folder.."sound" )
local localization = require( folder.."localization" )
local widget = require( "widget" )

local comicLib = {}
----------------------------------------------- Variables 
local currentComic
local initialized

local objectEditing, moveFlag
----------------------------------------------- Constants
local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/"
local PATH_SOUNDS = string.gsub(folder,"[%.]","/").."sounds/"

local SOUNDS_COMIC = {
	[1] = {id = "popComic", path = PATH_SOUNDS.."pop.mp3"},
}

local MOVE_PIXELS = 5 
local NAME_APPEND_COMIC = "comic" 
local SIZE_BACKGROUND = 1024

local PLAY_BUTTON_OPTIONS = {
	width = 256, 
	height = 256, 
	defaultFile = PATH_IMAGES.."play_01.png", 
	overFile = PATH_IMAGES.."play_02.png", 
	onPress = function() sound.play("popComic") end
}

----------------------------------------------- module functions
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

local function removeVignettes(comic)
	local vignettesImages = comic.vignettesImages
	local vignettesImagesText = comic.vignettesImagesText
	
	for vignetteIndex = #vignettesImages, 1, -1 do
		display.remove(vignettesImages[vignetteIndex])
		vignettesImages[vignetteIndex] = nil
	end

	for vignetteTextIndex = #vignettesImagesText, 1, -1 do
		display.remove(vignettesImagesText[vignetteTextIndex])
		vignettesImagesText[vignetteTextIndex] = nil
	end
end

local function loadPage(comic, pageData)
	pageData = pageData or {}
	moveFlag = false
	local currentVignette = 1
	
	removeVignettes(comic)
	
	mixpanel.logEvent("ComicViewed", {page = comic.currentPage, name = comic.name})
	
	local vignettePositions = pageData.vignettePositions
	local backgroundColor = pageData.backgroundColor or {0}
	local backgroundImage = pageData.backgroundImage
	local comicPath = pageData.comicPath
	local textPositions = pageData.textPositions 
	
	local vignettesImages = comic.vignettesImages
	local vignettesImagesText = comic.vignettesImagesText
	
	local pageMusicTrack = pageData.musicTrack
	
	local function nextVignette()
		if comic.comicTimer then 
			timer.cancel(comic.comicTimer)
			comic.comicTimer = nil
		end
		if currentVignette <= #vignettePositions then
			local vignette = vignettesImages[currentVignette]
			transition.to(vignette, {time = 900, x = vignettePositions[currentVignette].final.x, y = vignettePositions[currentVignette].final.y, transition = easing.outElastic})
			if vignettesImagesText[currentVignette] then
				transition.to(vignettesImagesText[currentVignette], {time = 900, x = textPositions[currentVignette].final.x, y = textPositions[currentVignette].final.y, transition = easing.outElastic})
			end
			currentVignette = currentVignette + 1
			comic.comicTimer = timer.performWithDelay(2000, nextVignette)
		else
			transition.to(comic.playButton, {time = 400, alpha = 1, onComplete = function()
				uifx.applyBounceTransition(comic.playButton, {smallScale = 0.5, largeScale = 0.7, intervalTime = 800})
			end})
		end
	end
	
	local backgroundGroup = comic.backgroundGroup
	
	comic.playButton.alpha = 0
	comic.playButton.x = pageData.buttonPosition.x or display.contentCenterX
	comic.playButton.y = pageData.buttonPosition.y or display.contentCenterY
	
	local dynamicScale = display.viewableContentWidth / SIZE_BACKGROUND
	
	display.remove(comic.backgroundRect)
	comic.backgroundRect = display.newRect(backgroundGroup, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	comic.backgroundRect:addEventListener("tap", nextVignette)
	comic.backgroundRect:setFillColor(unpack(backgroundColor))
	
	display.remove(comic.background)
	if backgroundImage then
		local background = display.newImage(backgroundImage, true)
		background.xScale = dynamicScale
		background.yScale = dynamicScale
		background.x = display.contentCenterX
		background.y = display.contentCenterY
		
		backgroundGroup:insert(background)
		comic.background = background
	end
	
	for vignetteIndex = 1, #vignettePositions do
		local vignette = display.newGroup()
		vignette.x = vignettePositions[vignetteIndex].final.x
		vignette.y = vignettePositions[vignetteIndex].final.y
		local vignetteImage = display.newImage(string.format("images/%s/vignette%d.png", comicPath, vignetteIndex))
		backgroundGroup:insert(vignette)
		vignette:insert(vignetteImage)
		vignette:addEventListener("touch", moveObject)
		vignette.x = vignettePositions[vignetteIndex].initial.x
		vignette.y = vignettePositions[vignetteIndex].initial.y
		vignettesImages[vignetteIndex] = vignette
		
		local imageTextPath = localization.format("images/" ..comicPath .. "/text"..vignetteIndex.."_%s.png")
		local vignettesImageText = display.newImage(imageTextPath)
		if vignettesImageText then
			vignettesImageText.x = textPositions[vignetteIndex].initial.x
			vignettesImageText.y = textPositions[vignetteIndex].initial.y
			vignettesImageText:addEventListener("touch", moveObject)
			vignette:insert(vignettesImageText)
			vignettesImagesText[vignetteIndex] = vignettesImageText
		end
	end
	
	comic.comicTimer = timer.performWithDelay(500, nextVignette)
	if pageMusicTrack and "number" == type(pageMusicTrack) then
		music.playTrack(pageMusicTrack, 400)
	end
end

local function onKeyEvent( event )
	if event.phase == "down" then -- TODO add mac support
		if event.keyName == "space" then
			moveFlag = not moveFlag
			display.newText("Editor on", display.contentCenterX, display.contentCenterY, native.systemFontBold, 18)
		elseif objectEditing then
			if event.keyName == "down" then
			objectEditing.y = objectEditing.y + MOVE_PIXELS
			elseif event.keyName == "up" then
				objectEditing.y = objectEditing.y - MOVE_PIXELS
			elseif event.keyName == "left" then
				objectEditing.x = objectEditing.x - MOVE_PIXELS
			elseif event.keyName == "right" then
				objectEditing.x = objectEditing.x + MOVE_PIXELS
			elseif event.keyName == "p" and event.phase == "down" then
				logger.log("[Comic] Offset x with contentCenterX " .. display.contentCenterX - objectEditing.x)
				logger.log("[Comic] Offset y with contentCenterY " .. display.contentCenterY - objectEditing.y)
			end
		end
	end
	
    return false
end

local function initialize()
	if not initialized then
		initialized = true
		currentComic = 0
		if "simulator" == system.getInfo("environment") then
			Runtime:addEventListener( "key", onKeyEvent )
		end
		sound.loadSounds(SOUNDS_COMIC)
	end
end

function comicLib.newComic(options)
	options = options or {}
	
	currentComic = currentComic + 1
	local comicName = options.name or NAME_APPEND_COMIC..tostring(currentComic)
	
	local newComic = director.newScene(comicName)
	newComic.name = comicName
	newComic.loadPage = loadPage
	newComic.removeVignettes = removeVignettes
	
	newComic.vignettesImages = {}
	newComic.vignettesImagesText = {}
	newComic.pages = options.pages or {}
	newComic.currentPage = 1
	
	newComic.nextScene = options.nextScene
	newComic.nextSceneParameters = options.nextSceneParameters
	
	function newComic.setNextScene(sceneName, sceneParams)
		newComic.nextScene = sceneName
		newComic.nextSceneParameters = sceneParams
	end

	function newComic:create()
		local sceneView = self.view
		
		self.backgroundGroup = display.newGroup()
		sceneView:insert(self.backgroundGroup)

		PLAY_BUTTON_OPTIONS.onRelease = function()
			if self.pages[self.currentPage + 1] then
				self.currentPage = self.currentPage + 1
				self:loadPage(self.pages[self.currentPage])
			else
				director.gotoScene(self.nextScene, {time = 500, effect = "fade", params = self.nextSceneParameters})
			end
		end
		
		local playButton = widget.newButton(PLAY_BUTTON_OPTIONS)
		playButton.x = display.contentCenterX
		playButton.y = display.contentCenterY
		playButton.xScale = 0.6
		playButton.yScale = 0.6
		playButton:addEventListener("touch", moveObject)
		sceneView:insert(playButton)
		self.playButton = playButton
	end
	
	function newComic:show(event)
		if "will" == event.phase then
			self.currentPage = 1
			self:loadPage(self.pages[1])
			self.playButton:setEnabled(true)
		end
	end
	
	function newComic:hide(event)
		if "will" == event.phase then
			if self.comicTimer then timer.cancel(self.comicTimer) end
			self.playButton:setEnabled(false)
			music.fade(event.effectTime * 0.5)
		elseif "did" == event.phase then
			uifx.cancelBounceTransition(self.playButton)
			self:removeVignettes()
		end
	end
	
	newComic:addEventListener( "create" )
	newComic:addEventListener( "hide" )
	newComic:addEventListener( "show" )
	
	return newComic
end

initialize()

return comicLib
