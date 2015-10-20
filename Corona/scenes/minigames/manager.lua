------------------------------------------------ Minigames manager 2
local managerPath = ...
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local settings = require( "settings" )
local offlinequeue = require( "libs.helpers.offlinequeue" )
local logger = require( "libs.helpers.logger" )
local settings = require( "settings" )
local json = require( "json" )
local extraFile = require( "libs.helpers.extrafile" )
local educationService  = require( "services.education" )
local players = require( "models.players" )
local localization = require( "libs.helpers.localization" )
local banners = require( "libs.helpers.banners" )
local music = require( "libs.helpers.music" )
local sound = require( "libs.helpers.sound" )
local mixpanel = require( "libs.helpers.mixpanel" )
local database = require( "libs.helpers.database" )
local onboarding = require("data.onboarding")
local educationCompletion = require("data.education.completion")

local manager = director.newScene()
------------------------------------------------ Variables
local currentPlayer
local minigameDictionary
local minigameBar
local initialized
local sceneParameters
local readyGoTimer
local sessionStartTime
local readyGo
local currentMinigameIndex
local chosenMinigames
local nextScene, nextSceneParameters
local answers
local answerLock
local cubesPerMinigame, maxPowerCubes, currentPowerCubes
local onComplete, onChange
local amountMinigames, correctAnswers
local perfectTimer, perfectImage
local winScreen, loseScreen
local cross, checkmark
local musicTrack
local showAdvancedResults
local sessionEndTime, totalSessionTime
local minigameTimeBegin
local isDemoSession, screenshotMode, skipWindows
local oldNewText
local mui
------------------------------------------------ Constants
local DEFAULT_MANAGER_UI = "scenes.minigames.mui" 

local DIRECTION_MINIGAMESBAR = "vertical"
local FULLSCREEN_BAR = false 
local DIRECTORY_MINIGAMES = "gamefiles/"
local DEFAULT_PARTIME_AVERAGE = 15

local PLATFORMNAME = system.getInfo("platformName")
local IS_MAC = PLATFORMNAME == "Mac OS X"
local KEYCODE_ENTER = IS_MAC and 36 or 13

local DEFAULT_MAX_POWERCUBES = 25

local RATIO_EXTRAHEIGHT = 1.1

local TIME_TOTAL_PERFECT = 1800
local TIME_TOTAL_PERFECT_THIRD = TIME_TOTAL_PERFECT / 3

local TIME_READYGO = 3500
local DELAY_READYGO = 400

local TIME_MINIGAME_SHOW = 500

local DEFAULT_MINIGAME_DATA = {available = false}

local THICKNESS_MINIGAMESBAR_LINE = 8
local RADIUS_MINIGAMESBAR_CIRCLE_BASE = FULLSCREEN_BAR and 20 or 15

local COLOR_MINIGAMESBAR = FULLSCREEN_BAR and colors.convertFrom256({3,58,73}) or colors.white

local IMAGE_MINIGAMESBAR_CIRCLE_WRONG = "images/manager/incorrecto.png"
local IMAGE_MINIGAMESBAR_CIRCLE_CORRECT = "images/manager/correcto.png"
local IMAGE_MINIGAMESBAR_CIRCLE_OTHER = "images/manager/vacio.png"

local POSITION_MINIGAMESBAR = 35
local PADDING_ICONS_MINIGAMESBAR = FULLSCREEN_BAR and 42 or 60

local COLOR_BACKGROUND = colors.convertFrom256({127, 32, 226})
local DEFAULT_MUSIC_TRACK = 1
------------------------------------------------ Functions
local function removeMinigamesBar()
	display.remove(minigameBar)
	minigameBar = nil
end 

