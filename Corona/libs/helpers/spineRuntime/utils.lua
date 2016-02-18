----------------------------------------------- Spine utils
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$")
local json = require("json")

local utils = {}
----------------------------------------------- Caches
local ioOpen = io.open
local ioClose = io.close
local systemPathForFile = system.pathForFile
----------------------------------------------- Module functions
function utils.indexOf(haystack, needle)
	for index = 1, #haystack do
		if haystack[index] == needle then
			return index
		end
	end
end

function utils.readFile(fileName, base)
	if not base then base = system.ResourceDirectory end
	local path = systemPathForFile(fileName, base)
	local fileObject = ioOpen(path, "r")
	if not fileObject then return nil end
	local contents = fileObject:read("*a")
	ioClose(fileObject)
	return contents
end

function utils.readJSON(text)
	return json.decode(text) -- TODO switched from extrajson
end

return utils
