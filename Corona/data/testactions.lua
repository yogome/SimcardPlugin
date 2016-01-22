----------------------------------------------- Test actions
local director = require( "libs.helpers.director" )
local colors = require( "libs.helpers.colors" )
local players = require( "models.players" )
local offlinequeue = require( "libs.helpers.offlinequeue" )
local json = require( "json" )
local settings = require( "settings" )
----------------------------------------------- Functions
local function goYogome()
	director.gotoScene("scenes.intro.yogome")
end
local function unlockAllLevels()
	local currentPlayer = players.getCurrent()
	local worldsdata = require( "data.worldsdata" )
	for world = 1, #worldsdata do
		currentPlayer.unlockedWorlds[world] = {unlocked = true, levels = {}, watchedEnd = false}
		for level = 1, #worldsdata[world] do
			currentPlayer.unlockedWorlds[world].levels[level] = {unlocked = true, stars = 1}
		end
	end
	players.save(currentPlayer)
end

local function giveCoins()
	local player = players.getCurrent()
	if player.coins then
		player.coins = player.coins + 100
	else
		player.coins = 100
	end
	players.save(player)
end

local function resetPlayer()
	local currentPlayer = players.getCurrent()
	local playerID = currentPlayer.id
	local remoteID = currentPlayer.remoteID
	if playerID then
		currentPlayer = players.new()
		currentPlayer.id = playerID
		currentPlayer.remoteID = remoteID
		players.save(currentPlayer)
	end
end

local function goManagerMath()
	local minigames = {
--		"mathballoon",
--		"mathBlocks",
--		"mathcatch",
		"mathClaw",
--		"mathCountFood",
--		"mathCountFrog",
--		"mathDogJump",
--		"mathDragAndDrop",
--		"mathDragCupcakes",
--		"mathDungeon",
--		"mathEquationMarker",
--		"mathFractionInvaders",
--		"mathFractionPizza",
--		"mathHungryMonster",
--		"mathinvaders",
--		"mathNinja",
--		"mathProblemEquation",
--		"mathroulette",
--		"mathSlash",
--		"mathslider",
--		"mathSushi",
--		"mathSushi2",
--		"mathTapBirds",
--		"mathTapBunnies",
--		"mathTapCat",
--		"mathTapFishes",
--		"mathTapFood",
--		"mathTapNumber",
--		"mathTrain",
--		"mathTrainTime",
--		"mathTrueOrNot",
--		"mathWindowCurtain",
	}
	director.gotoScene("scenes.minigames.manager", {params = {minigames = minigames}})
end
local function goManager()
	director.gotoScene("scenes.minigames.manager", {params = {minigameIndexes = {1}}})
end
local function goHome()
	director.gotoScene("scenes.menus.home")
end
local function goMinigamesUnits()
	director.gotoScene("scenes.game.units", {params = {powercubes = 200}})
end
local function goHero()
	director.gotoScene("scenes.menus.selecthero")
end
local function goWorlds()
	director.gotoScene("scenes.menus.worlds")
end
local function goLevels()
	director.gotoScene("scenes.menus.levels")
end
local function goBonus()
	director.gotoScene("scenes.game.bonus")
end
local function goGame()
	director.gotoScene("scenes.game.game")
end
local function goOnboarding()
	director.gotoScene("scenes.menus.login.onboarding")
end
-----------------------------------------------
local testActions = {
	{"Go game", goGame, {0.4,0.4,0.4}, 1},
	{"Go Bonus", goBonus, {0.3,0.3,0.3}, 2},
	{"Go units", goMinigamesUnits, {0.3,0.3,0.3}, 2},
	{"Go Manager Math", goManagerMath, {0.3,0.3,0.3}, 2},
	{"Go Home", goHome, {0.5,0.5,0.5}},
	{"Go Hero", goHero, {0.5,0.5,0.5}},
	{"Go Worlds", goWorlds, {0.5,0.5,0.5}},
	{"Go Levels", goLevels, {0.5,0.5,0.5}},
	{"Go Manager", goManager, {0.5,0.6,0.3}},
	{"Give Coins", giveCoins,{0.2,0.8,0.2}},
	{"Go Yogome", goYogome, {0.3,0.3,0.3}},
	{"Reset player", resetPlayer,{0.8,0.2,0.2}},
	{"Unlock levels", unlockAllLevels,{0.8,0.8,0.2}},
	
	{"Go onboarding", goOnboarding, {0.4,0.5,0.4}, 2},
}

return testActions