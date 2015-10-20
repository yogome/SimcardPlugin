---------------------------------------------- Database
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extrafile = require( folder.."extrafile" )
local sqlite = require( "sqlite3" )
local crypto = require( "crypto" )
local json = require( "json" )
local mime = require( "mime" )
local extrajson = require( folder.."extrajson" )
local extratable = require( folder.."extratable" )
local database = {}
---------------------------------------------- Variables
local initialized
local databaseObject
local debugDatabase
local configurationModel, configurationObject
local models

local overrideChecksum
local onDatabaseClose
---------------------------------------------- Constants
local FILENAME_DATABASE = "default.db"
local NAME_CONFIGURATION_TABLE = "configuration"
local KEY_TIMESTAMP_CREATION = "databaseCreationDate"
---------------------------------------------- Caches
local mathRound = math.round 
---------------------------------------------- Functions
function database.count(tableName)
	local sql = "SELECT COUNT(*) AS total FROM "..tableName..";"
	local count = database.getColumn("total", sql)
	return tonumber(count)
end

local function generateChecksum()
	local sql = [[SELECT name FROM sqlite_master WHERE type="table";]]
	local result = database.getColumns("name", sql)
	
	local checkString = ""
	for indexA = 1, #result do
		if result[indexA] ~= "sqlite_sequence" then
			local dbTable = database.getTable(result[indexA])
			for indexB = 1, #dbTable do
				local row = dbTable[indexB]
				local skip = false
				for key, value in pairs(row) do
					if not skip then
						if "checksum" == value then
							skip = true
						else
							checkString = checkString..value
						end
					else
						skip = false
					end
				end
			end
		end
	end
	return crypto.digest( crypto.md5, checkString )
end

local function onSystemEvent( event )
	if event.type == "applicationExit" then
		if databaseObject and databaseObject:isopen() then
			if onDatabaseClose and "function" == type(onDatabaseClose) then
				onDatabaseClose()
			end
			database.calculateChecksum()
			logger.log("[Database] Closing database.")
			databaseObject:close()
			databaseObject = nil
		end
	end
end 

local function createTable(tableName)
	local statement = databaseObject:prepare([[SELECT COUNT(*) FROM sqlite_master WHERE type = "table" AND name = "]]..tableName..[["]])
	local step = statement:step()
	assert(step == sqlite.ROW, "[Database] Failed to detect if "..tableName.." already exists")

	local value = statement:get_value(0)
	if value == 0 then
		logger.log( "[Database] Creating "..tableName.." table." )
		local tableCreate = [[CREATE TABLE IF NOT EXISTS ]]..tableName..[[ (
			id INTEGER PRIMARY KEY AUTOINCREMENT,
			data TEXT);]]
		local exec = databaseObject:exec(tableCreate)
		assert(exec == sqlite.OK, "[Database] There was an error creating "..tableName)
		return true
	elseif value == 1 then
		logger.log( "[Database] "..tableName.." table is present." )
		return false
	end
end

local function getBlameData()
	if "simulator" == system.getInfo("environment") then
		local info = debug.getinfo(3)
		local lineNumber = info.currentline
		local filepath = string.sub(info.source, 2, -1)
		local currentPath = system.pathForFile(nil, system.ResourceDirectory)
		local relativePath = string.sub(string.gsub(filepath, currentPath, ""), 2, -1)
		local blamedUser = extrafile.getBlame(relativePath, lineNumber)
		return unpack({(blamedUser and (blamedUser.." attempted") or "Attempt"), relativePath, lineNumber})
	end
	return unpack({"Attempt","","",})
end
---------------------------------------------- Module Functions
function database.setOnDatabaseClose(onCloseFunction)
	onDatabaseClose = onCloseFunction
end

function database.compareChecksum()
	database.initialize()
	local dbChecksum = database.config("checksum")
	local currentChecksum = generateChecksum()
	
	local result = dbChecksum == currentChecksum or overrideChecksum
	overrideChecksum = false
	return  result
end

function database.calculateChecksum()
	database.initialize()
	local currentChecksum = generateChecksum()
	database.config("checksum", currentChecksum)
end

function database.exec(sql, args)
	database.initialize()
	local result
	if not args then
		result = databaseObject:exec(sql)
		assert(result == sqlite3.OK, "[Database] Failed("..result.."): "..sql)
	else
		local stmt = databaseObject:prepare(sql)
		assert(type(args) == "table", "expected parameter args to be a table")

		stmt:bind_names(args)
		result = stmt:step()
		assert(result == sqlite3.DONE, "[Database] failed to execute SQL "..result)
	end
end

function database.initialize()
	if not initialized then
		initialized = true
		
		models = models or {}
		if not extrafile.exists(FILENAME_DATABASE, system.DocumentsDirectory) then
			overrideChecksum = true
			logger.log("[Database] Creating database.")
		else
			logger.log("[Database] Opening database.")
		end
		
		local databasePath = system.pathForFile( FILENAME_DATABASE, system.DocumentsDirectory)
		databaseObject = sqlite3.open(databasePath)

		Runtime:addEventListener( "system", onSystemEvent )
		
		databaseObject:trace(function(udata, sql)
			if debugDatabase then
				logger.log("[Database] "..sql)
			end
		end, {})
		
		configurationModel = database.newModel(NAME_CONFIGURATION_TABLE, nil, nil, true)
		configurationObject = configurationModel.get(1, false)
		if not configurationObject then
			configurationObject = configurationModel.new()
			configurationObject.id = 1
			configurationObject[KEY_TIMESTAMP_CREATION] = os.time(os.date("*t"))
			configurationModel.save(configurationObject)
		end
	end
end

function database.getDatabaseAgeDays()
	local timeToday = os.time(os.date("*t"))
	local creationDate = tonumber(database.config(KEY_TIMESTAMP_CREATION)) or 0
	local ageSeconds = timeToday - creationDate
	local ageMinutes = ageSeconds / 60
	local ageHours = ageMinutes / 60
	local ageDays = ageHours / 24
	
	return mathRound(ageDays)
end

