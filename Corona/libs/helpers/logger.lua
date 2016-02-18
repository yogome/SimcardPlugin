---------------------------------------------- Logger
local path = ...
local folder = path:match("(.-)[^%.]+$")
local json = require( "json" ) 

local logger = {
	outputConsole = true,
}
---------------------------------------------- Variables
local globalMonitorEnabled 
local memoryMonitorEnabled
local initialized
local moduleNamesCache
local logFile
local debugLibrary
local debugLevel
---------------------------------------------- Constants
local LEVEL_TAGS = {
	ERROR = "[E]",
	WARN = "[W]",
	INFO = "[I]",
	DEBUG = "[D]",
} 

local LEVEL_ORDER = {
	[LEVEL_TAGS.ERROR] = 1,
	[LEVEL_TAGS.WARN] = 2,
	[LEVEL_TAGS.INFO] = 3,
	[LEVEL_TAGS.DEBUG] = 4,
}

local DEFAULT_LOG_LEVEL = LEVEL_ORDER[LEVEL_TAGS.DEBUG]
local FILE_LOG = "log.txt"
local MAX_LOGSIZE = 1000000
local SEPARATOR = " "
---------------------------------------------- Caches
local ioClose = io.close
local osRemove = os.remove
local ioOpen = io.open
local osDate = os.date
local stringFormat = string.format
local errorFunction = system.getInfo("environment") == "simulator" and error or print
---------------------------------------------- Local functions
local function printTable(luaTable)
	print(json.prettify(json.encode(luaTable)))
end 

local function printMessage(level, message, errorPrint)
	if logger.outputConsole then
		if level <= debugLevel then
			if errorPrint then
				pcall(function()
					errorFunction(tostring(message))
				end)
			else
				print(tostring(message))
			end
		end
	end
	
	if logFile then
		logFile:write(tostring(message).."\n")
	end
end

local function initialize()
	if not initialized then
		initialized = true
		
		moduleNamesCache = {}
		
		debugLevel = DEFAULT_LOG_LEVEL
		
		debugLibrary = debug or require("debug") or error([[build.settings "build.neverStripDebugInfo" must be true!]])
		
		local path = system.pathForFile(FILE_LOG, system.DocumentsDirectory)
		logFile = ioOpen(path, "a")
		local fileSize = logFile:seek("end")
		if fileSize > MAX_LOGSIZE then
			ioClose(logFile)
			pcall(function()
				osRemove(path)
			end)
			logFile = ioOpen(path, "a")
		end
		
		local today = osDate("*t")
		printMessage(LEVEL_ORDER[LEVEL_TAGS.INFO], stringFormat("/////////////////////////////////////////////// %2d/%2d/%4d %2d:%2d:%2d", today.month, today.day, today.year, today.hour, today.min, today.sec))
		
		if not logFile then
			logger.error("Log file could not be opened")
		else
			logFile:setvbuf("no")
			Runtime:addEventListener("unhandledError", function(event)
				logger.error("Unhandled error: "..(event.errorMessage or "Unknown error")..": "..(event.stackTrace or "No trace"))
				return false
			end)
			
			Runtime:addEventListener("system", function(event)
				if event.type == "applicationExit" then
					Runtime:addEventListener("system", function(event)
						if event.type == "applicationExit" then
							if logFile then
								ioClose(logFile)
							end
						end
					end)
				end
			end)
		end
	end
end

local function getModuleName()
	local callerInfo = debugLibrary.getinfo(3, "S")
	local extrastring = require(folder.."extrastring")
	
	if not moduleNamesCache[callerInfo] then
		pcall(function()
			local shortSrc = callerInfo.short_src
			local splitSrc = extrastring.split(shortSrc, "/")
			local moduleName = extrastring.firstToUpper(extrastring.split(splitSrc[#splitSrc], ".")[1])
			moduleNamesCache[callerInfo] = "["..moduleName.."]" or "[Unknown]"
		end)
	end
	
	return moduleNamesCache[callerInfo]
end
---------------------------------------------- Module functions
function logger.line(message)
	printMessage(LEVEL_ORDER[LEVEL_TAGS.INFO], "----------------------------------------------- "..tostring(message or ""))
end

function logger.error(...)
	local params = {...}
	local moduleName = getModuleName()
	
	for index = 1, #params do
		local object = params[index]
		if "table" == type(object) then
			printTable(object)
		else
			printMessage(LEVEL_ORDER[LEVEL_TAGS.ERROR], LEVEL_TAGS.ERROR..moduleName..SEPARATOR..tostring(object), true)
		end
	end
end

function logger.warn(...)
	local params = {...}
	local moduleName = getModuleName()
	
	for index = 1, #params do
		local object = params[index]
		if "table" == type(object) then
			printTable(object)
		else
			printMessage(LEVEL_ORDER[LEVEL_TAGS.WARN], LEVEL_TAGS.WARN..moduleName..SEPARATOR..tostring(object), true)
		end
	end
end

function logger.info(...)
	local params = {...}
	local moduleName = getModuleName()
	
	for index = 1, #params do
		local object = params[index]
		if "table" == type(object) then
			printTable(object)
		else
			printMessage(LEVEL_ORDER[LEVEL_TAGS.INFO], LEVEL_TAGS.INFO..moduleName..SEPARATOR..tostring(object))
		end
	end
end

function logger.debug(...)
	local params = {...}
	local moduleName = getModuleName()
	
	for index = 1, #params do
		local object = params[index]
		if "table" == type(object) then
			printTable(object)
		else
			printMessage(LEVEL_ORDER[LEVEL_TAGS.DEBUG], LEVEL_TAGS.DEBUG..moduleName..SEPARATOR..tostring(object))
		end
	end
end

function logger.monitorGlobals()
	if not globalMonitorEnabled then
		globalMonitorEnabled = true
		local function globalWatch(g, key, value)
			logger.warn("Global "..tostring(key).." has been added to _G\n"..debugLibrary.traceback())
			rawset(g, key, value)
		end
		setmetatable(_G, { __newindex = globalWatch })
	end
end

function logger.monitorMemory()
	if not memoryMonitorEnabled then
		memoryMonitorEnabled = true
	
		local oldMemory = 0

		local oldnewImageSheet = graphics.newImageSheet
		graphics.newImageSheet = function(...)
			local result = oldnewImageSheet(...)

			local fileName = ""
			local params = {...}
			for index = 1, #params do
				if "string" == type(params[index]) then
					fileName = params[index]
					break
				end
			end

			local nowMemory = system.getInfo("textureMemoryUsed")*0.00000095
			local memoryUsed = (nowMemory - oldMemory)
			if memoryUsed > 2 then
				print(fileName..": "..memoryUsed.." mb")
				oldMemory = nowMemory
			end
			return result
		end


		local oldNewImage = display.newImage
		display.newImage = function(...)
			local result = oldNewImage(...)

			local fileName = ""
			local params = {...}
			for index = 1, #params do
				if "string" == type(params[index]) then
					fileName = params[index]
					break
				end
			end

			local nowMemory = system.getInfo("textureMemoryUsed")*0.00000095
			local memoryUsed = (nowMemory - oldMemory)
			if memoryUsed > 3 then
				print(fileName..": "..memoryUsed.." mb")
				oldMemory = nowMemory
			end
			return result
		end
	end
end

function logger.setLevel(logLevel)
	debugLevel = logLevel
end

logger.log = logger.info
---------------------------------------------- Execution
initialize() 

return logger
