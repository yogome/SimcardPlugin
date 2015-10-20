----------------------------------------------- Director - Scene management
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local localization = require( folder.."localization" )
local extratable = require( folder.."extratable" )
local keycodes = require( folder.."keycodes" )
local screen = require( folder.."screen" )
local dialog = require( folder.."dialog" )
local effects = require(folder.."data.effects")

local director = {
	sceneDictionary = {},
	showingScenes = {},
	mode = "director",
	purgeOnSceneChange = false,
	handleLowMemory = true,
	maxSimulatorMemory = 150,
}
----------------------------------------------- Variables
local stage
local touchRect
local variables
local debugDirector, crashProtection
local performanceRecords
local activityIndicator
local editorActive, editorInitialized, editorElements, elementIndex, propertyWindow
local initialized
local editSceneZIndex
----------------------------------------------- Caches
local CONTENT_CENTER_X = display.contentCenterX
local CONTENT_CENTER_Y = display.contentCenterY
local VIEWABLE_CONTENT_WIDTH = display.viewableContentWidth
local VIEWABLE_CONTENT_HEIGHT = display.viewableContentHeight

local stringFormat = string.format
----------------------------------------------- Constants
local SIMULATOR_MEMORY_WARNING_INTERVAL = 10000

local EFFECT_DEFAULT = "crossFade" 
local EFFECT_TIME_DEFAULT = 0

local TIME_INDICATOR_HIDE = 600
local TIME_INDICATOR_FADEIN = 300
local TIME_INDICATOR_SOLID = 400
local TIME_INDICATOR_FADEOUT = 600

local EDIT_MOVE = 10
local EDIT_SIZE = 10
local EDIT_SCALE = 0.1

local EVENT_DATA = {
	["director"] = {
		onCreate = {name = "create"},
		onDestroy = {name = "destroy"},
		onWillShow = {name = "show", phase = "will"},
		onDidShow = {name = "show", phase = "did"},
		onWillHide = {name = "hide", phase = "will"},
		onDidHide = {name = "hide", phase = "did"},
	},
	["composer"] = {
		onCreate = {name = "create"},
		onDestroy = {name = "destroy"},
		onWillShow = {name = "show", phase = "will"},
		onDidShow = {name = "show", phase = "did"},
		onWillHide = {name = "hide", phase = "will"},
		onDidHide = {name = "hide", phase = "did"},
	},
	["storyboard"] = {
		onCreate = {name = "createScene"},
		onDestroy = {name = "destroyScene"},
		onWillShow = {name = "willEnterScene"},
		onDidShow = {name = "enterScene"},
		onWillHide = {name = "exitScene"},
		onDidHide = {name = "didExitScene"},
	}
}

