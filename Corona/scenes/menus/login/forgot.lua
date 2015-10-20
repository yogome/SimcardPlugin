----------------------------------------------- Scene
local director = require( "libs.helpers.director" )
local settings = require( "settings" )
local localization = require ( "libs.helpers.localization" )
local colors = require( "libs.helpers.colors" )
local widget = require( "widget" )
local textbox = require( "libs.helpers.textbox" )
local internet = require( "libs.helpers.internet" )
local json = require( "json" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonsEnabled
local buttonRecover
local isBusy
local validEmail
local email
local buttonRecover
local waitText
local currentLoop, waitTextLoop
local recoverTitle, emailTextbox
----------------------------------------------- Constants
local PADDING = 16 

local OFFSET_ALREADYLOGIN = {x = display.contentCenterX, y = display.screenOriginY + display.viewableContentHeight - 80}
local COLOR_CIRCLE_SELECTED = colors.convertFrom256({43, 33, 88})

local LOOP_UPDATE_WAITTEXT = 50
local OFFSET_Y_FORGOTEMAIL = 150
local OFFSET_Y_RECOVERBUTTON = 250
local SIZE_FONT_TITLE = 46
local OFFSET_Y_TITLE = 30
local FONTNAME_TITLE = settings.fontName
local SIZE_WAIT_TEXT = 30

local TAG_TRANSITION_RECOVER = "tagTransitionLogin"

local COLOR_BACKGROUNDS = colors.convertFromHex("00a4e4")

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

local BUTTON_BACK = { width = 64, height = 64, defaultFile = "images/onboarding/back1.png", overFile = "images/onboarding/back2.png"}
----------------------------------------------- Caches
----------------------------------------------- Functions
local function showLoginElements()
	transition.to(buttonRecover, {tag = TAG_TRANSITION_RECOVER, time = 400, alpha = 1, transition = easing.inQuad})
	transition.to(waitText, {tag = TAG_TRANSITION_RECOVER, time = 600, alpha = 0, transition = easing.outQuad})
end

local function cancelTransitionAndShowButtons()
	transition.cancel(TAG_TRANSITION_RECOVER)
	showLoginElements()
end

local function recoverListener(event)
	isBusy = false
	if event.isError then
		native.showAlert( "Error", localization.getString("errorServer"), { localization.getString("ok") })
		scene.enableButtons()
		cancelTransitionAndShowButtons()
	else
		local luaResponse = json.decode(event.response)
		if luaResponse and "success" == luaResponse.status then
			native.showAlert( localization.getString("success"), localization.getString("recoverSuccess"), { localization.getString("ok") }, function(event)
				if "clicked" == event.action then
					director.gotoScene("scenes.menus.login.onboarding", {effect = "slideUp", time = 800, params = {skipTransition = true}})
				end
			end)
		elseif luaResponse == nil then
			native.showAlert( localization.getString("error"), localization.getString("errorGeneral"), { localization.getString("ok") })
			scene.enableButtons()
			cancelTransitionAndShowButtons()
		end
	end
end 

local function loginReleased(event)
	native.setKeyboardFocus(nil)
	if validEmail then
		if internet.isConnected() and not isBusy then
			isBusy = true
			local body = {
				email = email,
				language = localization.getLanguage(),
			}
			local params = {
				headers = {
					["Content-Type"] = settings.server.contentType,
					["X-API-Key"] = settings.server.contentType,
				},
				body = json.encode(body)
			}
			scene.disableButtons()
			transition.to(buttonRecover, {tag = TAG_TRANSITION_RECOVER, time = 400, alpha = 0, transition = easing.inQuad})
			transition.to(waitText, {tag = TAG_TRANSITION_RECOVER, time = 600, alpha = 1, transition = easing.outQuad})
	
			network.request(settings.server.hostname.."/users/parent/recover", "POST", recoverListener, params )
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
end

local function onBackReleased()
	director.gotoScene("scenes.menus.login.onboarding", {effect = "slideRight", time = 800, params = {skipTransition = true}})
end

local function updateDynamicObjects()
	currentLoop = currentLoop + 1
	if waitText then
		if currentLoop % LOOP_UPDATE_WAITTEXT == 0 then
			waitTextLoop = waitTextLoop + 1
			if waitTextLoop > 3 then
				waitTextLoop = 0
			end
			local dots = ""
			for index = 1, waitTextLoop do
				dots = dots.."."
			end
			waitText.text = localization.getString("wait")..dots
		end
	end
end

local function initialize(event)
	email = ""
	isBusy = false
	validEmail = false
	
	waitText.text = localization.getString("wait")
	recoverTitle.text = localization.getString("recoverPassword")
	emailTextbox.placeholderText.text = localization.getString("email")
	buttonRecover:setLabel(localization.getString("recover"))
	
	currentLoop = 0
	waitTextLoop = 0
	Runtime:addEventListener("enterFrame", updateDynamicObjects)
	
	cancelTransitionAndShowButtons()
end

local function validateLoginEmail(event)
	local field = event.target
	email = string.lower(field.value) or ""
	if email:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") then
		validEmail = true
	else
		validEmail = false
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
	
	local sceneContainer = display.newContainer(display.viewableContentWidth, display.viewableContentHeight)
	sceneContainer.x = display.contentCenterX
	sceneContainer.y = display.contentCenterY
	sceneView:insert(sceneContainer)

	local background = display.newRect(sceneContainer, 0, 0, sceneContainer.width, sceneContainer.height)
	background:setFillColor(unpack(COLOR_BACKGROUNDS))
	
	recoverTitle = display.newText(localization.getString("onBoardingTitle5"), 0, -sceneContainer.height * 0.5 + OFFSET_Y_TITLE, FONTNAME_TITLE, SIZE_FONT_TITLE)
	recoverTitle.anchorY = 0
	recoverTitle:setFillColor(unpack(colors.white))
	sceneContainer:insert(recoverTitle)
	
	local texboxOptions = {
		backgroundImage = "images/onboarding/field.png",
		backgroundScale = 0.5,
		fontSize = 32,
		font = settings.fontName,
		inputType = "email",
		color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
	}
	
	texboxOptions.placeholder = localization.getString("email")
	texboxOptions.onChange = validateLoginEmail
	texboxOptions.onComplete = loginReleased
	emailTextbox = textbox.new(texboxOptions)
	emailTextbox.y = -sceneContainer.height * 0.5 + OFFSET_Y_FORGOTEMAIL
	sceneContainer:insert(emailTextbox)
	
	BUTTON_GENERIC.onRelease = loginReleased
	buttonRecover = widget.newButton(BUTTON_GENERIC)
	buttonRecover.x = 0
	buttonRecover.y = -sceneContainer.height * 0.5 + OFFSET_Y_RECOVERBUTTON
	sceneContainer:insert(buttonRecover)
	
	local waitTextOptions = {
		x = buttonRecover.x,
		y = buttonRecover.y,
		font = settings.fontName,
		text = localization.getString("wait"),
		fontSize = SIZE_WAIT_TEXT,
		align = "center"
	}
	waitText = display.newText(waitTextOptions)
	waitText:setFillColor(unpack(colors.white))
	sceneContainer:insert(waitText)
	waitText.alpha = 0
	
	BUTTON_BACK.onRelease = onBackReleased
	local backButton = widget.newButton(BUTTON_BACK)
	backButton.x = display.screenOriginX + PADDING + backButton.width * 0.5
	backButton.y = display.screenOriginY + PADDING + backButton.height * 0.5
	sceneView:insert(backButton)
	
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		scene.disableButtons()
		initialize(event)
	elseif phase == "did" then
		scene.enableButtons()
	end
end

function scene:hide( event )
	local sceneView = self.view
	local phase = event.phase

	if phase == "will" then
		self.disableButtons()
		native.setKeyboardFocus( nil )
	elseif phase == "did" then
		native.setKeyboardFocus( nil )
		Runtime:removeEventListener("enterFrame", updateDynamicObjects)
	end
end

----------------------------------------------- Execution
scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene


