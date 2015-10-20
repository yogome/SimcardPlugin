----------------------------------------------- Programming education service
local programmingModule = {}
----------------------------------------------- Variables
----------------------------------------------- Constants
----------------------------------------------- Functions 
----------------------------------------------- Module Functions
function programmingModule.isEligible(minigameData, player)
	return true
end 

function programmingModule.getEducationParameters(minigameInfo, player)
	-- TODO choose a subcategory depending on player, check requires and return then
	local chosenSubcategory = minigameInfo.subcategories[math.random(1,#minigameInfo.subcategories)]
	
	for index = 1, #minigameInfo.requires do
		local requireData = minigameInfo.requires[index]
		
	end
	
	return {
		subcategory = chosenSubcategory,
		dataString = "No data required",
	}
end

return programmingModule