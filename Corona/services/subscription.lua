local players = require( "models.players" )
local plugin = require "plugin.simcard"
local json = require("json")
local logger = require("libs.helpers.logger")
local widget = require("widget")
local subscription = {}

-------------Variables

local mcc, mnc
local currentPlayer
local overlay
local checkCallback
-------------Constants
local PARAMS = {}
PARAMS.headers = {}
PARAMS.headers["Partner"]= "WW9nb21lLXlhcHBLaWRz"

local API_URL = "http://api.yapp.net/api.php"
local PID = 1

local TEMPLATE_GETCONFIG = "?pid=%s&mcc=%s&mnc=%s"
local TEMPLATE_GETSTATUS = "?pid=%s&action=check&msisdn=%s"
-------------Module functions

local function saveConfig(configData)

	currentPlayer.subscriptionConfig.subscriptionEcosystem = (configData.subscription_ecosystem == 1)
	currentPlayer.subscriptionConfig.urlMsisdn = configData.url_msisdn
	currentPlayer.subscriptionConfig.urlCheckSubscription = configData.url_check_suscription
	currentPlayer.subscriptionConfig.urlCancelSubscription = configData.url_cancel_suscription
	currentPlayer.subscriptionConfig.urlNoSubscriptor = configData.url_no_suscriptor
	currentPlayer.subscriptionConfig.showDisclaimer = (configData.show_disclaimer == 1)
	currentPlayer.subscriptionConfig.urlDisclaimer = configData.url_disclaimer
	currentPlayer.subscriptionConfig.renewalPeriod = tonumber(configData.renewal_period)
	currentPlayer.subscriptionConfig.trialPeriod = tonumber(configData.trial_period)
	currentPlayer.subscriptionConfig.freeService = (configData.free_service == 1)
	
	local subscriptionConfig = currentPlayer.subscriptionConfig

	local rawstring = ""
	for key, value in pairs(subscriptionConfig) do
		rawstring = rawstring .. tostring(value)
	end

	local hash = crypto.digest(crypto.md5, rawstring)

	currentPlayer.subscriptionHash = hash

	if currentPlayer.subscriptionData.subscriptionActive then
		global_isSubscribed = true
	end

	players.save(currentPlayer)	
end

local function checkSubscriptionStatus(msisdn)

	local function onCheckStatus(event)
		logger.log("[Subscription]Got Status")
		logger.log(event)
		local response = event.response
		local decoded = json.decode(response)

		currentPlayer.subscriptionData.msisdn = msisdn
		currentPlayer.subscriptionData.subscriptionActive = (decoded.subscription_active == 1)
		currentPlayer.subscriptionData.idSubscription = decoded.id_suscription
		currentPlayer.subscriptionData.startDate = decoded.dt_subscription
		currentPlayer.subscriptionData.lastChargeDate = decoded.dt_last_charge
		currentPlayer.subscriptionData.status = tonumber(decoded.b_status)

		players.save(currentPlayer)
		display.remove(overlay)
		logger.log(currentPlayer.subscriptionData)
	end

	logger.log("[Subscription]Checking Status")
	local body = string.format(TEMPLATE_GETSTATUS, PID, msisdn)

	local urlCheckSubscription = currentPlayer.subscriptionConfig.urlCheckSubscription
	network.request(urlCheckSubscription .. body, "GET", onCheckStatus, PARAMS)
end

local function checkSubscription(subscriptionConfig)

	local ecosystem = subscriptionConfig.subscriptionEcosystem
	local urlDisclaimer = subscriptionConfig.urlDisclaimer
	local freeService = subscriptionConfig.freeService

	if ecosystem then
		logger.log("[Subscription]Ecosystem availabe")

		if showDisclaimer then
			logger.log("[Subscription]Open webview with disclaimer")
		end

		if freeService then
			logger.log("[Subscription]Free service!")
			validSubscription = true
			global_isSubscribed = true
		else
			logger.log("[Subscription]Checking subscription")
			--------Checking Subscription
			logger.log("[Subscription]Getting MSISDN")
			plugin.enableWifi(false)
			
			local isMobileEnabled = plugin.enableMobileData(true)
			if isMobileEnabled then
				local urlMsisdn = subscriptionConfig.urlMsisdn

				local function onCompleteMsisdn(event)

					local response = event.response
					if event.isError then
						network.request(urlMsisdn .. "?pid="..PID, "GET", onCompleteMsisdn, PARAMS)
					else
						local decoded = json.decode(response)
						local msisdn = decoded.msisdn
						--local msisdn = "51945701928"
						--logger.log("MSDISDN: ".."51945701928")
						players.save(currentPlayer)
						logger.log(currentPlayer.subscriptionConfig)

						checkSubscriptionStatus(msisdn)
					end
				end

				timer.performWithDelay(2000, function()
					logger.log("[Subscription]Sending request for MSISDN")
					network.request(urlMsisdn .. "?pid="..PID, "GET", onCompleteMsisdn, PARAMS)
				end)

			end
		end
	else

		logger.log("[Subscription]No ecosystem available")
		if showDisclaimer then
			logger.log("[Subscription]Open webview with disclaimer")
		end

		subscription.setMessage("Servicio no disponible")
		plugin.openWebview(urlDisclaimer)
		--plugin.openWebview("http://192.168.15.67")
		if freeService then
			logger.log("[Subscription]Free service!")
			currentPlayer.subscriptionData.subscriptionActive = true
		end
	end
end

local function requestConfigData()

	local function onRequestComplete(event)
		local response = event.response
		local decoded = json.decode(response)

		saveConfig(decoded)
		checkSubscription(currentPlayer.subscriptionConfig)
	end

	local body = string.format(TEMPLATE_GETCONFIG, PID, mcc, mnc)
	network.request(API_URL .. body, "GET", onRequestComplete, PARAMS)

end

local function getSimInfo()

	local simInformation = plugin.getTelephonyData()

	local networkOperator = simInformation.NetworkOperator or "00000"
	--local networkOperator = "71606"
	mcc = string.sub(networkOperator, 0, 3)
	mnc = string.sub(networkOperator, 4, 5)
end

function subscription.check(onCheck)

	overlay = display.newGroup()
	overlay.x = display.contentCenterX
	overlay.y = display.contentCenterY

	local overlaybg = display.newRect(0, 0, display.contentWidth, display.contentHeight)
	overlaybg:setFillColor(0, 0.5)
	overlay:insert(overlaybg)

	local overlayText = display.newText("Verificando subscripción...", 0, 0, "VAGRounded", 42)
	overlay.label = overlayText
	overlay:insert(overlayText)

	currentPlayer = players.getCurrent()
	getSimInfo()
	requestConfigData()

end

function subscription.setMessage(messageString)
	overlay.label.text = messageString
end

return subscription