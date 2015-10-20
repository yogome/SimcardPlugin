local plugin = require "plugin.simcard"
local composer = require("composer")
local json = require "json"

local scene = composer.newScene()

local HEADERS = {}
HEADERS["Content-Type"] = "application/x-www-form-urlencoded"
HEADERS["Accept-Language"] = "en-US	"
HEADERS["Partner"]= "WW9nb21lLXlhcHBLaWRz"

local API_URL = "http://api.yapp.net/api.php"

local function getConfigData()

	local simInformation = plugin.getTelephonyData()

	local networkOperator = simInformation.NetworkOperator or "00000"
	local mcc = string.sub(networkOperator, 0, 3)
	local mnc = string.sub(networkOperator, 4, 5)

	local params = {}

	local productId = 1
	local body = string.format("id=%s&mcc=%s&mnc=%s", productId, mcc, mnc)

	params.headers = HEADERS
	params.body = body

	local message = display.newText(body, display.screenOriginX + 100, display.screenOriginY + 100, native.systemFont, 5)

	local function onRequestComplete(event)
		message.text = mcc .. mnc
		local response = event.response
		print(response)

		local decoded = json.decode(response)

		local UrlDisclaimer = decoded.url_disclaimer
		local freeService = decoded.free_service
		local showDisclaimer = decoded.show_disclaimer
		local subscriptionEcosystem = decoded.subscription_ecosystem

		-- --plugin.newExtendedWebView("http://192.168.15.70/index.html")
		if subscriptionEcosystem == "0" then
			if showDisclaimer == "1" then
				plugin.newExtendedWebView(UrlDisclaimer)
			end
		else
		 	plugin.newExtendedWebView("http://192.168.15.70/index.html")
		end
	end

	network.request(API_URL, "GET", onRequestComplete, params)

end

function scene:create()
	
end

function scene:show(event)

	getConfigData()
		
end

function scene:hide(event)

end

function scene:destroy()
end

scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

scene:show()

return scene