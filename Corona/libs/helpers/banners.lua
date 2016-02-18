----------------------------------------------- Banners
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local sound = require( folder.."sound" )

local banners = {}
----------------------------------------------- Variables
local initialized
----------------------------------------------- Constants 
local PATH_IMAGES = string.gsub(folder,"[%.]","/").."images/"
local PATH_SOUNDS = string.gsub(folder,"[%.]","/").."sounds/"

local SOUND_IDS = {
	ready = {en = "bannersReady_en", es = "bannersReady_es", pt = "bannersReady_pt"},
	go = {en = "bannersGo_en", es = "bannersGo_es", pt = "bannersGo_pt"},
}

local SOUNDLIST = {
	[SOUND_IDS.ready.en] = PATH_SOUNDS.."ready_en.mp3",
	[SOUND_IDS.ready.es] = PATH_SOUNDS.."ready_es.mp3",
	[SOUND_IDS.ready.pt] = PATH_SOUNDS.."ready_pt.mp3",
	[SOUND_IDS.go.en] = PATH_SOUNDS.."go_en.mp3",
	[SOUND_IDS.go.es] = PATH_SOUNDS.."go_es.mp3",
	[SOUND_IDS.go.pt] = PATH_SOUNDS.."go_pt.mp3",
}
----------------------------------------------- Functions
local function initialize()
	if not initialized then
		initialized = true
		
		logger.log("Initializing.")
		sound.loadTable(SOUNDLIST)
	end
end

----------------------------------------------- Module functions 
function banners.newReadyGo(options)
	local readyGo = display.newGroup()
	readyGo.x = display.contentCenterX
	readyGo.y = display.contentCenterY
	
	options = options or {}
	local language = options.language or "en"
	
	local readyPath = options.readyPath or PATH_IMAGES.."ready_"..language..".png"
	local goPath = options.goPath or PATH_IMAGES.."go_"..language..".png"
	
	local readySound = options.readySound or SOUND_IDS.ready[language]
	local goSound = options.goSound or SOUND_IDS.go[language]
	local delay = options.delay or 0
	local totalTime = options.time or 3500
	local onComplete = options.onComplete
	
	local customScales = options.scales or {}
	local initialScale = customScales[1] or 5
	
	local readyScale1 = customScales[2] or 1.3
	local readyScale2 = customScales[3] or 0.9
	local readyScale3 = customScales[4] or 0.9
	
	local goScale1 = customScales[5] or 1.3
	local goScale2 = customScales[6] or 1.1
	local goScale3 = customScales[7] or 0.9

	local ready = display.newImage(readyPath)
	ready.xScale = initialScale
	ready.yScale = initialScale
	ready.alpha = 0
	readyGo:insert(ready)

	local go = display.newImage(goPath)
	go.xScale = initialScale
	go.yScale = initialScale
	go.alpha = 0
	readyGo:insert(go)
	
	local partTime = totalTime / 7

	transition.to(ready, {delay = delay, time = partTime, alpha = 1, xScale = readyScale1, yScale = readyScale1,  transition=easing.outQuad, onStart = function()
		sound.play(readySound)
	end})
	transition.to(ready, {delay = delay + partTime, time = partTime * 2, alpha = 1, xScale = readyScale2, yScale = readyScale2,  transition=easing.outQuad})
	transition.to(ready, {delay = delay + partTime * 3, time = partTime, alpha = 0, xScale = readyScale3, yScale = readyScale3,  transition=easing.outQuad})

	transition.to(go, {delay = delay + partTime * 3, time = partTime, alpha = 1, xScale = goScale1, yScale = goScale1,  transition=easing.outQuad, onComplete = function()
		sound.play(goSound)
	end})
	transition.to(go, {delay = delay + partTime * 4, time = partTime * 2, alpha = 1, xScale = goScale2, yScale = goScale2,  transition=easing.outQuad})
	transition.to(go, {delay = delay + partTime * 6, time = partTime, alpha = 0, xScale = goScale3, yScale = goScale3,  transition=easing.outQuad, onComplete = function()
		display.remove(readyGo)
		readyGo = nil
		if onComplete and "function" == type(onComplete) then
			onComplete()
		end
	end})
	
	readyGo:addEventListener("finalize", function(event)
		if event.target then
			transition.cancel(event.target)
		end
	end)
	
	return readyGo
end

----------------------------------------------- Execution

initialize()


return banners
