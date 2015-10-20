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
        logger.log("[Storefront] Transaction was cancelled.")
	elseif state == "failed" then
		logger.error("[Storefront] Transaction failed. Error type: "..tostring(transaction.errorType)..(transaction.errorString and (" Message: "..tostring(transaction.errorString)) or ""))
    else
        logger.error("[Storefront] There was an unknown response")
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
	
	logger.log(string.format("[Storefront] Loaded %d valid products from store.", validAmount))
	if invalidAmount > 0 then
		logger.error(string.format("[Storefront] There were %d invalid products.", invalidAmount))
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
		logger.log([[[Storefront] Read pricematrix.]])
	else
		logger.error([[[Storefront] pricematrix was not found.]])
	end
	
	if not luaPriceMatrix then
		logger.error([[[Storefront] pricematrix contains no data.]])
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
				logger.error("[Storefront] Receipt was not valid")
			end
		else
			logger.error("[Storefront] Receipt was not valid")
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
			logger.log("[Storefront] Receipt validation status: "..tostring(statusDescription))
			
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
			logger.error("[Storefront] There was an error contacting the validation host")
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
				logger.error("[Storefront] Is not initialized.")
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
		logger.error("[Storefront] Is not initialized.")
	end
end

function storeModule.initialize(productListIn)
	if not initialized then
		logger.log("[Storefront] Initializing.")
		targetStore = store.target
		
		purchaseComplete = {}
		addStrings()
		prepareProductList(productListIn)

		if targetStore == "google" or targetStore == "apple" then
			store.init(targetStore, storeListener)
			
			if store.isActive then
				logger.log("[Storefront] Is now active and listener was added succesfully.")
				initialized = true
				if store.canLoadProducts then
					logger.log("[Storefront] Will load products from store.")
					local productsToLoad = {}
					for index = 1, #productListIn do
						productsToLoad[index] = productListIn[index].id
					end
					store.loadProducts( productsToLoad, onProductsLoaded )
				end
			else
				logger.error("[Storefront] Failed to initialize.")
			end
		else
			if ENVIRONMENT == "simulator" then
				initialized = true
				logger.log("[Storefront] Is now active in simulator mode.")
			else
				logger.error([[[Storefront] Target store "]]..tostring(targetStore)..[[" is not supported, could not initialize.]])
			end
		end
	else
		logger.log("[Storefront] Is already initialized.")
	end
end

--function storeModule.test()
--	local receiptData = "<7b0a0922 7369676e 61747572 6522203d 20224170 3532564b 64717743 50455561 6e52574f 69704573 50435230 7331594c 6f675276 72737968 6b353848 31766877 64673132 4345744e 44685545 66327a78 6d6a4748 68535837 41714955 7478425a 6e546259 4f52596e 63716b54 4a386e59 76583050 4e574950 694d724f 6251346a 54686558 2b4e6755 41655650 73566a47 516f5275 5a2f4b51 4849724d 48434571 7538416b 4f485154 51323239 614c6b68 7255316e 766a6147 33764b32 30304141 4144567a 43434131 4d776767 49376f41 4d434151 49434342 7570342b 5041686d 2f4c4d41 30474353 71475349 62334451 45424251 55414d48 3878437a 414a4267 4e564241 5954416c 56544d52 4d774551 59445651 514b4441 70426348 42735a53 424a626d 4d754d53 59774a41 59445651 514c4442 31426348 42735a53 42445a58 4a306157 5a705932 46306157 39754945 46316447 6876636d 6c306554 457a4d44 45474131 55454177 77715158 42776247 55676156 5231626d 567a4946 4e306233 4a6c4945 4e6c636e 52705a6d 6c6a5958 52706232 34675158 56306147 39796158 52354d42 34584454 45304d44 59774e7a 41774d44 49794d56 6f584454 45324d44 55784f44 45344d7a 457a4d46 6f775a44 456a4d43 45474131 55454177 77615548 56795932 68686332 56535a57 4e6c6158 42305132 56796447 6c6d6157 4e686447 5578477a 415a4267 4e564241 734d456b 46776347 786c4947 6c556457 356c6379 42546447 39795a54 45544d42 45474131 55454367 774b5158 42776247 55675357 356a4c6a 454c4d41 6b474131 55454268 4d435656 4d77675a 38774451 594a4b6f 5a496876 634e4151 45424251 41446759 30414d49 474a416f 4742414d 6d544575 4c676a69 6d4c7752 4a787931 6f456630 6573554e 44564549 65367744 736e6e61 6c313468 4e427431 76313935 58366e39 33594f37 6769336f 72505375 78394435 3534536b 4d702b53 61796738 346c5463 33363255 746d594c 70576e62 33346e71 79477839 4b425654 79354f47 56346c6a 45314f77 432b6f54 6e524d2b 514c5243 6d654e78 4d62505a 68533437 542b655a 74444568 56423975 736b332b 4a4d3243 6f676677 6f374167 4d424141 476a636a 42774d42 30474131 55644467 51574242 534a6145 654e7571 39446636 5a664e36 3846652b 49327532 32737344 414d4267 4e564852 4d424166 3845416a 41414d42 38474131 55644977 51594d42 61414644 5964364f 4b646774 4942474c 55796177 37585177 75525745 4d364d41 34474131 55644477 45422f77 51454177 49486744 41514267 6f71686b 69473932 4e6b4267 55424241 49464144 414e4267 6b71686b 69473977 30424151 55464141 4f434151 45416561 4a563255 35317278 66637141 41653543 322f6645 57384b55 6c34694f 346c4d75 7461374e 36587a50 31705a49 7a314e6b 6b437449 49776579 4e6a3555 5259484b 2b486a52 4b535539 524c6775 4e6c306e 6b667871 4f62694d 636b7752 75644b53 7136394e 496e725a 79434436 3652344b 37376e62 396c4d54 41425353 596c734b 74386f4e 746c6867 522f316b 6a535352 5163486b 74734463 53695147 4b4d646b 536c7034 41795866 37766e48 50426534 79437759 56325070 534e3034 6b626f69 4a337042 6c787347 77562f5a 6c4c3236 4d327565 59484b59 43755868 64714677 7856676d 35326833 6f654a4f 4f742f76 59344563 51713765 71486d36 6d30335a 39623750 527a594d 324b4758 48446d4f 4d6b3776 4470654d 566c4c44 50534759 7a312b55 33734478 4a7a6562 53706261 4a6d5437 696d7a55 4b666767 45593778 78663463 7a664830 796a3577 4e7a5347 544f7651 3d3d223b 0a092270 75726368 6173652d 696e666f 22203d20 2265776f 4a496d39 79615764 70626d46 734c5842 31636d4e 6f59584e 6c4c5752 68644755 7463484e 30496941 39494349 794d4445 304c5445 794c5441 78494445 794f6a41 354f6a51 7a494546 745a584a 70593245 76544739 7a583046 755a3256 735a584d 694f776f 4a496e42 31636d4e 6f59584e 6c4c5752 68644755 7462584d 69494430 67496a45 304d6a67 304e4463 324d6a49 334d6a63 694f776f 4a496e56 75615846 315a5331 705a4756 7564476c 6d615756 79496941 39494349 7a4d5759 32596a63 314e7a45 304e7a64 6c4d4467 305a6d52 6b4f544d 324f5464 68596a4d 354e6a67 305a6a4d 775a6d46 6c5a474d 7a496a73 4b43534a 76636d6c 6e615735 68624331 30636d46 75633246 6a64476c 76626931 705a4349 67505341 694d5441 774d4441 774d4445 7a4d7a63 314d4451 7a4f4349 3743676b 695a5868 7761584a 6c637931 6b595852 6c496941 39494349 784e4449 344e4455 784d6a49 794e7a49 33496a73 4b43534a 30636d46 75633246 6a64476c 76626931 705a4349 67505341 694d5441 774d4441 774d4445 314d4463 344d6a49 314d5349 3743676b 6962334a 705a326c 75595777 74634856 79593268 68633255 745a4746 305a5331 74637949 67505341 694d5451 784e7a51 324e4455 344d7a41 774d4349 3743676b 69643256 694c5739 795a4756 794c5778 70626d55 74615852 6c625331 705a4349 67505341 694d5441 774d4441 774d4441 794f4467 344f444d 314f4349 3743676b 69596e5a 79637949 67505341 694d6a41 784e5334 774e4334 774e7a45 334e5441 694f776f 4a496e56 75615846 315a5331 325a5735 6b623349 74615752 6c626e52 705a6d6c 6c636949 67505341 694d455a 43526a64 454e6a6b 744d554d 304d4330 304f546b 354c546b 304f5545 744e5549 334e446c 464d4451 314e6a51 78496a73 4b43534a 6c654842 70636d56 7a4c5752 68644755 745a6d39 79625746 30644756 6b4c5842 7a644349 67505341 694d6a41 784e5330 774e4330 774e7941 784e7a6f 774d446f 794d6942 42625756 7961574e 684c3078 76633139 42626d64 6c624756 7a496a73 4b43534a 70644756 744c576c 6b496941 39494349 354e4459 794e4449 334e6a41 694f776f 4a496d56 3463476c 795a584d 745a4746 305a5331 6d62334a 74595852 305a5751 69494430 67496a49 774d5455 744d4451 744d4467 674d4441 364d4441 364d6a49 67525852 6a4c3064 4e564349 3743676b 6963484a 765a4856 6a644331 705a4349 67505341 69593239 744c6e6c 765a3239 745a5335 495a584a 765a584e 505a6b74 75623364 735a5752 6e5a5335 474d544a 4e623235 30614349 3743676b 69634856 79593268 68633255 745a4746 305a5349 67505341 694d6a41 784e5330 774e4330 774e7941 794d7a6f 774d446f 794d6942 4664474d 76523031 55496a73 4b43534a 76636d6c 6e615735 68624331 7764584a 6a614746 7a5a5331 6b595852 6c496941 39494349 794d4445 304c5445 794c5441 78494449 774f6a41 354f6a51 7a494556 30597939 48545651 694f776f 4a496d4a 705a4349 67505341 69593239 744c6e6c 765a3239 745a5335 495a584a 765a584e 505a6b74 75623364 735a5752 6e5a5349 3743676b 69634856 79593268 68633255 745a4746 305a5331 77633351 69494430 67496a49 774d5455 744d4451 744d4463 674d5459 364d4441 364d6a49 67515731 6c636d6c 6a595339 4d62334e 66515735 6e5a5778 6c637949 3743676b 69635856 68626e52 7064486b 69494430 67496a45 694f7770 39223b0a 0922656e 7669726f 6e6d656e 7422203d 20225361 6e64626f 78223b0a 0922706f 6422203d 20223130 30223b0a 09227369 676e696e 672d7374 61747573 22203d20 2230223b 0a7d>"
--	storeModule.validateReceipt(receiptData, "5de3ffa9e80c440bb081ccba085b4e9a")
--end
--storeModule.test()

return storeModule