local function gotoNextScene()
	if currentPowerCubes > maxPowerCubes then
		currentPowerCubes = maxPowerCubes
	end
	
	local event = {
		amountMinigames = amountMinigames,
		correctAnswers = correctAnswers,
		powerCubes = currentPowerCubes,
		answers = answers,
	}
	
	local function finishManager()
		if nextScene then
			director.hideOverlay("fade", 400)
			director.performWithDelay(managerPath, 600, function()
				nextSceneParameters = nextSceneParameters or {}
				nextSceneParameters.event = event
				director.gotoScene(nextScene, {effect = "fade", time = 600, params = nextSceneParameters})
			end)
		end
	end
	
	event.complete = finishManager
    event.retry = manager.retry
	
	if showAdvancedResults then
		music.fade(200)
		local incorrectAnswers = amountMinigames - correctAnswers
		local won = currentPowerCubes > incorrectAnswers

		local parametersWinLose = {
			correctAnswers = correctAnswers,
			incorrectAnswers = incorrectAnswers,
			powerCubes = currentPowerCubes,
			onComplete = won and finishManager or manager.retry,
		}
		local winLose = won and "scenes.minigames.win" or "scenes.minigames.lose"
		if minigameBar then
			manager.view:insert(minigameBar)
		end
		director.showOverlay(winLose, {isModal = true, effect = "fade", time = 800, params = parametersWinLose})
	else
		if onComplete and "function" == type(onComplete) then
			onComplete(event)
		else
			finishManager()
		end
	end
end

local function saveSession()
	sessionEndTime = os.time(os.date( "*t" ))
	totalSessionTime = sessionEndTime - sessionStartTime
	if initialized then
		correctAnswers = 0
		for answerIndex = 1, #answers do
			if answers[answerIndex].correct then
				correctAnswers = correctAnswers + 1
			end
		end
		
		local remoteID = currentPlayer.remoteID
		local educationID = currentPlayer.educationID or remoteID
		
		local savedEmail = database.config(onboarding.currentUserEmail.key)
		local savedPassword = database.config(onboarding.currentUserPassword.key)
		
		if remoteID and savedEmail and savedPassword then
			local testDayOffset = (60 * 60 * 24) * (manager and manager.dayOffset or 0)
			-- TODO add extra data?
			
			local bodyData = {
				email = savedEmail,
				password = savedPassword,
				educationID = educationID,
				session = {
					game = settings.gameName,
					version = settings.gameVersion,
					timeStamp = tostring(math.floor(sessionStartTime + testDayOffset) * 1000),
					answers = answers,
				},
			}

			local url = settings.hostname.."/sessions"
 			offlinequeue.request(url, "POST", {
				headers = {
					["Content-Type"] = settings.serverContentType,
					["X-Parse-Application-Id"] = settings.serverAppID,
					["X-Parse-REST-API-Key"] = settings.serverRestKey,
				},
				body = json.encode(bodyData),
			}, "minigameManager")
		elseif not remoteID then
			logger.error("[Minigame Manager] Player does not have a remoteID! Will not send session data.")
		else
			logger.error("[Minigame Manager] There is no valid session. Log in to send session.")
		end
	else
		logger.error("[Minigame Manager] Is not initialized! Session saving might not work as expected!")
	end
end

local function saveEducationData(subject, topic, subtopic, wasCorrect)
	currentPlayer.educationData = currentPlayer.educationData or {}
	currentPlayer.educationData[subject] = currentPlayer.educationData[subject] or {}
	currentPlayer.educationData[subject][topic] = currentPlayer.educationData[subject][topic] or {}
	currentPlayer.educationData[subject][topic][subtopic] = currentPlayer.educationData[subject][topic][subtopic] or {currentExp = 0}
	
	local currentExp = currentPlayer.educationData[subject][topic][subtopic].currentExp or 0
	local expWon = wasCorrect and 1 or -0.5
	currentExp = currentExp + expWon
	
	currentExp = currentExp > 0 and currentExp or 0
	currentPlayer.educationData[subject][topic][subtopic].currentExp = currentExp
	
	local grade = currentPlayer.grade or 1
	local gradeCompletion = educationCompletion.grade[grade] or {}
	local subjectCompletion = gradeCompletion[subject] or {}
	local subtopicCompletion = subjectCompletion[subtopic] or {}
	local maxLevel = subtopicCompletion.completionExp or 100
	
	local completionPercent = (maxLevel / 100) * currentExp
	completionPercent = completionPercent > 100 and 100 or completionPercent
	completionPercent = completionPercent < 0 and 0 or completionPercent
	
	return completionPercent
