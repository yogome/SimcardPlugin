----------------------------------------------- Sustainability education service
local sustainabilityService = {}
----------------------------------------------- Variables
----------------------------------------------- Constants
----------------------------------------------- Functions 
----------------------------------------------- Module Functions
function sustainabilityService.isEligible(minigameData, player)
	return true
end

function sustainabilityService.getEducationParameters(minigameInfo, player)
	local chosenSubcategory = minigameInfo.subcategories[math.random(1, #minigameInfo.subcategories)]

	for index = 1, #minigameInfo.requires do
		local requireData = minigameInfo.requires[index]
		
	end
	
	return {
		subcategory = chosenSubcategory,
		dataString = "No data provided"
	}
end

return sustainabilityService
