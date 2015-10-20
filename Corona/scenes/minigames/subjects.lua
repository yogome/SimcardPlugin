----------------------------------------------- Subjects
local scenePath = ...
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local localization = require( "libs.helpers.localization" )
local database = require( "libs.helpers.database" )
local onboarding = require( "data.onboarding" )
local settings = require( "settings" )
local widget = require( "widget" )
local creditsService = require("services.credits")
local screen = require("libs.helpers.screen")
local sound = require("libs.helpers.sound")

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonSubjects
local backButton
local availableSubjects
local header
local params
local backScene, backSceneParams
local goSubmenu
local usesCredits
local hudLayer
local backgroundGroup, background
local buttonsEnabled
local failedBackground
local promoGroup
----------------------------------------------- Constants
local GO_SUBMENU_DEFAULT = true 
local COLOR_UNAVAILABLE = colors.gray

local OFFSET_Y_HEADER = 65

local USES_CREDITS_DEFAULT = true

local PATH_IMAGES = "images/subjects/"
local LIST_SUBJECTS = {
	[1] = {id = "math", needsSubscription = false},
	[2] = {id = "geography", needsSubscription = false},
	[3] = {id = "sustainability", needsSubscription = false},
	[4] = {id = "programming", needsSubscription = false},
	[5] = {id = "health", needsSubscription = false},
	[6] = {id = "creativity", needsSubscription = false},
	[7] = {id = "science", needsSubscription = false},
	[8] = {id = "languages", needsSubscription = false},
}

local OFFSET_CREDIT_TEXTS = {x = -160, y = 70}
local OFFSET_CREDIT_COUNTER = {x = 0, y = 0}
local OFFSET_STATUS = {x = -40, y = 0}
local OFFSET_CREDITS_LABEL = {x = 40, y = 0}
local OFFSET_UPGRADE = {x = 0, y = 65}

local SCALE_ALLSUBJECTSGROUP = 1.1
local SCALE_SUBJECTICON = 0.5
local OFFSET_Y_SUBJECTS = -20
local COLUMNS_SUBJECTS = 4
local ROWS_SUBJECTS = 2
local PADDING_SUBJECTS = {x = 220, y = 220}
local OFFSET_Y_ALLSUBJECTSGROUP = 0
local OFFSET_SUBJECTICON = {x = 0, y = -10}
local OFFSET_SUBJECTTEXT = {x = 0, y = 62}
local SIZE_FONT_SUBJECTTEXT = 22
local FONTNAME_DESCRIPTION = settings.fontName

local BUTTON_GENERIC = {
	width = 192,
	height = 56,
	defaultFile = "images/onboarding/buttons/offer_small1.png",
	overFile = "images/onboarding/buttons/offer_small2.png",
	font = settings.fontName,
	fontSize = 32,
	labelColor = { default = colors.white, over = colors.white},
	labelYOffset = 0,
	label = "",
}
----------------------------------------------- Functions
local function backReleased()
	sound.play("onboardingClick")
	director.gotoScene(backScene, {time = 400, effect = "fade", params = backSceneParams})
end

