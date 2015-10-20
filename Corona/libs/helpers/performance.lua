----------------------------------------------- Performance
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local performance = {}
---------------------------------------------- Variables
local currentLoop, previousTime, MAX_SAVED_FPS, lastFPSCounter
local lastFPS
---------------------------------------------- Constants
local UPDATE_EVERY_LOOPS = 12
local MAX_SAVED_FPS = 10
---------------------------------------------- Caches
local systemGetTimer = system.getTimer 
local mathFloor = math.floor
local stringFormat = string.format
local systemGetInfo = system.getInfo
local mathHuge = math.huge
---------------------------------------------- Functions
local function minElement(tableIn)
	local minimum = mathHuge
	for index = 1, #tableIn do
		if(tableIn[index] < minimum) then minimum = tableIn[index] end
	end
	return minimum
end

local function avgElement(tableIn)
	local avg = 0
	for index = 1, #tableIn do
		avg = avg + tableIn[index]
	end
	avg = avg / #tableIn
	return avg
end

local function createInstance()
	logger.log("[Performance] Creating performance counter.")
	currentLoop = 0
	previousTime = 0
	
	lastFPS = {}
	lastFPSCounter = 1
	
	local counter = {}
	counter.group = display.newGroup()

	counter.memory = display.newText("0/10", 0, -15, native.systemFont, 24)
	counter.framerate = display.newText("0", 0, 15, native.systemFont, 26)
	local background = display.newRect(0,0, 280, 80)
	background:setFillColor(0.3,0.3,0.3)

	counter.memory:setFillColor(1,1,1)
	counter.framerate:setFillColor(1,1,1)

	counter.group:insert(background)
	counter.group:insert(counter.memory)
	counter.group:insert(counter.framerate)
	
	function counter:enterFrame(event)
		currentLoop = currentLoop + 1
		if currentLoop % UPDATE_EVERY_LOOPS == 0 then
			local currentTime = systemGetTimer()
			local deltaTime = currentTime - previousTime
			previousTime = currentTime

			local fps = mathFloor(1000/deltaTime) * UPDATE_EVERY_LOOPS

			lastFPS[lastFPSCounter] = fps
			lastFPSCounter = lastFPSCounter + 1
			if lastFPSCounter > MAX_SAVED_FPS then
				lastFPSCounter = 1
			end
			local minLastFps = minElement(lastFPS)
			local avgFps = avgElement(lastFPS)

			self.framerate.text = stringFormat("FPS: avg: %d min: %d", avgFps, minLastFps)
			self.memory.text = stringFormat("G:%.2fmb S:%.2fmb", systemGetInfo("textureMemoryUsed") * 0.00000095, collectgarbage("count") * 0.00095)
		end
	end
	return counter
end

----------------------------------------------- Class functions
function performance.getGroup()
	if not performance.counter then 
		performance.counter = createInstance()
		Runtime:addEventListener("enterFrame", performance.counter)
	end

	return performance.counter.group
end

return performance