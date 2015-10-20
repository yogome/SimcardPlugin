----------------------------------------------- Scene loader
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local director = require( folder.."director" )

local sceneLoader = {}
---------------------------------------------- Functions
function sceneLoader.loadScenes(sceneList, onSceneLoaded, sceneDelay)
	if not (not onSceneLoaded or (onSceneLoaded and "function" == type(onSceneLoaded))) then
		error("onSceneLoaded must be a function or be nil", 3)
	end
	sceneDelay = sceneDelay or 0
	if not "number" == type(sceneDelay) then
		error("sceneDelay must be a number", 3)
	end
	
	local totalScenes = #sceneList
	local percentagePerScene = 1 / totalScenes
	if sceneList and type(sceneList) == "table" and totalScenes > 0 then
		logger.log("[Sceneloader] Will attempt to load "..totalScenes.." scenes.")
		
		display.setDefault( "preloadTextures", true )
		for index = 1, totalScenes do
			if sceneList[index] then
				
				local function loadScene(sceneIndex)
					local result, errorMessage = pcall(function()
						director.loadScene(sceneList[sceneIndex])
					end)

					if not result then
						logger.error("[Sceneloader] There was an error loading "..sceneList[sceneIndex]..": "..errorMessage)
					else
						logger.log("[Sceneloader] Loaded "..sceneList[sceneIndex]..".")
					end
					if onSceneLoaded then
						local event = {
							percentage = sceneIndex * percentagePerScene,
							index = sceneIndex,
							percentagePerScene = percentagePerScene,
						}
						onSceneLoaded(event)
					end
				end
				
				if sceneDelay > 0 then
					timer.performWithDelay(sceneDelay * index, function()
						loadScene(index)
					end)
				else
					loadScene(index)
				end
			end
		end
	else
		logger.log("[Sceneloader] sceneList must not be nil, be a table and not be empty.")
	end
end

return sceneLoader
