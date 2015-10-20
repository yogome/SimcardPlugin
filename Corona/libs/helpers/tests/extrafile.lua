------------------------------------------- Extra file test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local extrafile = require( upFolder.."extrafile" )
local extratable = require( upFolder.."extratable" )
local logger = require( upFolder.."logger" )

local extrafileTest = {}
------------------------------------------ Variables

------------------------------------------ Tests
function extrafileTest.testFileExists()
	local directory = string.gsub(folder,"[%.]","/").."files"
	local filelist = extrafile.getFiles(directory)
	
	assert(#filelist > 0)
	assert(extratable.containsValue(filelist, "file1.txt"))
end

function extrafileTest.testGetLines()
	local filepath = string.gsub(folder,"[%.]","/").."files/file1.txt"
	local fileLines = extrafile.getLines(filepath)
	
	assert(#fileLines > 0)
	assert(extratable.containsValue(fileLines, "This is a test string on line 1"))
	assert(extratable.containsValue(fileLines, "This is a test string on line 2"))
	assert(extratable.containsValue(fileLines, "This is a test string on line 3"))
end

function extrafileTest.testGetPNGDimensions()
	local filepath = string.gsub(folder,"[%.]","/").."files/image.png"
	
	local width, height = extrafile.getPNGDimensions(filepath)
	assert(width == 2)
	assert(height == 2)
end

return extrafileTest
