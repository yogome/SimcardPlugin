---------------------------------------------- Sliders
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local colors = require( folder.."colors" ) 
local director = require( folder.."director" ) 

local sliders = {}
---------------------------------------------- Module Functions
function sliders.newOptionSlider(options)
	local slider = display.newGroup()
	
	local positions = options.positions
	local scenePath = options.scenePath
	local debugPosition = options.debugPosition
	
	local knobScale = options.knobScale or 1
	local backgroundScale = options.backgroundScale or 1
	
	local eventListener = options.eventListener
	
	local background = display.newImage(options.background)
	background:scale(backgroundScale, backgroundScale)
	slider:insert(background)
	
	local width = background.contentWidth
	local halfWidth = width * 0.5
	local leftLimit = debugPosition and -halfWidth or (-halfWidth + (positions[1].x * width))
	local rightLimit = debugPosition and halfWidth or (-halfWidth + (positions[#positions].x * width))
	
	local knob = display.newImage(options.knob)
	knob.x = -halfWidth + (positions[options.positionIndex].x * width)
	knob:setFillColor(1,1,1)
	knob:scale(knobScale, knobScale)
	colors.addColorTransition(knob)
	local knobColor = positions[options.positionIndex].color
	director.to(scenePath, knob, {time = 200, r = knobColor[1], g = knobColor[2], b = knobColor[3]})
	slider.knob = knob
	
	slider:insert(knob)
	slider.currentIndex = options.positionIndex
	slider.value = positions[options.positionIndex].value
	
	local function knobTouched( event )
		if eventListener and "function" == type(eventListener) then
			eventListener(event)
		end
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
				slider.oldValue = slider.value
				slider.value = positions[slider.currentIndex].value
			elseif event.phase == "ended" or event.phase == "cancelled" then
				transition.cancel(knob)
				
				if debugPosition then
					logger.log(((knob.x + halfWidth) / width))
				end
				
				local knobColor = positions[slider.currentIndex].color
				director.to(scenePath, knob, {time = 200, r = knobColor[1], g = knobColor[2], b = knobColor[3]})
				director.to(scenePath, knob, {x = -halfWidth + positions[slider.currentIndex].x * width})
				display.getCurrentStage():setFocus( knob, nil )
				knob.isFocus = false
			end
		end
		return true
	end
	knob:addEventListener("touch", knobTouched)
	
	function slider:initialize(initialIndex)
		self.currentIndex = initialIndex or options.positionIndex
		
		self.value = positions[self.currentIndex].value
		self.oldValue = self.value
		
		local knob = self.knob
		knob.x = -halfWidth + (positions[self.currentIndex].x * width)
		knob:setFillColor(1,1,1)
		colors.addColorTransition(knob)
		local knobColor = positions[self.currentIndex].color
		director.to(scenePath, knob, {time = 200, r = knobColor[1], g = knobColor[2], b = knobColor[3]})
	end
	
	function slider:changeBackground(newBackground)
		display.remove(background)
		background = display.newImage(newBackground)
		self:insert(background)
		background:toBack()
	end
	
	return slider
end



return sliders
