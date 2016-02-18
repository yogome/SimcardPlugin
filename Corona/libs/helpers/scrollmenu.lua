--------------------------------------------- Scrollmenu
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local colors = require( folder.."colors" )

local widget = require( "widget" ) 

local scrollmenu = {}
-------------------------------------------- Functions
function scrollmenu.new(options)
	if not options and "table" == type(options) then
		error("Options can not be nil and must be a table.", 3)
	end
	
	if not options.itemSize and options.lockAlpha and options.smallIconScale and options.lock and options.items and options.tapListener and options.tolerance then
		error("Options must contain all parameters. (itemSize, lockAlpha, smallIconScale, lock, items, tapListener, tolerance)", 3)
	end
	
	if not(not options.itemOffsetY or options.itemOffsetY and "number" == type(options.itemOffsetY)) then
		error("itemOffsetY must be a number or nil", 3)
	end
	
	options.lockDarken = options.lockDarken or 1
	if not "number" == type(options.lockDarken) then
		error("lockDarken must be a number", 3)
	end
		
	if not "table" == type(options.items) and #options.items > 0 then
		error("Options items must be a table and not be empty", 3)
	end
	
	if not "function" == type(options.tapListener) then
		error("Options tapListener must be a function.", 3)
	end
	
	local scrollViewOptions = {
		x = display.contentCenterX,
		y = display.contentCenterY,
		width = display.viewableContentWidth,
		height = display.viewableContentHeight,
		verticalScrollDisabled = true,
		hideBackground = true,
	}
	local newScrollmenu = widget.newScrollView(scrollViewOptions)
	newScrollmenu.options = options
	newScrollmenu.items = {}
	newScrollmenu.tolerance = options.tolerance
	
	local function newItemGroup(itemOptions, index)
		local item = display.newGroup()
		item.index = index
		item.locked = itemOptions.locked
		
		if itemOptions.image then
			local itemImage = display.newImageRect(itemOptions.image, options.itemSize, options.itemSize)
			item:insert(itemImage)
			item.image = itemImage
		elseif itemOptions.unlockedGroup then
			item:insert(itemOptions.unlockedGroup)
			item.unlockedGroup = itemOptions.unlockedGroup
		end
		
		if itemOptions.lockedGroup then
			itemOptions.lockedGroup.alpha = options.lockAlpha
			if itemOptions.lockScales then
				item:insert(itemOptions.lockedGroup)
			end
			item.lock = itemOptions.lockedGroup
		else
			local lockImage = display.newImageRect(options.lock, options.itemSize, options.itemSize)
			lockImage.alpha = options.lockAlpha
			if itemOptions.lockScales then
				item:insert(lockImage)
			end
			item.lock = lockImage
		end
		
		item.lock.isVisible = itemOptions.locked
		
		local function itemTapped(event)
			if newScrollmenu.enabled then
				event.index = event.target.index
				options.tapListener(event)
			end
		end
		
		item:addEventListener("tap", itemTapped)

		return item
	end
	
	local fillerWidth = #options.items * options.itemSize + display.viewableContentWidth - options.itemSize
	local menuFiller = display.newRect(fillerWidth*0.5, display.contentCenterY, fillerWidth, 200)
	menuFiller.isVisible = false
	newScrollmenu:insert(menuFiller)
	
	for index = 1, #options.items do
		local itemOptions = options.items[index]
		
		local item = newItemGroup(itemOptions, index)
		item.x = display.viewableContentWidth * 0.5 + options.itemSize * index - options.itemSize
		item.y = display.contentCenterY + (options.itemOffsetY or 0)
		newScrollmenu:insert(item)
		
		if itemOptions.unscaledGroup then
			itemOptions.unscaledGroup.x = item.x
			itemOptions.unscaledGroup.y = item.y
			newScrollmenu:insert(itemOptions.unscaledGroup)
		end
		
		if not options.lockScales then
			item.lock.x = item.x
			item.lock.y = item.y
			newScrollmenu:insert(item.lock)
		end
		
		newScrollmenu.items[index] = item
	end
	
	function newScrollmenu:enterFrame(event)
		local x, y = self:getContentPosition()
		for index = 1, #self.items do
			local itemGroup = self.items[index]
			
			local positionDifference = ((index - 1) * self.options.itemSize) + x
			
			local absolutePositionDifference = math.abs(positionDifference)
			local inverseScale = 1 - self.options.smallIconScale
			if positionDifference < self.tolerance and positionDifference > -self.tolerance then
				local addScale = (1 - absolutePositionDifference / self.tolerance) * inverseScale
				itemGroup.xScale = self.options.smallIconScale + addScale
				itemGroup.yScale = self.options.smallIconScale + addScale
			else
				itemGroup.xScale = self.options.smallIconScale
				itemGroup.yScale = self.options.smallIconScale
			end
		end
	end
	
	function newScrollmenu:setEnabled(enabled)
		self:setIsLocked(not enabled)
		self.enabled = enabled
	end
	
	function newScrollmenu:setLocked(index, locked)
		locked = locked or false
		if index <= #self.items and index > 0 then
			
			local item = self.items[index]
			item.lock.isVisible = locked
			item.locked = locked
			
			local function setItemColor(color)
				if item.image and item.image.setFillColor then
					item.image:setFillColor(color)
				elseif item.unlockedGroup and item.unlockedGroup.setFillColor then
					item.unlockedGroup:setFillColor(color)
				end
			end
			
			if locked then
				setItemColor(self.options.lockDarken)
			else
				setItemColor(unpack(colors.white))
			end
		else
			logger.log("index out of bounds.")
		end
	end
	
	return newScrollmenu
end

return scrollmenu

