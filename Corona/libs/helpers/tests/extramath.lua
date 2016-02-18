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

function extramathTest.testRangesOverlap()
	local range1From, range1To
	local range2From, range2To
	
	range1From, range1To = 0, 100
	range2From, range2To = 50, 200
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == true)
	
	range1From, range1To = 0, 100
	range2From, range2To = 100, 200
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == true)
	
	range1From, range1To = 0, 100
	range2From, range2To = 200, 300
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == false)
	
	range1From, range1To = -50, 100
	range2From, range2To = 50, 200
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == true)
	
	range1From, range1To = -200, -100
	range2From, range2To = -150, 200
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == true)
	
	range1From, range1To = -200, -100
	range2From, range2To = -50, -20
	assert(extramath.rangesOverlap(range1From, range1To, range2From, range2To) == false)
end

function extramathTest.testIsInRadialRange()
	
end

function extramathTest.testSum()
	
end


return extramathTest
