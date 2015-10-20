---------------------------------------------- Logger
local json = require( "json" ) 

local logger = {
	enabled = true,
}
---------------------------------------------- Variables
local globalMonitorEnabled 
local memoryMonitorEnabled
---------------------------------------------- Constants
local LEVELS_LOG = { -- TODO actually implement levels
	[1] = "error",
	[2] = "info",
} 
---------------------------------------------- Functions
local function printTable(luaTable)
	print(json.prettify(json.encode(luaTable)))
end 

function logger.line(message)
	logger.log("----------------------------------------------- "..tostring(message or ""))
end

function logger.log(message)
	if logger.enabled then
		if "table" == type(message) then
			printTable(message)
		elseif "string" == type(message) or "number" == type(message) then
			print(message)
		else
			logger.error("[Logger] message must be a string or a table")
		end
	end
end

function logger.error(message)
	if logger.enabled then
		pcall(function()
			error(message)
		end)
	end
end

function logger.info(message)
	if logger.enabled then
		if "string" == type(message) or "number" == type(message) then
			print(message)
		else
			logger.error("[Logger] message must be a string")
		end
	end
end

function logger.monitorGlobals()
	if debug and debug.traceback and not globalMonitorEnabled then
		globalMonitorEnabled = true
		local function globalWatch(g, key, value)
			logger.error("[Logger] Global "..tostring(key).." has been added to _G\n"..debug.traceback())
			rawset(g, key, value)
		end
		setmetatable(_G, { __index = globalWatch })
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

return logger
