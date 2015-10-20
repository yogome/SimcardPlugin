-------------------------------------------- Compatibility
local path = ...
local folder = path:match("(.-)[^%.]+$")  
local logger = require( folder.."logger" )

local compatibility = {}

-------------------------------------------- Variables
local oldDisplayNewText
local oldDisplayNewSprite
local oldDisplayNewImage
local initialized

-------------------------------------------- Local functions
local function newSetReferencePoint(self, referencePoint)
	local isLeft = referencePoint == display.BottomLeftReferencePoint or referencePoint == display.CenterLeftReferencePoint or referencePoint == display.TopLeftReferencePoint
	local isMiddle = referencePoint == display.BottomCenterReferencePoint or referencePoint == display.CenterReferencePoint or referencePoint == display.TopCenterReferencePoint
	local isRight = referencePoint == display.BottomRightReferencePoint or referencePoint == display.CenterRightReferencePoint or referencePoint == display.TopRightReferencePoint

	local isTop = referencePoint == display.TopLeftReferencePoint or referencePoint == display.TopCenterReferencePoint or referencePoint == display.TopRightReferencePoint
	local isCenter = referencePoint == display.CenterLeftReferencePoint or referencePoint == display.CenterReferencePoint or referencePoint == display.CenterRightReferencePoint
	local isBottom = referencePoint == display.BottomLeftReferencePoint or referencePoint == display.BottomCenterReferencePoint or referencePoint == display.BottomRightReferencePoint

	self.anchorX = isLeft and 0 or isMiddle and 0.5 or isRight and 1
	self.anchorY = isTop and 0 or isCenter and 0.5 or isBottom and 1
end

local function initialize()
	if not initialized then
		initialized = true
		
		oldDisplayNewText = display.newText
		oldDisplayNewSprite = display.newSprite
		oldDisplayNewImage = display.newImage

		display.newImage = function(...)
			local displayObject = oldDisplayNewImage(...)
			displayObject.setReferencePoint = newSetReferencePoint
			return displayObject
		end

		display.newText = function(...)
			local displayObject = oldDisplayNewText(...)
			displayObject.setReferencePoint = newSetReferencePoint
			return displayObject
		end

		display.newSprite = function(...)
			local displayObject = oldDisplayNewSprite(...)
			displayObject.setReferencePoint = newSetReferencePoint
			return displayObject
		end
		
		logger.log(application)
	end
end

-------------------------------------------- Execution
initialize()

return compatibility