local DEFAULT_ZINDEX_OVERLAY = 2
local DEFAULT_ZINDEX = 1
----------------------------------------------- Functions
local function createActivityIndicator()
	local activityIndicator = display.newGroup()
	activityIndicator.x, activityIndicator.y = display.contentCenterX, display.contentCenterY
	
	local fadeRect = display.newRect(0, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	fadeRect:setFillColor(0, 0.5)
	fadeRect:addEventListener("tap", function() return true end)
	fadeRect:addEventListener("touch", function() return true end)
	activityIndicator:insert(fadeRect)
	
	local DISTANCE_BARS = 80
	local NUM_ACTIVITY_BARS = 12
	local degreesBar = 360 / NUM_ACTIVITY_BARS
	
	activityIndicator.bars = {}
	for index = 1, NUM_ACTIVITY_BARS do
		local currentAngle = (index - 1) * degreesBar
		local posX = math.cos(math.rad(currentAngle)) * DISTANCE_BARS
		local posY = math.sin(math.rad(currentAngle)) * DISTANCE_BARS
		
		local bar = display.newRoundedRect(posX, posY, 100, 30, 15)
		bar.strokeWidth = 6
		bar.stroke = {0.5, 0.5, 0.5}
		bar.alpha = 0
		bar.anchorX = 0
		
		bar.rotation = currentAngle
		activityIndicator:insert(bar)
		activityIndicator.bars[index] = bar
	end
	
	function activityIndicator:setColors(fillColor, strokeColor)
		for index = 1, NUM_ACTIVITY_BARS do
			self.bars[index]:setFillColor(fillColor)
			self.bars[index].stroke = strokeColor
		end
	end
	
	local fadeInTime = TIME_INDICATOR_FADEIN
	local solidTime = TIME_INDICATOR_SOLID
	local fadeOutTime = TIME_INDICATOR_FADEOUT
	local totalAnimationUnit = fadeInTime + solidTime + fadeOutTime
	local overlapTime = totalAnimationUnit * 0.75
	local totalAnimationTime = (totalAnimationUnit * NUM_ACTIVITY_BARS - overlapTime * NUM_ACTIVITY_BARS) - (totalAnimationUnit)
	
	function activityIndicator:fadeAnimation(bar, startDelay)
		transition.to(bar, {delay = startDelay, time = fadeInTime, alpha = 1, onComplete = function()
			transition.to(bar, {delay = solidTime, time = fadeOutTime, alpha = 0, onComplete = function()
				self:fadeAnimation(bar, totalAnimationTime)
			end})
		end})
	end
	
	function activityIndicator:animate(value)
		transition.cancel(self)
		if value then
			for index = 1, NUM_ACTIVITY_BARS do
				self.bars[index].alpha = 0
				local startDelay = (index - 1) * (totalAnimationUnit - overlapTime)
				self:fadeAnimation(self.bars[index], startDelay)
			end
		else
			local function hideSelf()
				self.alpha = 0
				for index = 1, NUM_ACTIVITY_BARS do
					self.bars[index].alpha = 0
				end
			end
			transition.to(self, {time = TIME_INDICATOR_HIDE, alpha = 0, onCancel = hideSelf, onComplete = hideSelf})
		end
	end
	
	return activityIndicator
end

local function performanceHook(object, event)
	performanceRecords = performanceRecords or {}
	
	local totalChildren = 0
	local maxNesting = 0
	
--	local childrenList = {}

	local function countChildren(group, indexNesting)
		indexNesting = indexNesting + 1
		if group.numChildren then
			for index = 1, group.numChildren do
				local displayObject = group[index]
				if displayObject.numChildren then
					countChildren(displayObject, indexNesting)
				end
--				childrenList[#childrenList + 1] = childrenList
				totalChildren = totalChildren + 1
			end
		end
		if indexNesting > maxNesting then
			maxNesting = indexNesting
		end
	end
	
	local function measurePerformance(phase)
		countChildren(object.view, 0)
				
		performanceRecords[object._name] = performanceRecords[object._name] or {}
		performanceRecords[object._name][phase] = performanceRecords[object._name][phase] or {
			name = object._name,
			phase = phase,
			maxNesting = maxNesting,
			totalChildren = totalChildren,
--			childrenList = childrenList,
			measurements = 0,
			nestingWarnings = 0,
			childrenWarnings = 0,
		}

		performanceRecords[object._name][phase].measurements = performanceRecords[object._name][phase].measurements + 1
		local nestingWarning = false
		local childrenWarning = false
		
--		local oldChildrenList = performanceRecords[object._name][phase].childrenList
--		local leakedObjects = {}
--		for index = 1, #childrenList do
--			local child = childrenList[index]
--			if not extratable.containsValue(oldChildrenList, child) then
--				leakedObjects[#leakedObjects + 1] = child
--			end
--		end
--		performanceRecords[object._name][phase].childrenList = childrenList
		
		local previousMaxNesting = performanceRecords[object._name][phase].maxNesting
		if maxNesting > previousMaxNesting then
			performanceRecords[object._name][phase].maxNesting = maxNesting
			performanceRecords[object._name][phase].nestingWarnings = performanceRecords[object._name][phase].nestingWarnings + 1
			nestingWarning = true
		end

		local previousTotalChildren = performanceRecords[object._name][phase].totalChildren
		if totalChildren > previousTotalChildren then
			performanceRecords[object._name][phase].totalChildren = totalChildren
			performanceRecords[object._name][phase].childrenWarnings = performanceRecords[object._name][phase].childrenWarnings + 1
			childrenWarning = true
		end
		
		if performanceRecords[object._name][phase].measurements > 3 then
			if nestingWarning or childrenWarning then
				logger.error([[[Director] scene "]]..object._name..[[" might have a graphic memory leak. C]]..previousTotalChildren..[[:]]..performanceRecords[object._name][phase].totalChildren..[[ N]]..previousMaxNesting..[[:]]..performanceRecords[object._name][phase].maxNesting..[[ M]]..performanceRecords[object._name][phase].measurements)
			end
		end
	end
			
	if object and object.view then
		if event.name == "show" and event.phase == "will" then
			measurePerformance("show-will")
		end
	end
end

local function localizationHook(scene, event)
	if event and (event.name == EVENT_DATA.composer.onWillShow.name and event.phase == EVENT_DATA.composer.onWillShow.phase) or event.name == EVENT_DATA.storyboard.onWillShow or event.force then
		if scene and scene._texts then
			for index = 1, #scene._texts do
				if scene._texts[index] and scene._texts[index].text and scene._texts[index].stringID then
					scene._texts[index].text = localization.getString(scene._texts[index].stringID)
				end
			end
		end
		
		if scene and scene._images then
			for index = 1, #scene._images do
				if scene._images[index] and scene._images[index].localizedPath then
					scene._images[index].fill = {type = "image", filename = localization.format(scene._images[index].localizedPath)}
				end
			end
		end
	end
end

local function eventDispatcher(scene, event)
	if debugDirector then
		logger.log("[Director] Dispatching event:"..event.name..(event.phase and (", phase:"..event.phase) or ""))
	end
	
	localizationHook(scene, event)
	performanceHook(scene, event)
	
	if crashProtection then
		local success, message = pcall(function() scene:dispatchEvent(event) end)
		if not success then
			logger.error([[[Director] Crash protection prevented a critical crash on ]]..scene._name..[[ on  event "]]..event.name..[["]])
			logger.error(message)
		end
	else
		scene:dispatchEvent(event)
	end
end

local function cancelSceneTimers(scene)
	if scene and scene._timers and "table" == type(scene._timers) then
		for index = #scene._timers, 1, -1 do
			if scene._timers[index] then
				timer.cancel(scene._timers[index])
			end
		end
		scene._timers = {}
	end
end

local function cancelSceneTransitions(scene)
	if scene and scene._transitions and "table" == type(scene._transitions) then
		for index = #scene._transitions, 1, -1 do
			if scene._transitions[index] then
				transition.cancel(scene._transitions[index])
			end
		end
		scene._transitions = {}
	end
end

local function initializeEditor()
	if not editorInitialized then
		editorInitialized = true
		
		elementIndex = 1
		
		local customBlend = {
			srcColor = "oneMinusDstColor",
			dstColor = "zero",
		}
		
		local cursor = display.newGroup()
		cursor.isVisible = false
		
		local cursorRect = display.newRect(cursor, 0, 0, 100, 100)
		cursorRect.fill = {0,0,0,0}
		cursorRect.strokeWidth = 3
		cursorRect.stroke.blendMode = customBlend
		
		local cursorAnchor = display.newCircle(cursor, 0, 0, 8)
		cursorAnchor.fill.blendMode = customBlend
		
		local cursorOrigin = screen.newGrid(nil, nil, nil, 2)
		cursorOrigin:setFillColor(1,0,0,0.8)
		cursor:insert(cursorOrigin)
		
		cursor.rect = cursorRect
		cursor.anchor = cursorAnchor
		cursor.origin = cursorOrigin
		
		function cursor:selectObject(displayObject)
			if displayObject then
				if displayObject.localToContent and displayObject.x and displayObject.y and displayObject.contentWidth and displayObject.contentHeight and displayObject.anchorX and displayObject.anchorY then
					local x, y = displayObject.parent:localToContent(displayObject.x, displayObject.y)
					local width = (displayObject.width or 0) * (displayObject.xScale >= 0 and displayObject.xScale or -displayObject.xScale)
					local height = (displayObject.height or 0) * (displayObject.yScale >= 0 and displayObject.yScale or -displayObject.yScale)
					local anchorX, anchorY = displayObject.anchorX, displayObject.anchorY
					
					self.rect.anchorX, self.rect.anchorY = anchorX, anchorY
					self.rect.x, self.rect.y = x, y
					self.rect.rotation = screen.getContentRotation(displayObject)

					self.anchor.x, self.anchor.y = x, y
					
					self.origin.x, self.origin.y = displayObject.parent:localToContent(0, 0)
					self.origin.rotation = screen.getContentRotation(displayObject.parent)
					
					if displayObject.numChildren then
						if displayObject._widgetType then -- Is widget
							self.rect.x, self.rect.y = displayObject.x, displayObject.y
							self.rect.width, self.rect.height = width, height
							
						else -- Is group
							if displayObject.anchorChildren then -- has anchorChildren
								self.rect.width, self.rect.height = width, height
							else
								self.rect.width, self.rect.height = 0, 0
							end
						end
					else
						self.rect.width, self.rect.height = width, height
					end
				end
			end
		end
		
		editorElements = {}
		editorElements.cursor = cursor
		editorElements.editObjects = {}
	end
end

local function setupEditingElements(scene)
	local view = scene.view
	
	local editingElements = {}
	
	local function addChildren(group, indexNesting)
		indexNesting = indexNesting + 1
		if group.numChildren then
			for index = 1, group.numChildren do
				local displayObject = group[index]
				if displayObject.numChildren then
					addChildren(displayObject, indexNesting)
				end
				
				editingElements[#editingElements + 1] = displayObject
			end
		end
	end
	
	addChildren(view, 0)
	
	return editingElements
end

local function showEditWindow(displayObject)
	display.remove(propertyWindow)
	
	local objectKind = "Display Object"
	if displayObject.numChildren then
		if displayObject._widgetType then
			objectKind = "Widget"
		else
			objectKind = "Display Group"
		end
	elseif displayObject.setSequence and displayObject.play then
		objectKind = "Sprite"
	end
	
	propertyWindow = dialog.newPropertyWindow({
		title = "Edit "..objectKind,
		properties = {
			x = stringFormat("%.02f", displayObject.x),
			y = stringFormat("%.02f", displayObject.y),
			rotation = stringFormat("%.02f", displayObject.rotation),
			alpha = stringFormat("%.02f", displayObject.alpha),
			anchorX = stringFormat("%.02f", displayObject.anchorX),
			anchorY = stringFormat("%.02f", displayObject.anchorY),
			xScale = stringFormat("%.02f", displayObject.xScale),
			yScale = stringFormat("%.02f", displayObject.yScale),
			isVisible = tostring(displayObject.isVisible),
			anchorChildren = tostring(displayObject.anchorChildren),
			text = displayObject.text,
		},
		onSuccess = function(newProperties)
			displayObject.x = tonumber(newProperties.x) or 0
			displayObject.y = tonumber(newProperties.y) or 0
			displayObject.alpha = tonumber(newProperties.alpha) or 1
			displayObject.xScale = tonumber(newProperties.xScale) or 1
			displayObject.yScale = tonumber(newProperties.yScale) or 1
			displayObject.anchorX = tonumber(newProperties.anchorX) or 0.5
			displayObject.anchorY = tonumber(newProperties.anchorY) or 0.5
			displayObject.rotation = tonumber(newProperties.rotation) or 0
			displayObject.isVisible = string.match(tostring(newProperties.isVisible), "true") and true or nil
			displayObject.anchorChildren = string.match(tostring(newProperties.isVisible), "true") and true
			displayObject.text = newProperties.text
			
			timer.performWithDelay(1, function()
				display.remove(propertyWindow)
				propertyWindow = nil
			end)
			editorElements.cursor:selectObject(displayObject)
		end,
		onCancel = function()
			timer.performWithDelay(1, function()
				display.remove(propertyWindow)
				propertyWindow = nil
			end)
			editorElements.cursor:selectObject(displayObject)
		end,
	})
	propertyWindow.x, propertyWindow.y = display.contentCenterX, display.contentCenterY
	display.getCurrentStage():insert(propertyWindow)
end

local function editorKeyListener(event)
	if event.phase == "up" then
		local keycode = event.nativeKeyCode
		local isShiftDown = event.isShiftDown
		local isCtrlDown = event.isCtrlDown
		
		local number = tonumber(event.descriptor)
		
		if propertyWindow and propertyWindow.isEditing then
			if keycode == keycodes["ESC"] then
				if propertyWindow.cancel and "function" == type(propertyWindow.cancel) then
					propertyWindow:cancel()
				end
			elseif keycode == keycodes["ENTER"] and not propertyWindow.isEditing() then
				if propertyWindow.success and "function" == type(propertyWindow.success) then
					propertyWindow:success()
				end
			end
		else
			if isCtrlDown and keycode == keycodes["E"] then
				if not editorActive then
					local currentScene = director.showingScenes[editSceneZIndex] and director.showingScenes[editSceneZIndex].currentScene
					editorElements.editObjects = setupEditingElements(currentScene)
					elementIndex = 1
					
					editorElements.realTime = function()
						if editorElements.editObjects[elementIndex] then
							editorElements.cursor:selectObject(editorElements.editObjects[elementIndex])
						end
					end
					Runtime:addEventListener("enterFrame", editorElements.realTime)
				else
					if editorElements.realTime then
						Runtime:removeEventListener("enterFrame", editorElements.realTime)
						editorElements.realTime = nil
					end
				end
				
				editorActive = not editorActive
				editorElements.cursor.isVisible = editorActive
			end

			if editorActive then
				if number and director.showingScenes[number] then
					if editSceneZIndex ~= number then
						editSceneZIndex = number
						logger.log([[[Director editor] Now editing "]]..director.showingScenes[editSceneZIndex].currentScene._name)
						local currentScene = director.showingScenes[editSceneZIndex] and director.showingScenes[editSceneZIndex].currentScene
						editorElements.editObjects = setupEditingElements(currentScene)
						elementIndex = 1
					end
				end
				local currentScene = director.showingScenes[editSceneZIndex] and director.showingScenes[editSceneZIndex].currentScene
				if not editorElements.editObjects then
					editorElements.editObjects = setupEditingElements(currentScene)
				end
				editorElements.currentEditScene = currentScene

				if editorElements.currentEditScene and editorElements.currentEditScene.view then
					local editObject = editorElements.editObjects[elementIndex]
					
					local editScale = isShiftDown and 0.1 or 1
					
					if keycode == keycodes["Z"] then
						elementIndex = elementIndex - 1
					elseif keycode == keycodes["X"] then
						elementIndex = elementIndex + 1
					elseif keycode == keycodes["ENTER"] then
						showEditWindow(editorElements.editObjects[elementIndex])
					elseif keycode == keycodes["DOWN"] then
						editObject.y = editObject.y + EDIT_MOVE * editScale
					elseif keycode == keycodes["UP"] then
						editObject.y = editObject.y - EDIT_MOVE * editScale
					elseif keycode == keycodes["LEFT"] then
						editObject.x = editObject.x - EDIT_MOVE * editScale
					elseif keycode == keycodes["RIGHT"] then
						editObject.x = editObject.x + EDIT_MOVE * editScale
					elseif keycode == keycodes["P"] then
						local position = isShiftDown and {"object.x = display.contentCenterX + %d\nobject.y = display.contentCenterY + %d", editObject.x - display.contentCenterX, editObject.y - display.contentCenterY} or {"object.x = %d\nobject.y = %d", editObject.x, editObject.y}
						logger.line()
						logger.log(string.format(unpack(position)))
						logger.log(string.format("object.anchorX = %.02f\nobject.anchorY = %.02f", editObject.anchorX, editObject.anchorY))
						logger.log(string.format("object.xScale = %.03f\nobject.yScale = %.03f", editObject.xScale, editObject.yScale))
						logger.log(string.format("object.rotation = %d\nobject.alpha = %.02f", editObject.rotation, editObject.alpha))
						
						if editObject.text then
							logger.log(string.format("object.text = %s", editObject.text))
						end
						logger.line()
					elseif keycode == keycodes["D"] then
						editObject.width = editObject.width + EDIT_SIZE * editScale
					elseif keycode == keycodes["A"] then
						editObject.width = editObject.width - EDIT_SIZE * editScale
					elseif keycode == keycodes["W"] then
						editObject.height = editObject.height + EDIT_SIZE * editScale
					elseif keycode == keycodes["S"] then
						editObject.height = editObject.height - EDIT_SIZE * editScale
					elseif keycode == keycodes["-"] or keycode == keycodes["NUMPAD-"]then
						editObject.xScale = editObject.xScale - EDIT_SCALE * editScale
						editObject.yScale = editObject.yScale - EDIT_SCALE * editScale
					elseif keycode == keycodes["="] or keycode == keycodes["NUMPAD+"] then
						editObject.xScale = editObject.xScale + EDIT_SCALE * editScale
						editObject.yScale = editObject.yScale + EDIT_SCALE * editScale
					end

					if elementIndex > #editorElements.editObjects then
						elementIndex = 1
					elseif elementIndex < 1 then
						elementIndex = #editorElements.editObjects
					end

					editorElements.cursor:selectObject(editorElements.editObjects[elementIndex])
				end

				return true
			else
				return false
			end
		end
		
	end
end

local function initialize()
	if not initialized then
		initialized  = true
		
		local function handleLowMemory(event)
			if director.handleLowMemory then
				logger.log("[Director] Received memory warning, will remove hidden scenes")
				director.removeHidden(true)
			else
				logger.log("[Director] Received memory warning but handling is disabled")		
			end
		end
		Runtime:addEventListener("memoryWarning", handleLowMemory)
		
		if system.getInfo("environment") == "simulator" then
			timer.performWithDelay(SIMULATOR_MEMORY_WARNING_INTERVAL, function()
				local memoryUsed = system.getInfo("textureMemoryUsed") * 0.00000095 + collectgarbage("count") * 0.00095
				if memoryUsed >= director.maxSimulatorMemory then
					logger.error("[Director] Memory exceeded "..tostring(director.maxSimulatorMemory).."mb, simulating memory warning.")
					handleLowMemory({})
				end
			end, -1)
		end
		
		stage = display.newGroup()
		director.stage = stage
		local generalStage = display.getCurrentStage()
		generalStage:insert(stage)

		editSceneZIndex = 1

		local oldTransitionCancel = transition.cancel
		transition.cancel = function(...)
			local args = {...}
			if #args <= 0 then
				logger.error("[Transition] Calling transition.cancel without parameters is forbidden")
			else
				oldTransitionCancel(...)
			end
		end

		if system.getInfo("environment") == "simulator" then
			initializeEditor()
			Runtime:addEventListener("key", editorKeyListener)
		end

		variables = {}
	end
end

local function modalTouch()
	return true
end

local function checkTouchRect()
	if not touchRect then
		touchRect = display.newRect( CONTENT_CENTER_X, CONTENT_CENTER_Y, VIEWABLE_CONTENT_WIDTH, VIEWABLE_CONTENT_HEIGHT )
		touchRect.isVisible = false
		touchRect.id = "touchRect"
		touchRect:addEventListener( "touch", modalTouch )
		touchRect:addEventListener( "tap", modalTouch )
	end
end

local function createModalRect()
	local modalRect = display.newRect( CONTENT_CENTER_X, CONTENT_CENTER_Y, VIEWABLE_CONTENT_WIDTH, VIEWABLE_CONTENT_HEIGHT )
	modalRect.isVisible = false
	modalRect:addEventListener( "touch", modalTouch )
	modalRect:addEventListener( "tap", modalTouch )

	return modalRect
end

local function disableTouchEvents()
	checkTouchRect()
	touchRect.isHitTestable = true
	display.getCurrentStage():insert(touchRect)
end

local function enableTouchEvents()
	checkTouchRect()
	touchRect.isHitTestable = false
	display.getCurrentStage():insert(touchRect)
end
----------------------------------------------- Module functions
function director.setCrashProtection(enable)
	crashProtection = enable
end

function director.getSceneName(zIndex)
	zIndex = zIndex or DEFAULT_ZINDEX
	if type(zIndex) == "string" then
		if zIndex == "current" then
			if director.showingScenes[DEFAULT_ZINDEX].currentScene then
				return director.showingScenes[DEFAULT_ZINDEX].currentScene._name
			end
		elseif zIndex == "previous" then
			if director.showingScenes[DEFAULT_ZINDEX].pastScene then
				return director.showingScenes[DEFAULT_ZINDEX].pastScene._name
			end
		elseif zIndex == "overlay" then
			if director.showingScenes[DEFAULT_ZINDEX_OVERLAY] then
				if director.showingScenes[DEFAULT_ZINDEX_OVERLAY].currentScene then
					return director.showingScenes[DEFAULT_ZINDEX_OVERLAY].currentScene._name
				end
			end
		end
	elseif type(zIndex) == "number" then
		if director.showingScenes[zIndex] and director.showingScenes[zIndex].currentScene then
			return director.showingScenes[zIndex].currentScene._name
		end
	end
end

function director.getPrevious()
	return director.getSceneName("previous")
end

function director.getScene(sceneName)
	return director.sceneDictionary[sceneName]
end

function director.newScene(sceneName)
	local newScene = Runtime._super:new()
	
	if sceneName and not director.sceneDictionary[sceneName] then
		director.sceneDictionary[sceneName] = newScene
		newScene._name = sceneName
		newScene._timers = {}
		newScene._transitions = {}
		newScene._texts = {}
		newScene._images = {}
	end
	
	return newScene
end

function director.loadScene(sceneName, options, params)
	options = options or {}
	local doNotLoadView = options and "boolean" == type(options)
	local unloadCounter = "number" == type(options.unloadCounter) and options.unloadCounter
	
	local scene = director.sceneDictionary[sceneName]
	
	local function prepareScene()
		scene.view = display.newGroup()
		scene._modalView = createModalRect()
		scene.view:insert(scene._modalView)
		scene._modalView.isHitTestable = false
		scene.view.isVisible = false
		scene._eventData = scene.createScene and EVENT_DATA["storyboard"] or EVENT_DATA["composer"]
		scene._unloadCounter = unloadCounter
		
		local event = extratable.deepcopy(director.sceneDictionary[sceneName]._eventData.onCreate)
		event.params = params
		eventDispatcher(director.sceneDictionary[sceneName], event)
	end
	
	if scene then
		if scene.view then
			return scene
		elseif not doNotLoadView then
			prepareScene()
		end
	else
		local success, message = pcall(function()
			scene = require(sceneName)
			scene._name = sceneName
			scene._timers = {}
			scene._transitions = {}
			scene._texts = {}
			scene._images = {}
			director.sceneDictionary[sceneName] = scene
			scene._eventData = scene.createScene and EVENT_DATA["storyboard"] or EVENT_DATA["composer"]
		end)

		if not success and message then
			logger.error([[[Director] Error with scene "]]..sceneName..[[".]])
			logger.error(message)
			return
		end
		
		if not doNotLoadView then
			prepareScene()
		end
	end
	return scene
end

function director.showScene(sceneName, zIndex, options, parentScene)
	zIndex = zIndex or DEFAULT_ZINDEX
	options = options or {}
	
	if debugDirector then
		logger.log("[Director] will show scene "..sceneName.."")
	end
	
	local params = options.params
	local effectName = options.effect or EFFECT_DEFAULT
	local effectTime = options.time or EFFECT_TIME_DEFAULT
	local isModal = options.isModal
	local transitionEffect = effects[effectName]
	local sameScene = false
	
	if not director.showingScenes[zIndex] then
		director.showingScenes[zIndex] = {
			currentScene = nil,
			pastScene = nil,
			view = display.newGroup(),
		}
		stage:insert(zIndex, director.showingScenes[zIndex].view)
	end
	
	if not parentScene then
		local upOneScene = director.showingScenes[zIndex - 1]
		if upOneScene and upOneScene.currentScene then
			parentScene = upOneScene.currentScene
		end
	end
	
	disableTouchEvents()
	
	if sceneName then
		local scene = director.sceneDictionary[sceneName]
		
		local function prepareScene()
			if not scene.view then
				scene.view = display.newGroup()
				scene._modalView = createModalRect()
				scene.view:insert(scene._modalView)
				
				scene._modalView.isHitTestable = false
				scene.view.isVisible = false
				scene._eventData = scene.createScene and EVENT_DATA["storyboard"] or EVENT_DATA["composer"]
				
				local event = extratable.deepcopy(director.sceneDictionary[sceneName]._eventData.onCreate)
				event.params = params
				event.parent = parentScene
				eventDispatcher(director.sceneDictionary[sceneName], event)
			end
			
			scene._modalView.isHitTestable = isModal
			scene.zIndex = zIndex
			scene.sceneSlot = "currentScene"
			if director.showingScenes[zIndex].currentScene ~= scene then
				director.showingScenes[zIndex].pastScene = director.showingScenes[zIndex].currentScene
				if director.showingScenes[zIndex].pastScene then
					director.showingScenes[zIndex].pastScene.sceneSlot = "pastScene"
				end
			else
				sameScene = true
				director.showingScenes[zIndex].pastScene = nil
			end
			director.showingScenes[zIndex].currentScene = scene
			
			if not pcall(function()
				director.showingScenes[zIndex].view:insert(scene.view)
			end) then
				error([[[Director] Scene "]]..sceneName..[[" does not have a valid view. Did you remove it by accident?]], 4)
			end
		end
		
		if scene then
			prepareScene()
		else
			local success, message = pcall(function()
				scene = require(sceneName)
				scene._name = sceneName
				scene._timers = {}
				scene._transitions = {}
				scene._texts = {}
				scene._images = {}
				director.sceneDictionary[sceneName] = scene
				scene._eventData = scene.createScene and EVENT_DATA["storyboard"] or EVENT_DATA["composer"]
			end)
			
			if not success and message then
				logger.error([[[Director] Error with scene "]]..sceneName..[[".]])
				logger.error(message)
				return
			end
			
			prepareScene()
		end
		
		local currentScene = director.showingScenes[zIndex].currentScene
		local pastScene = director.showingScenes[zIndex].pastScene
		
		if pastScene then
			local event = extratable.deepcopy(pastScene._eventData.onWillHide)
			event.params = params
			event.parent = parentScene
			event.effectTime = effectTime
			eventDispatcher(pastScene, event)
		end
		
		transition.cancel(currentScene.view)
		
		if not sameScene then
			currentScene.view.isVisible = false
			if transitionEffect.to then
				currentScene.view.x = transitionEffect.to.xStart or 0
				currentScene.view.y = transitionEffect.to.yStart or 0
				currentScene.view.alpha = transitionEffect.to.alphaStart or 1.0
				currentScene.view.xScale = transitionEffect.to.xScaleStart or 1.0
				currentScene.view.yScale = transitionEffect.to.yScaleStart or 1.0
				currentScene.view.rotation = transitionEffect.to.rotationStart or 0
			end
		end
		
		local function newSceneOnComplete()
			enableTouchEvents()
			if pastScene and pastScene.view then
				pastScene.view.isVisible = false
			end

			local event = extratable.deepcopy(currentScene._eventData.onDidShow)
			event.params = params
			event.parent = parentScene
			eventDispatcher(currentScene, event)
		end
		
		local newSceneTransitionOptions = {
			x = transitionEffect.to.xEnd,
			y = transitionEffect.to.yEnd,
			alpha = transitionEffect.to.alphaEnd,
			xScale = transitionEffect.to.xScaleEnd,
			yScale = transitionEffect.to.yScaleEnd,
			rotation =  transitionEffect.to.rotationEnd,
			time = effectTime or EFFECT_TIME_DEFAULT,
			transition = transitionEffect.to.transition,
			onComplete = newSceneOnComplete,
		}
		
		local function willShowNewScene()
			system.deactivate("multitouch")
			
			local event = extratable.deepcopy(currentScene._eventData.onWillShow)
			event.params = params
			event.parent = parentScene
			eventDispatcher(currentScene, event)

			currentScene.view.isVisible = true
			if newSceneTransitionOptions.time <= 0 then
				for key, value in pairs(newSceneTransitionOptions) do
					if key ~= "onComplete" then
						currentScene.view[key] = value
					end
				end
				if newSceneTransitionOptions.onComplete then
					newSceneTransitionOptions.onComplete()
				end
			else
				local sceneTransition = transition.to( currentScene.view, newSceneTransitionOptions )
			end
		end
		
		local function previousSceneOnComplete()
			cancelSceneTimers(pastScene)
			cancelSceneTransitions(pastScene)
			local event = extratable.deepcopy(pastScene._eventData.onDidHide)
			event.params = params
			event.parent = parentScene
			event.effectTime = effectTime
			eventDispatcher(pastScene, event)
			if not transitionEffect.concurrent then
				display.getCurrentStage():setFocus(nil)
				willShowNewScene()
			end
		end
		
		local previousSceneTransitionOptions = {
			x = transitionEffect.from.xEnd,
			y = transitionEffect.from.yEnd,
			alpha = transitionEffect.from.alphaEnd,
			xScale = transitionEffect.from.xScaleEnd,
			yScale = transitionEffect.from.yScaleEnd,
			rotation = transitionEffect.from.rotationEnd,
			time = effectTime or 500,
			transition = transitionEffect.from.transition,
			onComplete = previousSceneOnComplete,
		}
		
		if pastScene then
			if previousSceneTransitionOptions.time <= 0 then
				for key, value in pairs(previousSceneTransitionOptions) do
					if key ~= "onComplete" then
						pastScene.view[key] = value
					end
				end
				if previousSceneTransitionOptions.onComplete then
					previousSceneTransitionOptions.onComplete()
				end
			else
				local sceneTransition = transition.to( pastScene.view, previousSceneTransitionOptions )
			end
			
			if transitionEffect.concurrent then
				willShowNewScene()
			end
		else
			if not sameScene then
				willShowNewScene()
			else
				enableTouchEvents()
			end
		end
	else
		
	end
end

function director.gotoScene(...)
	local arguments = {...}
	
	director.hideOverlay()
	
	if #arguments == 1 then
		local sceneName = arguments[1]
		director.showScene(sceneName)
	elseif #arguments == 2 then
		local sceneName = arguments[1]
		local options = arguments[2]
		director.showScene(sceneName, 1, options)
	elseif #arguments == 3 then
		local sceneName = arguments[1]
		local zIndex = arguments[2]
		local options = arguments[3]
		director.showScene(sceneName, zIndex, options)
	end
	
	if director.purgeOnSceneChange then
		director.removeHidden(false)
	end
end

function director.showOverlay(sceneName, options)
	local currentSceneName = director.getSceneName("current")
	local parentScene = director.getScene(currentSceneName)
	local currentOverlayName = director.getSceneName("overlay")
	if sceneName ~= currentOverlayName then
		director.showScene(sceneName, DEFAULT_ZINDEX_OVERLAY, options, parentScene)
	end
	
	if parentScene then
		local scene = director.sceneDictionary[sceneName]local scene = director.sceneDictionary[sceneName]
		eventDispatcher(parentScene, {name = "overlayBegan", overlay = scene})
	end
end

function director.hideOverlay(...)
	local arguments = {...}
	
	local recycleOnly, effectName, effectTime
	if #arguments == 1 then
		effectName = arguments[1]
	elseif #arguments == 2 then
		effectName = arguments[1]
		effectTime = arguments[2]
	elseif #arguments == 3 then
		recycleOnly = arguments[1]
		effectName = arguments[2]
		effectTime = arguments[3]
	end
	
	if director.showingScenes[DEFAULT_ZINDEX_OVERLAY] and director.showingScenes[DEFAULT_ZINDEX_OVERLAY].currentScene then
		disableTouchEvents()
		
		local currentSceneName = director.getSceneName("current")
		local parentScene = director.getScene(currentSceneName)
		
		local overlay = director.showingScenes[DEFAULT_ZINDEX_OVERLAY].currentScene
		director.hideScene(overlay._name, effectName, effectTime, parentScene)
		
		if parentScene and overlay then
			eventDispatcher(parentScene, {name = "overlayEnded", overlay = overlay})
		end
		
		enableTouchEvents()
	end
end

function director.hideScene(sceneName, effectName, effectTime, parentScene)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene.view then
		effectName = effectName or EFFECT_DEFAULT
		effectTime = effectTime or EFFECT_TIME_DEFAULT
		local transitionEffect = effects[effectName].from
		
		scene.view.x = transitionEffect.xStart or 0
		scene.view.y = transitionEffect.yStart or 0
		scene.view.alpha = transitionEffect.alphaStart or 1.0
		scene.view.xScale = transitionEffect.xScaleStart or 1.0
		scene.view.yScale = transitionEffect.yScaleStart or 1.0
		scene.view.rotation = transitionEffect.rotationStart or 0
		
		local function onHideTransitionComplete()
			scene.view.isVisible = false
			scene._modalView.isHitTestable = false
				
			cancelSceneTimers(scene)
			cancelSceneTransitions(scene)
			local event = extratable.deepcopy(scene._eventData.onDidHide)
			event.effectTime = effectTime
			event.parent = parentScene
			eventDispatcher(scene, event)
			director.showingScenes[scene.zIndex][scene.sceneSlot] = nil
			display.getCurrentStage():setFocus(nil)
		end

		local transitionOptions = {
			x = transitionEffect.xEnd,
			y = transitionEffect.yEnd,
			alpha = transitionEffect.alphaEnd,
			xScale = transitionEffect.xScaleEnd,
			yScale = transitionEffect.yScaleEnd,
			rotation = transitionEffect.rotationEnd,
			time = effectTime,
			transition = transitionEffect.transition,
			onComplete = onHideTransitionComplete
		}
		
		local event = extratable.deepcopy(scene._eventData.onWillHide)
		event.parent = parentScene
		event.effectTime = effectTime
		eventDispatcher(scene, event)
		
		transition.cancel(scene.view)
		if effectTime > 0 then
			local hideTransition = transition.to( scene.view, transitionOptions ) 
		else
			onHideTransitionComplete()
		end
	end
end

function director.setVariable(variableName, value)
	variables[variableName] = value
end

function director.getVariable(variableName)
	return variables[variableName]
end

function director.removeHidden(shouldRecycle)
	local showingScenes = {director.getSceneName("previous")}
	for index = 1, #director.showingScenes do
		local sceneName = director.getSceneName(index)
		if sceneName then
			showingScenes[#showingScenes + 1] = sceneName
		end
	end
	
	for sceneName, scene in pairs(director.sceneDictionary) do
		if not extratable.containsValue(showingScenes, sceneName) then
			director.purgeScene(sceneName, shouldRecycle)
		end
	end
end

function director.purgeScene(sceneName, shouldRecycle)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene.view then
		if scene._unloadCounter and scene._unloadCounter > 0 then
			scene._unloadCounter = scene._unloadCounter - 1
		else
			
			local currentSceneName = director.getSceneName("current")
			local currentOverlayName = director.getSceneName("overlay")
			if sceneName ~= currentSceneName and sceneName ~= currentOverlayName then
				local event = extratable.deepcopy(scene._eventData.onDestroy)
				eventDispatcher(scene, event)

				if scene.view then
					display.remove( scene.view )
					scene.view = nil
					if not shouldRecycle then
						director.sceneDictionary[sceneName] = nil
					end
					collectgarbage( "collect" )
					logger.log([[[Director] Purged scene "]]..sceneName..[[".]])
				end
			else
				logger.log([[[Director] Scene "]]..sceneName..[[" cannot be purged, it is the current scene or current overlay, queueing.]])
				scene._unloadCounter = scene._unloadCounter or 0
				scene._unloadCounter = scene._unloadCounter + 1
			end
		end
	else
		if not scene then
			logger.error([[[Director] Can't purge scene "]]..sceneName..[[". It does not exist.]])
		end
	end
end

function director.reloadScene(sceneName, params, parentScene)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene.view and scene.zIndex and "number" == type(scene.zIndex) then
		if not parentScene then
			local upOneScene = director.showingScenes[scene.zIndex - 1]
			if upOneScene and upOneScene.currentScene then
				parentScene = upOneScene.currentScene
			end
		end
	
		local event = extratable.deepcopy(scene._eventData.onWillHide)
		event.parent = parentScene
		event.params = params
		eventDispatcher(scene, event)
		local event = extratable.deepcopy(scene._eventData.onDidHide)
		event.parent = parentScene
		event.params = params
		eventDispatcher(scene, event)
		
		system.deactivate("multitouch")
		
		local event = extratable.deepcopy(scene._eventData.onWillShow)
		event.parent = parentScene
		event.params = params
		eventDispatcher(scene, event)
		local event = extratable.deepcopy(scene._eventData.onDidShow)
		event.parent = parentScene
		event.params = params
		eventDispatcher(scene, event)
	end
end

function director.reloadLocalization(sceneName)
	local scene = director.sceneDictionary[sceneName]
	if scene then
		localizationHook(scene, {force = true})
	end
end

function director.newLocalizedImage(sceneName, ...)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._images then
		local parameters = {...}
		local filename = ""
		for index = 1, #parameters do
			if parameters[index] and "string" == type(parameters[index]) then -- all display.newImage functions only have 1 string, filename.
				filename = parameters[index]
				parameters[index] = localization.format(parameters[index])
				break
			end
		end
				
		local localizedImage = display.newImage(unpack(parameters))
		if localizedImage then
			localizedImage.localizedPath = filename
			scene._images[#scene._images + 1] = localizedImage
			return localizedImage
		else
			logger.error("[Director] Image "..filename.." does not exist")
		end
	end
end

function director.newLocalizedEmbossedText(sceneName, stringID, ...)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._texts then
		local localizedText = display.newEmbossedText(...)
		localizedText.text = localization.getString(stringID)
		localizedText.stringID = stringID
		scene._texts[#scene._texts + 1] = localizedText
		return localizedText
	end
end

function director.newLocalizedText(sceneName, stringID, ...)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._texts then
		local localizedText = display.newText(...)
		localizedText.text = localization.getString(stringID)
		localizedText.stringID = stringID
		scene._texts[#scene._texts + 1] = localizedText
		return localizedText
	end
end

function director.to(sceneName, target, params)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._transitions then
		local onComplete = params.onComplete
		
		local transitionHandle
		params.onComplete = function(event)
			extratable.removeItem(scene._transitions, transitionHandle)
			if onComplete and "function" == type(onComplete) then
				onComplete(event)
			end
		end
		
		transitionHandle = transition.to(target, params)
		scene._transitions[#scene._transitions + 1] = transitionHandle
		return transitionHandle
	end
end

function director.from(sceneName, target, params)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._transitions then
		local onComplete = params.onComplete
		
		local transitionHandle
		params.onComplete = function(event)
			extratable.removeItem(scene._transitions, transitionHandle)
			if onComplete and "function" == type(onComplete) then
				onComplete(event)
			end
		end
		
		transitionHandle = transition.from(target, params)
		scene._transitions[#scene._transitions + 1] = transitionHandle
		return transitionHandle
	end
end

function director.performWithDelay(sceneName, delay, listener, iterations)
	local scene = director.sceneDictionary[sceneName]
	if scene and scene._timers then
		local timerHandle = timer.performWithDelay(delay, function(event)
			listener(event)
			extratable.removeItem(scene._timers, timerHandle)
		end, iterations)
		scene._timers[#scene._timers + 1] = timerHandle
		return timerHandle
	end
end

function director.pauseScene(sceneName, pause)
	local scene = director.sceneDictionary[sceneName]
	
	local timerFunction = pause and timer.pause or timer.resume
	if scene and scene._timers then
		for index = 1, #scene._timers do
			timerFunction(scene._timers[index])
		end
	end
	
	local transitionFunction = pause and transition.pause or transition.resume
	if scene and scene._transitions then
		for index = 1, #scene._transitions do
			transitionFunction(scene._transitions[index])
		end
	end
end

function director.setActivityIndicator(state)
	state = state and state
	
	local currentStage = display.getCurrentStage()
	
	if not activityIndicator then
		activityIndicator = createActivityIndicator()
		currentStage:insert(40, activityIndicator)
		local stageInsert = currentStage.insert
	
		local function newStageInsert(...)
			stageInsert(...)
			activityIndicator:toFront()
		end
		currentStage.insert = newStageInsert
	end
	
	activityIndicator:animate(state)
end

function director.setDebug(doDebug)
	debugDirector = doDebug
end
----------------------------------------------- Execution
initialize()

return director

