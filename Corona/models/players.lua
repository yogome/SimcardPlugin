---------------------------------------------- Player model
local database = require( "libs.helpers.database" ) 
local logger = require( "libs.helpers.logger" )
local offlinequeue = require( "libs.helpers.offlinequeue" )
local json = require( "json" )
local settings = require( "settings" )

local players = database.newModel("players", "Player")
--------------------------------------------- Variables
local initialized
--------------------------------------------- Constants 
--------------------------------------------- Functions
---------------------------------------------Module Functions
players.nilKeys = {
	"remoteID",
	"educationID",
} 

players.default = {
	id = nil,
	remoteID = nil,
	realName = "",
	characterName = "Player",
	age = 5,
	grade = 1,

	subscriptionConfig = {
		subscriptionEcosystem = false,
		urlMsisdn = "",
		urlCheckSubscription = "",
		urlCancelSubscription = "",
		urlNoSubscriptor = "",
		showDisclaimer = false,
		urlDisclaimer = "",
		renewalPeriod = 0,
		trialPeriod = 0,
		freeService = 0,
	},

	subscriptionData = {
		msisdn = "",
		subscriptionActive = false,
		idSubscription = "",
		startDate = "",
		lastChargeDate = "",
		status = 0
	},
	
	
	educationLevel = 1,
	educationData = {
		-- category
		math = {
			-- subcategory
			addition = {
				-- rank
				[1] = {
					-- level
					[1] = {hits = 0, correctAnswers = 0, wrongAnswers = 0},},

				currentRank = 1,
				currentLevel = 1,
			},
			subtraction = {
				-- rank
				[1] = {
					-- level
					[1] = {hits = 0, correctAnswers = 0, wrongAnswers = 0},},
				currentRank = 1,
				currentLevel = 1,
			},
			multiplication = {
				-- rank
				[1] = {
					-- level
					[1] = {hits = 0, correctAnswers = 0, wrongAnswers = 0},},
				currentRank = 1,
				currentLevel = 1,
			},
			division = {
				-- rank
				[1] = {
					-- level
					[1] = {hits = 0, correctAnswers = 0, wrongAnswers = 0},},
				currentRank = 1,
				currentLevel = 1,
			},
		},
	},
	gender = "none",
	coins = 0,
	hatIndex = 1,
	heroIndex = 1,
	firstRun = 1,
	firstMenu = false,
	timePlayed = 0,
	energy = 100,
	minigamesData = {
		[1] = {timesPlayed = 0, correctAnswers = 0, wrongAnswers = 0},
	},
	minigameData = {},
	units = {
		[1] = {bought = true, unlocked = true, upgradeLevel = 1},
		[2] = {bought = true, unlocked = false, upgradeLevel = 1},
		[3] = {bought = true, unlocked = false, upgradeLevel = 1},
		[4] = {bought = true, unlocked = false, upgradeLevel = 1},
		[5] = {bought = true, unlocked = false, upgradeLevel = 1},
		[6] = {bought = true, unlocked = false, upgradeLevel = 1},
		[7] = {bought = true, unlocked = false, upgradeLevel = 1},
		[8] = {bought = true, unlocked = false, upgradeLevel = 1},
		[9] = {bought = true, unlocked = false, upgradeLevel = 1},
	},
	heroes = {
		[1] = {bought = false, unlocked = false, upgradeLevel = 1},
		[2] = {bought = false, unlocked = false, upgradeLevel = 1},
		[3] = {bought = false, unlocked = false, upgradeLevel = 1},
		[4] = {bought = false, unlocked = false, upgradeLevel = 1},
		[5] = {bought = false, unlocked = false, upgradeLevel = 1},
		[6] = {bought = false, unlocked = false, upgradeLevel = 1},
		[7] = {bought = false, unlocked = false, upgradeLevel = 1},
		[8] = {bought = false, unlocked = false, upgradeLevel = 1},
		[9] = {bought = false, unlocked = false, upgradeLevel = 1},
		[10] = {bought = false, unlocked = false, upgradeLevel = 1},
	},
	badges = {
		data = {
			goodMinigames = 0,
			powercubeCount = 0,
			specialAttackCount = 0,
			killedUnits = 0,
			killedBosses = 0,
		},
		unlocked = {
			[1] = false,
		},
	},
	unlockedHats = {
		[1] = true,
	},
	unlockedWorlds = {
		[1] = {
			unlocked = true,
			watchedEnd = false,
			watchedStart = false,
			levels = {
				[1] = {unlocked = true, stars = 0},
			},
		},
	},
}

function players.initialize()
	if not initialized then
		logger.log("[Players] Initializing.")
		initialized = true
		local function newPlayerResultListener(event)
			if event.isError then
				logger.error("[Players] Could not be sent.")
			else
				if event.response then
					local luaResponse = json.decode(event.response)
					if luaResponse then

						local currentPlayer = players.getCurrent()
						if luaResponse.localID then
							currentPlayer = players.get(luaResponse.localID)
						end
						currentPlayer.remoteID = luaResponse.remoteID
						logger.log("[Players] Player "..currentPlayer.id.." was sent and received remoteID:"..currentPlayer.remoteID)
						players.save(currentPlayer)
					else
						logger.error("[Players] Player was sent but did not receive remote ID.")
						return false
					end
				end
			end
		end

		offlinequeue.addResultListener("newPlayerCreated", newPlayerResultListener)
		
		local function updatePlayerResultListener(event)
			if event.isError then
				logger.error("[Players] Could not be updated.")
			else
				if event.response then
					local luaResponse = json.decode(event.response)
					logger.log("[Players] Player was updated remotely.")
				end
			end
		end

		offlinequeue.addResultListener("updatePlayer", updatePlayerResultListener)
	end
end

function players:create(event)
	local player = event.target
	
end

function players:update(event)
	local player = event.target
	
	if player.remoteID then
		local bodyData = {
			email = database.config("currentUserEmail"),
			password = database.config("currentUserPassword"),
			gameName = settings.gameName,
			remoteID = player.remoteID,
			player = player,
			pushToken = database.config("pushToken")
		}

		local url = settings.server.hostname.."/users/player/update"
		offlinequeue.request(url, "POST", {
			headers = {
				["Content-Type"] = settings.server.contentType,
				["X-Parse-Application-Id"] = settings.server.appID,
				["X-Parse-REST-API-Key"] = settings.server.restKey,
			},
			body = json.encode(bodyData),
		}, "updatePlayer")
	end
end

function players:get(event)
	local player = event.target
	
end

players:addEventListener("create")
players:addEventListener("update")
players:addEventListener("get")

return players
