local widget = require( "widget" )

local extrawidget = {}

local mathFloor = math.floor

function extrawidget.newTextList(options)
	options = options or {}
	local width = options.width or 400
	local height = options.height or 400
	local strings = options.strings or {"option1"}
	local font = options.font or native.systemFont
	local fontSize = options.fontSize or 28
	local fontColor = options.fontColor or {1,1,1}
	local onSelect = options.onSelect
	
	local selectSize = fontSize + (fontSize * 0.25)
	local textlistOptions = {
		x = 0,
		y = 0,
		width = width,
		height = height,
		scrollWidth = 100,
		scrollHeight = 100,
		hideBackground = false,
		backgroundColor = {0.8, 0.8, 0.8},
	}
	local textlist = widget.newScrollView(textlistOptions)
	
	local highlightRect = display.newRect(0, 0, width, selectSize)
	highlightRect.anchorX, highlightRect.anchorY = 0, 0
	highlightRect:setFillColor(0.5)
	highlightRect.isVisible = false
	textlist:insert(highlightRect)
	
	local generalTextGroup = display.newGroup()
	textlist:insert(generalTextGroup)
	
	local textOptions = {
		text = "",	 
		x = 0,
		y = 0,
		font = font,   
		fontSize = fontSize,
		align = "left"
	}
	
	textlist:addEventListener("tap", function(event)
		local scrollX, scrollY = textlist:getContentPosition()
		local localX, localY = textlist:contentToLocal(event.x, event.y)
		localY = localY - scrollY
		local rectPosition = (localY + height * 0.5) - ((localY + height * 0.5) % selectSize)
		local selectedIndex = mathFloor(rectPosition / selectSize) + 1
		
		if selectedIndex > 0 and selectedIndex <= #strings then
			highlightRect.y = rectPosition
			highlightRect.isVisible = true
			if onSelect and "function" == type(onSelect) then
				onSelect({index = selectedIndex, value = strings[selectedIndex]})
			end
		end
	end)
	
	function textlist:setStrings(newStrings)
		strings = newStrings
		highlightRect.isVisible = false
		
		for childIndex = generalTextGroup.numChildren, 1, -1 do
			display.remove(generalTextGroup[childIndex])
		end
		
		local newScrollHeight = #strings * selectSize
		textlist:setScrollHeight(newScrollHeight > height and newScrollHeight or height)
		
		for index = 1, #strings do
			local textObject = display.newText(textOptions)
			textObject:setFillColor(unpack(fontColor))
			textObject.anchorX, textObject.anchorY = 0, 0
			textObject.y = (index - 1) * selectSize
			textObject.text = strings[index]
			generalTextGroup:insert(textObject)
		end
	end
	
	textlist:setStrings(strings)
	
	return textlist
end

return extrawidget
