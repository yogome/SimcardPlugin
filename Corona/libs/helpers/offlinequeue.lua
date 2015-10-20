---------------------------------------------- Offline Queue
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local internet = require( folder.."internet" )
local sqlite3 = require( "sqlite3" )
local json = require( "json" )

local offlinequeue = {}
---------------------------------------------- Variables 
local initialized
local database
local currentLoop
local resultListenerList
local retryOnError
local paused
---------------------------------------------- Constants 
local QUEUE_FILENAME = "offlinequeue.db"
local CHECK_INTERVAL = 300
---------------------------------------------- Functions
local function emptyQueue()
	local statement = database:prepare("SELECT ROWID, requestData, processing, tag FROM queue WHERE processing = 0 ORDER BY ROWID LIMIT 10")
	assert(statement, "Failed to prepare emptyQueue statement")
	
	local stop = false
	repeat
		local result = statement:step()
		if result == sqlite3.DONE then
			stop = true
		elseif result == sqlite3.ROW then
			local row = statement:get_named_values()

			local setProcessing = database:prepare("UPDATE queue SET processing = 1 WHERE rowid = "..row.rowid)
			local processingResult = setProcessing:step()
			assert(processingResult == sqlite3.DONE, "Failed to set processing")

			local tag = row.tag
			local rowid = row.rowid
			local function requestListener(event)
				if resultListenerList and resultListenerList[tag] then
					event.tag = tag
					local result = resultListenerList[tag](event)
					if result ~= nil then
						event.isError = not result
					end
				end
				if event.isError then
					
					if not retryOnError[event.tag] then
						local deleteStatement = database:prepare("DELETE FROM queue WHERE rowid = "..rowid)
						local result = deleteStatement:step()
						if result ~= sqlite3.DONE then
							logger.error([[[Offlinequeue] Event "]]..event.tag..[[" returned an error, but was not deleted.]])
						else
							logger.error([[[Offlinequeue] Event "]]..event.tag..[[" returned an error, and was removed from queue.]])
						end
					else
						local setProcessing = database:prepare("UPDATE queue SET processing = 0 WHERE rowid = "..rowid)
						local processingResult = setProcessing:step()
						assert(processingResult == sqlite3.DONE, "Failed to set processing")
						logger.error([[[Offlinequeue] Event "]]..event.tag..[[" returned an error.]])
					end
				else
					local deleteStatement = database:prepare("DELETE FROM queue WHERE rowid = "..rowid)
					local result = deleteStatement:step()
					if result ~= sqlite3.DONE then
						logger.error([[[Offlinequeue] Event "]]..event.tag..[[" was completed, but not deleted.]])
					else
						logger.log([[[Offlinequeue] Event "]]..tostring(event.tag)..[[" was completed.]])
					end
				end
			end
			
			local requestData = json.decode(row.requestData)
			network.request(requestData.url, requestData.method, requestListener, requestData.params)
		end
	until(stop)
end

local function queueLoop()
	if not paused then
		if currentLoop % CHECK_INTERVAL == 0 then
			if internet.isConnected() then
				emptyQueue()
			end
			currentLoop = 1
		end
		currentLoop = currentLoop + 1
	end
end

local function initialize()
	if not initialized then
		paused = false
		
		retryOnError = {}
		
		local databasePath = system.pathForFile(QUEUE_FILENAME, system.CachesDirectory)
		database = sqlite3.open(databasePath)
		assert(database, "There was an error opening offlinequeue database")

		database:trace(function(sql)
			logger.log("[OfflineQueue] SQL: "..sql)
		end, {})

		local statement = database:prepare([[SELECT COUNT(*) FROM sqlite_master WHERE type = "table" AND name = "queue"]])
		local result = statement:step()
		assert(result == sqlite3.ROW, "Failed to detect if queue already exists")

		if statement:get_value(0) == 0 then
			logger.log("[Offlinequeue] Creating queue table.")
			local exec = database:exec[[CREATE TABLE queue (requestData TEXT NOT NULL, processing INTEGER DEFAULT 0, tag VARCHAR)]]
			assert(exec == sqlite3.OK, "There was an error creating queue tablea")
		else
			logger.log("[Offlinequeue] Queue table already exists.")
		end
		statement:finalize()
		
		currentLoop = 0
		Runtime:addEventListener("enterFrame", queueLoop)

		initialized = true
	end
end

---------------------------------------------- Class/Module functions
function offlinequeue.clear()
	if initialized then
		logger.log("[Offlinequeue] resetting")
		local deleteStatement = database:prepare("DELETE FROM queue")
		local result = deleteStatement:step()
		assert(result == sqlite3.DONE, "Failed to delete requestData")
	else
		logger.error("[Offlinequeue] Must be initialized to reset!")
	end
end

function offlinequeue.pause()
	paused = true
end

function offlinequeue.unpause()
	paused = false
end

function offlinequeue.forceEmpty()
	if internet.isConnected() then
		currentLoop = 1
		emptyQueue()
	end
end

function offlinequeue.addResultListener(tag, listener, options)
	if not(tag and "string" == type(tag)) then
		error("tag must be a string.", 3)
	end
	
	if not(listener and "function" == type(listener)) then
		error("listener must be a function.", 3)
	end
	
	local retryFlag = false
	if options ~= nil and "boolean" == type(options) then
		retryFlag = options
	else
		options = options or {}
		retryFlag = options.retryOnError
	end
	
	retryOnError[tag] = retryFlag and true
	
	if not resultListenerList then
		resultListenerList = {}
	end
	if resultListenerList[tag] then
		logger.error("[Offlinequeue] "..tag.." listener already exists!")
	else
		logger.log("[Offlinequeue] Adding "..tag.." listener.")
		resultListenerList[tag] = listener
	end
end

function offlinequeue.removeResulListener(tag)
	if resultListenerList and resultListenerList[tag] then
		logger.log("[Offlinequeue] Removing "..tag.." listener.")
		resultListenerList[tag] = nil
	else
		logger.error("[Offlinequeue] Listener "..tag.." did not exist.")
	end
end

function offlinequeue.request(url, method, params, tag)
	if not(url and "string" == type(url)) then
		error("url must be a string.", 3)
	end
	
	method = method or "GET"
	if not(method and "string" == type(method) and (method == "GET" or method == "POST" or method == "HEAD" or method == "PUT" or method == "DELETE"))then
		error("method was invalid.", 3)
	end
	
	if not(not params or (params and "table" == type(params))) then
		error("params must be a table or nil.", 3)
	end
	
	local tag =  tag or ""
	if not(tag and "string" == type(tag)) then
		error("tag must be a string.", 3)
	end
	
	local requestData = {
		url = url,
		method = method,
		params = params
	}
	
	local jsonObject = json.encode(requestData)

	local statement = database:prepare("INSERT INTO queue (requestData, tag) VALUES (:jsonObject, :tag)")
	statement:bind_names({jsonObject = jsonObject, tag = tag})
	
	local result = statement:step()
	assert(result == sqlite3.DONE, "Failed to insert new queued item")

	statement:finalize()
end
---------------------------------------------- Execution
initialize() 

return offlinequeue





