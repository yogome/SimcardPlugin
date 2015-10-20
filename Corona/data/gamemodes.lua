local gamemodes = {
	["tutorial1"] = {
		heroAvailable = true,
		itemsAvailable = true,
		unitsCanSpecial = true,
		coinsDespawn = false,
		lanes = 1,
		warzoneWidth = 1800,
		maxEnergy = 40,
		maxFoodLevel = 20,
		maxItemRecharge = 100,
		itemRechargePerSecond = 4,
		foodRechargePerSecond = 5,
		energyRechargePerSecond = 2,
		warzoneScrollDelay = 2200,
		fortressData = {
			[1] = {
				enabled = true,
				columns = 2,
			},
			[2] = {
				enabled = true,
				columns = 2,
			},
		},
		buildings = {
			[1] = {
				[1] = {4,6},
			},
			[2] = {
				[1] = {12,13},
			},
		},
		events = {
			{
				frame = 1,
				freeze = {"warzoneScrollView","unitScrollView","coinPick","unitSpawn"},
			},
			{
				frame = 2,
				pause = {"energy", "food"},
			},
			{
				frame = 102,
				unpause = "food",
				specialEvent = "showFoodTutorial"
			},
			{
				frame = 341,
				unFreeze = "unitSpawn",
				pauseUntil = "unitSpawned",
				handDrag = {from = "firstUnitOnBar", to = "firstLane", offsetToX = display.viewableContentWidth * 0.45, loop = true, removeEvent = "unitSpawned"},
			},
			{
				frame = 342,
				pause = "food",
			},
			{
				frame = 520,
				specialEvent = "fullSpecial",
			},
			{
				frame = 521,
				pauseUntil = "lastPlayerUnitSpecial",
				handTap = {position = "lastPlayerUnit", removeEvent = "lastPlayerUnitSpecial"},
			},
			{
				frame = 522,
				unpause = "energy",
				specialEvent = {"showEnergyTutorial", "allowRandomness"}
			},
			{
				frame = 750,
				unpause = "food",
				unFreeze = {"warzoneScrollView", "unitScrollView", "coinPick", "unitSpawn"},
			},
			{
				frame = 850,
				specialEvent = "emptySpecial",
			},
		},
		enemyUnitInterval = 10,
		enemyUnits = {1,1,1},
		maxConcurrentEnemyUnits = 1,
		conditions = {
			win = {
				unitDespawn = true,
				buildingsKilled = true,
			},
			lose = {
				enemyDespawn = true,
				buildingsLost = true,
			},
		},
		goals = {
			[1] = {type = "killUnits", amount = 2,},
			[2] = {type = "collectCoins", amount = 1,},
			[3] = {type = "killBuildings", amount = 2,},
		},
	},
	
	["war"] = {
		unitsCanSpecial = true,
		heroAvailable = true,
		itemsAvailable = true,
		lanes = 3,
		warzoneScrollDelay = 1000,
		maxEnergy = 40,
		maxItemRecharge = 100,
		itemRechargePerSecond = 4,
		foodRechargePerSecond = 10,
		energyRechargePerSecond = 4,
		maxFoodLevel = 50,
		warzoneWidth = 1900,
		allowRandomness = true,
		buildings = {
			[1] = {
				[1] = {1,2,4,6},
				[2] = {1,7,5,6},
				[3] = {1,2,4,6},
			},
			[2] = {
				[1] = {12,13,10,8},
				[2] = {12,13,9,8},
				[3] = {12,14,10,8},
			},
		},
		fortressData = {
			[1] = {
				enabled = true,
				columns = 4,
			},
			[2] = {
				enabled = true,
				columns = 4,
			},
		},
		conditions = {
			win = {
				unitDespawn = false,
				buildingsKilled = false,
			},
			lose = {
				enemyDespawn = true,
				buildingsLost = true,
			},
		},
		goals = {
			[1] = {type = "killBuildings", amount = 12,},
			[2] = {type = "killUnits", amount = 20,},
		},
		enemyUnitInterval = 200,
		enemyUnits = {1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,1,1,1,1,1,1},
		maxConcurrentEnemyUnits = 5,
	},
	["test"] = {
		unitsCanSpecial = true,
		heroAvailable = true,
		itemsAvailable = true,
		lanes = 3,
		warzoneScrollDelay = 1000,
		maxEnergy = 60,
		maxItemRecharge = 100,
		foodRechargePerSecond = 20,
		energyRechargePerSecond = 4,
		itemRechargePerSecond = 4,
		maxFoodLevel = 140,
		warzoneWidth = 1800,
		allowRandomness = true,
		buildings = {
			[1] = {
				[1] = {4,5,7},
				[2] = {4,5,7},
				[3] = {4,5,7},
			},
			[2] = {
				[1] = {12,14,10,8},
				[2] = {12,14,10,8},
				[3] = {12,14,10,8},
			},
		},
		fortressData = {
			[1] = {
				enabled = true,
				columns = 3,
			},
			[2] = {
				enabled = true,
				columns = 4,
			},
		},
		conditions = {
			win = {
				unitDespawn = false,
				buildingsKilled = false,
			},
			lose = {
				enemyDespawn = true,
				buildingsLost = true,
			},
		},
		goals = {
			[1] = {type = "killBuildings", amount = 1,},
--			[2] = {type = "killUnits", amount = 140,},
		},
		enemyUnitInterval = 1,
		enemyUnits = {
			--{amount = 3, index = 1},
			{amount = 3, index = 2},
--			{amount = 3, index = 12},
--			{amount = 3, index = 17},
--			{amount = 3, index = 20},
--			{amount = 3, index = 21},
--			{amount = 3, index = 22},
		},
		maxConcurrentEnemyUnits = 1,
	},
}

return gamemodes