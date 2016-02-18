------------------------------------------- Extra math
local path = ... 
local json = require( "json" ) 
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )

local extrajson = {}
------------------------------------------- Caches
local jsonDecode = json.decode
------------------------------------------- Functions
local function fixJsonTable(inputTable)
	local result = {}
	for key,value in pairs(inputTable) do
		if not(tonumber(key) == nil) then
			if "table" == type(value) then
				result[tonumber(key)] = fixJsonTable(value)
			else
				result[tonumber(key)] = value
			end
		elseif "table" == type(inputTable[key]) then
			result[key] = fixJsonTable(inputTable[key])
		else
			result[key] = inputTable[key]
		end
	end

	return result
end  

local function trimString(stringIn)
	return string.match(stringIn, "^()%s*$") and "" or string.match(stringIn, "^%s*(.*%S)")
end

------------------------------------------- Module functions
function extrajson.fixLuaIndices(inputTable)
	return fixJsonTable(inputTable)
end

function extrajson.isValidJson(jsonObject)
	if jsonObject then
		local contents = trimString(jsonObject)
		if string.sub(contents, 1, 1) ~= "{" and string.sub(contents, 1, 1) ~= "[" then
			return false
		end
		return true
	end
	return false
end

function extrajson.decodeFixed(inputTable)
	local decodedJson
	local success, message = pcall(function()
		decodedJson = fixJsonTable(jsonDecode(inputTable))
	end)

	if not success and message then
		logger.error("there was an error decoding JSON")
		return
	end
	
	return decodedJson
end

return extrajson
