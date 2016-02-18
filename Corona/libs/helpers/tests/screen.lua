------------------------------------------- Extra math test
local path = ...
local folder = path:match("(.-)[^%.]+$")
local upFolder = string.sub(folder, 1, -2):match("(.-)[^%.]+$") 
local screen = require( upFolder.."screen" )

local screenTest = {}
------------------------------------------ Variables
------------------------------------------ Tests
function screenTest.testFillSceen()
	local rect = display.newRect(0,0,200,200)
	screen.fillScreen(rect)
	
	assert(rect.x == display.contentCenterX)
	assert(rect.y == display.contentCenterY)
	
	-- Corona Bug 
--	assert(rect.contentHeight == display.viewableContentHeight)
--	assert(rect.contentWidth == display.viewableContentWidth)
	
	display.remove(rect)
end

function screenTest.testGetContentRotation()
	local rect = display.newRect(0,0,200,200)
	rect.rotation = 90
	
	assert(screen.getContentRotation(rect) == 90)
	
	rect.rotation = 0
	local parent = display.newGroup()
	parent:insert(rect)
	
	assert(screen.getContentRotation(rect) == 0)
	
	parent.rotation = 90
	assert(screen.getContentRotation(rect) == 90)
	
	rect.rotation = 90
	assert(screen.getContentRotation(rect) == 180)
	
	rect.rotation = -90
	assert(screen.getContentRotation(rect) == 0)
	
	parent.rotation = -100
	assert(screen.getContentRotation(rect) == -190)
	
	display.remove(rect)
	display.remove(parent)
end

function screenTest.testGetContentScale()
	local rect = display.newRect(0,0,200,200)
	
	rect.xScale = 0.5
	rect.yScale = 0.5
	
	local scaleX, scaleY = screen.getContentScale(rect)
	assert(scaleX == 0.5)
	assert(scaleY == 0.5)
	
	local parent = display.newGroup()
	parent:insert(rect)
	
	scaleX, scaleY = screen.getContentScale(rect)
	assert(scaleX == 0.5)
	assert(scaleY == 0.5)
	
	rect.xScale = 1
	rect.yScale = 1
	
	scaleX, scaleY = screen.getContentScale(rect)
	assert(scaleX == 1)
	assert(scaleY == 1)
	
	parent.xScale = 0.2
	parent.yScale = 0.2
	
	scaleX, scaleY = screen.getContentScale(rect)
	assert(scaleX >= 0.19 and scaleX <= 0.21)
	assert(scaleY >= 0.19 and scaleY <= 0.21)
	
	rect.xScale = 0.5
	rect.yScale = 0.5
	
	scaleX, scaleY = screen.getContentScale(rect)
	assert(scaleX > 0.09 and scaleX < 0.11)
	assert(scaleY > 0.09 and scaleY < 0.11)
	
	display.remove(rect)
end

return screenTest
