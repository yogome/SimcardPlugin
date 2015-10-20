local extratable = require("libs.helpers.extratable")

local worldsData = {
	[1] = {
		maxDemoLevel = 5,
		icon = "images/worlds/worlds-01.png",
		backgroundColor = {47/255,190/255,196/255},
		asteroids = {
			[1] = "images/worlds/world01/asteroid_01.png",
			[2] = "images/worlds/world01/asteroid_02.png",
		},
		path = {easingX = easing.linear, easingY = easing.inOutCubic},
		defaultBackgroundID = "Yogopolis2",
		buildingList = {
			path = "images/game/world01/",
			[1] = {
				health = 500,
				healthbarY = -220,
				offsetY = 20,
				images = {
					conditionPerfect = "yogoBuildings/edif-01-01.png",
					conditionDamaged = "yogoBuildings/edif-01-02.png",
					conditionDestroyed = "yogoBuildings/edif-01-03.png",
				},
			},
			[2] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "yogoBuildings/edif-02-01.png",
					conditionDamaged = "yogoBuildings/edif-02-02.png",
					conditionDestroyed = "yogoBuildings/edif-02-03.png",
				},
			},
			[3] = {
				health = 500,
				healthbarY = -200,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edif-03-01.png",
					conditionDamaged = "yogoBuildings/edif-03-02.png",
					conditionDestroyed = "yogoBuildings/edif-03-03.png",
				},
			},
			[4] = {
				health = 500,
				healthbarY = -200,
				offsetY = 40,
				images = {
					conditionPerfect = "yogoBuildings/edif-04-01.png",
					conditionDamaged = "yogoBuildings/edif-04-02.png",
					conditionDestroyed = "yogoBuildings/edif-04-03.png",
				},
			},
			[5] = {
				health = 500,
				healthbarY = -200,
				offsetY = 20,
				images = {
					conditionPerfect = "yogoBuildings/edif-05-01.png",
					conditionDamaged = "yogoBuildings/edif-05-02.png",
					conditionDestroyed = "yogoBuildings/edif-05-03.png",
				},
			},
			[6] = {
				health = 800,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "yogoBuildings/edif-06-01.png",
					conditionDamaged = "yogoBuildings/edif-06-02.png",
					conditionDestroyed = "yogoBuildings/edif-06-03.png",
				},
			},
			[7] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "yogoBuildings/edif-07-01.png",
					conditionDamaged = "yogoBuildings/edif-07-02.png",
					conditionDestroyed = "yogoBuildings/edif-07-03.png",
				},
			},
			[8] = {
				health = 500,
				healthbarY = -220,
				offsetY = 20,
				images = {
					conditionPerfect = "ignaBuildings/edif-01-01.png",
					conditionDamaged = "ignaBuildings/edif-01-02.png",
					conditionDestroyed = "ignaBuildings/edif-01-03.png",
				},
			},
			[9] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-02-01.png",
					conditionDamaged = "ignaBuildings/edif-02-02.png",
					conditionDestroyed = "ignaBuildings/edif-02-03.png",
				},
			},
			[10] = {
				health = 500,
				healthbarY = -200,
				offsetY = -10,
				images = {
					conditionPerfect = "ignaBuildings/edif-03-01.png",
					conditionDamaged = "ignaBuildings/edif-03-02.png",
					conditionDestroyed = "ignaBuildings/edif-03-03.png",
				},
			},
			[11] = {
				health = 500,
				healthbarY = -200,
				offsetY = 40,
				images = {
					conditionPerfect = "ignaBuildings/edif-04-01.png",
					conditionDamaged = "ignaBuildings/edif-04-02.png",
					conditionDestroyed = "ignaBuildings/edif-04-03.png",
				},
			},
			[12] = {
				health = 500,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-05-01.png",
					conditionDamaged = "ignaBuildings/edif-05-02.png",
					conditionDestroyed = "ignaBuildings/edif-05-03.png",
				},
			},
			[13] = {
				health = 800,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-06-01.png",
					conditionDamaged = "ignaBuildings/edif-06-02.png",
					conditionDestroyed = "ignaBuildings/edif-06-03.png",
				},
			},
			[14] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-07-01.png",
					conditionDamaged = "ignaBuildings/edif-07-02.png",
					conditionDestroyed = "ignaBuildings/edif-07-03.png",
				},
			},
		},
		[1] = {
			x = 500,
			y = 0,
			gamemodeData = {
				mode = "tutorial1",
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 1},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 1},
				},
			},
		},
		[2] = {
			x = 800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 30,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {1,2},
						},
						[2] = {
							[1] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 4, index = 2},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 2,},
						[2] = {type = "killUnits", amount = 6,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 2},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 2}
				},
			},
		},
		[3] = {
			x = 1100,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 40,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 3, index = 1},
						{amount = 4, index = 2},
						{amount = 2, index = 3},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 3,},
						[2] = {type = "killUnits", amount = 8,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 3},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 3}
				},
			},
		},
		[4] = {
			x = 1400,
			y = 40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {4,6},
							[2] = {1,6},
						},
						[2] = {
							[1] = {12,8},
							[2] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 7, index = 2},
						{amount = 3, index = 3},
						{amount = 3, index = 4},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 4,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 4},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 4}
				},
			},
		},
		[5] = {
			x = 1700,
			y = -40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,3,6},
						},
						[2] = {
							[1] = {12,10,8},
							[2] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					lanes = 2,
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 7, index = 2},
						{amount = 5, index = 3},
						{amount = 5, index = 4},
					},
					maxConcurrentEnemyUnits = 3,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 5}
				},
			},
		},
		[6] = {
			x = 2000,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,8},
							[2] = {13,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 2, index = 1},
						{amount = 5, index = 2},
						{amount = 9, index = 3},
						{amount = 4, index = 4},
						{amount = 3, index = 5},
					},
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 12,},
					},
					maxFoodLevel = 60,
				},
				
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 5}
				},
			},
		},
		[7] = {
			x = 2300,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {2,4,6},
							[2] = {1,2,6},
						},
						[2] = {
							[1] = {13,10,8},
							[2] = {12,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 3, index = 2},
						{amount = 3, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
					},
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 16,},
					},
					maxFoodLevel = 60,
				},
				
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 6}
				},
			},
		},
		[8] = {
			x = 2600,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,3,6},
							[2] = {1,5,4,6},
						},
						[2] = {
							[1] = {12,13,9,8},
							[2] = {12,11,10,8},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 8, index = 2},
						{amount = 5, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
						{amount = 1, index = 6},
					},
					maxFoodLevel = 60,
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 6}
				},
			},
		},
		[9] = {
			x = 2900,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 2, index = 5},
						{amount = 2, index = 6},
					},
					maxFoodLevel = 70,
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 14,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 7}
				},
			},
		},
		[10] = {
			x = 3200,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 5, index = 2},
						{amount = 8, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 6,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 7}
				},
			},
		},
		[11] = {
			x = 3500,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 10, index = 2},
						{amount = 1, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 5,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 8}
				},
			},
		},
		[12] = {
			x = 3800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 5, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 1, index = 8},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 6,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 8}
				},
			},
		},
		[13] = {
			x = 4100,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 3, index = 8},
					},
					maxFoodLevel = 90,
					maxConcurrentEnemyUnits = 7,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 1, unitIndex = 9}
				},
			},
		},
		[14] = {
			x = 4400,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 4, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
						{amount = 1, index = 8},
						{amount = 1, index = 9},
					},
					maxFoodLevel = 90,
					maxConcurrentEnemyUnits = 8,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 1, unitIndex = 9}
				},
			},
		},
		[15] = {
			x = 5000,
			y = 120,
			miniBossLevel = true,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 7, index = 5},
						{amount = 4, index = 6},
						{amount = 3, index = 7},
						{amount = 4, index = 8},
						{amount = 2, index = 9},
					},
					maxFoodLevel = 100,
					maxConcurrentEnemyUnits = 9,
				},
				
			},
		},
	},
	--World 2 - Spooky Town
	[2] = {
		maxDemoLevel = 5,
		icon = "images/worlds/worlds-02.png",
		backgroundColor = {97/255,37/255,177/255},
		path = {easingX = easing.linear, easingY = easing.inOutQuad},
		asteroids = {
			[1] = "images/worlds/world02/asteroid_01.png",
			[2] = "images/worlds/world02/asteroid_02.png",
			[3] = "images/worlds/world02/asteroid_03.png",
			[4] = "images/worlds/world02/asteroid_04.png",
			[5] = "images/worlds/world02/asteroid_05.png",
		},
		defaultBackgroundID = "SpookyTown1",
		buildingList = {
			path = "images/game/world02/",
			[1] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_01_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_01_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_01_03.png",
				},
			},
			[2] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_02_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_02_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_02_03.png",
				},
			},
			[3] = {
				health = 500,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_03_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_03_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_03_03.png",
				},
			},
			[4] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_04_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_04_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_04_03.png",
				},
			},
			[5] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_05_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_05_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_05_03.png",
				},
			},
			[6] = {
				health = 800,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_06_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_06_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_06_03.png",
				},
			},
			[7] = {
				health = 500,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "yogoBuildings/edifHalloween_07_01.png",
					conditionDamaged = "yogoBuildings/edifHalloween_07_02.png",
					conditionDestroyed = "yogoBuildings/edifHalloween_07_03.png",
				},
			},
			[8] = {
				health = 500,
				healthbarY = -220,
				offsetY = 20,
				images = {
					conditionPerfect = "ignaBuildings/edif-01-01.png",
					conditionDamaged = "ignaBuildings/edif-01-02.png",
					conditionDestroyed = "ignaBuildings/edif-01-03.png",
				},
			},
			[9] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-02-01.png",
					conditionDamaged = "ignaBuildings/edif-02-02.png",
					conditionDestroyed = "ignaBuildings/edif-02-03.png",
				},
			},
			[10] = {
				health = 500,
				healthbarY = -200,
				offsetY = -10,
				images = {
					conditionPerfect = "ignaBuildings/edif-03-01.png",
					conditionDamaged = "ignaBuildings/edif-03-02.png",
					conditionDestroyed = "ignaBuildings/edif-03-03.png",
				},
			},
			[11] = {
				health = 500,
				healthbarY = -200,
				offsetY = 40,
				images = {
					conditionPerfect = "ignaBuildings/edif-04-01.png",
					conditionDamaged = "ignaBuildings/edif-04-02.png",
					conditionDestroyed = "ignaBuildings/edif-04-03.png",
				},
			},
			[12] = {
				health = 500,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-05-01.png",
					conditionDamaged = "ignaBuildings/edif-05-02.png",
					conditionDestroyed = "ignaBuildings/edif-05-03.png",
				},
			},
			[13] = {
				health = 800,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-06-01.png",
					conditionDamaged = "ignaBuildings/edif-06-02.png",
					conditionDestroyed = "ignaBuildings/edif-06-03.png",
				},
			},
			[14] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-07-01.png",
					conditionDamaged = "ignaBuildings/edif-07-02.png",
					conditionDestroyed = "ignaBuildings/edif-07-03.png",
				},
			},
		},
		[1] = {
			x = 500,
			y = 0,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 30,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {1,2},
						},
						[2] = {
							[1] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 8, index = 1},
						{amount = 4, index = 2},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 2,},
						[2] = {type = "killUnits", amount = 6,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 1},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 1},
				},
			},
		},
		[2] = {
			x = 800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 30,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {1,2},
						},
						[2] = {
							[1] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 4, index = 2},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 2,},
						[2] = {type = "killUnits", amount = 6,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 2},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 2}
				},
			},
		},
		[3] = {
			x = 1100,
			y = -40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 40,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 3, index = 1},
						{amount = 4, index = 2},
						{amount = 2, index = 3},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 3,},
						[2] = {type = "killUnits", amount = 8,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 3},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 3}
				},
			},
		},
		[4] = {
			x = 1400,
			y = 40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {4,6},
							[2] = {1,6},
						},
						[2] = {
							[1] = {12,8},
							[2] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 7, index = 2},
						{amount = 3, index = 3},
						{amount = 3, index = 4},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 4,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 4},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 4}
				},
			},
		},
		[5] = {
			x = 1700,
			y = -40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,3,6},
						},
						[2] = {
							[1] = {12,10,8},
							[2] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					lanes = 2,
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 7, index = 2},
						{amount = 5, index = 3},
						{amount = 5, index = 4},
					},
					maxConcurrentEnemyUnits = 3,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 5}
				},
			},
		},
		[6] = {
			x = 2000,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,8},
							[2] = {13,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 2, index = 1},
						{amount = 5, index = 2},
						{amount = 9, index = 3},
						{amount = 4, index = 4},
						{amount = 3, index = 5},
					},
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 12,},
					},
					maxFoodLevel = 60,
				},
				
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 5}
				},
			},
		},
		[7] = {
			x = 2300,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {2,4,6},
							[2] = {1,2,6},
						},
						[2] = {
							[1] = {13,10,8},
							[2] = {12,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 3, index = 2},
						{amount = 3, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
					},
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 16,},
					},
					maxFoodLevel = 60,
				},
				
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 6}
				},
			},
		},
		[8] = {
			x = 2600,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,3,6},
							[2] = {1,5,4,6},
						},
						[2] = {
							[1] = {12,13,9,8},
							[2] = {12,11,10,8},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 8, index = 2},
						{amount = 5, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
						{amount = 1, index = 6},
					},
					maxFoodLevel = 60,
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 6}
				},
			},
		},
		[9] = {
			x = 2900,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 2, index = 5},
						{amount = 2, index = 6},
					},
					maxFoodLevel = 70,
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 14,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 7}
				},
			},
		},
		[10] = {
			x = 3200,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 5, index = 2},
						{amount = 8, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
					},
					maxFoodLevel = 70,
					maxConcurrentEnemyUnits = 6,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 7}
				},
			},
		},
		[11] = {
			x = 3500,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 10, index = 2},
						{amount = 1, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 5,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 8}
				},
			},
		},
		[12] = {
			x = 3800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 5, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 1, index = 8},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 6,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 8}
				},
			},
		},
		[13] = {
			x = 4100,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 3, index = 8},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 7,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 2, unitIndex = 9}
				},
			},
		},
		[14] = {
			x = 4400,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 4, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
						{amount = 1, index = 8},
						{amount = 1, index = 9},
					},
					maxFoodLevel = 90,
					maxConcurrentEnemyUnits = 8,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 2, unitIndex = 9}
				},
			},
		},
		[15] = {
			x = 5000,
			y = 120,
			miniBossLevel = true,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 7, index = 5},
						{amount = 4, index = 6},
						{amount = 3, index = 7},
						{amount = 4, index = 8},
						{amount = 2, index = 9},
					},
					maxFoodLevel = 100,
					maxConcurrentEnemyUnits = 9,
				},
				
			},
		},
	},
	--World 3 - Christmas
	[3] = {
		maxDemoLevel = 5,
		icon = "images/worlds/worlds-03.png",
		backgroundColor = {153/255,255/255,255/255},
		path = {easingX = easing.linear, easingY = easing.inOutQuad},
		asteroids = {
			[1] = "images/worlds/world03/asteroid_01.png",
			[2] = "images/worlds/world03/asteroid_02.png",
			[3] = "images/worlds/world03/asteroid_03.png",
			[4] = "images/worlds/world03/asteroid_04.png",
			[5] = "images/worlds/world03/asteroid_05.png",
		},
		defaultBackgroundID = "Christmas2",
		buildingList = {
			path = "images/game/world03/",
			[1] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_01_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_01_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_01_03.png",
				},
			},
			[2] = {
				health = 500,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_02_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_02_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_02_03.png",
				},
			},
			[3] = {
				health = 500,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_03_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_03_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_03_03.png",
				},
			},
			[4] = {
				health = 500,
				healthbarY = -140,
				offsetY = -20,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_04_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_04_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_04_03.png",
				},
			},
			[5] = {
				health = 500,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_05_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_05_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_05_03.png",
				},
			},
			[6] = {
				health = 800,
				healthbarY = -140,
				offsetY = -10,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_06_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_06_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_06_03.png",
				},
			},
			[7] = {
				health = 500,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "yogoBuildings/edifNavidad_07_01.png",
					conditionDamaged = "yogoBuildings/edifNavidad_07_02.png",
					conditionDestroyed = "yogoBuildings/edifNavidad_07_03.png",
				},
			},
			[8] = {
				health = 500,
				healthbarY = -220,
				offsetY = 20,
				images = {
					conditionPerfect = "ignaBuildings/edif-01-01.png",
					conditionDamaged = "ignaBuildings/edif-01-02.png",
					conditionDestroyed = "ignaBuildings/edif-01-03.png",
				},
			},
			[9] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-02-01.png",
					conditionDamaged = "ignaBuildings/edif-02-02.png",
					conditionDestroyed = "ignaBuildings/edif-02-03.png",
				},
			},
			[10] = {
				health = 500,
				healthbarY = -200,
				offsetY = -10,
				images = {
					conditionPerfect = "ignaBuildings/edif-03-01.png",
					conditionDamaged = "ignaBuildings/edif-03-02.png",
					conditionDestroyed = "ignaBuildings/edif-03-03.png",
				},
			},
			[11] = {
				health = 500,
				healthbarY = -200,
				offsetY = 40,
				images = {
					conditionPerfect = "ignaBuildings/edif-04-01.png",
					conditionDamaged = "ignaBuildings/edif-04-02.png",
					conditionDestroyed = "ignaBuildings/edif-04-03.png",
				},
			},
			[12] = {
				health = 500,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-05-01.png",
					conditionDamaged = "ignaBuildings/edif-05-02.png",
					conditionDestroyed = "ignaBuildings/edif-05-03.png",
				},
			},
			[13] = {
				health = 800,
				healthbarY = -140,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-06-01.png",
					conditionDamaged = "ignaBuildings/edif-06-02.png",
					conditionDestroyed = "ignaBuildings/edif-06-03.png",
				},
			},
			[14] = {
				health = 500,
				healthbarY = -200,
				offsetY = 0,
				images = {
					conditionPerfect = "ignaBuildings/edif-07-01.png",
					conditionDamaged = "ignaBuildings/edif-07-02.png",
					conditionDestroyed = "ignaBuildings/edif-07-03.png",
				},
			},
		},
		[1] = {
			x = 500,
			y = 0,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 30,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {1,2},
						},
						[2] = {
							[1] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 4, index = 2},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 2,},
						[2] = {type = "killUnits", amount = 6,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 1},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 1},
				},
			},
		},
		[2] = {
			x = 800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 30,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {1,2},
						},
						[2] = {
							[1] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 4, index = 2},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 2,},
						[2] = {type = "killUnits", amount = 6,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 2},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 2}
				},
			},
		},
		[3] = {
			x = 1100,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 40,
					lanes = 1,
					buildings = {
						[1] = {
							[1] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 3, index = 1},
						{amount = 4, index = 2},
						{amount = 2, index = 3},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 3,},
						[2] = {type = "killUnits", amount = 8,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 3},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 3}
				},
			},
		},
		[4] = {
			x = 1400,
			y = 40,
			gamemodeData = {
				mode = "war",
				
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {4,6},
							[2] = {1,6},
						},
						[2] = {
							[1] = {12,8},
							[2] = {12,13},
						},
					},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 7, index = 2},
						{amount = 3, index = 3},
						{amount = 3, index = 4},
					},
					maxConcurrentEnemyUnits = 2,
					goals = {
						[1] = {type = "killBuildings", amount = 4,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 4},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 4}
				},
			},
		},
		[5] = {
			x = 1700,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					maxFoodLevel = 60,
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,3,6},
						},
						[2] = {
							[1] = {12,10,8},
							[2] = {12,13,10},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					lanes = 2,
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 7, index = 2},
						{amount = 5, index = 3},
						{amount = 5, index = 4},
					},
					maxConcurrentEnemyUnits = 3,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 10,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 5}
				},
			},
		},
		[6] = {
			x = 2000,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,4,6},
							[2] = {2,4,6},
						},
						[2] = {
							[1] = {12,13,8},
							[2] = {13,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 2, index = 1},
						{amount = 5, index = 2},
						{amount = 9, index = 3},
						{amount = 4, index = 4},
						{amount = 3, index = 5},
					},
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 12,},
					},
					maxFoodLevel = 60,
				},
				
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 5}
				},
			},
		},
		[7] = {
			x = 2300,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {2,4,6},
							[2] = {1,2,6},
						},
						[2] = {
							[1] = {13,10,8},
							[2] = {12,10,8},
						},
					},
					fortressData = {
						[1] = {
							enabled = true,
							columns = 3,
						},
						[2] = {
							enabled = true,
							columns = 3,
						},
					},
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 3, index = 2},
						{amount = 3, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
					},
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 6,},
						[2] = {type = "killUnits", amount = 16,},
					},
					maxFoodLevel = 60,
				},
				
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 6}
				},
			},
		},
		[8] = {
			x = 2600,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,3,6},
							[2] = {1,5,4,6},
						},
						[2] = {
							[1] = {12,13,9,8},
							[2] = {12,11,10,8},
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
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 8, index = 2},
						{amount = 5, index = 3},
						{amount = 4, index = 4},
						{amount = 4, index = 5},
						{amount = 1, index = 6},
					},
					maxFoodLevel = 60,
					maxConcurrentEnemyUnits = 4,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 6}
				},
			},
		},
		[9] = {
			x = 2900,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 2, index = 5},
						{amount = 2, index = 6},
					},
					maxFoodLevel = 70,
					maxConcurrentEnemyUnits = 5,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 14,},
					},
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 7}
				},
			},
		},
		[10] = {
			x = 3200,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					lanes = 2,
					buildings = {
						[1] = {
							[1] = {1,2,4,6},
							[2] = {1,2,4,6},
						},
						[2] = {
							[1] = {12,13,10,8},
							[2] = {12,13,10,8},
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
					enemyUnits = {
						{amount = 5, index = 1},
						{amount = 5, index = 2},
						{amount = 8, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 6,
					goals = {
						[1] = {type = "killBuildings", amount = 8,},
						[2] = {type = "killUnits", amount = 12,},
					},
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 7}
				},
			},
		},
		[11] = {
			x = 3500,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 10, index = 2},
						{amount = 1, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 5,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 8}
				},
			},
		},
		[12] = {
			x = 3800,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 6, index = 1},
						{amount = 5, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 1, index = 8},
					},
					maxFoodLevel = 80,
					maxConcurrentEnemyUnits = 6,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 8}
				},
			},
		},
		[13] = {
			x = 4100,
			y = -40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 10, index = 1},
						{amount = 8, index = 2},
						{amount = 6, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 2, index = 7},
						{amount = 3, index = 8},
					},
					maxFoodLevel = 90,
					maxConcurrentEnemyUnits = 7,
				},
				minigameRewards = {
					{type = "unlockYogotar", worldIndex = 3, unitIndex = 9}
				},
			},
		},
		[14] = {
			x = 4400,
			y = 40,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 4, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 4, index = 5},
						{amount = 4, index = 6},
						{amount = 1, index = 7},
						{amount = 1, index = 8},
						{amount = 1, index = 9},
					},
					maxFoodLevel = 100,
					maxConcurrentEnemyUnits = 8,
				},
				startRewards = {
					{type = "unlockIgnarus", worldIndex = 3, unitIndex = 9}
				},
			},
		},
		[15] = {
			x = 5000,
			y = 120,
			miniBossLevel = true,
			gamemodeData = {
				mode = "war",
				overrideData = {
					enemyUnits = {
						{amount = 7, index = 1},
						{amount = 10, index = 2},
						{amount = 10, index = 3},
						{amount = 5, index = 4},
						{amount = 7, index = 5},
						{amount = 4, index = 6},
						{amount = 3, index = 7},
						{amount = 4, index = 8},
						{amount = 2, index = 9},
					},
					maxFoodLevel = 100,
					maxConcurrentEnemyUnits = 9,
				},
				
			},
		},
	},

}

worldsData[4] = extratable.deepcopy(worldsData[1])
worldsData[5] = extratable.deepcopy(worldsData[1])
worldsData[6] = extratable.deepcopy(worldsData[1])
worldsData[7] = extratable.deepcopy(worldsData[1])
worldsData[8] = extratable.deepcopy(worldsData[1])

return worldsData
