-------------------------------------------- Colors
local path = ...
local folder = path:match("(.-)[^%.]+$")
local colors = require( folder.."colors" )
local protector = require( folder.."protector" )
local charts = {}
-------------------------------------------- Variables
-------------------------------------------- Constants
local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/" 

local SIZE_DONUT_MASK = 256
local SCALE_DONUT_MASK_SELECTED = 0.8
local ITERATIONS_TOTAL = 100
local LAST_ITERATIONS = ITERATIONS_TOTAL - (ITERATIONS_TOTAL * 0.05)
-------------------------------------------- Caches
local mathRad = math.rad
local mathSin = math.sin
local mathCos = math.cos
-------------------------------------------- Functions
-------------------------------------------- Module functions

function charts.newPie(options)
	options = options or {}
	local sections = options.sections or {{amount = 1, label = "Default", color = colors.lime}}
	local pieRadius = options.radius or 100
	local fontName = options.fontName or native.systemFont
	local fontSize = options.fontSize or 20
	local fontColor = options.fontColor or colors.white
	local showAmounts = options.showAmounts == nil and true or false
	local showLegend = options.showLegend == nil and true or false
	
	local showPercent = options.showPercent or false
	
	local legendFontColor = options.legendFontColor or colors.white
	local legendFontName = options.fontName or native.systemFont
	local legendFontSize = options.fontSize or 20
	local legendIconSize = options.legendIconSize or 20
	local legendPadding = options.legendPadding or 40
	
	local pieChart = display.newGroup()
	
	local totalAmount = 0
	for index = 1, #sections do
		totalAmount = totalAmount + sections[index].amount or 0
	end
	
	pieChart.totalAmount = totalAmount
	pieChart.sections = {}
	
	local currentPercentage = 0
	for index = 1, #sections do
		local sectionData = sections[index]
		local sectionPie = display.newCircle(0, 0, pieRadius)
		sectionPie.data = sectionData
		
		local percentage = sectionData.amount / totalAmount
		local currentDegrees = currentPercentage * 360 - 180
		local labelDegrees = currentDegrees + (percentage * 180)
		
		local labelRadians = mathRad(labelDegrees)
		local angleX = mathCos(labelRadians)
		local angleY = mathSin(labelRadians)
		local halfPieRadius = pieRadius * 0.5
		
		local labelX = angleX * halfPieRadius
		local labelY = angleY * halfPieRadius
		
		sectionPie.fill.effect = "filter.radialWipe"
		sectionPie.fill.effect.smoothness = 0
		sectionPie.fill.effect.center = { 0.5 + (angleX * 0.02), 0.5 + (angleY * 0.02)}
		sectionPie.fill.effect.axisOrientation = (currentDegrees + (360 * percentage) - 180) / 360
		sectionPie.fill.effect.progress = 0
		sectionPie:setFillColor(unpack(sectionData.color))
		pieChart:insert(sectionPie)
		
		transition.to(sectionPie.fill.effect, {
			delay = 100 * index,
			time = 400,
			progress = 1 - percentage,
			transition = easing.outQuad
		})
		
		if showAmounts then
			local amount = sectionData.amount
			if showPercent then amount = (amount / totalAmount) * 100 end
			local formatString = "%d"..(showPercent and "%" or "")
			local amountLabel = display.newText(string.format(formatString, amount), labelX, labelY, fontName, fontSize)
			amountLabel:setFillColor(unpack(fontColor))
			pieChart:insert(amountLabel)
		end
		
		pieChart.sections[index] = sectionPie
		
		currentPercentage = currentPercentage + percentage
	end
	
	if showLegend then
		local legend = display.newGroup()
		for index = 1, #sections do
			local sectionData = sections[index]

			local legendStartY = -(((#sections * legendIconSize) + ((#sections - 1) * legendIconSize * 0.5)) * 0.5)
			local legendY = legendStartY + (index - 1) * (legendIconSize + legendIconSize * 0.5)

			local legendIcon = display.newCircle(pieRadius + legendPadding, legendY, legendIconSize * 0.5)
			legendIcon:setFillColor(unpack(sectionData.color))
			legend:insert(legendIcon)

			local labelOptions = {
				x = legendIcon.x + legendIconSize * 0.5 + legendPadding * 0.5,
				y = legendY,
				width = 200,
				align = "left",
				font = legendFontName,
				text = sectionData.label,
				fontSize = legendFontSize,
			}

			local legendLabel = display.newText(labelOptions)
			legendLabel.anchorX = 0
			legendLabel:setFillColor(unpack(legendFontColor))
			legend:insert(legendLabel)
		end
		pieChart:insert(legend)
	end
	
	return pieChart
end

function charts.newDonut(options)
	options = options or {}
	options.radius = options.radius or 100
	options.showLegend = false
	options.showAmounts = false
	
	options.legendFontColor = options.legendFontColor or colors.white
	options.fontName = options.fontName or native.systemFont
	options.legendPadding = options.legendPadding or 15
	local sectionFontSize = options.sectionFontSize or 30
	local amountFontSize = options.amountFontSize or 20
	local showPercent = options.showPercent
	
	local donutChart = charts.newPie(options)
	donutChart.showPercent = showPercent
	donutChart.selectedSection = 1
	
	local sectionLabel = display.newText("", 0, -options.legendPadding, options.fontName, sectionFontSize)
	sectionLabel:setFillColor(unpack(options.legendFontColor))
	donutChart:insert(sectionLabel)
	
	local amountLabel = display.newText("", 0, options.legendPadding, options.fontName, amountFontSize)
	amountLabel:setFillColor(unpack(options.legendFontColor))
	donutChart:insert(amountLabel)
	
	donutChart.sectionLabel = sectionLabel
	donutChart.amountLabel = amountLabel
	
	for index = 1, #donutChart.sections do
		local sectionPie = donutChart.sections[index]
		sectionPie.percentage = sectionPie.data.amount / donutChart.totalAmount
		
		local mask = graphics.newMask( PATH_IMAGES.."donutMask.png" )
		sectionPie:setMask( mask )
		
		donutChart.defaultMaskScale = (options.radius * 2) / SIZE_DONUT_MASK
		donutChart.selectedMaskScale = donutChart.defaultMaskScale * SCALE_DONUT_MASK_SELECTED
		
		sectionPie.maskScaleX = donutChart.defaultMaskScale
		sectionPie.maskScaleY = donutChart.defaultMaskScale
	end
	
	local function selectSection(self, selectedSection)
		for index = 1, #self.sections do
			local sectionPie = self.sections[index]
			transition.cancel(sectionPie)
			
			if index == selectedSection then
				self.sectionLabel.text = sectionPie.data.label
				self.amountLabel.text = self.showPercent and string.format("%.2f %%", (sectionPie.percentage * 100)) or sectionPie.data.amount
				transition.to(sectionPie, {time = 400, maskScaleX = self.selectedMaskScale, maskScaleY = self.selectedMaskScale, transition = easing.outQuad})
			else
				transition.to(sectionPie, {time = 400, maskScaleX = self.defaultMaskScale, maskScaleY = self.defaultMaskScale, transition = easing.outQuad})
			end
		end
	end
	
	function donutChart:tap(event)
		-- TODO Add sound id and play on tap
		self.selectedSection = self.selectedSection + 1
		if self.selectedSection > #self.sections then
			self.selectedSection = 1
		end
		
		selectSection(self, self.selectedSection)
	end
	
	donutChart:addEventListener("tap")
	selectSection(donutChart, 1)
	
	return donutChart
end

function charts.newRoundedDonut(options)
	local radius = options.radius or 100
	local halfWidth = options.width and (options.width * 0.5) or 5
	local sections = options.sections or {{amount = 1, label = "Default", color = colors.lime}}
	
	local donutChart = display.newGroup()
	local showPercent = options.showPercent
	local sectionFontSize = options.sectionFontSize or 30
	local amountFontSize = options.amountFontSize or 20
	
	options.legendFontColor = options.legendFontColor or colors.white
	options.fontName = options.fontName or native.systemFont
	options.legendPadding = options.legendPadding or 15
	
	local sectionLabel = display.newText("", 0, -options.legendPadding, options.fontName, sectionFontSize)
	sectionLabel:setFillColor(unpack(options.legendFontColor))
	donutChart:insert(sectionLabel)
	
	local amountLabel = display.newText("", 0, options.legendPadding, options.fontName, amountFontSize)
	amountLabel:setFillColor(unpack(options.legendFontColor))
	donutChart:insert(amountLabel)
	
	donutChart.sectionLabel = sectionLabel
	donutChart.amountLabel = amountLabel
	donutChart.selectedSection = 1
	donutChart.showPercent = showPercent
	donutChart.anchorChildren = true

	local totalAmount = 0
	for index = 1, #sections do
		totalAmount = totalAmount + sections[index].amount or 0
	end
	
	local currentSection = 1
	local nextSectionStarts = (sections[currentSection].amount / totalAmount) * ITERATIONS_TOTAL
	
	donutChart.defaultScale = 1
	donutChart.selectedScale = 1.2
	
	local function createNewSection(sectionNumber)
		return {
			circles = {},
			data = sections[sectionNumber],
			percentage = sections[sectionNumber].amount / totalAmount,
		}
	end
	
	donutChart.sections = {
		[currentSection] = createNewSection(currentSection)
	}
	
	local multiplier = 360 / ITERATIONS_TOTAL
	for index = 1, ITERATIONS_TOTAL do
		local labelRadians = mathRad((index * multiplier + 180))
		local angleX = mathCos(labelRadians)
		local angleY = mathSin(labelRadians)

		local circleDistance = radius - halfWidth
		local positionX = angleX * circleDistance
		local positionY = angleY * circleDistance

		local circle = display.newCircle(positionX, positionY, halfWidth)
		circle:setFillColor(unpack(sections[currentSection].color))
		circle.alpha = 0
		donutChart.sections[currentSection].circles[#donutChart.sections[currentSection].circles + 1] = circle
		donutChart:insert( circle )

		if index > LAST_ITERATIONS then
			circle:toBack()
		end

		if nextSectionStarts <= index then
			currentSection = currentSection + 1
			if currentSection <= #sections then
				donutChart.sections[currentSection] = createNewSection(currentSection)
				nextSectionStarts = nextSectionStarts + ((sections[currentSection].amount / totalAmount) * ITERATIONS_TOTAL)
			end
		end
		transition.to(circle, {delay = index * 10, time = 400, alpha = 1, transition = easing.outQuad})
	end
	
	local function selectSection(self, selectedSection)
		for index = 1, #self.sections do
			local donutSection = self.sections[index]
			transition.cancel(self)
			
			if index == selectedSection then
				self.sectionLabel.text = donutSection.data.label
				self.amountLabel.text = self.showPercent and string.format("%.2f %%", (donutSection.percentage * 100)) or donutSection.data.amount
				for index = 1, #donutSection.circles do
					transition.to(donutSection.circles[index], {time = 400, xScale = self.selectedScale, yScale = self.selectedScale, transition = easing.outQuad})
				end
			else
				for index = 1, #donutSection.circles do
					transition.to(donutSection.circles[index], {time = 400, xScale = self.defaultScale, yScale = self.defaultScale, transition = easing.outQuad})
				end
			end
		end
	end
	
	function donutChart:tap(event)
		-- TODO Add sound id and play on tap
		self.selectedSection = self.selectedSection + 1
		if self.selectedSection > #self.sections then
			self.selectedSection = 1
		end
		
		selectSection(self, self.selectedSection)
	end
	
	donutChart:addEventListener("tap")
	selectSection(donutChart, 1)
	
	return donutChart
end

function charts.newBarGraph(options)
	options = options or {}
	local sections = options.sections or {{amount = 1, label = "default", color = colors.lime}}
	
	local width = options.width or 500
	local height = options.height or 300
	local frameColor = options.frameColor or colors.darkGray
	local frameWidth = options.frameWidth or 12
	local barWidth = options.barWidth or 36
	
	local amountText = options.amountText or "Amount"
	local sectionText = options.sectionText or "Sections"
	local legendFontColor = options.legendFontColor or colors.white
	local legendFontName = options.legendFontName or native.systemFontBold
	local legendFontSize = options.fontSize or 20
	local amountLabelWidth = options.amountLabelWidth or 100
	local sectionLabelHeight = options.sectionLabelHeight or 50
	local legendPadding = options.legendPadding or 20
	local showBackground = options.showBackground
	
	local graphWidth = width - amountLabelWidth - legendPadding
	local graphHeight = height - sectionLabelHeight - legendPadding * 3
	
	local graphX = amountLabelWidth * 0.5
	local graphY = graphHeight * 0.5 - legendPadding * 2
	
	local maxAmount = 0
	for index = 1, #sections do
		local sectionAmount = sections[index].amount
		maxAmount = sectionAmount > maxAmount and sectionAmount or maxAmount
	end
	maxAmount = math.floor((math.ceil(((maxAmount * 2) * 0.1)) / 2) * 10)
	
	maxAmount = maxAmount < 2 and 2 or maxAmount
	
	local barGraph = display.newGroup()
	
	local bgRect = display.newRect(0,0,width,height)
	bgRect:setFillColor(unpack(colors.lightGray))
	bgRect.isHitTestable = true
	barGraph:insert(bgRect)
	bgRect.isVisible = showBackground == true
	
	local lowerFrame = display.newRect(graphX, graphY, graphWidth, frameWidth)
	lowerFrame:setFillColor(unpack(frameColor))
	barGraph:insert(lowerFrame)
	
	local sideFrameX = graphX - graphWidth * 0.5
	local sideFrame = display.newRect(sideFrameX, graphY + frameWidth * 0.5, frameWidth, graphHeight + frameWidth * 0.5)
	sideFrame.anchorY = 1
	sideFrame:setFillColor(unpack(frameColor))
	barGraph:insert(sideFrame)
	
	local amountLabelOptions = {
		x = graphX - graphWidth * 0.5 - legendPadding,
		y = graphY - graphHeight,
		width = amountLabelWidth,
		align = "right",
		font = legendFontName,
		text = amountText,
		fontSize = legendFontSize,
	}

	local amountLabel = display.newText(amountLabelOptions)
	amountLabel.anchorX = 1
	amountLabel.anchorY = 0
	amountLabel:setFillColor(unpack(legendFontColor))
	barGraph:insert(amountLabel)
	
	local sectionLabelOptions = {
		x = graphX,
		y = graphY + legendPadding * 3,
		height = sectionLabelHeight,
		align = "center",
		font = legendFontName,
		text = sectionText,
		fontSize = legendFontSize,
	}

	local sectionLabel = display.newText(sectionLabelOptions)
	sectionLabel.anchorY = 0
	sectionLabel:setFillColor(unpack(legendFontColor))
	barGraph:insert(sectionLabel)
	
	local barSpacing = graphWidth / (#sections + 1)
	for index = 1, #sections do
		local sectionData = sections[index]
		
		local halfBarWidth = barWidth * 0.5
		local barHeight = (sectionData.amount / maxAmount) * (graphHeight - legendFontSize)
		barHeight = barHeight > halfBarWidth and barHeight or halfBarWidth
		local barX = sideFrameX + barSpacing * index
		
		local barGroup = display.newGroup()
		barGroup.x = barX
		barGroup.y = graphY
		barGraph:insert(barGroup)
		
		local bar = display.newRoundedRect(0, 0, barWidth, barWidth * 0.5, 15)
		bar.anchorY = 1
		bar:setFillColor(unpack(sectionData.color))
		barGroup:insert(bar)
		
		local barLabel = display.newText(sectionData.label, barX, graphY + legendPadding, legendFontName, legendFontSize)
		barLabel:setFillColor(unpack(legendFontColor))
		barGraph:insert(barLabel)
		
		local barAmount = display.newText(string.format("%d", sectionData.amount), 0, -barHeight - (legendFontSize * 0.5), legendFontName, legendFontSize)
		barGroup:insert(barAmount)
		barAmount:setFillColor(unpack(legendFontColor))
		bar.amount = barAmount
		
		local oldMetatable = getmetatable(bar)
		local metatable = {
			__index = function(self, key)
				return oldMetatable.__index(self, key)
			end,
			__newindex = function(self, key, value)
				getmetatable(self)[key] = value
				if key == "height" then
					self.amount.y = -value - (legendFontSize * 0.5)
				end
				return oldMetatable.__newindex(self, key, value)
			end
		}
		setmetatable(bar, metatable)
		
		bar.height = 20
		transition.to(bar, {delay = 200 * index, time = 400, height = barHeight, transition = easing.outQuad})
	end
		
	return barGraph
end

return charts