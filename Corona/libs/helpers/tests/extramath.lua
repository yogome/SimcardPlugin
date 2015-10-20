------------------------------------------- Extra math test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local extramath = require( upFolder.."extramath" )

local extramathTest = {}
------------------------------------------ Variables
local x, y 

------------------------------------------ Tests
function extramathTest.testGetFullAngle()
	
	x, y = 100, 0
	assert(extramath.getFullAngle(x, y) == -90)
	
	x, y = -100, 0
	assert(extramath.getFullAngle(x, y) == 90)
	
	x, y = 0, 100
	assert(extramath.getFullAngle(x, y) == 0)
	
	x, y = 0, -100
	assert(extramath.getFullAngle(x, y) == -180)
end


return extramathTest
