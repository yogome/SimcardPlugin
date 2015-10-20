------------------------------------------- Colors test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local extratable = require( upFolder.."extratable" )
local colors = require( upFolder.."colors" )

local colorsTest = {}
------------------------------------------ Variables
local displayObject
local color
------------------------------------------ Tests
function colorsTest.testConvertFrom256()
	color = {256, 256, 256}
	assert(extratable.compare(colors.convertFrom256(color), {1, 1, 1}, 0.01))
	
	color = {128, 128, 128}
	assert(extratable.compare(colors.convertFrom256(color), {0.5, 0.5, 0.5}, 0.01))
	
	color = {0, 0, 0}
	assert(extratable.compare(colors.convertFrom256(color), {0, 0, 0}, 0.01))
end

function colorsTest.testConvertFromHex()
	color = "FFFFFF" -- White
	assert(extratable.compare(colors.convertFromHex(color), {1, 1, 1}, 0.01))
	
	color = "000000" -- Black
	assert(extratable.compare(colors.convertFromHex(color), {0, 0, 0}, 0.01))
	
	color = "808080" -- Gray
	assert(extratable.compare(colors.convertFromHex(color), {0.5, 0.5, 0.5}, 0.01))
end

function colorsTest.testAddColorTransition()
	displayObject = display.newRect(0,0,2,2)
	colors.addColorTransition(displayObject)
	
	displayObject:setFillColor(0, 0, 0)
	assert(displayObject.r == 0)
	assert(displayObject.g == 0)
	assert(displayObject.b == 0)
	
	displayObject:setFillColor(1, 1, 1)
	assert(displayObject.r == 1)
	assert(displayObject.g == 1)
	assert(displayObject.b == 1)
end


return colorsTest
