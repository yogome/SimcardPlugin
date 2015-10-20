----------------------------------------------- Nutrition education service
local nutritionModule = {}
----------------------------------------------- Variables
----------------------------------------------- Constants

----------------------------------------------- Functions 
----------------------------------------------- Module Functions
function nutritionModule.getEducationParameters(minigameInfo, player)
	local categoryName = "nutrition"
	local nutritionInfo = minigameInfo.categories[categoryName]
	
	if nutritionInfo then
		local questionType = nutritionInfo.questionType or "multiple"
		local totalQuestions = nutritionInfo.totalQuestions or 1
		
		return {
			category = categoryName,
			subcategory = nutritionInfo.subcategories[1],
			gamemode = nutritionInfo.gamemodes[1],
			dataString = ""
		}
	end
end

return nutritionModule