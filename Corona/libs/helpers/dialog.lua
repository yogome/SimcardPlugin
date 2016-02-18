-------------------------------------------- Dialog
local path = ...
local folder = path:match("(.-)[^%.]+$") 
local extrawidget = require( folder.."extrawidget" )
local extrafile = require( folder.."extrafile" )
local textbox = require( folder.."textbox" )
local colors = require( folder.."colors" )
local logger = require( folder.."logger" )
local robot = require( folder.."robot" )
local widget = require( "widget" )
local lfs = require( "lfs" )

local dialog = {}
------------------------------------------- Constants
local alertWidth = 512
local alertHeight = 256 
local PADDING = 16

local COLOR_BG = colors.darkGray
local WIDTH_PROPERTY_WINDOW = 400
local SIZE_TEXTBOX_PROPERTY = {height = 32, width = 200}
local WIDTH_PROPERTY_BUTTONS = 150
local SIZE_TEXTBOX_LOAD = {height = 32, width = 400}
local SIZE_TEXTBOX_SAVE = {height = 32, width = 500}
local WIDTH_SAVE_WINDOW = 700
local SIZE_LOAD_TEXTLIST = {width = 630, height = 400}
local WIDTH_LOAD_WINDOW = 700
------------------------------------------- Class functions
function dialog.newAlert(options)
	options = options or {}
	if not options then
		error("options must not be nil.", 3)
	end
	
	options.text = options.text or "This is the default alert text."
	if not options.text then
		error("text must not be nil.", 3)
	end
	
	options.time = options.time or 1000
	if not "number" == type(options.time) then
		error("time must be a number.", 3)
	end
	
	local alert = display.newGroup()
	alert.x = display.contentCenterX
	alert.y = display.contentCenterY
	alert.alpha = 0
	
	local touchCatcher = display.newRect(0, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	touchCatcher:setFillColor(0,0.5)
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	alert:insert(touchCatcher)
	
	local background = display.newRect(0, 0, alertWidth, alertHeight)
	background:setFillColor(0.1)
	alert:insert(background)
	
	local textOptions = {
		x = 0,
		y = 0,
		width = alertWidth - PADDING * 2,
		align = "center",
		text = options.text,
		fontSize = 50,
	}
	
	local alertText = display.newText(textOptions)
	alertText:setFillColor(1)
	alert:insert(alertText)
	
	local director = require( folder.."director" ) 
	director.stage:insert(alert)
	
	local introTime = math.ceil(options.time * 0.1)
	local realTime = math.ceil(options.time * 0.8)
	local outroTime = math.ceil(options.time * 0.1)
	
	alert.introTransition = transition.to(alert, {time = introTime, alpha = 1, transition = easing.outQuad})
	alert.outroTransition = transition.to(alert, {delay = introTime + realTime, time = outroTime, alpha = 0.0005, transition = easing.outQuad, onComplete = function()
		transition.cancel(alert.introTransition)
		transition.cancel(alert.outroTransition)
		alert.introTransition = nil
		alert.outroTransition = nil
		
		display.remove(alert)
		alert = nil
	end})
end

function dialog.newVariableWindow(options)
	options = options or {}
	
	local variableWindow = display.newGroup()
	
	local touchCatcher = display.newRect(0, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	touchCatcher:setFillColor(0,0.5)
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	touchCatcher.isHitTestable = true
	variableWindow:insert(touchCatcher)
	
	local totalHeight = PADDING * 4 + SIZE_TEXTBOX_PROPERTY.height * 3
	local background = display.newRoundedRect(0, 0, 500, totalHeight, 15)
	background:setFillColor(unpack(COLOR_BG))
	variableWindow:insert(background)
	
	local title = display.newText("New variable", 0, -totalHeight * 0.5 + PADDING, native.systemFont, 32)
	title.anchorY = 0
	variableWindow:insert(title)
	
	local textboxes = {}
	
	local values = {}
	for index = 1, 2 do
		local texboxOptions = {
			fontSize = 32,
			width = SIZE_TEXTBOX_PROPERTY.width,
			height = SIZE_TEXTBOX_PROPERTY.height,
			font = native.systemFont,
			inputType = "email",
			useContainer = true,
			color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
			text = "",
			onComplete = function(event)
				values[index] = event.target.value
				if textboxes[index + 1] then
					robot.tap(textboxes[index + 1])
				else
					variableWindow:success()
				end
			end,
			onChange = function(event)
				values[index] = event.target.value
			end,
		}
		
		local propertyTextbox = textbox.new(texboxOptions)
		propertyTextbox.anchorX = 0
		propertyTextbox.x = -(SIZE_TEXTBOX_PROPERTY.width + PADDING * 0.5) + (index - 1) * (SIZE_TEXTBOX_PROPERTY.width + PADDING)
		propertyTextbox.y = 0
		variableWindow:insert(propertyTextbox)
		
		textboxes[index] = propertyTextbox
	end
	
	local okOptions = {
		label = "Ok",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_PROPERTY.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			if options.onSuccess and "function" == type(options.onSuccess) then
				options.onSuccess({key = values[1], value = values[2]})
			end
		end,
	}
	local buttonOK = widget.newButton(okOptions)
	buttonOK.anchorY = 1
	buttonOK.x = (PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonOK.y = totalHeight * 0.5 - PADDING
	variableWindow:insert(buttonOK)
	
	local cancelOptions = {
		label = "Cancel",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_PROPERTY.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			if options.onCancel and "function" == type(options.onCancel) then
				options.onCancel()
			end
		end,
	}
	local buttonCancel = widget.newButton(cancelOptions)
	buttonCancel.anchorY = 1
	buttonCancel.x = -(PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonCancel.y = totalHeight * 0.5 - PADDING
	variableWindow:insert(buttonCancel)
	
	function variableWindow:cancel()
		if options.onCancel and "function" == type(options.onCancel) then
			options.onCancel()
		end
	end
	
	function variableWindow:success()
		if options.onSuccess and "function" == type(options.onSuccess) then
			options.onSuccess({key = values[1], value = values[2]})
		end
	end
	
	function variableWindow:isEditing()
		for index = 1, #textboxes do
			if textboxes[index].hasFocus then
				return true
			end
		end
		return false
	end
	
	variableWindow:addEventListener("finalize", function()
		textbox.removeFocus()
	end)
		
	return variableWindow
end

function dialog.newPropertyWindow(options)
	options = options or {}
	local properties = options.properties or {}
	local propertyOrder = options.propertyOrder
	local width = options.width or WIDTH_PROPERTY_WINDOW
	local showNewButton = options.showNewButton
	
	local propertyWindow = display.newGroup()
	
	local touchCatcher = display.newRect(0, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	touchCatcher:setFillColor(0,0.5)
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	touchCatcher.isHitTestable = true
	propertyWindow:insert(touchCatcher)
	
	local totalProperties = 0
	for index, value in pairs(properties) do
		totalProperties = totalProperties + 1
	end
	
	local totalPropertyHeight = (totalProperties - 1) * (SIZE_TEXTBOX_PROPERTY.height + PADDING)
	
	local totalHeight = PADDING * 4 + SIZE_TEXTBOX_PROPERTY.height * 3 + totalPropertyHeight
	local background = display.newRoundedRect(0, 0, width, totalHeight, 15)
	background:setFillColor(unpack(COLOR_BG))
	propertyWindow:insert(background)
	
	local title = display.newText(options.title or "Edit properties", 0, -totalHeight * 0.5 + PADDING, native.systemFont, 32)
	title.anchorY = 0
	propertyWindow:insert(title)
	
	local textboxes = {}
	
	if not propertyOrder then
		propertyOrder = {}
		for index, value in pairs(properties) do
			propertyOrder[#propertyOrder + 1] = index
		end
	end
	
	local newProperties = {}
	local currentProperty = 0
	for index = 1, #propertyOrder do
		local key = propertyOrder[index]
		local value = properties[key]
		
		currentProperty = currentProperty + 1
		local textboxIndex = currentProperty
		local positionY = -(totalPropertyHeight * 0.5) + (currentProperty - 1) * (SIZE_TEXTBOX_PROPERTY.height + PADDING)
		
		local propertyText = display.newText("", -70, positionY, native.systemFont, 32)
		propertyText.anchorX = 1
		propertyText.text = tostring(key)
		propertyWindow:insert(propertyText)
		
		newProperties[key] = value
		
		local texboxOptions = {
			fontSize = 32,
			width = SIZE_TEXTBOX_PROPERTY.width,
			height = SIZE_TEXTBOX_PROPERTY.height,
			font = native.systemFont,
			inputType = "email",
			useContainer = true,
			color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
			text = tostring(value),
			onComplete = function(event)
				local newValue = event.target.value
				newProperties[key] = tonumber(newValue) or tostring(newValue)
				if textboxes[textboxIndex + 1] then
					robot.tap(textboxes[textboxIndex + 1])
				else
					propertyWindow:success()
				end
			end,
			onChange = function(event)
				local newValue = event.target.value
				newProperties[key] = tonumber(newValue) or tostring(newValue)
			end,
		}
		
		local propertyTextbox = textbox.new(texboxOptions)
		propertyTextbox.anchorX = 0
		propertyTextbox.x = -70 + PADDING
		propertyTextbox.y = positionY
		propertyWindow:insert(propertyTextbox)
		
		textboxes[currentProperty] = propertyTextbox
	end
	
	if showNewButton then
		local okOptions = {
			label = "New",
			shape = "rect",
			fontSize = 26,
			width = WIDTH_PROPERTY_BUTTONS,
			height = SIZE_TEXTBOX_PROPERTY.height,
			fillColor = { default = colors.lightGray, over = colors.lightGray },
			labelColor = { default = colors.black, over = colors.black},
			onRelease = function()
				propertyWindow.variableWindow = dialog.newVariableWindow({
					onSuccess = function(event)
						newProperties[event.key] = event.value
						display.remove(propertyWindow.variableWindow)
						propertyWindow.variableWindow = nil
						propertyWindow:success()
					end,
					onCancel = function(event)
						display.remove(propertyWindow.variableWindow)
						propertyWindow.variableWindow = nil
					end
				})
				propertyWindow:insert(propertyWindow.variableWindow)
			end,
		}
		local buttonNew = widget.newButton(okOptions)
		buttonNew.anchorY = 1
		buttonNew.x = (PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5 + PADDING + WIDTH_PROPERTY_BUTTONS
		buttonNew.y = totalHeight * 0.5 - PADDING
		propertyWindow:insert(buttonNew)
	end
	
	local okOptions = {
		label = "Ok",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_PROPERTY.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			if options.onSuccess and "function" == type(options.onSuccess) then
				options.onSuccess(newProperties)
			end
		end,
	}
	local buttonOK = widget.newButton(okOptions)
	buttonOK.anchorY = 1
	buttonOK.x = (PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonOK.y = totalHeight * 0.5 - PADDING
	propertyWindow:insert(buttonOK)
	
	local cancelOptions = {
		label = "Cancel",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_PROPERTY.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			if options.onCancel and "function" == type(options.onCancel) then
				options.onCancel()
			end
		end,
	}
	local buttonCancel = widget.newButton(cancelOptions)
	buttonCancel.anchorY = 1
	buttonCancel.x = -(PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonCancel.y = totalHeight * 0.5 - PADDING
	propertyWindow:insert(buttonCancel)
	
	function propertyWindow:cancel()
		if options.onCancel and "function" == type(options.onCancel) then
			options.onCancel()
		end
	end
	
	function propertyWindow:success()
		if options.onSuccess and "function" == type(options.onSuccess) then
			options.onSuccess(newProperties)
		end
	end
	
	function propertyWindow:isEditing()
		if self.variableWindow then
			return true
		end
		
		for index = 1, #textboxes do
			if textboxes[index].hasFocus then
				return true
			end
		end
		return false
	end
	
	propertyWindow:addEventListener("finalize", function()
		textbox.removeFocus()
	end)
		
	return propertyWindow
end

function dialog.newSavePrompt(options)
	options = options or {}
	
	local folder = options.folder or system.pathForFile( nil, system.DocumentsDirectory)
	local data = options.data and "string" == type(options.data) and options.data or "NO DATA"
	local filename = options.filename or "file.basi"
	local onSave = options.onSave
	local onFail = options.onFail
	local onCancel = options.onCancel
	
	local textBoxData = {
		{label = "folder", value = folder},
		{label = "filename", value = filename},
	}
	
	local savePrompt = display.newGroup()
	
	local touchCatcher = display.newRect(0, 0, display.viewableContentWidth + 2, display.viewableContentHeight + 2)
	touchCatcher:setFillColor(0,0.5)
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	touchCatcher.isHitTestable = true
	savePrompt:insert(touchCatcher)
	
	local totalHeight = PADDING * 5 + SIZE_TEXTBOX_SAVE.height * 4
	local background = display.newRoundedRect(0, 0, WIDTH_SAVE_WINDOW, totalHeight, 15)
	background:setFillColor(unpack(COLOR_BG))
	savePrompt:insert(background)
	
	local title = display.newText(options.title or "Save as", 0, -totalHeight * 0.5 + PADDING, native.systemFont, 32)
	title.anchorY = 0
	savePrompt:insert(title)
	
	local textboxes = {}
	
	local newProperties = {}
	for index = 1, 2 do
		local positionY = -totalHeight * 0.5 + PADDING * 3 + SIZE_TEXTBOX_SAVE.height + (index - 1) * (PADDING + SIZE_TEXTBOX_SAVE.height)
		local labelText = display.newText("", -70 - 130, positionY, native.systemFont, 32)
		labelText.anchorX = 1
		labelText.text = textBoxData[index].label
		savePrompt:insert(labelText)
		
		
		local texboxOptions = {
			fontSize = 32,
			width = SIZE_TEXTBOX_SAVE.width,
			height = SIZE_TEXTBOX_SAVE.height,
			font = native.systemFont,
			inputType = "email",
			useContainer = true,
			color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
			text = textBoxData[index].value,
			onComplete = function(event)
				local newValue = event.target.value
				newProperties[index] = tonumber(newValue) or tostring(newValue)
				if textboxes[index + 1] then
					robot.tap(textboxes[index + 1])
				else
					savePrompt:success()
				end
			end,
			onChange = function(event)
				local newValue = event.target.value
				newProperties[index] = tonumber(newValue) or tostring(newValue)
			end,
		}
		
		local newTextbox = textbox.new(texboxOptions)
		newTextbox.anchorX = 0
		newTextbox.x = -70 - 130 + PADDING
		newTextbox.y = positionY
		savePrompt:insert(newTextbox)
		
		textboxes[index] = newTextbox
	end
	
	local saveOptions = {
		label = "Save",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_SAVE.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			savePrompt:success()
		end,
	}
	local buttonSave = widget.newButton(saveOptions)
	buttonSave.anchorY = 1
	buttonSave.x = (PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonSave.y = totalHeight * 0.5 - PADDING
	savePrompt:insert(buttonSave)
	
	local cancelOptions = {
		label = "Cancel",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_SAVE.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			savePrompt:cancel()
		end,
	}
	local buttonCancel = widget.newButton(cancelOptions)
	buttonCancel.anchorY = 1
	buttonCancel.x = -(PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonCancel.y = totalHeight * 0.5 - PADDING
	savePrompt:insert(buttonCancel)
	
	function savePrompt:cancel()
		if onCancel and "function" == type(onCancel) then
			onCancel()
		end
	end
	
	function savePrompt:success()
		
		local success, message = pcall(function()
			local absolutePath = textboxes[1].value.."/"..textboxes[2].value
			local fileObject = io.open( absolutePath, "w" )
			fileObject:write( data )
			io.close( fileObject )
		end)
		
		if success then
			if onSave and "function" == type(onSave) then
				onSave({filename = textboxes[2].value, folder = textboxes[1].value})
			end
			logger.log("Saved data succesfully.")
		else
			logger.error("Data could not saved.")
			if onFail and "function" == type(onFail) then
				onFail({filename = textboxes[2].value, folder = textboxes[1].value})
			end
		end
	end
	
	function savePrompt:isEditing()
		for index = 1, #textboxes do
			if textboxes[index].hasFocus then
				return true
			end
		end
		return false
	end
	
	local oldRemoveSelf = savePrompt.removeSelf
	function savePrompt.removeSelf(self, ...)
		textbox.removeFocus()
		oldRemoveSelf(self, ...)
	end
	
	return savePrompt
end

function dialog.newLoadPrompt(options)
	options = options or {}
	
	local folder = options.folder or system.pathForFile( nil, system.DocumentsDirectory)
	local onLoad = options.onLoad
	local onFail = options.onFail
	local onCancel = options.onCancel
	
	local lastValidPath = folder
	local pathTextbox, selectedFile
	
	local loadPrompt = display.newGroup()
	
	local touchCatcher = display.newRect(0, 0, display.viewableContentWidth * 4, display.viewableContentHeight * 4)
	touchCatcher:setFillColor(0,0.5)
	touchCatcher:addEventListener( "tap", function() return true end)
	touchCatcher:addEventListener( "touch", function() return true end)
	touchCatcher.isHitTestable = true
	loadPrompt:insert(touchCatcher)
	
	local totalHeight = PADDING * 5 + SIZE_TEXTBOX_SAVE.height * 3 + SIZE_LOAD_TEXTLIST.height
	local background = display.newRoundedRect(0, 0, WIDTH_LOAD_WINDOW, totalHeight, 15)
	background:setFillColor(unpack(COLOR_BG))
	loadPrompt:insert(background)
	
	local title = display.newText(options.title or "Load file", 0, -totalHeight * 0.5 + PADDING, native.systemFont, 32)
	title.anchorY = 0
	loadPrompt:insert(title)
	
	local positionY = -totalHeight * 0.5 + PADDING * 3 + SIZE_TEXTBOX_SAVE.height 
	local labelText = display.newText("", -70 - 130, positionY, native.systemFont, 32)
	labelText.anchorX = 1
	labelText.text = "folder"
	loadPrompt:insert(labelText)
	
	local function getFileStructure(onFolder)
		local filenames = {}
		if pcall(function()
			for fileName in lfs.dir(onFolder) do
				if fileName and string.sub(fileName, 1, 1) ~= "." then
					table.insert(filenames, fileName)
				end
			end
		end) then
			lastValidPath = onFolder
			return filenames
		else
			dialog.newAlert({text = "Not a valid path"})
		end
	end
	
	local texboxOptions = {
		fontSize = 32,
		width = SIZE_TEXTBOX_LOAD.width,
		height = SIZE_TEXTBOX_LOAD.height,
		font = native.systemFont,
		inputType = "email",
		useContainer = true,
		color = { default = { 1, 1, 1 }, selected = { 1, 1, 1}, placeholder = {1, 1, 1} },
		text = folder,
		onComplete = function(event)
			local fileStructure = getFileStructure(event.target.value)
			if fileStructure then
				selectedFile = nil
				loadPrompt.filelist:setStrings(fileStructure)
			end
		end,
		onChange = function(event)
			
		end,
	}
	
	local pathTextbox = textbox.new(texboxOptions)
	pathTextbox.anchorX = 0
	pathTextbox.x = -70 - 130 + PADDING
	pathTextbox.y = positionY
	loadPrompt:insert(pathTextbox)
	loadPrompt.pathTextbox = pathTextbox
	
	local upFolderOptions = {
		label = "up",
		shape = "rect",
		fontSize = 26,
		width = 80,
		height = SIZE_TEXTBOX_SAVE.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			local currentFolder = pathTextbox.value
			local upFolder = string.sub(string.match(currentFolder, "(.-)[^%/]+$"), 1, -2)
			pathTextbox:setText(upFolder)
			local fileStructure = getFileStructure(pathTextbox.value)
			if fileStructure then
				selectedFile = nil
				loadPrompt.filelist:setStrings(fileStructure)
			end
		end,
	}
	local buttonUpFolder = widget.newButton(upFolderOptions)
	buttonUpFolder.anchorX = 0
	buttonUpFolder.x = pathTextbox.x + pathTextbox.width + PADDING
	buttonUpFolder.y = positionY
	loadPrompt:insert(buttonUpFolder)
	
	local lastTapTime = system.getTimer()
	local lastTapTimeValue
	
	local filelistOptions = {
		width = SIZE_LOAD_TEXTLIST.width,
		height = SIZE_LOAD_TEXTLIST.height,
		strings = getFileStructure(folder),
		--fontColor = {0,0,0},
		onSelect = function(event)
			selectedFile = event.value
			
			local newTapTime = system.getTimer()
			if newTapTime - 400 < lastTapTime then -- Double tap
				if lastTapTimeValue == event.value then
					if not string.find(event.value, "%.") then
						local newFolder = pathTextbox.value.."/"..event.value
						pathTextbox:setText(newFolder)
						local fileStructure = getFileStructure(newFolder)
						if fileStructure then
							loadPrompt.filelist:setStrings(fileStructure)
						end
					else
						loadPrompt:success()
					end
				end
			end
			lastTapTimeValue = event.value
			lastTapTime = newTapTime
		end,
	}
	local filelist = extrawidget.newTextList(filelistOptions)
	filelist.x = 0
	filelist.y = PADDING * 1.5
	loadPrompt:insert(filelist)
	loadPrompt.filelist = filelist
	
	local loadOptions = {
		label = "Load",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_SAVE.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			loadPrompt:success()
		end,
	}
	local buttonLoad = widget.newButton(loadOptions)
	buttonLoad.anchorY = 1
	buttonLoad.x = (PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonLoad.y = totalHeight * 0.5 - PADDING
	loadPrompt:insert(buttonLoad)
	
	local cancelOptions = {
		label = "Cancel",
		shape = "rect",
		fontSize = 26,
		width = WIDTH_PROPERTY_BUTTONS,
		height = SIZE_TEXTBOX_SAVE.height,
		fillColor = { default = colors.lightGray, over = colors.lightGray },
		labelColor = { default = colors.black, over = colors.black},
		onRelease = function()
			loadPrompt:cancel()
		end,
	}
	local buttonCancel = widget.newButton(cancelOptions)
	buttonCancel.anchorY = 1
	buttonCancel.x = -(PADDING + WIDTH_PROPERTY_BUTTONS) * 0.5
	buttonCancel.y = totalHeight * 0.5 - PADDING
	loadPrompt:insert(buttonCancel)
	
	function loadPrompt:cancel()
		if onCancel and "function" == type(onCancel) then
			onCancel()
		end
	end
	
	function loadPrompt:success()
		if selectedFile then
			local filePath = lastValidPath.."/"..tostring(selectedFile)
			local data = ""
			if pcall(function()
				local fileObject = io.open(filePath, "r" )
				if fileObject then
					data = fileObject:read( "*a" )
					io.close( fileObject )
				end
			end) then
				if onLoad and "function" == type(onLoad) then
					onLoad({filename = selectedFile, filePath = filePath, data = data})
				end
				logger.log("Loaded data succesfully.")
			else
				logger.error("Data was not saved")
				if onFail and "function" == type(onFail) then
					onFail({})
				end
			end
		else
			dialog.newAlert({text = "No file selected"})
		end
	end
	
	function loadPrompt:isEditing()
		if pathTextbox.hasFocus then
			return true
		end
		return false
	end
	
	local oldRemoveSelf = loadPrompt.removeSelf
	function loadPrompt.removeSelf(self, ...)
		textbox.removeFocus()
		oldRemoveSelf(self, ...)
	end
	
	return loadPrompt
end

return dialog
