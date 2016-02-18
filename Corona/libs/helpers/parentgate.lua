-------------------------------------------- Parent gate
local path = ...
local folder = path:match("(.-)[^%.]+$")
local director = require( folder.."director" )
local widget = require( "widget" )
local sound = require( folder.."sound" )
local database = require( folder.."database" )

local parentgate = director.newScene()

-------------------------------------------- Variables
local buttonBack
local questionGroup
local soundID
local nextScene, onCorrect
local buttonsEnabled
local nextSceneParams
-------------------------------------------- Constants
local padding = 16 
local imagePath = string.gsub(folder,"[%.]","/")
local decorationBarColor = {36/255, 174/255, 195/255}
local possibleAnswers = 5
local function playSound()
	if soundID then
		sound.play(soundID)
	end
end

local buttonData = {
	back = { width = 128, height = 128, defaultFile = imagePath.."images/back.png", overFile = imagePath.."images/back.png", onPress = playSound},
	number = { width = 128, height = 128, defaultFile = imagePath.."images/buttonBackground.png", overFile = imagePath.."images/buttonBackground.png", onPress = playSound, label = "", fontSize = 45, labelColor = { default={ 1, 1, 1 }, over={ 0.5, 0.5, 0.5} }},
}
-------------------------------------------- Functions
local function onReleasedBack()
	if buttonsEnabled then
		buttonsEnabled = false
		director.gotoScene(director.getSceneName("previous"), {effect = "slideUp", time = 1000})
	end
end

local function onReleasedWrong(event)
	if buttonsEnabled then
		buttonsEnabled = false
		local button = event.target
		button:setFillColor(1,0,0)

		timer.performWithDelay(400, function()
			director.gotoScene(director.getSceneName("previous"), {effect = "slideUp", time = 1000})
		end)
	end
end

local function onReleasedCorrect(event)
	if buttonsEnabled then
		buttonsEnabled = false
		
		local button = event.target
		button:setFillColor(0,1,0)
		
		if onCorrect and "function" == type(onCorrect) then
			onCorrect()
		end
		
		timer.performWithDelay(400, function()
			director.gotoScene(nextScene, {effect = "slideUp", time = 1000, params = nextSceneParams})
		end)
	end
end

local function createQuestion(parent)
	local language = database.config("language") or "en"

	display.remove(questionGroup)
	questionGroup = nil

	questionGroup = display.newGroup()
	parent:insert(questionGroup)

	local warning = display.newImage(imagePath.."images/parentText_"..language..".png")
	warning.x = display.contentCenterX
	warning.y = display.contentCenterY - 150
	questionGroup:insert(warning)

	local operand1 = math.random(25,75)
	local operand2 = math.random(51,99)
	local answer = operand1 + operand2

	local textOptions = {
		x = display.contentCenterX, 
		y = display.contentCenterY,
		align = "center",
		text = tostring(operand1).." + "..tostring(operand2).." = ?",
		fontSize = 60,
		font = native.systemFontBold,
	}

	local questionText = display.newText(textOptions)
	questionText:setFillColor(0)
	questionGroup:insert(questionText)

	local correctIndex = math.random(1, possibleAnswers)
	local answers = {}
	answers[correctIndex] = answer
	local allUniqueNumbers = false
	repeat
		allUniqueNumbers = true
		for index = 1, possibleAnswers do
			if index ~= correctIndex then
				answers[index] = 20 + 20 * index + math.random(0,20) 
				if answers[index] == answer then
					allUniqueNumbers = false
				end
			end
		end
	until allUniqueNumbers

	local startingX = display.contentCenterX - ((buttonData.number.width + padding) * (possibleAnswers - 1)) * 0.5
	for index = 1, possibleAnswers do
		buttonData.number.onRelease = index == correctIndex and onReleasedCorrect or onReleasedWrong
		buttonData.number.label = tostring(answers[index])

		local answerButton = widget.newButton(buttonData.number)
		answerButton.number = answers[index]
		answerButton.x = startingX + (index - 1) * (buttonData.number.width + padding)
		answerButton.y = display.contentCenterY + 150
		questionGroup:insert(answerButton)
	end
end

-------------------------------------------- Module functions
function parentgate.backAction()
	onReleasedBack()
	return true
end

function parentgate.disableButtons()
	buttonsEnabled = false
	buttonBack:setEnabled(false)
end

function parentgate.enableButtons()
	buttonsEnabled = true
	buttonBack:setEnabled(true)
end

function parentgate.setButtonSoundID(newID)
	soundID = newID
end

function parentgate:create(event)
	local sceneGroup = self.view

	local background = display.newRect(display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background:setFillColor(1)
	sceneGroup:insert(background)

	buttonData.back.onRelease = onReleasedBack
	buttonBack = widget.newButton(buttonData.back)
	buttonBack.x = display.screenOriginX + buttonBack.width * 0.5 + padding
	buttonBack.y = display.screenOriginY + buttonBack.height * 0.5 + padding
	sceneGroup:insert(buttonBack)

	local decorationRectangleHeight = buttonBack.height + padding * 2
	local decorationBar = display.newRect(sceneGroup, display.contentCenterX, display.screenOriginY + decorationRectangleHeight * 0.5, display.viewableContentWidth + 2, decorationRectangleHeight)
	decorationBar:setFillColor(unpack(decorationBarColor))

	buttonBack:toFront()
end

function parentgate:destroy()
	
end

function parentgate:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		local params = event.params or {}
		nextScene = params.nextScene or director.getSceneName("previous") or path
		nextSceneParams = params.nextSceneParams or {}
		onCorrect = params.onCorrect

		self.disableButtons()
		createQuestion(sceneGroup)
	elseif ( phase == "did" ) then
		self.enableButtons()
	end
end

function parentgate:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then

	end
end

-------------------------------------------- Execution
parentgate:addEventListener( "create", parentgate )
parentgate:addEventListener( "destroy", parentgate )
parentgate:addEventListener( "hide", parentgate )
parentgate:addEventListener( "show", parentgate )

return parentgate
