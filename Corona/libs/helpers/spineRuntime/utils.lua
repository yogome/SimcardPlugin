----------------------------------------------- Spine utils
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$")
local extrajson = require( upFolder.."extrajson" ) 

local utils = {}
----------------------------------------------- Module functions
function utils.indexOf(haystack, needle)
	for index, value in ipairs(haystack) do
		if value == needle then
			return index
		end
	end
end

function utils.readFile(fileName, base)
	if not base then base = system.ResourceDirectory end
	local path = system.pathForFile(fileName, base)
	local file = io.open(path, "r")
	if not file then return nil end
	local contents = file:read("*a")
	io.close(file)
	return contents
end

function utils.readJSON(text)
	return extrajson.decodeFixed(text)
end

return utils