local function createSubjectButtons(sceneGroup)
	local buttonGroup = display.newGroup()
	sceneGroup:insert(buttonGroup)
	
	local subjectStartX = -(COLUMNS_SUBJECTS * 0.5 * PADDING_SUBJECTS.x) + PADDING_SUBJECTS.x * 0.5
	local subjectStartY = -(ROWS_SUBJECTS * 0.5 * PADDING_SUBJECTS.y) + PADDING_SUBJECTS.y * 0.5 + OFFSET_Y_SUBJECTS
	local currentSubject = 0
	
	local allSubjectsGroup = display.newGroup()
	allSubjectsGroup.x = display.contentCenterX
	allSubjectsGroup.y = display.contentCenterY + OFFSET_Y_ALLSUBJECTSGROUP
	sceneGroup:insert(allSubjectsGroup)
	
	for rowIndex = 1, ROWS_SUBJECTS do
		for columnIndex = 1, COLUMNS_SUBJECTS do
			currentSubject = currentSubject + 1
			
			local subjectGroup = display.newGroup()
			subjectGroup.x = subjectStartX + (columnIndex - 1) * PADDING_SUBJECTS.x
			subjectGroup.y = subjectStartY + (rowIndex - 1) * PADDING_SUBJECTS.y
			subjectGroup.name = LIST_SUBJECTS[currentSubject].id
			subjectGroup.isEnabled = false
			
			local subjectBG = display.newImage("images/manager/gallery/frame.png")
			subjectGroup:insert(subjectBG)
			
			local subjectLockedBG = display.newImage("images/manager/gallery/frameLocked.png")
			subjectLockedBG.isVisible = false
			subjectGroup:insert(subjectLockedBG)
			
			local subjectText = display.newText(localization.getString(LIST_SUBJECTS[currentSubject].id.."Onboarding"), OFFSET_SUBJECTTEXT.x, OFFSET_SUBJECTTEXT.y, FONTNAME_DESCRIPTION, SIZE_FONT_SUBJECTTEXT)
			colors.addColorTransition(subjectText)
			subjectText.r, subjectText.g, subjectText.b = unpack(colors.white)
			subjectGroup:insert(subjectText)
			
			subjectGroup.subjectIndex = currentSubject
			subjectGroup.subjectText = subjectText
			
			local subjectIcon = display.newImage(PATH_IMAGES..LIST_SUBJECTS[#buttonSubjects + 1].id..".png")
			subjectIcon:scale(SCALE_SUBJECTICON, SCALE_SUBJECTICON)
			subjectIcon.x = OFFSET_SUBJECTICON.x
			subjectIcon.y = OFFSET_SUBJECTICON.y
			subjectGroup:insert(subjectIcon)
			
			function subjectGroup:setEnabled(isEnabled)
				local color = isEnabled and colors.white or COLOR_UNAVAILABLE
				subjectIcon:setFillColor(unpack(color))
				subjectBG:setFillColor(unpack(color))
				subjectText.r, subjectText.g, subjectText.b = unpack(color)
				subjectLockedBG.isVisible = not isEnabled
				subjectBG.isVisible = isEnabled
				self.isEnabled = isEnabled
			end
			
			local function subjectTapped()
				if buttonsEnabled then
					if availableSubjects[subjectGroup.name] and subjectGroup.isEnabled then
						buttonsEnabled = false

						sound.play("onboardingClick")
						params = params or {}
						params.subject = subjectGroup.name
						params.nextScene = "scenes.minigames.subjects"

						if goSubmenu then
							director.gotoScene("scenes.minigames.gallery", {params = params, time = 600, effect = "fade"})
						else
							director.gotoScene("scenes.minigames.manager", {params = params, effect = "fade", time = 600})
							-- TODO play minigame set
						end

						if usesCredits then
							creditsService.removeCredits(1)
						end
					else
						-- TODO play a sound?
					end
				end
			end
			
			subjectGroup:addEventListener("tap", function()
				if usesCredits then
					if creditsService.getAmount() > 0 then
						subjectTapped()
					else
						-- TODO show subscribe or facebook share
					end
				else
					subjectTapped()
				end
			end)
			
			subjectGroup:setEnabled(availableSubjects[subjectGroup.name] and not LIST_SUBJECTS[currentSubject].needsSubscription)
			
			allSubjectsGroup:insert(subjectGroup)
			subjectGroup.animationRatio = math.abs(-COLUMNS_SUBJECTS * 0.5 + columnIndex - 0.5) * 0.5
			buttonSubjects[#buttonSubjects +1] = subjectGroup
		end
	end
	
	local margin = 200
	local desiredHeight = display.viewableContentHeight - margin
	local oldAllSubjectsGroupHeight = allSubjectsGroup.height
	local calculatedWidth = allSubjectsGroup.width * (desiredHeight / oldAllSubjectsGroupHeight)
	
	if calculatedWidth > display.viewableContentWidth - margin then
		calculatedWidth = display.viewableContentWidth - margin
		desiredHeight = allSubjectsGroup.height * (calculatedWidth / allSubjectsGroup.width)
	end
	
	allSubjectsGroup.anchorChildren = true
	allSubjectsGroup.height = desiredHeight
	allSubjectsGroup.width = calculatedWidth
	allSubjectsGroup:scale(SCALE_ALLSUBJECTSGROUP,SCALE_ALLSUBJECTSGROUP)
end

local function prepareButtons()
	for index = 1, #buttonSubjects do
		local currentButton = buttonSubjects[index]
		currentButton.alpha = 0
		currentButton.xScale = 0.5
		currentButton.yScale = 0.5
		transition.to(currentButton, {delay = 100 * index, time = 350, xScale = 1, yScale = 1, alpha = 1, transition = easing.outBack})
		
		currentButton.subjectText = localization.getString(currentButton.name.."Onboarding")
		currentButton:setEnabled(availableSubjects[currentButton.name] and not LIST_SUBJECTS[currentButton.subjectIndex].needsSubscription)
	end
end

local function getAvailableSubjects()
	availableSubjects = {}
	
	local manager = require("scenes.minigames.manager")
	local allMinigames = manager.getMinigameDictionary()
	
	for index = 1, #allMinigames do
		local minigameData = allMinigames[index]
		
		if minigameData.available then
			if minigameData.category then
				availableSubjects[minigameData.category] = true
			end
		end
	end
end

local function createCreditCounter()
	display.remove(promoGroup)
	promoGroup = nil
	promoGroup = creditsService.getPromoGroup()
	if promoGroup then
		if creditsService.getAmount() > 0 then
			promoGroup.anchorX, promoGroup.anchorY = 1, 1
			promoGroup.x, promoGroup.y = screen.rightEdge() + 15, screen.bottomEdge() + 15
			local dynamicScale = display.viewableContentHeight / 1440
			promoGroup.xScale, promoGroup.yScale = dynamicScale, dynamicScale
		else
			promoGroup.anchorChildren = false
			
			local fadeRect = display.newRect(0, -OFFSET_Y_ALLSUBJECTSGROUP, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
			fadeRect:setFillColor(0, 0.5)
			promoGroup:insert(fadeRect)
			fadeRect:toBack()
			
			promoGroup.x = display.contentCenterX
			promoGroup.y = display.contentCenterY + OFFSET_Y_ALLSUBJECTSGROUP
			backButton:toFront()
		end
	
		hudLayer:insert(promoGroup)
	end
end


local function initialize(event)
	event = event or {}
	params = event.params
	
	backScene = backScene or params.backScene
	backButton.isVisible = backScene and true
	
	if goSubmenu == nil then
		goSubmenu = GO_SUBMENU_DEFAULT
	end
	
	if usesCredits == nil then
		usesCredits = USES_CREDITS_DEFAULT
	end
	
	header.text = localization.getString("chooseSubject")
end
----------------------------------------------- Module functions 
function scene.setBackScene(backSceneName, backSceneParameters)
	backScene = backSceneName
	backSceneParams = backSceneParameters
end

function scene.setSubmenuEnabled(isEnabled)
	goSubmenu = isEnabled
end

function scene.setUsesCredits(willUseCredits)
	usesCredits = willUseCredits
end

function scene.enableButtons()
	backButton:setEnabled(true)
	buttonsEnabled = true
end

function scene.disableButtons()
	backButton:setEnabled(false)
	buttonsEnabled = false
end

function scene.setBackground(filename)
	display.remove(background)
	background = nil
	
	local scale = display.viewableContentWidth / 1024
	if backgroundGroup and backgroundGroup.insert and "function" == type(backgroundGroup.insert) then
		background = display.newImage(filename)
		if background then
			background.x, background.y = display.contentCenterX, display.contentCenterY		
			background.xScale = scale		
			background.yScale = scale
			backgroundGroup:insert(background)
		end
	else
		failedBackground = filename
	end
end

function scene:create(event)
	local sceneView = self.view
	
	buttonSubjects = {}
	getAvailableSubjects()
	
	backgroundGroup = display.newGroup()
	sceneView:insert(backgroundGroup)
	
	local bg = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth, display.viewableContentHeight)
	bg:setFillColor(unpack(colors.convertFromHex("00a4e4")))
	backgroundGroup:insert(bg)
	
	if failedBackground then
		scene.setBackground(failedBackground)
		failedBackground = nil
	end
	
	local headerOptions = {
		text = "Select a Category",	 
		x = display.contentCenterX,
		y = display.screenOriginY + OFFSET_Y_HEADER,
		font = settings.fontName,   
		fontSize = 42,
		align = "center"
	}
	
	header = display.newText(headerOptions)
	header:setFillColor(unpack(colors.white))
	sceneView:insert(header)
	
	createSubjectButtons(sceneView)
	
	hudLayer = display.newGroup()
	sceneView:insert(hudLayer)
	
	local buttonOptions = {
		width = 128,
		height = 128,
		defaultFile = "images/manager/gallery/back1.png",
		overFile = "images/manager/gallery/back2.png",
		onRelease = backReleased,
	}
	
	backButton =  widget.newButton(buttonOptions)
	backButton.x = display.screenOriginX + 70
	backButton.y = display.screenOriginY + OFFSET_Y_HEADER
	hudLayer:insert(backButton)	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then
		initialize(event)
		getAvailableSubjects()
		prepareButtons()
		createCreditCounter()
	elseif phase == "did" then
		scene.enableButtons()
	end
end

function scene:hide( event )
	local sceneView = self.view
	local phase = event.phase
	
	if phase == "will" then
		scene.disableButtons()
	elseif phase == "did" then
		display.remove(promoGroup)
		promoGroup = nil
	end
end
----------------------------------------------- Execution
scene:addEventListener( "create" )
scene:addEventListener( "destroy" )
scene:addEventListener( "hide" )
scene:addEventListener( "show" )

return scene
