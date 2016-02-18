----------------------------------------------- Event counter
local path = ...
local folder = path:match("(.-)[^%.]+$") 
local logger = require(folder.."logger")
local database = require( folder.."database" )
local json = require( "json" )

local eventCounter = {}
----------------------------------------------- Variables
local allEventsModel 
local allEvents
local initialized
----------------------------------------------- Constants
local NAME_CONFIGURATION = "eventCountData"
----------------------------------------------- Functions
----------------------------------------------- Module functions
function eventCounter.initialize()
	if not initialized then
		allEventsModel = database.newModel(NAME_CONFIGURATION, nil, nil, true)
		allEvents = allEventsModel.getCurrent()
		initialized = true
	end
end

function eventCounter.updateEventCount(eventCategory, eventName)
	if initialized then
		local eventCounts = allEvents[eventCategory] or {}
	
		if eventCounts[eventName] then
			eventCounts[eventName] = eventCounts[eventName] + 1
		else
			eventCounts[eventName] = 1
		end

		logger.log("Category:"..eventCategory..", Name:"..eventName..", Times:"..eventCounts[eventName])

		allEvents[eventCategory] = eventCounts

		return eventCounts[eventName]
	else
		logger.error("You need to call initialize first! will always return 0.")
	end
	return 0
end

function eventCounter.saveCounts()
	if initialized then
		allEventsModel.save(allEvents)
		logger.log("Saved event count data.")
	else
		logger.error("You need to call initialize first! Unable to save data.")
	end
end

return eventCounter