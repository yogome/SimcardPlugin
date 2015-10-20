----------------------------------------------- Tutorials
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )

local tutorials = {}
----------------------------------------------- Variables
local tutorialTransitions
local tutorialList
----------------------------------------------- Caches
local mathFloor = math.floor 
----------------------------------------------- Constants
local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/"
local CENTERX = display.contentCenterX
local CENTERY = display.contentCenterY

local TIME_FADE_MAX = 400
local TIME_GOOD_MAX = 400

local ANCHOR_X = 0.25
local ANCHOR_Y = 0.2

local ID_STEP_TAP = "tap"
local ID_STEP_DRAG = "drag"

local function destroyTutorial(tutorial)
	display.remove(tutorial.dragObject)
	display.remove(tutorial.handSprite)
	tutorial.handSprite.playAnimation = nil
	tutorial.dragObject = nil
	tutorial.handSprite = nil
	tutorial.id = nil
	tutorial.transitions = nil
end
----------------------------------------------- Module functions
function tutorials.start(options)
	options = options or {}
	local iterations = options.iterations or 1
	local steps = options.steps or {}
	local scale = options.scale or 1
	local parentScene = options.parentScene
	
	tutorialTransitions = tutorialTransitions or {}
	
	local tutorial = {}
	local tutorialID = #tutorialTransitions + 1
	tutorialTransitions[tutorialID] = tutorial
		
	local handSpriteData = {width = 256, height = 256, numFrames = 6}
	local handSpriteSheet = graphics.newImageSheet( PATH_IMAGES.."tutorialHand.png", handSpriteData )

	local handAnimationData = {
		{ name = "idle", sheet = handSpriteSheet, frames = {1}, time = 500 },
		{ name = "drag", sheet = handSpriteSheet, frames = {2}, time = 500 },
		{ name = "tap", sheet = handSpriteSheet, start = 1, count = 2, time = 500},
		{ name = "good", sheet = handSpriteSheet, frames = {3,4,5,6}, time = 300, loopCount = 1},
	}

	local handSprite = display.newSprite( handSpriteSheet, handAnimationData )
	handSprite.alpha = 0
	handSprite.xScale, handSprite.yScale = scale, scale
	handSprite.anchorX, handSprite.anchorY = ANCHOR_X, ANCHOR_Y
	parentScene:insert(handSprite)
	
	local dragObject = display.newGroup()
	parentScene:insert(dragObject)
	tutorial.dragObject = dragObject
	
	local attachTo = nil
	local attachOffset = {x = 0, y = 0}
	handSprite.enterFrame = function()
		if attachTo and attachTo.x and attachTo.y and attachTo.rotation then
			local targetX, targetY = attachTo.localToContent and attachTo:localToContent(0,0) or attachTo.x, attachTo.y
			handSprite.x = targetX + attachOffset.x
			handSprite.y = targetY + attachOffset.y
			handSprite.rotation = -attachTo.rotation
		end
	end
	Runtime:addEventListener("enterFrame", handSprite.enterFrame)
	
	function handSprite:playAnimation(animation)
		handSprite:setSequence(animation)
		handSprite:play()
	end
	
	tutorial.handSprite = handSprite
	tutorial.id = tutorialID
	tutorial.transitions = {}
	
	local totalTime = 0
	for index = 1, #steps do
		local step = steps[index]
		
		local stepDelay = step.delay or 0
		local stepTime = step.time or 500
		
		totalTime = totalTime + stepDelay + stepTime
	end
	
	local function addTransition(transitionID)
		tutorial.transitions[#tutorial.transitions + 1] = transitionID
	end
	
	local function executeTransitions()
		local currentTime = 0
		for index = 1, #steps do
			local step = steps[index]

			local stepID = step.id or ID_STEP_TAP
			local stepTransition = step.transition or easing.inOutQuad
			local stepTransitionX = step.xTransition or easing.inOutQuad
			local stepTransitionY = step.yTransition or easing.inOutQuad
			
			local stepDelay = step.delay or 1
			local stepTime = step.time or 1500
			stepTime = stepTime > 0 and stepTime or math.huge
			
			local stepX = step.x or 0
			local stepY = step.y or 0
			
			local flipX = step.flipX and step.flipX
			local flipY = step.flipY and step.flipY
			
			local thumbsUp = step.thumbsUp == nil or step.thumbsUp
			
			local eventTimeMultipler = thumbsUp and 0.5 or 0.7 -- If not thumbsUp, we use up that extra time here
			local fadeTime = mathFloor(stepTime * 0.15)
			local eventTime = mathFloor(stepTime * eventTimeMultipler)
			local goodTime = mathFloor(stepTime * 0.2)

			if fadeTime > TIME_FADE_MAX then
				local extraTime = fadeTime - TIME_FADE_MAX
				fadeTime = TIME_FADE_MAX
				eventTime = eventTime + extraTime * 2
			end

			if goodTime > TIME_GOOD_MAX then
				local extraTime = goodTime - TIME_FADE_MAX
				goodTime = TIME_GOOD_MAX
				eventTime = eventTime + extraTime
			end

			if stepID == ID_STEP_TAP then
				addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = fadeTime, alpha = 1, transition = stepTransition, onStart = function()
					
					handSprite.xScale = flipX and -scale or scale
					handSprite.yScale = flipY and -scale or scale
					
					handSprite:playAnimation("idle")
					if step.getObject and "function" == type(step.getObject) then
						attachOffset = {x = stepX or 0, y = stepY or 0}
						attachTo = step.getObject()
					else
						attachTo = {x = stepX, y = stepY, rotation = 0}
					end
				end}))
				currentTime = currentTime + fadeTime
				
				addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = eventTime, transition = stepTransition, onStart = function()
					handSprite.xScale = flipX and -scale or scale
					handSprite.yScale = flipY and -scale or scale
					handSprite:playAnimation("tap")
				end}))
				currentTime = currentTime + eventTime
				
				if thumbsUp then
					addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = goodTime, transition = stepTransition, onStart = function()
						handSprite.xScale = flipX and -scale or scale
						handSprite.yScale = flipY and -scale or scale
						handSprite:playAnimation("good")
					end}))
					currentTime = currentTime + goodTime
				end
				
				addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = fadeTime, alpha = 0, transition = stepTransition}))
				currentTime = currentTime + fadeTime
			elseif stepID == ID_STEP_DRAG then
				local toX = step.toX or 0
				local toY = step.toY or 0
				
				addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = fadeTime, alpha = 1, transition = stepTransition, onStart = function()
					handSprite.xScale = flipX and -scale or scale
					handSprite.yScale = flipY and -scale or scale
					handSprite:playAnimation("idle")
					if step.getObject and "function" == type(step.getObject) then
						attachOffset = {x = stepX or 0, y = stepY or 0}
						attachTo = step.getObject()
						dragObject.x, dragObject.y = attachTo.x, attachTo.y				
					else
						attachTo = {x = stepX, y = stepY, rotation = 0}
						dragObject.x, dragObject.y = stepX, stepY
					end
				end}))
				currentTime = currentTime + fadeTime
				
				addTransition(transition.to(dragObject, {delay = currentTime + stepDelay, time = 1, onStart = function()
					handSprite.xScale = flipX and -scale or scale
					handSprite.yScale = flipY and -scale or scale
					
					dragObject.x = attachTo.x
					addTransition(transition.to(dragObject, {time = eventTime, x = toX, transition = (stepTransitionX or stepTransition)}))
				end}))
				addTransition(transition.to(dragObject, {delay = currentTime + stepDelay, time = 1, onStart = function()
					handSprite.xScale = flipX and -scale or scale
					handSprite.yScale = flipY and -scale or scale
					
					dragObject.y = attachTo.y
					addTransition(transition.to(dragObject, {time = eventTime, y = toY, transition = (stepTransitionY or stepTransition)}))
					handSprite:playAnimation("drag")
					attachTo = dragObject
				end}))
				currentTime = currentTime + eventTime
				
				if thumbsUp then
					addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = goodTime, transition = stepTransition, onStart = function()
						handSprite.xScale = flipX and -scale or scale
						handSprite.yScale = flipY and -scale or scale

						handSprite:playAnimation("good")
					end}))
					currentTime = currentTime + goodTime
				end
				
				
				addTransition(transition.to(handSprite, {delay = currentTime + stepDelay, time = fadeTime, alpha = 0, transition = stepTransition}))
				currentTime = currentTime + fadeTime
			end
			currentTime = currentTime + stepDelay
		end
	end
	
	local currentIterations = 0
	addTransition(transition.to(handSprite, {time = totalTime, iterations = iterations, onStart = function()
		executeTransitions()
	end, onRepeat = function(event)
		currentIterations = currentIterations + 1
		if currentIterations >= iterations then
			tutorials.cancel(tutorial)
		else
			executeTransitions()
		end
	end}))
	
	function tutorial:stop()
		currentIterations = iterations
	end
	
	function tutorial:pause()
		if self.tutorialHand then
			transition.pause(self.tutorialHand)
		end
	end
	
	function tutorial:resume()
		if self.tutorialHand then
			transition.resume(self.tutorialHand)
		end
	end
	
	function tutorial:cancel()
		tutorials.cancel(self)
	end
	
	parentScene:addEventListener("finalize", function()
		pcall(function()
			logger.error("[Tutorials] Canceling tutorial due to parent scene elimination")
			tutorials.cancel(tutorial)
		end)
	end)
	
	return tutorial
end

function tutorials.pause(tutorial)
	if tutorial and tutorial.pause and "function" == type(tutorial.pause) then
		tutorial:pause()
	end
end

function tutorials.resume(tutorial)
	if tutorial and tutorial.resume and "function" == type(tutorial.resume) then
		tutorial:resume()
	end
end

function tutorials.stop(tutorial, softness)
	if tutorial and tutorial.stop and "function" == type(tutorial.stop) then
		tutorial:stop()
	end
end

function tutorials.cancel(tutorial, softness)
	if tutorial and tutorial.id then
		if tutorial.handSprite then
			if tutorial.handSprite.enterFrame then 
				Runtime:removeEventListener("enterFrame", tutorial.handSprite.enterFrame) 
			end
			transition.cancel(tutorial.handSprite)
			transition.cancel(tutorial.dragObject)
			if softness and softness > 0 then
				transition.to(tutorial.handSprite, {time = softness, alpha = 0, transition = easing.inOutQuad, onComplete = function()
					destroyTutorial(tutorial)
				end})
			else
				destroyTutorial(tutorial)
			end
		end
	end
end

return tutorials
