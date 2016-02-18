---------------------------------------------- Offline Queue
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extrafile = require(folder.."extrafile")
local internet = require(folder.."internet")
local logger = require(folder.."logger")
local sqlite3 = require("sqlite3")
local json = require("json")

local offlinequeue = {}
---------------------------------------------- Variables 
local initialized
local database
local currentLoop
local resultListenerList
local retryOnError
local paused
---------------------------------------------- Constants 
local FILENAME_QUEUE = "offlinequeue.db"
local CHECK_INTERVAL = 600
local MAX_REQUESTS = 6

local ID_STATUS = {
	READY = 0,
	PROCESSING = 1,
	NO_LISTENER = 2,
}
---------------------------------------------- Functions
local function setProcessingStatus(row, statusID)
	statusID = statusID or ID_STATUS.READY
	local setProcessing = database:prepare("UPDATE queue SET processing = "..tostring(statusID).." WHERE rowid = "..row.rowid)
	local processingResult = setProcessing:step()
	assert(processingResult == sqlite3.DONE, "Failed to set processing")
end

local function deleteRequest(rowID, tag)
	local deleteStatement = database:prepare("DELETE FROM queue WHERE rowid = "..tostring(rowID))
	local result = deleteStatement:step()
	if result ~= sqlite3.DONE then
		logger.info([[Event "]]..tostring(tag)..[[" ]]..tostring(rowID)..[[ was not deleted.]])
	else
		logger.info([[Event "]]..tostring(tag)..[[" ]]..tostring(rowID)..[[ was deleted.]])
	end
end

local function emptyQueue(statusID)
	statusID = statusID or ID_STATUS.READY
	local statement = database:prepare("SELECT ROWID, requestData, processing, tag FROM queue WHERE processing = "..tostring(statusID).." ORDER BY ROWID LIMIT "..MAX_REQUESTS)
	assert(statement, "Failed to prepare emptyQueue statement")
	
	local stop = false
	repeat
		local result = statement:step()
		if result == sqlite3.DONE then
			stop = true
		elseif result == sqlite3.ROW then
			local row = statement:get_named_values()
			
			setProcessingStatus(row, ID_STATUS.PROCESSING)

			local tag = row.tag
			local rowid = row.rowid
			local function requestListener(event)
				if resultListenerList and resultListenerList[tag] then
					event.tag = tag
					local result = resultListenerList[tag](event) -- User can return false to indicate that there was an error
					if result ~= nil then
						event.isError = not result
					end
					
					if event.isError then
						if not retryOnError[event.tag] then
							logger.log([[Will not retry event "]]..tostring(event.tag)..[[" ]]..tostring(rowid)..[[ .]])
							deleteRequest(rowid, event.tag)
						else
							setProcessingStatus(row, ID_STATUS.READY) -- Retry on next cycle
							logger.error([[Will retry sending event "]]..tostring(event.tag)..[[" ]]..tostring(rowid)..[[ .]])
						end
					else
						logger.log([[Event "]]..tostring(event.tag)..[[" ]]..tostring(rowid)..[[ was completed.]])
						deleteRequest(rowid, event.tag)
					end
				else
					setProcessingStatus(row, ID_STATUS.NO_LISTENER)
					logger.error([[Event "]]..tostring(event.tag)..[[" ]]..tostring(rowid)..[[ was completed, but had no listener.]])
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

local function openDatabase()
	if extrafile.exists(FILENAME_QUEUE, system.CachesDirectory) then
		if not extrafile.exists(FILENAME_QUEUE, system.DocumentsDirectory) then
			local copyFromPath = system.pathForFile( FILENAME_QUEUE, system.CachesDirectory)
			local copyToPath = system.pathForFile( FILENAME_QUEUE, system.DocumentsDirectory)
			
			local copyFromFile = io.open(copyFromPath, "rb")
			local copyToFile, fileError = io.open(copyToPath, "wb")
			
			if copyFromFile and copyToFile then
				local copyFromData = copyFromFile:read("*a")
				if copyFromData then
					if not copyToFile:write(copyFromData) then
						logger.error("Cache could not be restored")
					else
						logger.log("Found cache, restored as working copy")
						os.remove(system.pathForFile(FILENAME_QUEUE, system.CachesDirectory))
					end
				else
					logger.error("There was no data when restoring cache")
				end
			elseif fileError then
				logger.error("Restoring cache failed: "..tostring(fileError))
			end
		end
	end
	
	local syncResults, syncError = native.setSync(FILENAME_QUEUE, {iCloudBackup = false})
	if syncError and "string" == type(syncError) then
		logger.error("[OfflineQueue] "..tostring(syncError))
	end
	
	local databasePath = system.pathForFile(FILENAME_QUEUE, system.DocumentsDirectory)
	local databaseObject = sqlite3.open(databasePath)
	assert(databaseObject, "There was an error opening offlinequeue database")
	
	return databaseObject
end

local function initialize()
	if not initialized then
		paused = false
		
		retryOnError = {}
		
		database = openDatabase()
		database:trace(function(sql)
			logger.log("SQL: "..sql)
		end, {})

		local statement, errorCode = database:prepare([[SELECT COUNT(*) FROM sqlite_master WHERE type = "table" AND name = "queue"]])
		
		if statement and statement.step then
			local result = statement:step()
			assert(result == sqlite3.ROW, "Failed to detect if queue already exists")

			if statement:get_value(0) == 0 then
				logger.log("Creating queue table.")
				local exec = database:exec[[CREATE TABLE queue (requestData TEXT NOT NULL, processing INTEGER DEFAULT 0, tag VARCHAR)]]
				assert(exec == sqlite3.OK, "There was an error creating queue tablea")
			else
				logger.log("Queue table already exists.")
			end
			statement:finalize()

			currentLoop = 0
			Runtime:addEventListener("enterFrame", queueLoop)

			initialized = true
		else
			logger.error("There was a critical error detecting queue database, error "..tostring(errorCode))
			os.exit(-1000) -- TODO add an error code dictionary
		end
	end
end

---------------------------------------------- Class/Module functions
function offlinequeue.clear()
	if initialized then
		logger.log("resetting")
		local deleteStatement = database:prepare("DELETE FROM queue")
		local result = deleteStatement:step()
		assert(result == sqlite3.DONE, "Failed to delete requestData")
	else
		logger.error("Must be initialized to reset!")
	end
end

function offlinequeue.pause()
	paused = true
end

function offlinequeue.unpause()
	paused = false
end

function offlinequeue.retryTagless()
	if internet.isConnected() then
		currentLoop = 1
		emptyQueue(ID_STATUS.NO_LISTENER)
	end
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
		logger.error(""..tag.." listener already exists!")
	else
		logger.log("Adding "..tag.." listener.")
		resultListenerList[tag] = listener
	end
end

function offlinequeue.removeResulListener(tag)
	if resultListenerList and resultListenerList[tag] then
		logger.log("Removing "..tag.." listener.")
		resultListenerList[tag] = nil
	else
		logger.error("Listener "..tag.." did not exist.")
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
	
	local rowid = database:last_insert_rowid()

	logger.log([["]]..tostring(tag)..[[" ]]..tostring(rowid)..[[ request was added to queue.]])
	currentLoop = 1

end
---------------------------------------------- Execution
initialize() 

return offlinequeue





