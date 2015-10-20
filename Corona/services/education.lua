----------------------------------------------- Education service
local logger = require("libs.helpers.logger") 

local educationService = {}
----------------------------------------------- Variables
 
----------------------------------------------- Constants
local MAX_SUBJECT_WEIGTH = 10
local AMOUNT_DEFAULT_MINIGAMES = {
	["math"] = 5,
	["science"] = 3,
	["sustainability"] = 2,
	["health"] = 1,
	["programming"] = 2,
	["art"] = 2,
	["geography"] = 3,
	["languages"] = 2,
}
----------------------------------------------- Functions
----------------------------------------------- Module functions 
function educationService.getEducationSession(player, minigameDictionary, amount, specificSubject)
	-- TODO We will select subjects based on importance and amount
	
	-- TODO must choose games depending on player game counts?
	local availableSubjects = {}
	for index = 1, #minigameDictionary do
		local minigameData = minigameDictionary[index]
		if minigameData.available then
			if not availableSubjects[minigameData.category] then
				availableSubjects[minigameData.category] = 0
			end
			
			-- TODO this limits a subject weight, do depending on player
			if availableSubjects[minigameData.category] < MAX_SUBJECT_WEIGTH then
				availableSubjects[minigameData.category] = availableSubjects[minigameData.category] + 1
				availableSubjects[#availableSubjects + 1] = minigameData.category
			end
		end
	end
	
	for subject in pairs(availableSubjects) do
		if not tonumber(subject) then
			logger.log("[Education] Subject "..subject.." is available")
		end
	end
	
	local educationSession = {}
	
	local function getSubject()
		return specificSubject or availableSubjects[math.random(1,#availableSubjects)]
	end
	
	if (not amount or amount <= 0) and specificSubject then
		amount = AMOUNT_DEFAULT_MINIGAMES[specificSubject]
	end
	
	amount = amount or 5
	
	-- TODO it chooses a random subject depending on subject weight. 
	for index = 1, amount do
		educationSession[index] = {category = getSubject(),}
	end
	
	return educationSession
end

function educationService.selectMinigames(educationSession, minigameDictionary, player, onlyAvailable)
	player = player or {}
	local selectedMinigames = {}
	
	if onlyAvailable == nil then
		onlyAvailable = true
	end
		
	for sessionIndex = 1, #educationSession do
		local sessionCategory = educationSession[sessionIndex].category
		
		local selectedMinigame = false
		local minigameIndex = 1
		repeat
			local minigameData = minigameDictionary[minigameIndex]
			
			local canPlayMinigame = true
			if onlyAvailable then
				canPlayMinigame = minigameData.available
			end
			
			if canPlayMinigame then
				if minigameData.category == sessionCategory then
					
					local educationModuleName = "services.education."..sessionCategory
					local educationModule
					local success, message = pcall(function()
						educationModule = require(educationModuleName)
					end)

					if not success and message then
						logger.error([[[Education Service] Module "]]..educationModuleName..[[" does not exist or contains errors.]])
					else
						if educationModule.isEligible(minigameData, player) then
							-- TODO check minigame choosing
							selectedMinigame = true
							selectedMinigames[sessionIndex] = {
								index = minigameIndex,
								requirePath = minigameData.requirePath,
								info = minigameData
							}
						end
					end
				end
			end
				
			minigameIndex = minigameIndex + math.random(1, #minigameDictionary)
			if minigameIndex > #minigameDictionary then
				minigameIndex = 1 + minigameIndex % #minigameDictionary
			end
		
		until selectedMinigame
	end
	
	for index = 1, #selectedMinigames do
		logger.log([[[Education] Chose "]]..selectedMinigames[index].info.folderName..[["]])
	end
	
	return selectedMinigames
end

function educationService.injectEducationParameters(minigameTable, player)
	for index = 1, #minigameTable do
		local chosenCategory = minigameTable[index].info.category
		-- TODO log useful information here
		
		if chosenCategory then
			local educationModuleName = "services.education."..chosenCategory
			local educationModule
			local success, message = pcall(function()
				educationModule = require(educationModuleName)
			end)

			if not success and message then
				logger.error([[[Education Service] Module "]]..educationModuleName..[[" does not exist or contains errors.]])
			else
				minigameTable[index].params = educationModule.getEducationParameters(minigameTable[index].info, player)
			end
		end
	end
end

return educationService
