---------------------------------------------- Screen focus
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local colors = require( folder.."colors" )

local screenfocus = {}
---------------------------------------------- Constants
local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/"

local WIDTH_FADE = 32

local CONTENT_CENTER_Y = display.contentCenterY
local CONTENT_WIDTH = display.viewableContentWidth
local CONTENT_HEIGHT = display.viewableContentHeight
local ORIGIN_X = display.screenOriginX
local ORIGIN_Y = display.screenOriginY
---------------------------------------------- Variables
---------------------------------------------- Functions
local function createScreenfocus(parameters)
	
	local newScreenfocus = display.newGroup()
	
	local leftRect = display.newRect(newScreenfocus, 0, CONTENT_CENTER_Y, 0, 0)
	leftRect.anchorX = 1
	local rightRect = display.newRect(newScreenfocus, 0, CONTENT_CENTER_Y, 0, 0)
	rightRect.anchorX = 0
	local topRect = display.newRect(newScreenfocus, 0, 0, 0, 0)
	topRect.anchorY = 1
	local bottomRect = display.newRect(newScreenfocus, 0, 0, 0, 0)
	bottomRect.anchorY = 0
	
	local leftFade = display.newRect(newScreenfocus, 0, 0, WIDTH_FADE, 0)
	local rightFade = display.newRect(newScreenfocus, 0, 0, WIDTH_FADE, 0)
	local topFade = display.newRect(newScreenfocus, 0, 0, WIDTH_FADE, 0)
	local bottomFade = display.newRect(newScreenfocus, 0, 0, WIDTH_FADE, 0)
	
	leftFade.anchorX = 0
	rightFade.anchorX = 0
	topFade.anchorX = 0
	bottomFade.anchorX = 0
	
	leftFade.rotation = 0
	rightFade.rotation = 180
	topFade.rotation = 90
	bottomFade.rotation = 270
	
	local paint = {type = "image", filename = PATH_IMAGES.."fade.png"}
	
	leftFade.fill = paint
	rightFade.fill = paint
	topFade.fill = paint
	bottomFade.fill = paint
	
	leftFade.path.y4 = WIDTH_FADE
	leftFade.path.y3 = -WIDTH_FADE
	
	rightFade.path.y4 = WIDTH_FADE
	rightFade.path.y3 = -WIDTH_FADE
	
	topFade.path.y4 = WIDTH_FADE
	topFade.path.y3 = -WIDTH_FADE
	
	bottomFade.path.y4 = WIDTH_FADE
	bottomFade.path.y3 = -WIDTH_FADE
	
	local values = {
		x = 0,
		y = 0,
		width = 0,
		height = 0,
	}
	
	newScreenfocus.setFillColor = function(self, ...)
		leftRect:setFillColor(...)
		rightRect:setFillColor(...)
		topRect:setFillColor(...)
		bottomRect:setFillColor(...)

		leftFade:setFillColor(...)
		rightFade:setFillColor(...)
		topFade:setFillColor(...)
		bottomFade:setFillColor(...)
	end
		
	local newProxy = {
		_proxy = newScreenfocus._proxy,
		_class = newScreenfocus._class,
	}
	local metatable = {
		__index = function (self,key)
			if key == "width" or key == "height" or key == "x" or key == "y" then
				return values[key]
			else
				return newScreenfocus[key]
			end
		end,
		__newindex = function (self, key, value)
			getmetatable(self)[key] = value
			if key == "width" or key == "height" or key == "x" or key == "y" then
				values[key] = value
				
				local x = values.x
				local y = values.y
				local width = values.width
				local height = values.height
				local halfWidth = width * 0.5
				local halfHeight = height * 0.5
				
				leftRect.x = x - halfWidth
				leftRect.width = x - halfWidth - ORIGIN_X
				leftRect.height = CONTENT_HEIGHT + 2

				rightRect.x = x + halfWidth
				rightRect.width = ORIGIN_X + CONTENT_WIDTH - x + halfWidth
				rightRect.height = CONTENT_HEIGHT + 2

				topRect.x = x
				topRect.y = y - halfHeight
				topRect.width = width
				topRect.height = y - halfHeight - ORIGIN_Y

				bottomRect.x = x
				bottomRect.y = y + halfHeight
				bottomRect.width = width
				bottomRect.height = ORIGIN_Y + CONTENT_HEIGHT - y + halfHeight
				
				leftFade.x = x - halfWidth
				leftFade.y = y
				leftFade.height = height
				
				rightFade.x = x + halfWidth
				rightFade.y = y
				rightFade.height = height
				
				topFade.x = x
				topFade.y = y - halfHeight
				topFade.height = width
				
				bottomFade.x = x
				bottomFade.y = y + halfHeight
				bottomFade.height = width
				
			else
				newScreenfocus[key] = value
			end
		end
	}
	setmetatable(newProxy, metatable)
	
	newProxy.width = parameters.width
	newProxy.height = parameters.height
	newProxy.x = parameters.x
	newProxy.y = parameters.y
	
	return newProxy
end
---------------------------------------------- Module functions
function screenfocus.new(parameters)
	parameters = parameters or {}
	
	parameters.x = parameters.x or display.contentCenterX
	parameters.y = parameters.y or display.contentCenterY
	parameters.width = parameters.width or 200
	parameters.height = parameters.height or 200
	parameters.color = parameters.color or {0,0,0,1}
	
	local screenFocus = createScreenfocus(parameters)
	colors.addColorTransition(screenFocus)
	screenFocus:setFillColor(unpack(parameters.color))

	return screenFocus
end

return screenfocus