end

local function saveAnswer(wasCorrect)
	local currentMinigame = chosenMinigames[currentMinigameIndex]
	local minigameTimeEnd = system.getTimer()
	local totalTime = minigameTimeEnd - minigameTimeBegin
	
	local minigameParTime = currentMinigame.info.parTime or DEFAULT_PARTIME_AVERAGE
	local maxTime = minigameParTime * 2
	local secondValue = 100 / minigameParTime
	
	local agility = 100 - ((totalTime * 0.001) - minigameParTime) * secondValue
	agility = agility > 100 and 100 or agility
	agility = agility < 0 and 0 or agility
	
	agility = math.round(agility)
	
	local understanding = wasCorrect and 100 or 0
	agility = wasCorrect and agility or 0
	
	local subject = currentMinigame.info.subject or currentMinigame.info.category
	local topic = currentMinigame.params.topic or currentMinigame.params.subcategory
	local subtopic = currentMinigame.params.subtopic or topic
	
	local completionPercent = saveEducationData(subject, topic, subtopic, wasCorrect)
	local subjectState = 1 + (completionPercent / 100)
	
	local answer = {
		subject = subject,
		topic = topic,
		subtopic = subtopic,
		correct = wasCorrect,
		timeAnswered = totalTime,
		agility = agility,
		understanding = understanding,
		subjectState = 1,--string.format("%.03f", subjectState), -- 1 is just started, 2 is completed
		game = currentMinigame.info.folderName,
	}
	
	answers[#answers + 1] = answer
	
	return answer
end

local function isPerfectGame()
	if correctAnswers >= amountMinigames then
		display.remove(perfectImage)
		perfectImage = display.newImage(localization.format("images/manager/perfect_%s.png"))
		perfectImage.x = display.contentCenterX
		perfectImage.y = display.contentCenterY
		perfectImage.xScale = 0.5
		perfectImage.yScale = 0.5
		perfectImage.alpha = 0
		director.to(managerPath, perfectImage, {time = TIME_TOTAL_PERFECT_THIRD, alpha = 1, xScale = 1, yScale = 1, transition = easing.outQuad})
		director.to(managerPath, perfectImage, {delay = TIME_TOTAL_PERFECT_THIRD * 2, time = TIME_TOTAL_PERFECT_THIRD, alpha = 0, xScale = 1.5, yScale = 1.5, transition = easing.outQuad})

		return TIME_TOTAL_PERFECT
	end
	return 1
end

local function nextMinigame()
	local function goNext()
		local nextMinigameName = chosenMinigames[currentMinigameIndex].requirePath
		logger.log([[[Minigames manager] Will now play "]]..chosenMinigames[currentMinigameIndex].info.folderName..[[" ]]..(chosenMinigames[currentMinigameIndex].params.isFirstTime and "for the first time." or ""))
		local musicVolume = chosenMinigames[currentMinigameIndex].info.musicVolume or 1
		music.setVolume(musicVolume)
		director.showScene(nextMinigameName, 2, {effect = "zoomInOutFade", time = TIME_MINIGAME_SHOW, params = chosenMinigames[currentMinigameIndex].params}, manager)
		
		director.performWithDelay(managerPath, TIME_MINIGAME_SHOW - 1, function()
			minigameTimeBegin = system.getTimer()
		end)
	end
	
	answerLock = false
	currentMinigameIndex = currentMinigameIndex + 1
	if currentMinigameIndex <= #chosenMinigames then
		if onChange and "function" == type(onChange) and currentMinigameIndex > 1 then
			local lastMinigameIndex = currentMinigameIndex - 1
			local event = {
				minigameIndex = lastMinigameIndex,
				correct = answers[lastMinigameIndex].correct,
				complete = goNext,
			}
			onChange(event)
		else
			goNext()
		end
	else
		saveSession()
		Runtime:removeEventListener("key", onBackPress)
		mixpanel.logEvent("minigamesEnded", {totalMinigames = #chosenMinigames,totalSessionTime = totalSessionTime})
		director.to(managerPath, minigameBar, {delay = 500, time = 500, alpha = 0, onComplete = removeMinigamesBar})
		perfectTimer = director.performWithDelay(managerPath, isPerfectGame(), function()
			gotoNextScene()
		end)
	end
end

local function createMinigamesBar(phaseAmount)
	
	local circleSize = RADIUS_MINIGAMESBAR_CIRCLE_BASE * 2
	local fullscreenWidth = circleSize * RATIO_EXTRAHEIGHT
	
	local isVertical = DIRECTION_MINIGAMESBAR == "vertical"
	local isHorizontal = not isVertical
	
	minigameBar = display.newGroup()
	minigameBar.isVisible = not screenshotMode
	minigameBar.x = isVertical and (FULLSCREEN_BAR and fullscreenWidth * 0.5 or (display.screenOriginX + POSITION_MINIGAMESBAR)) or display.contentCenterX
	minigameBar.y = isVertical and display.contentCenterY or (isHorizontal and fullscreenWidth * 0.5 or (display.screenOriginY + POSITION_MINIGAMESBAR))
	
	minigameBar.alpha = 0
	display.getCurrentStage():insert(minigameBar)
	
	minigameBar.currentMinigameIndex = 1
	minigameBar.phaseAmount = phaseAmount
	minigameBar.circleBases = {}
	minigameBar.circleCorrect = {}
	minigameBar.circleWrong = {}
	
	local totalLenght = PADDING_ICONS_MINIGAMESBAR * (minigameBar.phaseAmount - 1)
	
	local lineWidth = isHorizontal and totalLenght or THICKNESS_MINIGAMESBAR_LINE
	local lineHeight = isHorizontal and THICKNESS_MINIGAMESBAR_LINE or totalLenght
	
	lineWidth = FULLSCREEN_BAR and isHorizontal and display.viewableContentWidth or lineWidth
	lineHeight = FULLSCREEN_BAR and isVertical and display.viewableContentHeight or lineHeight
	
	lineWidth = FULLSCREEN_BAR and isVertical and fullscreenWidth or lineWidth
	lineHeight = FULLSCREEN_BAR and isHorizontal and fullscreenWidth or lineHeight
	
	local barLine = display.newRect(0, 0, lineWidth, lineHeight)
	barLine:setFillColor(unpack(COLOR_MINIGAMESBAR))
	minigameBar:insert(barLine)
	
	for minigameIndex = 1, minigameBar.phaseAmount do
		local circleOffset = -totalLenght * 0.5 + PADDING_ICONS_MINIGAMESBAR * (minigameIndex - 1)
		
		local positionX = isHorizontal and circleOffset or 0
		local positionY = isVertical and circleOffset or 0
		local barCircleBase = display.newImageRect(IMAGE_MINIGAMESBAR_CIRCLE_OTHER, circleSize, circleSize)
		barCircleBase.x = positionX
		barCircleBase.y = positionY
		minigameBar:insert(barCircleBase)
		
		local barCirlceAnswerCorrect = display.newImageRect(IMAGE_MINIGAMESBAR_CIRCLE_CORRECT, circleSize, circleSize)
		barCirlceAnswerCorrect.x = positionX
		barCirlceAnswerCorrect.y = positionY
		barCirlceAnswerCorrect.alpha = 0
		minigameBar:insert(barCirlceAnswerCorrect)
		
		local barCirlceAnswerWrong = display.newImageRect(IMAGE_MINIGAMESBAR_CIRCLE_WRONG, circleSize, circleSize)
		barCirlceAnswerWrong.x = positionX
		barCirlceAnswerWrong.y = positionY
		barCirlceAnswerWrong.alpha = 0
		minigameBar:insert(barCirlceAnswerWrong)
		
		minigameBar.circleBases[minigameIndex] = barCircleBase
		minigameBar.circleCorrect[minigameIndex] = barCirlceAnswerCorrect
		minigameBar.circleWrong[minigameIndex] = barCirlceAnswerWrong
		
		if minigameIndex == 1 then
			barCircleBase.alpha = 1
		end
		
		local fromVar = isHorizontal and "x" or "y"
		director.from(managerPath, barCircleBase, {[fromVar] = 0, transition = easing.inOutQuad, time = 800})
		director.from(managerPath, barCirlceAnswerCorrect, {[fromVar] = 0, transition = easing.inOutQuad, time = 800})
	end
	
	function minigameBar:answer(correct)
		local circleAnswer = correct and self.circleCorrect[self.currentMinigameIndex] or self.circleWrong[self.currentMinigameIndex]
		circleAnswer.alpha = 0
		circleAnswer.xScale = 0.01
		circleAnswer.yScale = 0.01
		director.to(managerPath, circleAnswer, {time = 1000, alpha = 1, xScale = 1, yScale = 1, transition = easing.outElastic})
		
		if self.currentMinigameIndex < self.phaseAmount then
			local nextCircleBase = self.circleBases[self.currentMinigameIndex + 1]
			director.to(managerPath, nextCircleBase, {time = 1000, alpha = 1, xScale = 1, yScale = 1, transition = easing.outElastic})
		
			self.currentMinigameIndex = self.currentMinigameIndex + 1
		end
	end
	
	local transitionVar = FULLSCREEN_BAR and (isVertical and "x" or "y") or (isVertical and "height" or "width")
	local finalValue = FULLSCREEN_BAR and (isVertical and (display.screenOriginX) - 100 or (display.screenOriginY - 100)) or 1
	
	director.from(managerPath, barLine, {[transitionVar] = finalValue, transition = easing.inOutQuad, time = 800})
	director.to(managerPath, minigameBar, {delay = 200, time = 500, alpha = 1, transition = easing.outQuad})
end

local function createMinigameDictionary()
	minigameDictionary = {}
	local folders = extraFile.getFiles(DIRECTORY_MINIGAMES)
	local goodMinigames = 0
	for index = 1, #folders do
		local minigameName = folders[index]
		if not string.match(minigameName, "%.") then
			local minigamePath = DIRECTORY_MINIGAMES..minigameName.."/game.lua"
			if extraFile.exists(minigamePath) then
				local requirePath = string.gsub(string.sub(minigamePath,1,-5),"[%/]",".")
				local success, message = pcall(function()
					local minigame = require(requirePath)

					goodMinigames = goodMinigames + 1
					minigameDictionary[minigameName] = minigame.getInfo and minigame.getInfo() or DEFAULT_MINIGAME_DATA
					minigameDictionary[minigameName].requirePath = requirePath
					minigameDictionary[minigameName].folderName = minigameName
					minigameDictionary[minigameName].index = goodMinigames
					minigameDictionary[goodMinigames] = minigameDictionary[minigameName]
				end)

				if not success and message then
					logger.error([[[Minigame manager] Minigame "]]..minigameName..[[" contains errors.]])
				end
			end
		end
	end
end

local function prepareChosenMinigames()
	for index = 1, #chosenMinigames do
		currentPlayer.minigameData = currentPlayer.minigameData or {}
		local requirePath = chosenMinigames[index].requirePath
		currentPlayer.minigameData[requirePath] = currentPlayer.minigameData[requirePath] or {timesPlayed = 0}
		chosenMinigames[index].params = chosenMinigames[index].params or {}
		local isFirstTime = currentPlayer.minigameData[chosenMinigames[index].requirePath].timesPlayed == 0
		chosenMinigames[index].params.isFirstTime = isFirstTime
		chosenMinigames[index].params.isDemo = isDemoSession
		-- We add timesplayed from start to prevent repeated first times.
		currentPlayer.minigameData[requirePath].timesPlayed = currentPlayer.minigameData[requirePath].timesPlayed + 1
	end
end

local function saveThumbnail(event)
	if event.nativeKeyCode == KEYCODE_ENTER and "down" == event.phase then
		local thumbnailPath = chosenMinigames[currentMinigameIndex].info.requirePath:match("(.-)[^%.]+$")
		thumbnailPath = string.gsub(thumbnailPath,"[%.]","/")

		display.save(display.getCurrentStage(), { filename = "thumbnail.png", baseDir = system.DocumentsDirectory})

		local resourceDirectory = system.pathForFile(nil, system.ResourceDirectory)
		local documentsDirectory = system.pathForFile(nil, system.DocumentsDirectory)
		local executeHandle = io.popen("cd '"..documentsDirectory.."';cp thumbnail.png '"..resourceDirectory.."/"..thumbnailPath.."'")
		executeHandle:close()			
		logger.log([[[Manager] saved thumbnail for "]]..chosenMinigames[currentMinigameIndex].info.folderName..[["]])
		manager.correct({delay = 0})
	end
end

local function setScreenshotMode(enabled)
	if "simulator" == system.getInfo("environment") then
		screenshotMode = enabled
	end
	
	if enabled then
		oldNewText = display.newText
		display.newText = function(...)
			local newText = oldNewText(...)
			newText.alpha = 0
			local oldTextMetatable = getmetatable(newText)
			setmetatable(newText, {
				__newindex = function(self, key, value)
					getmetatable(self)[key] = value
					if key ~= "alpha" then
						oldTextMetatable.__newindex(self, key, value)
					end
				end,
				__index = function(self, key)
					return oldTextMetatable.__index(self, key)
				end
			})

			return newText
		end
		
		local alert = native.showAlert( "Screenshot mode", "Text is disabled, press ENTER to capture thumbnail", {"OK"}, function() end )
	
		Runtime:addEventListener("key", saveThumbnail)
	end
end

local function onBackPress(event)
	if event.keyName == "back" then
		local backScene = "scenes.menus.worlds"
		director.gotoScene(backScene, {effect = "fade", time = 500})
	end
end

local function startManager(event)
	event = event or {}
	
	currentPlayer = players.getCurrent()
	music.fade(400)
	
	currentPowerCubes = 0
	currentMinigameIndex = 0
	answers = {}
	answerLock = false
	
	sceneParameters = event.params or {}
	nextScene = nextScene or sceneParameters.nextScene or director.getSceneName("previous")
	nextSceneParameters = nextSceneParameters or sceneParameters.nextSceneParameters
	onComplete = sceneParameters.onComplete or onComplete
	musicTrack = sceneParameters.musicTrack or musicTrack or DEFAULT_MUSIC_TRACK
	onChange = sceneParameters.onChange or onChange
	showAdvancedResults = sceneParameters.showAdvancedResults
	amountMinigames = sceneParameters.minigames and #sceneParameters.minigames
	maxPowerCubes = sceneParameters.maxPowerCubes or DEFAULT_MAX_POWERCUBES
	isDemoSession = sceneParameters.isDemo
	skipWindows = sceneParameters.skipWindows
	
	Runtime:addEventListener("key", onBackPress)
	
	mui = require(sceneParameters.muiRequire or DEFAULT_MANAGER_UI)
	
	setScreenshotMode(sceneParameters.screenshotMode)
	
	local specificMinigames = sceneParameters.minigames
	local specificSubject = sceneParameters.subject
	local onlyAvailable = sceneParameters.onlyAvailable
		
	chosenMinigames = {}
	if specificMinigames then
		for index = 1, #specificMinigames do
			if minigameDictionary[specificMinigames[index]] then
				chosenMinigames[#chosenMinigames + 1] = {
					index = minigameDictionary[specificMinigames[index]].index,
					requirePath = minigameDictionary[specificMinigames[index]].requirePath,
					info = minigameDictionary[specificMinigames[index]]
				}
			end
		end
	else
		local educationSession = educationService.getEducationSession(currentPlayer, minigameDictionary, amountMinigames, specificSubject)
		amountMinigames = #educationSession
		chosenMinigames = educationService.selectMinigames(educationSession, minigameDictionary, currentPlayer, onlyAvailable)
	end
	educationService.injectEducationParameters(chosenMinigames, currentPlayer)
	
	cubesPerMinigame = math.ceil(maxPowerCubes / amountMinigames)
	prepareChosenMinigames()
	
	createMinigamesBar(amountMinigames)
	
	local readyGoOptions = {
		readyPath = localization.format("images/manager/banners/ready_%s.png"),
		goPath = localization.format("images/manager/banners/go_%s.png"),
		scales = {1.5,  0.5,0.4,0.4,  0.5,0.4,0.4},
		time = TIME_READYGO,
		delay = DELAY_READYGO,
		language = localization.getLanguage(),
	}
	readyGo = banners.newReadyGo(readyGoOptions)
	display.getCurrentStage():insert(readyGo)
	
	mixpanel.logEvent("minigamesStarted")
	
	readyGoTimer = director.performWithDelay(managerPath, DELAY_READYGO + TIME_READYGO, function()
		sessionStartTime = os.time(os.date( "*t" ))
		nextMinigame()
		music.playTrack(musicTrack, 400)
	end)
end

local function endManager(event)
	event = event or {}
	
	local hideTime = event.effectTime or 0
	local halfTime = hideTime * 0.5
	director.to(managerPath, minigameBar, {alpha = 0, time = halfTime, onComplete = removeMinigamesBar})
	
	music.fade(halfTime)
	
	display.remove(perfectImage)
	perfectImage = nil
	
	if readyGoTimer then
		timer.cancel(readyGoTimer)
		readyGoTimer = nil
	end
	
	if readyGo and readyGo.tag then
		transition.cancel(readyGo.tag)
		display.remove(readyGo)
		readyGo = nil
	end
	
	if screenshotMode then
		screenshotMode = false
		display.newText = oldNewText
		Runtime:removeEventListener("key", saveThumbnail)
	end
	
	mixpanel.updateProfile(nil, {["MinigamesPlayed"] = (chosenMinigames and #chosenMinigames)})
	players.save(currentPlayer)
end

local function removeScreens()
	display.remove(loseScreen)
	loseScreen = nil
	display.remove(winScreen)
	winScreen = nil
	display.remove(cross)
	cross = nil
	display.remove(checkmark)
	checkmark = nil
end
------------------------------------------------ Module Functions
function manager.retry()
	director.to(managerPath, {}, {time = 600, onStart = function()
		director.hideOverlay("fade", 600)
		endManager({effectTime = 400})
	end, onComplete = function()
		removeMinigamesBar()
		removeScreens()
		startManager({params = sceneParameters})
	end})
end

function manager.setMusicTrack(track)
	musicTrack = track
end

function manager.setOnComplete(onCompleteFunction)
	onComplete = onCompleteFunction
end

function manager.setOnChange(onChangeFunction)
	onChange = onChangeFunction
end

function manager.setNextScene(nextSceneName, nextSceneParams)
	nextScene = nextSceneName
	nextSceneParameters = nextSceneParams
end

function manager.correct(options)
	options = options or {}
	
	if not answerLock and minigameBar then
		answerLock = true
		
		local minigameInfo = chosenMinigames[currentMinigameIndex].info
		local correctDelay = options.delay or minigameInfo.correctDelay or 0
		local skipWindow = skipWindows or options.skipWindow
		
		local function finishMinigame()
			director.hideOverlay("fade", 600)
			sound.play("correctAnswer")

			minigameBar:answer(true)
			saveAnswer(true)
			music.setVolume(1)
			if screenshotMode or skipWindow then -- Dont show anything, just skip to next minigame
				nextMinigame()
			else
				checkmark = mui.newCheckmark(managerPath, 700, function()
					winScreen = mui.newWinScreen({powerCubesStart = currentPowerCubes, powerCubesEnd = currentPowerCubes + cubesPerMinigame ,onComplete = nextMinigame})
					currentPowerCubes = currentPowerCubes + cubesPerMinigame
					display.remove(checkmark)
					checkmark = nil
				end)
			end
			mixpanel.logEvent("minigameAnswer", {minigameName = minigameInfo.name, category = minigameInfo.category, correct = true})
		end
		
		if correctDelay <= 0 then
			finishMinigame()
		else
			director.performWithDelay(managerPath, correctDelay, finishMinigame)
		end
	else
		local conflictiveMinigame = chosenMinigames[currentMinigameIndex].info.folderName
		logger.error([[[Minigames manager] "]]..conflictiveMinigame..[[" answered correct too many times!]])
	end
end

function manager.wrong(correctAnswer, options)
	options = options or {}
	
	if not answerLock and minigameBar then
		answerLock = true
		
		local minigameInfo = chosenMinigames[currentMinigameIndex].info
		local wrongDelay = options.delay or minigameInfo.wrongDelay or 0
		local skipWindow = skipWindows or options.skipWindow
		local showTime = options.showTime
		
		local function finishMinigame()
			director.hideOverlay("fade", 600)
			sound.play("wrongAnswer")
			minigameBar:answer(false)
			saveAnswer(false)
			music.setVolume(1)
			
			if screenshotMode or skipWindow then -- Dont show anything, just skip to next minigame
				nextMinigame()
			else
				cross = mui.newCross(managerPath, 500, function()
					loseScreen = mui.newLoseScreen({correctAnswer = correctAnswer, onComplete = nextMinigame, showTime = showTime})
					display.remove(cross)
					cross = nil
				end)
			end
			mixpanel.logEvent("minigameAnswer", {minigameName = minigameInfo.name, category = minigameInfo.category, correct = false})
		end
		
		if wrongDelay <= 0 then
			finishMinigame()
		else
			director.performWithDelay(managerPath, wrongDelay, finishMinigame)
		end
	else
		local conflictiveMinigame = chosenMinigames[currentMinigameIndex].info.folderName
		logger.error([[[Minigames manager] "]]..conflictiveMinigame..[[" answered wrong too many times!]])
	end
end

function manager.initialize()
	if not initialized then
		logger.log("[Minigame Manager] Initializing.")
		initialized = true
		local function managerRequestListener(event)
			if event.isError then
				logger.error("[Minigame Manager] Could not be sent.")
			else
				if event.response then
					local luaResponse = json.decode(event.response)
					if luaResponse then
						if "updated" == luaResponse.status then
							logger.log("[Minigame Manager] Data was sent!")
						else
							logger.error("[Minigame Manager] Data was sent, but server did not respond normally")
						end
					else
						logger.error("[Minigame Manager] Data was sent, but server did not respond normally")
					end
				else
					logger.error("[Minigame Manager] Data was sent, but server did not respond normally")
				end
			end
		end

		offlinequeue.addResultListener("minigameManager", managerRequestListener)
		
		createMinigameDictionary()
	end
end

function manager.getMinigameDictionary()
	if initialized then
		return minigameDictionary
	else
		logger.error("[Manager] you must initialize first.")
	end
end

function manager:create(event)
	local sceneView = self.view
	
	local skipMinigamesButton = display.newRect(display.screenOriginX + 50, display.screenOriginY + 50, 100, 100)
	skipMinigamesButton.isHitTestable = true
	skipMinigamesButton.isVisible = false
	sceneView:insert(skipMinigamesButton)
	local skipTapCount = 0
	skipMinigamesButton:addEventListener("tap", function()
		skipTapCount = skipTapCount + 1
		if skipTapCount == 4 then
			skipTapCount = 0
			if currentMinigameIndex > 0 and currentMinigameIndex <= #chosenMinigames then
				manager.correct({delay = 0, skipWindow = true})
			end
		end
	end)
	
	local background = display.newRect(sceneView, display.contentCenterX, display.contentCenterY, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	background:setFillColor(unpack(COLOR_BACKGROUND))
	
	manager.initialize()
end

function manager:show(event)
	local phase = event.phase

	if phase == "will" then
		startManager(event)
	elseif phase == "did" then

	end
end

function manager:hide(event)
	local phase = event.phase

	if phase == "will" then
		endManager(event)
	elseif phase == "did" then
		removeMinigamesBar()
		removeScreens()
	end
end


function manager:destroy()
	
end
------------------------------------------------ Excution
manager:addEventListener( "create" )
manager:addEventListener( "destroy" )
manager:addEventListener( "hide" )
manager:addEventListener( "show" )

return manager
