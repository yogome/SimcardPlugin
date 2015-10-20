--------------------------------------------- Level service
local levels = {}
--------------------------------------------- Variables
--------------------------------------------- Constants
--------------------------------------------- Module functions
function levels.check(player, worldIndex, levelIndex, stars)
	if not player.unlockedWorlds[worldIndex] then
		player.unlockedWorlds[worldIndex] = {
			unlocked = true,
			levels = {},
		}
	end
	
	if not player.unlockedWorlds[worldIndex].levels[levelIndex] then
		player.unlockedWorlds[worldIndex].levels[levelIndex] = {unlocked = true, stars = stars}
	else
		local currentStars = player.unlockedWorlds[worldIndex].levels[levelIndex].stars
		if stars > currentStars then
			player.unlockedWorlds[worldIndex].levels[levelIndex].stars = stars
		end
	end
	
	if not player.unlockedWorlds[worldIndex].levels[levelIndex + 1] then
		player.unlockedWorlds[worldIndex].levels[levelIndex + 1] = {unlocked = true, stars = 0}
	end

end

return levels
