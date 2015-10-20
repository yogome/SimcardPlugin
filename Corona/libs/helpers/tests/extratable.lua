------------------------------------------- Extra table test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local extrafile = require( upFolder.."extrafile" )
local extratable = require( upFolder.."extratable" )
local logger = require( upFolder.."logger" )

local extratableTest = {}
------------------------------------------ Variables
------------------------------------------ Tests
function extratableTest.testContainsValues()
	local filepath = string.gsub(folder,"[%.]","/").."files/file1.txt"
	local fileLines = extrafile.getLines(filepath)
	
	assert(extratable.containsValue(fileLines, "This is a test string on line 1"))
	assert(extratable.containsValue(fileLines, "This is a test string on line 2"))
	assert(extratable.containsValue(fileLines, "This is a test string on line 3"))
end

return extratableTest
