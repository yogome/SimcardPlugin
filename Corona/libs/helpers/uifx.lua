----------------------------------------------- UIFX
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local director = require( folder.."director" )

local uifx = {}
----------------------------------------------- Module functions
function uifx.applyBounceTransition(displayObject, options)
	uifx.cancelBounceTransition(displayObject)
	
	options = options or {}
	
	local smallScale = options.smallScale or 0.5
	local largeScale = options.largeScale or 0.75
	local intervalTime = options.intervalTime or 900
	local iterations = options.iterations or -1
	
	transition.to(displayObject, {time = intervalTime, xScale = smallScale, yScale = smallScale, transition = easing.inOutSine})
	transition.to(displayObject, {delay = intervalTime, time = intervalTime, xScale = largeScale, yScale = largeScale, transition = easing.inOutSine})
	displayObject.bounceTimer = timer.performWithDelay(intervalTime * 2, function()
		transition.to(displayObject, {time = intervalTime, xScale = smallScale, yScale = smallScale, transition = easing.inOutSine})
		transition.to(displayObject, {delay = intervalTime, time = intervalTime, xScale = largeScale, yScale = largeScale, transition = easing.inOutSine})
	end, iterations)
end

function uifx.sine(displayObject, options)
	uifx.cancel(displayObject)
	options = options or {}
	
	local index = options.index or "x"
	local halfAmplitude = options.amplitude or 100

	local initialValue = displayObject[index] - halfAmplitude
	local finalValue = initialValue + halfAmplitude
	
	local intervalTime = options.intervalTime or 900
	local iterations = options.iterations or -1
	
	transition.to(displayObject, {time = intervalTime, [index] = initialValue, transition = easing.inOutSine})
	transition.to(displayObject, {delay = intervalTime, time = intervalTime, [index] = finalValue, transition = easing.inOutSine})
	displayObject.bounceTimer = timer.performWithDelay(intervalTime * 2, function()
		transition.to(displayObject, {time = intervalTime, [index] = initialValue, transition = easing.inOutSine})
		transition.to(displayObject, {delay = intervalTime, time = intervalTime, [index] = finalValue, transition = easing.inOutSine})
	end, iterations)
end

function uifx.cancelBounceTransition(displayObject)
	if displayObject and displayObject.bounceTimer then
		timer.cancel(displayObject.bounceTimer)
		displayObject.bounceTimer = nil
		transition.cancel(displayObject)
	end
end

function uifx.cancel(displayObject)
	if displayObject and displayObject.bounceTimer then
		timer.cancel(displayObject.bounceTimer)
		displayObject.bounceTimer = nil
		transition.cancel(displayObject)
	end
end

function uifx.jump(displayObject, options)
	local xPostion = options.x or displayObject.x + 200
	local yPosition = options.y or displayObject.y
	local height = options.height or 100
	local totalTime = options.time or 500
	local halfTime = totalTime * 0.5
	
	local jumpY = displayObject.y - height
	
	local transitions = {}
	transitions[1] = transition.to(displayObject, {time = totalTime, x = xPostion})
	transitions[2] = transition.to(displayObject, {time = halfTime, y = jumpY, transition = easing.outQuad})
	transitions[3] = transition.to(displayObject, {delay = halfTime, time = halfTime, y = yPosition, transition = easing.inQuad})
	
	return transitions
end

function uifx.test()
	local testUIFXScene = director.newScene("testUIFXScene")
	function testUIFXScene:create(event)
		local testRect = display.newRect(display.contentCenterX, display.contentCenterY, 200, 200)
		testRect.x = display.contentCenterX
		testRect.y = display.contentCenterY
		self.view:insert(testRect)
		
		local isBouncing = true
		
		local options = {smallScale = 0.5, largeScale = 1, intervalTime = 600}
		uifx.applyBounceTransition(testRect, options)
		testRect:addEventListener("tap", function()
			isBouncing = not isBouncing
			if isBouncing then
				uifx.cancelBounceTransition(testRect)
			else
				uifx.applyBounceTransition(testRect, options)
			end
		end)
	end
	testUIFXScene:addEventListener("create")
	director.gotoScene("testUIFXScene")
end

return uifx
