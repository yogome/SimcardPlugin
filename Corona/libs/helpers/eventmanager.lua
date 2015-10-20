----------------------------------------------- Event manager
local eventManager = {}
----------------------------------------------- Variables
local eventObject 
local eventTracker
----------------------------------------------- Constants
----------------------------------------------- Functions
local function initialize()
	eventObject = Runtime._super:new()
	eventTracker = {}
end
----------------------------------------------- Module Functions 
function eventManager:addEventListener(eventName, eventFunction)
	local eventData = eventTracker[eventName]
	if eventData then
		eventObject:removeEventListener(eventData.eventName, eventData.eventFunction)
		eventTracker[eventName] = nil
	end
	eventTracker[eventName] = {eventName = eventName, eventFunction = eventFunction}
	eventObject:addEventListener(eventName, eventFunction)
end

function eventManager:dispatchEvent(eventName, parameters)
	local event = {
		name = eventName,
		parameters = parameters,
	}
	eventObject:dispatchEvent(event)
end

function eventManager:removeEventListener(eventName)
	local eventData = eventTracker[eventName]
	if eventData then
		eventObject:removeEventListener(eventData.eventName, eventData.eventFunction)
		eventTracker[eventName] = nil
	end
end
----------------------------------------------- Execution
initialize() 

return eventManager
