----------------------------------------------- Scene
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local localization = require ( "libs.helpers.localization" )
local colors = require( "libs.helpers.colors" )
local widget = require( "widget" )
local logger = require( "libs.helpers.logger" )
local textbox = require( "libs.helpers.textbox" )
local robot = require( "libs.helpers.robot" )
local internet = require( "libs.helpers.internet" )
local json = require( "json" )
local extraJson = require( "libs.helpers.extrajson" )
local database = require( "libs.helpers.database" )
local screen = require( "libs.helpers.screen" )
local extratable = require( "libs.helpers.extratable" )
local players = require( "models.players" )
local sound = require( "libs.helpers.sound" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonsEnabled
local scrollViewGroup, scrollView
local swipeLearn
local swipeSections
local swipeLearnGroup
local goLoginButton
local isBusy
local validRegisterEmail
local validLoginEmail
local registerEmail, loginEmail, loginPassword
local buttonRegister, buttonLogin
local registerWaitText, loginWaitText
local forgotPassword
local acceptTerms1, acceptTerms2
local swipeStartPageIndex
local currentLoop, waitTextLoop
local gradeSlider, ageSlider
local subjectGroups
----------------------------------------------- Constants
local PADDING_PAGE_INDICATOR = 40

local COLOR_SWIPETEXT = colors.white
local SCALE_LOGO = 0.5
local TAG_TRANSITION_SCROLLVIEW = "tagTransitionScroll"

local OFFSET_ALREADYLOGIN = {x = display.contentCenterX, y = display.screenOriginY + display.viewableContentHeight - 80}
local OFFSET_Y_SWIPELEARN = 40
local RADIUS_SWIPE_CIRCLES = 10
local COLOR_CIRCLE_UNSELECTED = colors.white
local COLOR_CIRCLE_SELECTED = colors.convertFrom256({248, 57, 36})

local OFFSET_Y_REGISTEREMAIL = 150
local OFFSET_Y_BUTTONCREATE = 240
local OFFSET_Y_TERMS = 300

local LOOP_UPDATE_WAITTEXT = 50

local OFFSET_Y_LOGINEMAIL = 150
local OFFSET_Y_LOGINPASSWORD = 240
local OFFSET_Y_LOGINBUTTON = 330
local OFFSET_Y_FORGOT = 400

local SIZE_FONT_FORGOT = 30

local OFFSET_Y_SUBJECTS = -20
local PADDING_SUBJECTS = {x = 220, y = 220}
local SCALE_SUBJECTICON = 0.5
local SCALE_SELECTION = 0.5
local COLUMNS_SUBJECTS = 4
local ROWS_SUBJECTS = 2

local FLAG_SKIP_AUTHENTICATION = false

local OFFSET_Y_ALLSUBJECTSGROUP = 15
local SCALE_ALLSUBJECTSGROUP = 1.1
local OFFSET_SUBJECTICON = {x = 0, y = 0}
local OFFSET_SUBJECTTEXT = {x = 0, y = 72}
local SIZE_FONT_SUBJECTTEXT = 22
local SIZE_FONT_DESCRIPTION = 38
local SIZE_FONT_TITLE = 46
local OFFSET_Y_TITLE = 30
local OFFSET_Y_DESCRIPTION = 90

local SIZE_FONT_TERMS = 30
local COLOR_ACCEPT_TERMS1 = colors.white
local COLOR_ACCEPT_TERMS2 = colors.convertFrom256({99,209,255})
local URL_TERMS = "http://dashboard.yogome.com/terms"

local FONTNAME_TITLE = settings.fontName
local FONTNAME_DESCRIPTION = settings.fontName
local OFFSET_Y_ICON_SECTION1 = 40
local COLOR_FORGOT_PASSWORD = colors.white
local SIZE_WAIT_TEXT = 30
local SWIPE_NEXTPAGE = display.viewableContentWidth * 0.1

local OFFSET_GRADESLIDER = {x = 10, y = 70}
local OFFSET_AGESLIDER = {x = 10, y = -70}

local OFFSET_YOGOTAR = {x = 360, y = 20}
local SCALE_YOGOTAR = 0.7

local TAG_TRANSITION_REGISTER = "tagTransitionRegister"
local TAG_TRANSITION_LOGIN = "tagTransitionLogin"

local COLOR_BACKGROUNDS = colors.convertFrom256({46,52,98})
local BUTTON_GENERIC = {
	width = 512,
	height = 128,
	defaultFile = "images/onboarding/button1.png",
	overFile = "images/onboarding/button2.png",
	font = settings.fontName,
	fontSize = 32,
	labelColor = { default = colors.convertFrom256({0,163,231}), over = colors.convertFrom256({0,163,231})},
	labelYOffset = 0,
	label = "",
}

local SUBJECTS = {
	[1] = {id = "math", iconPath = "images/onboarding/subjects/math.png"},
	[2] = {id = "science", iconPath = "images/onboarding/subjects/science.png"},
	[3] = {id = "geography", iconPath = "images/onboarding/subjects/geography.png"},
	[4] = {id = "programming", iconPath = "images/onboarding/subjects/programming.png"},
	[5] = {id = "sustainability", iconPath = "images/onboarding/subjects/sustainability.png"},
	[6] = {id = "health", iconPath = "images/onboarding/subjects/health.png"},
	[7] = {id = "art", iconPath = "images/onboarding/subjects/art.png"},
	[8] = {id = "languages", iconPath = "images/onboarding/subjects/languages.png"},
}
----------------------------------------------- Caches
local mathFloor = math.floor 
----------------------------------------------- Functions
local function showLoginElements()
	transition.to(buttonLogin, {tag = TAG_TRANSITION_LOGIN, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(forgotPassword, {tag = TAG_TRANSITION_LOGIN, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(loginWaitText, {tag = TAG_TRANSITION_LOGIN, time = 600, alpha = 0, transition = easing.outQuad})
end

local function cancelTransitionAndShowButtons()
	transition.cancel(TAG_TRANSITION_LOGIN)
	showLoginElements()
end

local function loginListener(event)
	isBusy = false
	if event.isError then
		native.showAlert( localization.getString("error"), localization.getString("errorInternet"), { localization.getString("ok") })
		scene.enableButtons()
		cancelTransitionAndShowButtons()
	else
		local luaResponse = json.decode(event.response)
		if "success" == luaResponse.status or FLAG_SKIP_AUTHENTICATION then
			database.config("validLogin", true)
			database.config("currentUserEmail", loginEmail)
			database.config("currentUserPassword", loginPassword)
			
			players.deleteAll()
			
			local currentUser = {
				email = loginEmail,
				password = loginPassword,
				discountLevel = luaResponse.discountLevel,
				childIndex = 1
			}
			
			local playerIndex = 1
			currentUser.playerList = {}
			if luaResponse.players then
				for remoteID, playerInfo in pairs(luaResponse.players) do
					local hokData = extraJson.decodeFixed(playerInfo.player) or {}
					currentUser.playerList[playerIndex] = {
						remoteID = playerInfo.remoteID,
						name = hokData.characterName or "Player",
						hokData = hokData,
					}
					if hokData then
						hokData.id = playerIndex
						players.save(hokData, playerIndex)
					end
					playerIndex = playerIndex + 1
				end
				players.setCurrentID(1)
			end
				
			director.gotoScene("scenes.menus.home", {effect = "slideLeft", time = 800})
		else
			database.config("validLogin", false)
			native.showAlert( localization.getString("error"), localization.getString("errorLoginCredentials"), { localization.getString("ok") })
			scene.enableButtons()
			cancelTransitionAndShowButtons()
		end
	end
end 

local function loginReleased(event)
	native.setKeyboardFocus(nil)
	if internet.isConnected() then
		if loginEmail and loginPassword and validLoginEmail and not isBusy then
			isBusy = true
			local body = {
				email = loginEmail,
				password = loginPassword,
				language = localization.getLanguage(),
				pushToken = database.config("pushToken"),
				gameName = settings.gameName,
			}
			local params = {
				headers = {
					["Content-Type"] = settings.server.contentType,
					["X-API-Key"] = settings.server.restKey,
				},
				body = json.encode(body)
			}
			scene.disableButtons()
			
			transition.to(buttonLogin, {tag = TAG_TRANSITION_LOGIN, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(forgotPassword, {tag = TAG_TRANSITION_LOGIN, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(loginWaitText, {tag = TAG_TRANSITION_LOGIN, time = 600, alpha = 1, transition = easing.outQuad})
			
			network.request(settings.server.hostname.."/users/parent/get", "POST", loginListener, params )
		else
			if isBusy then
				native.showAlert( localization.getString("error"), localization.getString("wait"), { localization.getString("ok") })
			else
				if not loginPassword then
					native.showAlert( localization.getString("error"), localization.getString("noEmptyPassword"), { localization.getString("ok") })
				else
					native.showAlert( localization.getString("error"), localization.getString("errorInvalidEmail"), { localization.getString("ok") })
				end
				scene.enableButtons()
			end
		end
	else
		native.showAlert( localization.getString("error"), localization.getString("errorInternet"), { localization.getString("ok") })
		scene.enableButtons()
	end
	--director.gotoScene("scenes.menus.home", {effect = "crossFade", time = 600,})
end

local function goLogin()
	if swipeLearn.selectedIndex ~= 5 then
		transition.cancel(TAG_TRANSITION_SCROLLVIEW)
		transition.to(scrollView._view, {time = 500, x = -(scrollView.width * (5 - 1)), transition = easing.outinOutQuad, onComplete = function()

		end})
	end
end

local function showRegisterButtons()
	transition.cancel(TAG_TRANSITION_REGISTER)
	transition.to(buttonRegister, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(acceptTerms1, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(acceptTerms2, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(registerWaitText, {tag = TAG_TRANSITION_REGISTER, time = 600, alpha = 0, transition = easing.outQuad})
end

local function createListener( event )
	isBusy = false
	if event.isError then
		native.showAlert( "Error", localization.getString("errorServer"), { localization.getString("ok") })
		scene.enableButtons()
		showRegisterButtons()
	else
		local luaResponse = json.decode(event.response)
		if luaResponse and "already registered" == luaResponse.status then
			native.showAlert( localization.getString("error"), localization.getString("errorUserExists"), { localization.getString("ok") })
			scene.enableButtons()
			showRegisterButtons()
		elseif luaResponse and "success" == luaResponse.status then
			native.showAlert( localization.getString("success"), localization.getString("registrationEmail"), { localization.getString("ok") }, function(event)
				if "clicked" == event.action then

					database.config("currentUserID", registerEmail)
					database.config("currentUserEmail", registerEmail)
					database.config("currentUserPassword", luaResponse.password)
					database.config("currentUserDiscountLevel", luaResponse.discountLevel)
					database.config("validLogin", true)
					
					database.config("tempValidSubscription", 0)
					database.config("validSubscription", false)
					
					local currentPlayer = players.getCurrent()
					currentPlayer.grade = gradeSlider.value
					currentPlayer.age = ageSlider.value
					players.save(currentPlayer)
					
					local params = {}
					for index = 1, #subjectGroups do
						local subjectData = subjectGroups[index].data
						params[subjectData.id] = subjectGroups[index].isSelected
					end
								
					director.gotoScene("scenes.menus.home", {effect = "crossFade", time = 600, params = {nextScene = "scenes.menus.selecthero"}})
				end
			end)
		else
			native.showAlert( localization.getString("error"), localization.getString("errorGeneral"), { localization.getString("ok") })
			scene.enableButtons()
			showRegisterButtons()
		end
	end
end 

local function createReleased(event)
	native.setKeyboardFocus(nil)
	if validRegisterEmail then
		if internet.isConnected() and not isBusy then
			isBusy = true
			local body = {
				email = registerEmail,
				language = localization.getLanguage(),
				gameName = settings.gameName,
			}
			local params = {
				headers = {
					["Content-Type"] = settings.server.contentType,
					["X-API-Key"] = settings.server.contentType,
				},
				body = json.encode(body)
			}
			
			scene.disableButtons()
			transition.to(buttonRegister, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(acceptTerms1, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(acceptTerms2, {tag = TAG_TRANSITION_REGISTER, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(registerWaitText, {tag = TAG_TRANSITION_REGISTER, time = 600, alpha = 1, transition = easing.outQuad})
	
			network.request(settings.server.hostname.."/users/parent/register", "POST", createListener, params )
		else
			if isBusy then
				native.showAlert( localization.getString("error"), localization.getString("wait"), { localization.getString("ok") })
			else
				native.showAlert( localization.getString("error"), localization.getString("errorInternet"), { localization.getString("ok") })
				scene.enableButtons()
			end
		end
	else
		native.showAlert( localization.getString("error"), localization.getString("errorInvalidEmail"), { localization.getString("ok") })
		scene.enableButtons()
	end
	--director.gotoScene("scenes.menus.home", {effect = "crossFade", time = 600,})
end

local function forgotPasswordTapped()
	director.gotoScene("scenes.menus.login.forgot", {effect = "slideLeft", time = 600})
end

local function onTermsTapped()
	if buttonsEnabled then
		system.openURL(URL_TERMS)
	end
end

local function createSlider(options)
	local slider = display.newGroup()
	
	local positions = options.positions
	
	local background = display.newImage(options.background)
	slider:insert(background)
	
	local width = background.width
	local halfWidth = width * 0.5
	local leftLimit = -halfWidth + (positions[1].x * width)
	local rightLimit = -halfWidth + (positions[#positions].x * width)
	
	local knob = display.newImage(options.knob)
	knob.x = -halfWidth + (positions[options.positionIndex].x * width)
	slider:insert(knob)
	slider.currentIndex = options.positionIndex
	slider.value = positions[options.positionIndex].value
	
	local function knobTouched( event )
		local knob = event.target
		if event.phase == "began" then
			display.getCurrentStage():setFocus( knob, event.id )
			knob.isFocus = true
			knob.markX = knob.x
			transition.cancel(knob)
		elseif knob.isFocus then
			if event.phase == "moved" then
				knob.x = event.x - event.xStart + knob.markX
				if knob.x < leftLimit then
					knob.x = leftLimit
				elseif knob.x > rightLimit then
					knob.x = rightLimit
				end
				local currentX = (knob.x + halfWidth) / width
				if #positions > 1 then
					for index = 2, #positions do
						local beforeIndex = index - 1
						local beforePosition = positions[beforeIndex].x
						local nextPosition = positions[index].x
						
						if beforePosition < currentX and currentX < nextPosition then
							local halfPoint = (beforePosition + nextPosition) * 0.5
							if currentX <= halfPoint then
								slider.currentIndex = beforeIndex
							else
								slider.currentIndex = index
							end
						end
					end
				elseif #positions == 1 then
					slider.currentIndex = 1
				end
				slider.value = positions[slider.currentIndex].value
			elseif event.phase == "ended" or event.phase == "cancelled" then
				--print(0.5 + (knob.x / slider.width))
				transition.cancel(knob)
				transition.to(knob, {x = -halfWidth + positions[slider.currentIndex].x * width})
				display.getCurrentStage():setFocus( knob, nil )
				knob.isFocus = false
			end
		end
		return true
	end
	knob:addEventListener("touch", knobTouched)
	
	return slider
end

local function updateDynamicObjects()
	currentLoop = currentLoop + 1
	if registerWaitText and loginWaitText then
		if currentLoop % LOOP_UPDATE_WAITTEXT == 0 then
			waitTextLoop = waitTextLoop + 1
			if waitTextLoop > 3 then
				waitTextLoop = 0
			end
			local dots = ""
			for index = 1, waitTextLoop do
				dots = dots.."."
			end
			loginWaitText.text = localization.getString("waitLogin")..dots
			registerWaitText.text = localization.getString("waitRegister")..dots
		end
	end
end

local function initialize(event)
	registerEmail = ""
	loginEmail = ""
	loginPassword = ""
	isBusy = false
	validRegisterEmail = false
	validLoginEmail = false
	transition.cancel(TAG_TRANSITION_SCROLLVIEW)
	goLoginButton:setLabel(localization.getString("haveAccount"))
	goLoginButton.alpha = 1
	players.deleteAll()
	currentLoop = 0
	waitTextLoop = 0
end

local function swipeListener(event)
	event.scrollX, event.scrollY = scrollView:getContentPosition()
	if event.phase == "began" then
		textbox.removeFocus()
		transition.cancel(TAG_TRANSITION_SCROLLVIEW)
		swipeStartPageIndex = mathFloor((-event.scrollX + scrollView.width * 0.5) / display.viewableContentWidth) + 1
	elseif event.phase == "moved" then
		
	elseif event.phase == "ended" then
		local totalScroll = event.xStart - event.x
		if math.abs(totalScroll) > SWIPE_NEXTPAGE then
			local direction = totalScroll < 0 and -1 or 1
			swipeStartPageIndex = swipeStartPageIndex + direction
			swipeStartPageIndex = swipeStartPageIndex > 0 and swipeStartPageIndex or 1
			swipeStartPageIndex = swipeStartPageIndex <= #swipeSections and swipeStartPageIndex or #swipeSections
		end
		
		transition.to(scrollView._view, {time = 200, x = -(scrollView.width * (swipeStartPageIndex - 1)), transition = easing.outinOutQuad, onComplete = function()

		end})
	end
end

local function createScrollView()
	local scrollViewHeight = display.viewableContentHeight
	local scrollViewOptions = {
		x = display.contentCenterX,
		y = display.screenOriginY + scrollViewHeight * 0.5,
		width = display.viewableContentWidth,
		height = scrollViewHeight,
		hideBackground = false,
		horizontalScrollDisabled = false,
		verticalScrollDisabled = true,
		isBounceEnabled = false,
		listener = swipeListener,
		friction = 0,
		backgroundColor = COLOR_BACKGROUNDS,
	}
	
	scrollView = widget.newScrollView(scrollViewOptions)
	scrollViewGroup:insert(scrollView)
end

local function removeScrollView()
	display.remove(scrollView)
	scrollView = nil
end

local function populateScrollView()
	local language = localization.getLanguage()
	for index = 1, #swipeSections do
		local section = swipeSections[index]
		section.x = (index - 1) * display.viewableContentWidth
		section.y = 0
		section.anchorX = 0
		section.anchorY = 0

		scrollView:insert(section)
	end
end

local function updateScrollView()
	updateDynamicObjects()
	local scrollX, scrollY = scrollView:getContentPosition()
	swipeLearn:selectIndex(mathFloor((-scrollX + scrollView.width * 0.5) / display.viewableContentWidth) + 1)
	
	local currentScroll = (-scrollX + scrollView.width * 0.5) / display.viewableContentWidth + 0.5
	for index = 1, #swipeSections do
		local swipeSection = swipeSections[index]
		if swipeSection.update then swipeSection.update({currentScroll = currentScroll, scrollX = -scrollX}) end
	end
end

local function removeRuntimeListener()
	Runtime:removeEventListener("enterFrame", updateScrollView)
end

local function addRuntimeListener()
	Runtime:addEventListener("enterFrame", updateScrollView)
end

local function validateRegisterEmail(event)
	local field = event.target
	registerEmail = string.lower(field.value) or ""
	if registerEmail:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") then
		validRegisterEmail = true
	else
		validRegisterEmail = false
	end
end

local function validateLoginEmail(event)
	local field = event.target
	loginEmail = string.lower(field.value) or ""
	if loginEmail:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") then
		validLoginEmail = true
	else
		validLoginEmail = false
	end
end

local function storePassword(event)
	local field = event.target
	loginPassword = field.value
end

local function createSwipeLearn()
	display.remove(swipeLearn)
	swipeLearn = display.newGroup()
	swipeLearn.x = display.contentCenterX
	swipeLearn.y = display.screenOriginY + display.viewableContentHeight - OFFSET_Y_SWIPELEARN
	local circles = {}
	
	local totalHalfWidth = ((#swipeSections - 1) * PADDING_PAGE_INDICATOR) * 0.5
	
	for index = 1, #swipeSections do
		local circle = display.newCircle(0, 0, RADIUS_SWIPE_CIRCLES)
		circle.x = -totalHalfWidth + (index - 1) * PADDING_PAGE_INDICATOR
		circle.y = 0
		circle:setFillColor(unpack(COLOR_CIRCLE_UNSELECTED))
		
		swipeLearn:insert(circle)
		circles[index] = circle
	end
	swipeLearn.circles = circles
	
	function swipeLearn:selectIndex(selectedIndex)
		local circles = self.circles
		selectedIndex = selectedIndex < 1 and 1 or selectedIndex
		selectedIndex = selectedIndex > #circles and #circles or selectedIndex
		
		self.selectedIndex = selectedIndex
		for index = 1, #circles do
			local circle = circles[index]
			
			circle:setFillColor(unpack(COLOR_CIRCLE_UNSELECTED))
		end
		circles[selectedIndex]:setFillColor(unpack(COLOR_CIRCLE_SELECTED))
	end
	
--	local swipeLearnText = display.newText(localization.getString("slideLearn"), 0, OFFSET_Y_SWIPETEXT, settings.fontName, SIZE_FONT_SWIPETEXT)
--	swipeLearnText:setFillColor(unpack(COLOR_SWIPETEXT))
--	swipeLearn:insert(swipeLearnText)
	
	swipeLearnGroup:insert(swipeLearn)
end

local function createSwipeSection1(availableCenterPixels)
	local swipeSection1 = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	
	local title1 = display.newText(localization.getString("onBoardingTitle1"), 0, -swipeSection1.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	title1.anchorY = 0
	title1:setFillColor(unpack(colors.white))
	swipeSection1:insert(title1)
	
	local description1Options = {
		x = 0,
		y = -swipeSection1.height * 0.5 + OFFSET_Y_DESCRIPTION,
		font = FONTNAME_DESCRIPTION,
		text = localization.getString("onBoardingDescription1"),
		fontSize = SIZE_FONT_DESCRIPTION,
		width = 900,
		align = "center"
	}
	
	local description1 = display.newText(description1Options)
	description1.anchorY = 0
	description1:setFillColor(unpack(colors.white))
	swipeSection1:insert(description1)
	
	local iconSection1 = display.newImage("images/onboarding/minigames.png")
	local oldHeight = iconSection1.height
	iconSection1.height = availableCenterPixels
	iconSection1.width = iconSection1.width * (availableCenterPixels / oldHeight)
	iconSection1.y = OFFSET_Y_ICON_SECTION1
	swipeSection1:insert(iconSection1)
	
	local finalIconScale = iconSection1.xScale
	
	function swipeSection1.update(event)
		if 0 < event.currentScroll and event.currentScroll < 2 then
			local scale = finalIconScale - math.abs(1 - event.currentScroll)
			iconSection1.xScale = scale
			iconSection1.yScale = scale
		end
	end
	return swipeSection1
end

local function createSwipeSection2(availableCenterPixels)
	local swipeSection2 = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	
	local title2 = display.newText(localization.getString("onBoardingTitle2"), 0, -swipeSection2.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	title2.anchorY = 0
	title2:setFillColor(unpack(colors.white))
	swipeSection2:insert(title2)
	
	local description2 = display.newText(localization.getString("onBoardingDescription2"), 0, -swipeSection2.height * 0.5 + OFFSET_Y_DESCRIPTION, FONTNAME_DESCRIPTION, SIZE_FONT_DESCRIPTION)
	description2.anchorY = 0
	description2:setFillColor(unpack(colors.white))
	swipeSection2:insert(description2)
	
	local subjectStartX = -(COLUMNS_SUBJECTS * 0.5 * PADDING_SUBJECTS.x) + PADDING_SUBJECTS.x * 0.5
	local subjectStartY = -(ROWS_SUBJECTS * 0.5 * PADDING_SUBJECTS.y) + PADDING_SUBJECTS.y * 0.5 + OFFSET_Y_SUBJECTS
	local currentSubject = 0
	
	local allSubjectsGroup = display.newGroup()
	allSubjectsGroup.y = OFFSET_Y_ALLSUBJECTSGROUP
	swipeSection2:insert(allSubjectsGroup)
	
	subjectGroups = {}
	for rowIndex = 1, ROWS_SUBJECTS do
		for columnIndex = 1, COLUMNS_SUBJECTS do
			currentSubject = currentSubject + 1
			
			local subjectGroup = display.newGroup()
			subjectGroup.x = subjectStartX + (columnIndex - 1) * PADDING_SUBJECTS.x
			subjectGroup.y = subjectStartY + (rowIndex - 1) * PADDING_SUBJECTS.y
			subjectGroup.data = SUBJECTS[currentSubject]
			
			subjectGroup.isSelected = false
			
			local selectedImage = display.newImage("images/onboarding/selected.png")
			selectedImage:scale(SCALE_SELECTION,SCALE_SELECTION)
			selectedImage.alpha = 0
			subjectGroup:insert(selectedImage)
			
			local unselectedImage = display.newImage("images/onboarding/unselected.png")
			unselectedImage:scale(SCALE_SELECTION,SCALE_SELECTION)
			unselectedImage.alpha = 1
			subjectGroup:insert(unselectedImage)
			
			local subjectText = display.newText(localization.getString(SUBJECTS[currentSubject].id), OFFSET_SUBJECTTEXT.x, OFFSET_SUBJECTTEXT.y, FONTNAME_DESCRIPTION, SIZE_FONT_SUBJECTTEXT)
			colors.addColorTransition(subjectText)
			subjectText.r, subjectText.g, subjectText.b = unpack(colors.white)
			subjectGroup:insert(subjectText)
			
			local subjectIcon = display.newImage(SUBJECTS[currentSubject].iconPath)
			subjectIcon:scale(SCALE_SUBJECTICON, SCALE_SUBJECTICON)
			subjectIcon.x = OFFSET_SUBJECTICON.x
			subjectIcon.y = OFFSET_SUBJECTICON.y
			subjectGroup:insert(subjectIcon)
			
			subjectGroup:addEventListener("tap", function(event)
				
				subjectGroup.isSelected = not subjectGroup.isSelected
				transition.cancel(selectedImage)
				
				local selectedAlpha = subjectGroup.isSelected and 1 or 0
				local unselectedAlpha = subjectGroup.isSelected and 0 or 1
				transition.to(selectedImage, {alpha = selectedAlpha, transition = easing.inOutQuad})
				transition.to(unselectedImage, {alpha = unselectedAlpha, transition = easing.inOutQuad})
				
				if subjectGroup.isSelected then
					sound.play("pop")
					subjectIcon.xScale = SCALE_SELECTION * 1.5
					subjectIcon.yScale = SCALE_SELECTION * 1.5
					transition.to(subjectIcon, {time = 300, xScale = SCALE_SELECTION, yScale = SCALE_SELECTION, transition = easing.outBounce})
				else
					sound.play("flipCard")
				end
				
				local textColor = subjectGroup.isSelected and COLOR_BACKGROUNDS or colors.white
				transition.cancel(subjectText)
				transition.to(subjectText, {r = textColor[1], g = textColor[2], b = textColor[3], transition = easing.inOutQuad})
				
			end)
			
			allSubjectsGroup:insert(subjectGroup)
			subjectGroup.animationRatio = math.abs(-COLUMNS_SUBJECTS * 0.5 + columnIndex - 0.5) * 0.5
			subjectGroups[currentSubject] = subjectGroup
		end
	end
	
	allSubjectsGroup.anchorChildren = true
	local oldAllSubjectsGroupHeight = allSubjectsGroup.height
	allSubjectsGroup.height = availableCenterPixels
	allSubjectsGroup.width = allSubjectsGroup.width * (availableCenterPixels / oldAllSubjectsGroupHeight)
	allSubjectsGroup:scale(SCALE_ALLSUBJECTSGROUP,SCALE_ALLSUBJECTSGROUP)
	
	function swipeSection2.update(event)
		if 1 < event.currentScroll and event.currentScroll < 3 then
			for index = 1, #subjectGroups do
				local subjectGroup = subjectGroups[index]
				local scale = 1 - math.abs(2 - event.currentScroll) * subjectGroup.animationRatio
				subjectGroup.xScale = scale
				subjectGroup.yScale = scale
			end
		end
	end
	return swipeSection2
end

local function createSwipeSection3()
	local swipeSection3 = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	
	local title3 = display.newText(localization.getString("onBoardingTitle3"), 0, -swipeSection3.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	title3.anchorY = 0
	title3:setFillColor(unpack(colors.white))
	swipeSection3:insert(title3)
	
	local descriptionOptions = {
		x = 0,
		y = -swipeSection3.height * 0.5 + OFFSET_Y_DESCRIPTION,
		width = display.viewableContentWidth * 0.8,
		align = "center",
		text = localization.getString("onBoardingDescription3"),
		font = FONTNAME_DESCRIPTION,
		fontSize = SIZE_FONT_DESCRIPTION,
	}
	
	local description3 = display.newText(descriptionOptions)
	description3.anchorY = 0
	description3:setFillColor(unpack(colors.white))
	swipeSection3:insert(description3)
	
	local yogotard = display.newImage("images/register/tard1.png")
	yogotard.x = -OFFSET_YOGOTAR.x
	yogotard.y = OFFSET_YOGOTAR.y
	yogotard.xScale = SCALE_YOGOTAR
	yogotard.yScale = SCALE_YOGOTAR
	swipeSection3:insert(yogotard)
	
	local yogotard2 = display.newImage("images/register/tard2.png")
	yogotard2.x = OFFSET_YOGOTAR.x
	yogotard2.y = OFFSET_YOGOTAR.y
	yogotard2.xScale = SCALE_YOGOTAR
	yogotard2.yScale = SCALE_YOGOTAR
	swipeSection3:insert(yogotard2)
	
	local ageSliderOptions = {
		background = localization.format("images/register/age_%s.png"),
		knob = "images/register/selectAgeGrade.png",
		positionIndex = 1,
		positions = {
			{x = 0.35992, value = 5},
			{x = 0.43101, value = 6},
			{x = 0.502015, value = 7},
			{x = 0.572109, value = 8},
			{x = 0.64632, value = 9},
			{x = 0.73109, value = 10},
			{x = 0.82109, value = 11},
			{x = 0.91024, value = 12},
		},
	}
	ageSlider = createSlider(ageSliderOptions)
	ageSlider.x = OFFSET_AGESLIDER.x
	ageSlider.y = OFFSET_AGESLIDER.y
	swipeSection3:insert(ageSlider)
	
	local gradeSliderOptions = {
		background = localization.format("images/register/grade_%s.png"),
		knob = "images/register/selectAgeGrade.png",
		positionIndex = 1,
		positions = {
			{x = 0.35351, value = 1},
			{x = 0.43554, value = 2},
			{x = 0.524187, value = 3},
			{x = 0.61598, value = 4},
			{x = 0.70312, value = 5},
			{x = 0.79421, value = 6},
		},
	}
	gradeSlider = createSlider(gradeSliderOptions)
	gradeSlider.x = OFFSET_GRADESLIDER.x
	gradeSlider.y = OFFSET_GRADESLIDER.y
	swipeSection3:insert(gradeSlider)
	
	return swipeSection3
end

local function createSwipeSection4()
	local swipeSection4 = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	
	local title4 = display.newText(localization.getString("onBoardingTitle4"), 0, -swipeSection4.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	title4.anchorY = 0
	title4:setFillColor(unpack(colors.white))
	swipeSection4:insert(title4)
	
	local texboxOptions = {
		backgroundImage = "images/onboarding/field.png",
		backgroundScale = 0.5,
		fontSize = 32,
		font = settings.fontName,
		inputType = "email",
		color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
		placeholder = localization.getString("parentEmail"),
		onComplete = createReleased,
		onChange = validateRegisterEmail,
	}
	
	texboxOptions.onComplete = createReleased
	local registerEmailTextbox = textbox.new(texboxOptions)
	registerEmailTextbox.y = -swipeSection4.height * 0.5 + OFFSET_Y_REGISTEREMAIL
	swipeSection4:insert(registerEmailTextbox)
	
	BUTTON_GENERIC.onRelease = createReleased
	buttonRegister = widget.newButton(BUTTON_GENERIC)
	buttonRegister.x = 0
	buttonRegister.y = -swipeSection4.height * 0.5 + OFFSET_Y_BUTTONCREATE
	buttonRegister:setLabel(localization.getString("createAccount"))
	swipeSection4:insert(buttonRegister)
	
	local waitTextOptions = {
		x = buttonRegister.x,
		y = buttonRegister.y,
		font = settings.fontName,
		text = localization.getString("waitRegister"),
		fontSize = SIZE_WAIT_TEXT,
		align = "center"
	}
	registerWaitText = display.newText(waitTextOptions)
	registerWaitText:setFillColor(unpack(colors.white))
	swipeSection4:insert(registerWaitText)
	registerWaitText.alpha = 0
	
	local acceptTermsOptions = {
		x = 0,
		y = 0,
		font = settings.fontName,
		text = "",
		fontSize = SIZE_FONT_TERMS,
		align = "center",
		width = 400,
	}
	acceptTerms1 = display.newText(acceptTermsOptions)
	acceptTerms1.anchorY = 0
	acceptTerms1.y = -swipeSection4.height * 0.5 + OFFSET_Y_TERMS
	acceptTerms1:setFillColor(unpack(COLOR_ACCEPT_TERMS1))
	acceptTerms1.text = localization.getString("acceptTerms1")
	swipeSection4:insert(acceptTerms1)
	
	local buttonData = {
		width = 512,
		height = 128,
		font = settings.fontName,
		fontSize = SIZE_FONT_TERMS,
		labelColor = { default = COLOR_ACCEPT_TERMS2, over = COLOR_ACCEPT_TERMS2},
		label = localization.getString("acceptTerms2"),
		onRelease = onTermsTapped,
		textOnly = true,
	}
	
	acceptTerms2 = widget.newButton(buttonData)
	acceptTerms2.anchorY = 0
	acceptTerms2.x = 0
	acceptTerms2.y = acceptTerms1.y + acceptTerms1.height
	swipeSection4:insert(acceptTerms2)
	
	function swipeSection4.update(event)
		
	end
	return swipeSection4
end

local function createSwipeSection5()
	local swipeSection5 = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	
	local title5 = display.newText(localization.getString("onBoardingTitle5"), 0, -swipeSection5.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	title5.anchorY = 0
	title5:setFillColor(unpack(colors.white))
	swipeSection5:insert(title5)
	
	local texboxOptions = {
		backgroundImage = "images/onboarding/field.png",
		backgroundScale = 0.5,
		fontSize = 32,
		font = settings.fontName,
		inputType = "email",
		color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
	}
	
	texboxOptions.placeholder = localization.getString("password")
	texboxOptions.onComplete = loginReleased
	texboxOptions.onChange = storePassword
	local loginPasswordTextbox = textbox.new(texboxOptions)
	loginPasswordTextbox.isPassword = true
	loginPasswordTextbox.y = -swipeSection5.height * 0.5 + OFFSET_Y_LOGINPASSWORD
	swipeSection5:insert(loginPasswordTextbox)
	
	texboxOptions.placeholder = localization.getString("parentEmail")
	texboxOptions.onChange = validateLoginEmail
	texboxOptions.onComplete = function()
		robot.tap(loginPasswordTextbox)
	end
	local loginEmailTextbox = textbox.new(texboxOptions)
	loginEmailTextbox.y = -swipeSection5.height * 0.5 + OFFSET_Y_LOGINEMAIL
	swipeSection5:insert(loginEmailTextbox)
	
	BUTTON_GENERIC.onRelease = loginReleased
	buttonLogin = widget.newButton(BUTTON_GENERIC)
	buttonLogin.x = 0
	buttonLogin.y = -swipeSection5.height * 0.5 + OFFSET_Y_LOGINBUTTON
	buttonLogin:setLabel(localization.getString("login"))
	swipeSection5:insert(buttonLogin)
	
	local waitTextOptions = {
		x = buttonLogin.x,
		y = buttonLogin.y,
		font = settings.fontName,
		text = localization.getString("waitLogin"),
		fontSize = SIZE_WAIT_TEXT,
		align = "center"
	}
	loginWaitText = display.newText(waitTextOptions)
	loginWaitText:setFillColor(unpack(colors.white))
	swipeSection5:insert(loginWaitText)
	loginWaitText.alpha = 0
	
	local buttonData = {
		width = 512,
		height = 128,
		font = settings.fontName,
		fontSize = SIZE_FONT_FORGOT,
		labelColor = { default = colors.white, over = colors.white},
		label = localization.getString("forgotPassword"),
		onRelease = forgotPasswordTapped,
		textOnly = true,
	}
	
	forgotPassword = widget.newButton(buttonData)
	forgotPassword.x = 0
	forgotPassword.y = -swipeSection5.height * 0.5 + OFFSET_Y_FORGOT
	forgotPassword:setFillColor(unpack(COLOR_FORGOT_PASSWORD))
	swipeSection5:insert(forgotPassword)
	
	function swipeSection5.update(event)
		if 4 < event.currentScroll and event.currentScroll < 6 then
			local alpha = math.abs(5 - event.currentScroll)
			goLoginButton.alpha = alpha
		end
	end
	return swipeSection5
end

local function createSwipeSections()
	swipeSections = {}
	
	local availableCenterPixels = display.viewableContentHeight - 280
	
	local swipeSection1 = createSwipeSection1(availableCenterPixels)
	swipeSections[1] = swipeSection1
	
	local swipeSection2 = createSwipeSection2(availableCenterPixels)
	swipeSections[2] = swipeSection2
	
	local swipeSection3 = createSwipeSection3()
	swipeSections[3] = swipeSection3
	
	local swipeSection4 = createSwipeSection4()
	swipeSections[4] = swipeSection4
	
	local swipeSection5 = createSwipeSection5()
	swipeSections[5] = swipeSection5
	
end

local function startTransition(params)
	params = params or {}
	if not params.skipTransition then
		scrollView:scrollToPosition({x = -500, time = 0, onComplete = function()
			scrollView:scrollToPosition({x = 0, time = 600})
		end})
	end
end
----------------------------------------------- Module functions 
function scene.disableButtons()
	buttonsEnabled = false
end

function scene.enableButtons()
	buttonsEnabled = true
end

function scene:create(event)
	local sceneView = self.view
	
	scrollViewGroup = display.newGroup()
	sceneView:insert(scrollViewGroup)
	
	swipeLearnGroup = display.newGroup()
	sceneView:insert(swipeLearnGroup)
	
	local goLoginButtonData = {
		width = 512,
		height = 128,
		font = settings.fontName,
		fontSize = 24,
		labelColor = { default = colors.white, over = colors.white},
		label = "",
		onRelease = goLogin,
		textOnly = true,
	}
	
	goLoginButton = widget.newButton(goLoginButtonData)
	goLoginButton.x = display.contentCenterX
	goLoginButton.x = OFFSET_ALREADYLOGIN.x
	goLoginButton.y = OFFSET_ALREADYLOGIN.y
	sceneView:insert(goLoginButton)
	
	local logo = display.newImage("images/onboarding/logo.png")
	logo.anchorX = 1
	logo.anchorY = 1
	logo.x = display.screenOriginX + display.viewableContentWidth
	logo.y = display.screenOriginY + display.viewableContentHeight
	logo:scale(SCALE_LOGO,SCALE_LOGO)
	sceneView:insert(logo)
	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		scene.disableButtons()
		initialize(event)
		createScrollView()
		createSwipeSections()
		populateScrollView()
		createSwipeLearn()
		addRuntimeListener()
		startTransition(event.params)
	elseif phase == "did" then
		scene.enableButtons()
	end
end

function scene:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		self.disableButtons()
	elseif phase == "did" then
		transition.cancel(TAG_TRANSITION_SCROLLVIEW)
		removeRuntimeListener()
		removeScrollView()
	end
end

----------------------------------------------- Execution
scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene
