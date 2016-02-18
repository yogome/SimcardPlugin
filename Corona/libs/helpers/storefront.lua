-------------------------------------------- Store front
local path = ...
local folder = path:match("(.-)[^%.]+$")
local localization = require( folder.."localization" )
local extraTable = require( folder.."extratable" )
local extrajson = require( folder.."extrajson" )
local database = require( folder.."database" )
local logger = require( folder.."logger" )
local store = require("store") 
local json = require("json")
local mime = require("mime")

local storeModule = {
	productsLoaded = false
}
-------------------------------------------- Variables
local initialized
local targetStore
local loadedProducts
local productsList
local purchaseComplete
-------------------------------------------- Constants
local ENVIRONMENT = system.getInfo( "environment" )
local PATH_DATA = string.gsub(folder,"[%.]","/").."data/"
local DEFAULT_CURRENCY = {code = "USD", text = "$ %.02f"}

local STRINGID_PURCHASE_DISABLED_TITLE = "purchasesDisabledTitle"
local STRINGID_PURCHASE_DISABLED_TEXT = "purchasesDisabledText"
local STRINGID_PURCHASE_DISABLED_OK = "purchasesDisabledOk"

local CODE_ERRORS_VALIDATION = {
	["0"] = "No Error",
	["21000"] = "The App Store could not read the JSON object you provided.",
	["21002"] = "The data in the receipt-data property was malformed.",
	["21003"] = "The receipt could not be authenticated.",
	["21004"] = "The shared secret you provided does not match the shared secret on file for your account.",
	["21005"] = "The receipt server is not currently available.",
	["21006"] = "This receipt is valid but the subscription has expired.",
	["21007"] = "This receipt is a sandbox receipt, but it was sent to the production service for verification.",
	["21008"] = "This receipt is a production receipt, but it was sent to the sandbox service for verification.",
}

local STRINGS_LOCALIZATION = {
	["en"] = {
		[STRINGID_PURCHASE_DISABLED_TITLE] = "Purchases disabled",
		[STRINGID_PURCHASE_DISABLED_TEXT] = "Purchases are disabled externally, please check your settings.",
		[STRINGID_PURCHASE_DISABLED_OK] = "Ok",
	},
	["es"] = {
		[STRINGID_PURCHASE_DISABLED_TITLE] = "Compras deshabilitadas",
		[STRINGID_PURCHASE_DISABLED_TEXT] = "Las compras están deshabilitadas externamente, revisa tu configuración.",
		[STRINGID_PURCHASE_DISABLED_OK] = "Ok",
	},
	["pt"] = {
		[STRINGID_PURCHASE_DISABLED_TITLE] = "Compras desativadas",
		[STRINGID_PURCHASE_DISABLED_TEXT] = "Compras desativadas externamente. Por favor, veja suas configurações.",
		[STRINGID_PURCHASE_DISABLED_OK] = "Ok",
	}

}
local EVENT_PURCHASE_FAILED = {success = false, finishTransaction = function() end}
-------------------------------------------- Functions
local function storeListener(event)
	local jsonEvent = json.encode(event)
	logger.log(jsonEvent)
	
	local transaction = event.transaction
	local state = transaction.state
	local productID = transaction.productIdentifier
	event.success = state == "purchased" or state == "restored"
	
	if state == "purchased" then
		local purchasedData = {
			state = "purchased",
			productIdentifier = tostring(transaction.productIdentifier),
			receipt = tostring(transaction.receipt),
			transactionIdentifier = tostring(transaction.identifier),
			transactionDate = tostring(transaction.date),
		}
		database.config("storeListenerPurchased", mime.b64(json.encode(purchasedData)))
	elseif state == "restored" then
		local restoredData = {
			state = "restored",
			productIdentifier = tostring(transaction.productIdentifier),
			receipt = tostring(transaction.receipt),
			transactionIdentifier = tostring(transaction.identifier),
			transactionDate = tostring(transaction.date),
			originalReceipt = tostring(transaction.originalReceipt),
			originalTransactionIdentifier = tostring(transaction.originalIdentifier),
			originalDate = tostring(transaction.originalDate),
		}
		database.config("storeListenerRestored", mime.b64(json.encode(restoredData)))
    elseif state == "cancelled" then
        logger.log("Transaction was cancelled.")
	elseif state == "failed" then
		logger.error("Transaction failed. Error type: "..tostring(transaction.errorType)..(transaction.errorString and (" Message: "..tostring(transaction.errorString)) or ""))
    else
        logger.error("There was an unknown response")
    end
	
	event.finishTransaction = function()
		timer.performWithDelay(1, function()
			native.setActivityIndicator(false)
		end)
		store.finishTransaction(transaction)
	end
	
	if purchaseComplete[productID] and "function" == type(purchaseComplete[productID]) then
		purchaseComplete[productID](event)
	else
		event.finishTransaction()
	end
end

local function onProductsLoaded(event)
	loadedProducts = {}
	for index = 1, #event.products do
		local loadedProduct = event.products[index]
		
		for listIndex = 1, #productsList do
			local listProduct = productsList[listIndex]
			if listProduct.id == loadedProduct.productIdentifier then
				for key, value in pairs(listProduct) do
					loadedProduct[key] = value
				end
			end
		end
		
		loadedProducts[index] = loadedProduct
    end
	
	storeModule.productsLoaded = true
	local validAmount = event and event.products and #event.products or 0
	local invalidAmount = event and event.invalidProducts and #event.invalidProducts or 0
	
	logger.log(string.format("Loaded %d valid products from store.", validAmount))
	if invalidAmount > 0 then
		logger.error(string.format("There were %d invalid products.", invalidAmount))
	end
end

local function prepareProductList(productListIn)
	productsList = extraTable.deepcopy(productListIn)
	loadedProducts = extraTable.deepcopy(productListIn)
	
	local luaPriceMatrix
	local path = system.pathForFile(PATH_DATA.."pricematrix.json", system.ResourceDirectory )
	if pcall(function()
		local languageFile = io.open( path, "r" )
		local savedData = languageFile:read( "*a" )
		luaPriceMatrix = extrajson.decodeFixed(savedData)
		io.close(languageFile)
	end) then
		logger.log([[Read pricematrix.]])
	else
		logger.error([[pricematrix was not found.]])
	end
	
	if not luaPriceMatrix then
		logger.error([[pricematrix contains no data.]])
	end
	
	for index = 1, #productListIn do
		local product = productListIn[index]
		if product and product.priceTier then
			local price = luaPriceMatrix[product.priceTier][DEFAULT_CURRENCY.code]
			productsList[index].price = price
			loadedProducts[index].price = price
			
			productsList[index].priceLocale = DEFAULT_CURRENCY.code
			loadedProducts[index].priceLocale = DEFAULT_CURRENCY.code
			
			productsList[index].localizedPrice = string.format(DEFAULT_CURRENCY.text, price)
			loadedProducts[index].localizedPrice = string.format(DEFAULT_CURRENCY.text, price)
			
			productsList[index].productIdentifier = productsList[index].id
			loadedProducts[index].productIdentifier = productsList[index].id
		end
	end
end

local function addStrings()
	for language, data in pairs(STRINGS_LOCALIZATION) do
		for stringID, stringValue in pairs(data) do
			localization.addString(language, stringID, stringValue)
		end
	end
end

local function checkStoreType()
	if system.getInfo("platformName") == "Android" then
		if not pcall(function()
			store = require("plugin.google.iap.v3")
		end) then
			logger.error([[Could not load google.iap.v3 plugin. make sure it is set on build.settings]])
		end
	end
end
-------------------------------------------- Module Functions
function storeModule.prepareReceiptValidationData(receipt, password)
	local b64encode
	
	local startChar = receipt:sub(1,1)
	local endChar = receipt:sub(-1,-1)
	
	if startChar == "<" and endChar == ">" then -- Binary receipt
		receipt = receipt:sub(2,-2)
		receipt = receipt:gsub(" ","")

		local ascii = ""
		local receiptLenght = receipt:len()
		for index = 1, receiptLenght, 2 do 
			local hex = receipt:sub(index, index + 1)
			local dec = tonumber(hex, 16)
			if dec then 
				local char = string.char(dec)
				ascii = ascii..char
			end
		end

		b64encode = mime.b64(ascii)
	elseif startChar == "{" and endChar == "}" then -- JSON receipt
		b64encode = mime.b64(receipt)
	else
		local b64decoded = mime.unb64(receipt)
		if b64decoded then
			local luaTable = json.decode(b64decoded)
			if luaTable and "table" == type(luaTable) then -- b64 Encoded receipt
				b64encode = receipt
			else
				logger.error("Receipt was not valid")
			end
		else
			logger.error("Receipt was not valid")
		end
	end

	local postJson = json.encode({
		["receipt-data"] = b64encode,
		["password"] = password,
	})
	
	return postJson 
end 

function storeModule.validateReceipt(receipt, password, listener, productionMode)
	local link = productionMode and "https://buy.itunes.apple.com/verifyReceipt" or "https://sandbox.itunes.apple.com/verifyReceipt"
	local postData = storeModule.prepareReceiptValidationData(receipt, password)

	database.config("storeValidationReceipt", mime.b64(tostring(receipt)))
	local function localListener(event)
		local response = event.response 
		local decoded = json.decode(response)
		
		if decoded and "table" == type(decoded) and not event.isError then
			local statusDescription = CODE_ERRORS_VALIDATION[tostring(decoded.status)]
			logger.log("Receipt validation status: "..tostring(statusDescription))
			
			event.iTunesStatusCode = decoded.status
			event.iTunesResponse = decoded
			event.iTunesStatusCodeDescription = statusDescription
			
			if tostring(decoded.status) == "21006" then
				event.subscriptionExpired = true
			end
			
			if event.response and "string" == type(event.response) then
				database.config("storeValidationResponse", mime.b64(event.response))
			end
		else
			logger.error("There was an error contacting the validation host")
		end
		
		if listener and "function" == type(listener) then
			listener(event)
		end
	end 

	network.request(link, "POST", localListener, {body = postData})
end 

function storeModule.getSubscriptionList(discountLevel)
	discountLevel = discountLevel or 0
	local subscriptions = {}
	
	for index = 1, #loadedProducts do
		local product = loadedProducts[index]
		
		if product.type == "subscription" then
			if product.discountFamily == discountLevel then
				subscriptions[#subscriptions + 1] = product
			end
		end
	end
	
	extraTable.sortAscByKey(subscriptions, "durationMonths")
	
	return subscriptions
end

function storeModule.purchase(productID, onComplete)
	native.setActivityIndicator(true)
	timer.performWithDelay(1, function()
		if ENVIRONMENT ~= "simulator" then
			if initialized then
				if store.canMakePurchases then
					purchaseComplete[productID] = onComplete
					store.purchase({productID})
				else
					local alert = native.showAlert(localization.getString(STRINGID_PURCHASE_DISABLED_TITLE), localization.getString(STRINGID_PURCHASE_DISABLED_TEXT), {localization.getString(STRINGID_PURCHASE_DISABLED_OK)}, function(event)
						if "clicked" == event.action then
							timer.performWithDelay(1, function()
								native.setActivityIndicator(false)
							end)
							if onComplete then onComplete(EVENT_PURCHASE_FAILED) end
						end
					end)
				end
			else
				timer.performWithDelay(1, function()
					native.setActivityIndicator(false)
				end)
				if onComplete then onComplete(EVENT_PURCHASE_FAILED) end
				logger.error("Is not initialized.")
			end
		else
			local alert = native.showAlert( "Purchase test","Will purchase "..tostring(productID), { "Cancel", "Purchase" }, function(event)
				if "clicked" == event.action then
					timer.performWithDelay(1, function()
						native.setActivityIndicator(false)
					end)
					if onComplete then onComplete({success = event.index == 2, finishTransaction = function() end}) end
				end
			end)
		end
	end)
end

function storeModule.restore()
	if initialized then
		store.restore()
	else
		logger.error("Is not initialized.")
	end
end

function storeModule.initialize(productListIn)
	if not initialized then
		logger.log("Initializing.")
		checkStoreType()
		
		targetStore = store.target
		
		purchaseComplete = {}
		addStrings()
		prepareProductList(productListIn)

		if targetStore == "google" or targetStore == "apple" then
			store.init(targetStore, storeListener)
			
			if store.isActive then
				logger.log("Is now active and listener was added succesfully.")
				initialized = true
				if store.canLoadProducts then
					logger.log("Will load products from store.")
					local productsToLoad = {}
					for index = 1, #productListIn do
						productsToLoad[index] = productListIn[index].id
					end
					store.loadProducts( productsToLoad, onProductsLoaded )
				end
			else
				logger.error("Failed to initialize.")
			end
		else
			if ENVIRONMENT == "simulator" then
				initialized = true
				logger.log("Is now active in simulator mode.")
			else
				logger.error([[Target store "]]..tostring(targetStore)..[[" is not supported, could not initialize.]])
			end
		end
	else
		logger.log("Is already initialized.")
	end
end



return storeModule


