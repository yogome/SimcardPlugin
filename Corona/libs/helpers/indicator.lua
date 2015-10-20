----------------------------------------------- Indicators
local indicator = {}
----------------------------------------------- Constants
local barMinimumFill = 0.00001
----------------------------------------------- Functions
local function createBar(newBar, options)
	newBar.anchorChildren = true
	if options.background then
		local background = display.newImageRect(options.background, options.width, options.height)
		newBar:insert(background)
	else
		local background = display.newRect(0, 0, options.width, options.height)
		background:setFillColor(0.5)
		newBar:insert(background)
	end
	
	local bar = display.newRect(-options.width * 0.5 + options.barPadding, 0, options.width - options.barPadding * 2, options.height - options.barPadding * 2)
	bar:setFillColor(0,1,0)
	
	if options.bar then
		display.remove(bar)
		bar = display.newImageRect(options.bar, options.width - options.barPadding * 2, options.height - options.barPadding * 2)
		bar.x = -options.width * 0.5 + options.barPadding
		
		newBar.barColors = options.barColors
		bar.fill.effect = "filter.monotone"
		bar.fill.effect.r = newBar.barColors.full[1] or 1
		bar.fill.effect.g = newBar.barColors.full[2] or 1
		bar.fill.effect.b = newBar.barColors.full[3] or 1
	end
	
	bar.anchorX = 0
	newBar:insert(bar)
	newBar.bar = bar
	newBar.fillAmount = options.currentFill
	
	local textOptions = {
		x = 0,
		y = 0,
		align = "center",
		text = options.text,
		fontSize = options.fontSize,
	}
	
	local text = display.newText(textOptions)
	text:setFillColor(unpack(options.textColor))
	newBar:insert(text)
	newBar.text = text
	
	if options.foreground then
		local foreground = display.newImageRect(options.foreground, options.width, options.height)
		newBar:insert(foreground)
	end
	
	function newBar:setLabel(label)
		self.text.text = label
	end
	
	function newBar:setFillAmount(newFill)
		if newFill > 1 then
			newFill = 1
		elseif newFill <= 0 then
			newFill = barMinimumFill
		end
			
		self.fillAmount = newFill
		
		if self.bar.fill and self.bar.fill.effect then
			bar.fill.effect.r = (self.barColors.full[1] * self.fillAmount) + (self.barColors.empty[1] * (1 - self.fillAmount))
			bar.fill.effect.g = (self.barColors.full[2] * self.fillAmount) + (self.barColors.empty[2] * (1 - self.fillAmount))
			bar.fill.effect.b = (self.barColors.full[3] * self.fillAmount) + (self.barColors.empty[3] * (1 - self.fillAmount))
		end
		
		self.bar.xScale = self.fillAmount
	end
end

function indicator.newBar(options)
	if not (options and "table" == type(options)) then
		error("options must be a table and not nil.", 3)
	end
	
	if not (options.width and options.height) then
		error("width and height must not be nil.", 3)
	end
	
	options.text = options.text or ""
	if not "string" == type(options.text) then
		error("text must be a string.", 3)
	end
	
	options.fontSize = options.fontSize or 35
	if not "number" == type(options.fontSize) then
		error("fontSize must be a number.", 3)
	end
	
	options.textColor = options.textColor or {1,1,1}
	if not "table" == type(options.textColor) then
		error("textColor must be a table.", 3)
	end
	
	if not ("number" == type(options.width) and "number" == type(options.height)) then
		error("width and height must be a number", 3)
	end
	
	if options.background then
		if not "string" == type(options.background) then
			error("background must be a string.", 3)
		end
	end
	
	if options.foreground then
		if not "string" == type(options.foreground) then
			error("foreground must be a string.", 3)
		end
	end
	
	if options.bar then
		if not "string" == type(options.bar) then
			error("bar must be a string.", 3)
		end
		
		if not (options.barColors and options.barColors.empty and options.barColors.full and "table" == type(options.barColors.empty) and "table" == type(options.barColors.full)) then
			error("you must specify barColors.empty and barColors.full.", 3)
		end
	end
	
	options.currentFill = options.currentFill or barMinimumFill
	if not "number" == type(options.currentFill) then
		error("currentFill must be a number.", 3)
	else
		if options.currentFill == 0 then options.currentFill = barMinimumFill end
		if options.currentFill > 1 or options.currentFill < 0 or not "number" == type(options.currentFill) then
			error("fill can only be from 0 to 1.", 3)
		end
	end
	
	options.barPadding = options.barPadding or 8
	if not "number" == type(options.barPadding) then
		error("barPadding must be a number.", 3)
	end
	
	local newBar = display.newGroup()
	
	createBar(newBar, options)
	
	return newBar
end

return indicator
