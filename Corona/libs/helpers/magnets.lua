----------------------------------------------- Magnets
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger")
local extratable = require(folder.."extratable")

local magnets = {}
----------------------------------------------- Local functions
local function slotGetObjects(slot)
	return slot.objects
end

local function rearrangeSlot(slot)
	for index = 1, #slot.objects do
		transition.cancel(slot.objects[index])
		local x, y = slot.offsetFunction(index)
		transition.to(slot.objects[index], {time = 400, x = x, y = y, transition = easing.inOutQuad})
	end
end

local function defaultOffsetFunction(index)
	return unpack({0, 0})
end

local function destroyObject(object)
	display.remove(object)
end

local function insertObjectOnOriginal(object)
	object.originalSlot.capacity = object.originalSlot.capacity - 1
	if not extratable.containsValue(object.originalSlot.objects, object) then
		object.originalSlot.objects[#object.originalSlot.objects + 1] = object
	end
	object.slot = object.originalSlot

	local offsetX, offsetY = object.originalSlot.offsetFunction(object.originalSlot.maxCapacity - object.originalSlot.capacity)

	local contentX, contentY = object:localToContent(0, 0)
	object.x, object.y = object.originalSlot:contentToLocal(contentX, contentY)

	object.originalSlot:insert(object)

	object.lockDrag = false

	transition.cancel(object)
	transition.to(object, {time = 500, x = offsetX, y = offsetY, transition = easing.outQuad})
end

local function insertObjectOnLast(object)
	object.lastSlot.capacity = object.lastSlot.capacity - 1
	if not extratable.containsValue(object.lastSlot.objects, object) then
		object.lastSlot.objects[#object.lastSlot.objects + 1] = object
	end
	object.slot = object.lastSlot

	local offsetX, offsetY = object.lastSlot.offsetFunction(object.lastSlot.maxCapacity - object.lastSlot.capacity)

	local contentX, contentY = object:localToContent(0, 0)
	object.x, object.y = object.lastSlot:contentToLocal(contentX, contentY)

	object.lastSlot:insert(object)

	object.lockDrag = false

	transition.cancel(object)
	transition.to(object, {time = 500, x = offsetX, y = offsetY, transition = easing.outQuad})
end

local function dragObject(event)
	local object = event.target

	local slotEnabled = (object.slot == nil and true) or (object.slot ~= nil and object.slot.isEnabled)
	
	if not object.lockDrag and slotEnabled then
		local phase = event.phase
		if "began" == phase then
			transition.cancel(object)
			local contentX, contentY = object:localToContent(0, 0)
			object.x, object.y = object.canvas:contentToLocal(contentX, contentY)
			object.canvas:insert(object)
			
			display.getCurrentStage():setFocus(object)
			
			if object.slot then
				extratable.removeItem(object.slot.objects, object)
				object.slot.capacity = object.slot.capacity + 1
				object.slot:rearrange()
				object.lastSlot = object.slot
				object.slot = nil
			end

			object.isFocus = true

			object.x0 = event.x - object.x
			object.y0 = event.y - object.y
		elseif object.isFocus then
			if "moved" == phase then
				object.x = event.x - object.x0
				object.y = event.y - object.y0
			elseif "ended" == phase or "cancelled" == phase then
				display.getCurrentStage():setFocus(nil)
				object.isFocus = false
				object.lockDrag = true
				
				if #object.slots > 0 then
					for index = 1, #object.slots do
						local slot = object.slots[index]
						
						local x, y = object:localToContent(0, 0)
						local slotX, slotY = slot:localToContent(0, 0)
						
						local halfWidth = slot.width * 0.5
						local halfHeight = slot.height * 0.5

						local insideX = slotX - halfWidth < x and x < slotX + halfWidth
						local insideY = slotY - halfHeight < y and y < slotY + halfHeight

						if insideX and insideY and slot.capacity > 0 then
							slot.capacity = slot.capacity - 1
							if not extratable.containsValue(slot.objects, object) then
								slot.objects[#slot.objects + 1] = object
							end
							object.slot = slot
							
							local offsetX, offsetY = slot.offsetFunction(slot.maxCapacity - slot.capacity)
							
							local contentX, contentY = object:localToContent(0, 0)
							object.x, object.y = slot:contentToLocal(contentX, contentY)
							
							slot:insert(object)

							object.lockDrag = false
							
							transition.cancel(object)
							transition.to(object, {time = 500, x = offsetX, y = offsetY, transition = easing.outQuad})

							break
						elseif index == #object.slots then -- Is outside and is last object
							
							if object.returnToOriginal and object.originalSlot and object.originalSlot.capacity > 0 then
								insertObjectOnOriginal(object)
							elseif object.returnToPrevious and object.lastSlot then -- TODO refactor this repeated code
								insertObjectOnLast(object)
							else
								transition.to(object, {time = 500, alpha = 0, transition = easing.inOutQuad, onComplete = destroyObject})
							end
						end
					end
				else
					transition.to(object, {time = 500, alpha = 0, transition = easing.inOutQuad, onComplete = destroyObject})
				end
			end
		end
	end

	return true
end
----------------------------------------------- Module functions

function magnets.newSlot(options)
	options = options or {}
	options = extratable.deepcopy(options)
	
	local radius = options.radius
	local width = options.width or 100
	local height = options.height or 100
	
	local isVisible = options.isVisible
	
	local slot = display.newGroup()
	slot.capacity = options.capacity or 1
	slot.maxCapacity = options.capacity
	slot.isEnabled = true
	slot.offsetFunction = options.offsetFunction or defaultOffsetFunction
	slot.objects = {}
	
	slot.rearrange = rearrangeSlot
	slot.getObjects = slotGetObjects
	
	if options.prefill and options.prefill.cloneFunction and options.prefill.slots and options.prefill.canvasGroup then
		options.prefill.slots[#options.prefill.slots + 1] = slot
		
		local amount = options.prefill.amount or 1
		local returnToPrevious = options.prefill.returnToPrevious == nil or options.prefill.returnToPrevious
		local returnToOriginal = options.prefill.returnToOriginal
		
		for index = 1, amount do
			local cloned = options.prefill.cloneFunction()
			cloned.x, cloned.y = slot.offsetFunction(index)
			cloned.originalSlot = slot
			cloned.slots = options.prefill.slots
			cloned.slot = slot
			cloned.lastSlot = slot
			cloned.canvas = options.prefill.canvasGroup
			cloned.returnToPrevious = returnToPrevious
			cloned.returnToOriginal = returnToOriginal
			cloned:addEventListener("touch", dragObject)
			slot:insert(cloned)

			slot.capacity = slot.capacity - 1
			slot.objects[#slot.objects + 1] = cloned
		end
	end
	
	slot:addEventListener("touch", function(event)
		if event.phase == "began" then
			local object = slot.objects[#slot.objects]
			if object and object.dispatchEvent then
				display.getCurrentStage():setFocus(slot, nil)
				event.phase = "began"
				event.target = object
				object:dispatchEvent(event)
			end
		end
	end)
	
	local slotGraphic = radius and display.newCircle(0, 0, radius) or display.newRect(0, 0, width, height)
	slotGraphic.radius = radius
	slotGraphic.isHitTestable = true
	slotGraphic.fill = {0, 0, 0, 0}
	slotGraphic:setStrokeColor(1)
	slotGraphic.strokeWidth = 3
	slotGraphic.isVisible = isVisible
	slot:insert(slotGraphic)
	
	function slot:setEnabled(value)
		self.isEnabled = value
	end
	
	return slot
end

function magnets.newCloner(cloneFunction, options)
	if cloneFunction and "function" == type(cloneFunction) then
		options = options or {}
		
		local radius = options.radius
		local width = options.width or 100
		local height = options.height or 100
		local isVisible = options.isVisible
		local canvasGroup = options.canvasGroup
		local slots = options.slots or {}
		
		local cloner = display.newGroup()
		cloner.isEnabled = true
		local clonerGraphic = radius and display.newCircle(0, 0, radius) or display.newRect(0, 0, width, height)
		cloner:insert(clonerGraphic)
		clonerGraphic.isHitTestable = true
		clonerGraphic.fill = {0, 0, 0, 0}

		if isVisible then
			clonerGraphic:setStrokeColor(1)
			clonerGraphic.strokeWidth = 3
		end
		
		clonerGraphic:addEventListener("touch", function(event)
			if event.phase == "began" and cloner.isEnabled then
				local cloned = cloneFunction()
				cloned.x, cloned.y = cloner.x, cloner.y
				cloned.slots = slots
				cloned:addEventListener("touch", dragObject)
				
				canvasGroup = canvasGroup or cloner.parent
				cloned.canvas = canvasGroup
				canvasGroup:insert(cloned)
				
				display.getCurrentStage():setFocus(clonerGraphic, nil)
				event.phase = "began"
				event.target = cloned
				cloned:dispatchEvent(event)
			end
		end)
		
		function cloner:setEnabled(value)
			self.isEnabled = value
		end
		
		return cloner
	else
		
	end
end


return magnets