function database.getColumns(column, sql)
	local result = {}
	for row in databaseObject:nrows(sql) do
		result[#result + 1] = row[column]
	end
	return result
end

function database.getColumn(column, sql)
	local result
	for row in databaseObject:nrows(sql) do
		result = row[column]
	end
	return result
end

function database.lastRowID()
	return databaseObject:last_insert_rowid()
end

function database.getRow(tableName, args)
	local result = {}
	if tableName and type(tableName) == "string" then
		local where = " "
		if args and type(args) == "table" then
			where = where.." WHERE "
			for key, value in pairs(args) do
				where = where..key.." = "..value.." "
				where = where..","
			end
			where = string.sub(where,1,-2)
		end
		
		local sql = "SELECT * FROM "..tableName..where.." ORDER BY rowid"
		for row in databaseObject:nrows(sql) do
			result = row
		end
	else
		logger.log( "[Database] tableName must not be nil and be a string." )
	end
	return result
end

function database.getRows(tableName, args)
	local result = {}
	if tableName and type(tableName) == "string" then
		local where = " "
		if args and type(args) == "table" then
			where = where.." WHERE "
			for key, value in pairs(args) do
				where = where..key.." = "..value.." "
				where = where..","
			end
			where = string.sub(where,1,-2)
		end
		
		local sql = "SELECT * FROM "..tableName..where.." ORDER BY rowid"
		for row in databaseObject:nrows(sql) do
			result[#result + 1] = row
		end
	else
		logger.log( "[Database] tableName must not be nil and be a string." )
	end
	return result
end

function database.getTable(tableName)
	local result = {}
	if tableName and type(tableName) == "string" then
		local sql = "SELECT * FROM "..tableName.." ORDER BY rowid"
		for row in databaseObject:nrows(sql) do
			result[#result + 1] = row
		end
	else
		logger.log( "[Database] tableName must not be nil and be a string." )
	end
	return result
end

function database.delete()
	for index = 1, #models do
		models[index].deleteAll()
	end
	
	if databaseObject and databaseObject:isopen() then
		databaseObject:close()
		databaseObject = nil
	end
	
	initialized = false
	local deleted, reason = os.remove( system.pathForFile( FILENAME_DATABASE, system.DocumentsDirectory) )
	if deleted then
		logger.log("[Database] Deleted database file.")
		
		database.initialize()
		
		for index = 1, #models do
			models[index].recreate()
		end
	else
		logger.error("[Database] Datbase file could not be deleted.")
	end
end

function database.decodeConfig(encodedData)
	local trimmedEncodedData = string.sub(encodedData, 1, -4)
	local trimmedEncodedDataLenght = string.len(trimmedEncodedData)
	local magicNumber = tonumber(string.sub(encodedData, -3, -3)) - 2
	local decodedB64 = ""
	for index = 1, trimmedEncodedDataLenght do
		local character = string.sub(trimmedEncodedData, index, index)
		local convertOffset = (index % magicNumber == 0 and 1 or -1)
		character = string.char(string.byte(character) - convertOffset)
		decodedB64 = decodedB64..character
	end
	
	local jsonData = mime.unb64(decodedB64)
	return extrajson.decodeFixed(jsonData)
end

function database.dumpConfig()
	database.initialize()
	if configurationObject then
		local jsonConfiguration = json.encode(configurationObject)
		local encodedConfiguration = mime.b64(jsonConfiguration)
		local encodedLenght = string.len(encodedConfiguration)
		local newEncoded = ""
		local randomEncode = math.random(2,5)
		for index = 1, encodedLenght do
			newEncoded = newEncoded..string.char(string.byte(encodedConfiguration, index, index) + (index % randomEncode == 0 and 1 or -1))
		end
		newEncoded = newEncoded..tostring(randomEncode + 2).."=="
		return newEncoded
	else
		logger.error("[Database] Configuration object is not available")
	end
end

function database.getConfigurationModel()
	return configurationModel
end

function database.config(key, value)
	database.initialize()
	if configurationObject then
		if key and type(key) == "string" then
			if value ~= nil then
				configurationObject[key] = value
			elseif not value then
				return configurationObject[key]
			end
			configurationModel.save(configurationObject)
		end
	end
end

function database.newModel(modelName, singularName, debugFields, allowAllKeys)
	database.initialize()
	if modelName and "string" == type(modelName) then
		local model = Runtime._super:new()
		local currentObject
		
		local defaultObject = {}
		local nilKeys = {
			"id",
		}
		
		local modelProperties = {
			name = modelName,
			singularName = singularName or modelName,
			debugFields = debugFields and true,
			allowAllKeys = allowAllKeys and true,
		}

		local modelObjectMetatable = {
			__index = function(tab, key)
				local modelID = rawget(tab, "id")
				if rawget(tab, key) == nil and defaultObject and defaultObject[key] ~= nil then
					if debugFields then
						logger.error([[[Database] key "]]..tostring(key)..[[" from object ]]..(modelID and tostring(modelID) or "with no ID")..[[ from "]]..modelName..[[" was nil, returned default value.]])
					end
					rawset(tab, key, defaultObject[key])
				elseif defaultObject[key] == nil and not extratable.containsValue(nilKeys, key) then
					local blameMessage, relativePath, lineNumber = getBlameData()
					logger.error([[[Database] ]]..blameMessage..[[ to get key "]]..tostring(key)..[[" from object ]]..(modelID and tostring(modelID) or "with no ID")..[[ from "]]..modelName..[[" which is not on the default model, at ]]..relativePath..[[:]]..lineNumber)
				end
				return rawget(tab, key)
			end,
			__newindex = function(tab, key, value)
				if debugFields and debug and debug.traceback and debug.getinfo then
					local modelID = rawget(tab, "id")
					local blameMessage, relativePath, lineNumber = getBlameData()
					if value == nil then
						logger.error("[Database] "..blameMessage..[[ to set nil value on key "]]..tostring(key)..[[" on object ]]..modelID..[[ from "]]..modelName..[[" at ]]..relativePath..[[:]]..lineNumber)
						return
					elseif not defaultObject[key] or not extratable.contains(nilKeys, key) then
						logger.error([[[Database] ]]..blameMessage..[[ to set key "]]..tostring(key)..[[" which is not present in default "]]..modelName..[[" at ]]..relativePath..[[:]]..lineNumber)
						return
					end
				end
				rawset(tab, key, value)
			end
		}
		
		local function setModelObjectMetatable(object, metatable)
			if not allowAllKeys then
				setmetatable(object, metatable)
			end
		end
		
		function model.new(localID, customData)
			local defaultModelObject = (defaultObject and type(defaultObject) == "table" and defaultObject) or {id = localID}
			local newModelObject = extratable.deepcopy(defaultModelObject)
			
			if customData and "table" == type(customData) then
				for key, value in pairs(customData) do
					newModelObject[key] = value
				end
			end
			
			model.save(newModelObject, localID)
			setModelObjectMetatable(newModelObject, modelObjectMetatable)
			return newModelObject
		end
		
		function model.get(objectID, warn)
			warn = warn == nil or warn == true or false
			
			if objectID and "number" == type(tonumber(objectID)) then
				if currentObject and tonumber(currentObject.id) == tonumber(objectID) then
					database.config("current"..modelProperties.singularName.."ID", currentObject.id)
					model:dispatchEvent({name = "fetch", target = currentObject})
					setModelObjectMetatable(currentObject, modelObjectMetatable)
					return currentObject
				end
				
				local persistedObject = database.getRow(modelProperties.name, {id = objectID})
				if persistedObject and not extratable.isEmpty(persistedObject) then
					local decodedObject = extrajson.decodeFixed(persistedObject.data)
					database.config("current"..modelProperties.singularName.."ID", decodedObject.id)
					model:dispatchEvent({name = "fetch", target = decodedObject})
					setModelObjectMetatable(decodedObject, modelObjectMetatable)
					return decodedObject
				elseif warn then
					logger.error("[Database] "..objectID.." is not a valid objectID for "..modelProperties.name)
				end
			elseif warn then
				logger.error("[Database] "..tostring(type(objectID))..":"..tostring(objectID).." is not a valid objectID for "..modelProperties.name)
			end
		end
		
		function model.getCurrent()
			local currentID = database.config("current"..modelProperties.singularName.."ID")
			if currentID then
				if not(currentObject and currentObject.id == currentID) then
					local databaseObject = database.getRow(modelProperties.name, {id = currentID})
					if databaseObject and databaseObject.id and databaseObject.data then
						logger.log("[Database] fetching database object "..currentID.." from "..modelProperties.name)
						currentObject = extrajson.decodeFixed(databaseObject.data)
					else
						local count = model.getCount()
--						database.config("current"..modelProperties.singularName.."ID", false)
--						currentObject = nil
						logger.log("[Database] fetching a new object from "..modelProperties.name)
						
						local newModelObject = model.new(count == 0 and 1 or nil)
						currentObject = newModelObject
						database.config("current"..modelProperties.singularName.."ID", newModelObject.id)
						setModelObjectMetatable(newModelObject, modelObjectMetatable)
						return newModelObject
					end
				else
					logger.log("[Players] fetching current object "..currentID.." from "..modelProperties.name.." from memory")
				end
			else
				logger.log("[Database] fetching a new object from "..modelProperties.name)
				currentObject = model.new()
				database.config("current"..modelProperties.singularName.."ID", currentObject.id)
			end

			model:dispatchEvent({name = "fetch", target = currentObject})
			setModelObjectMetatable(currentObject, modelObjectMetatable)
			return currentObject
		end
		
		function model.getAll()
			local persistedObjects = database.getTable(modelProperties.name)
			local allObjects = {}
			if persistedObjects then
				for index = 1, #persistedObjects do
					local modelObject = extrajson.decodeFixed(persistedObjects[index].data)
					setModelObjectMetatable(modelObject, modelObjectMetatable)
					allObjects[#allObjects + 1] = modelObject
					model:dispatchEvent({name = "fetch", target = modelObject})
				end
			end
			return allObjects
		end
		
		function model.save(modelObject, localID)
			if modelObject and type(modelObject) == "table" then
				modelObject.id = modelObject.id or (type(tonumber(localID)) == "number" and localID)
				
				local function overwrite()
					local jsonData = json.encode(modelObject)
					local function update()
						local sql = [[UPDATE ]]..modelProperties.name..[[ SET data = :data WHERE id = :id;]]
						database.exec(sql, {data = jsonData, id = modelObject.id})
					end

					local oldDatabaseObject = database.getRow(modelProperties.name, {id = modelObject.id})
					if oldDatabaseObject and oldDatabaseObject.id and oldDatabaseObject.data then
						update()
					else
						local sql = [[INSERT INTO ]]..modelProperties.name..[[ (id, data) VALUES (:id, :data)]]
						database.exec(sql, {id = modelObject.id, data = jsonData})
						logger.log("[Database] Created new object from "..modelProperties.name.." with ID "..modelObject.id)
						model:dispatchEvent({name = "create", target = modelObject})
					end
				end
				
				if modelObject.id then
					overwrite()
					logger.log("[Database] Saved "..modelProperties.singularName.." "..tostring(modelObject.id))
					model:dispatchEvent({name = "update", target = modelObject})
				else
					local function persist()
						local jsonData = json.encode(modelObject)
						local sql = [[INSERT INTO ]]..modelProperties.name..[[ (data) VALUES (:data)]]
						database.exec(sql, {data = jsonData})
					end
					
					persist()
					local lastRowID = database.lastRowID()
					local sql = [[SELECT id FROM ]]..modelProperties.name..[[ WHERE rowid = ]]..lastRowID..[[;]]
					local lastID = tonumber(database.getColumn("id", sql))
					modelObject.id = lastID
					local jsonData = json.encode(modelObject)
					overwrite()
					
					logger.log("[Database] Created new object from "..modelProperties.name.." with ID "..tostring(lastID))
					model:dispatchEvent({name = "create", target = modelObject})
				end
			else
				logger.log("[Database] Could not save object. it must not be nil and be a table.")
			end
		end
		
		function model.delete(modelObject)
			if modelObject and type(modelObject) == "table" then
				if modelObject.id then
					local currentID = database.config("current"..modelProperties.singularName.."ID")
					if modelObject.id == currentID then
						currentObject = nil
						database.config("current"..modelProperties.singularName.."ID", false)
					end
					database.exec([[DELETE from ]]..modelProperties.name..[[ WHERE id = :id]], modelObject)
					logger.log("[Database] Deleted "..tostring(modelObject.id).." from ")
				else
					logger.log("[Database] Could not delete object from "..modelProperties.name)
				end
			else
				logger.log("[Database] Could not delete object from "..modelProperties.name.." object must not be nil and be a table.")
			end
		end
		
		function model.recreate()
			createTable(modelName)
		end
		
		function model.deleteAll()
			currentObject = nil
			database.exec([[DELETE from ]]..modelProperties.name)
			logger.log("[Database] Deleted all "..modelProperties.name)
			model.deleted = true
		end
		
		function model.getCount()
			return database.count(modelProperties.name) or 0
		end
		
		function model.getCurrentID()
			return tonumber(database.config("current"..modelProperties.singularName.."ID"))
		end
		
		function model.setCurrentID(currentID)
			currentID = tonumber(currentID)
			if currentID and type(currentID) == "number" then
				database.config("current"..modelProperties.singularName.."ID", currentID)
			end
		end

		if createTable(modelName) then
			logger.log([[[Database] Created model "]]..modelProperties.name..[[" table]])
		else
			logger.log([[[Database] Model "]]..modelProperties.name..[[" table already exists]])
		end
		
		models[#models + 1] = model
		
		local oldMetatable = getmetatable(model)
		local modelMetatable = {
			__index = function(tab, key)
				return oldMetatable[key] and oldMetatable[key] or rawget(tab, key)
			end,
			__newindex = function(tab, key, value)
				if key == "default" and "table" == type(value) then
					defaultObject = extratable.deepcopy(value)
				elseif key == "nilKeys" and "table" == type(value) then
					extratable.add(nilKeys, value)
				end
				rawset(tab, key, value)
			end
		}
		setmetatable(model, modelMetatable)

		return model
	end
end

return database

