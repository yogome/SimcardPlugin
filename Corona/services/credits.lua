----------------------------------------------- Credits service
local localization = require( "libs.helpers.localization" )
local database = require ( "libs.helpers.database" )
local onboarding = require ( "data.onboarding" )
local sound = require("libs.helpers.sound")
local colors = require( "libs.helpers.colors" )
local settings = require("settings")
local director = require("libs.helpers.director")
local subscription = require("services.subscription")
local widget = require("widget")

local credits = {}

----------------------------------------------- Variables
local lastPromoGroup
local validSubscriptionCache 
----------------------------------------------- Constants
local AMOUNT_CREDITS_DEFAULT = 15 

local SCALE_PROMO = 1.5

local SIZE_BACKGROUND = {width = 560 * SCALE_PROMO, height = 160 * SCALE_PROMO}

local COLOR_GOOD = colors.convertFrom256({101, 133, 200})
local COLOR_BAD = colors.convertFrom256({232, 113, 109})

local SCALE_ICON = 0.45 * SCALE_PROMO
local SCALE_GOPRO_BUTTON = 0.4 * SCALE_PROMO

local SIZE_FONT_CREDITSLABEL = 25 * SCALE_PROMO
local SIZE_FONT_CREDITS = 40 * SCALE_PROMO

local OFFSET_CREDITS_TEXT = {x = -60 * SCALE_PROMO, y = -15 * SCALE_PROMO}
local OFFSET_ICON = {x = -40 * SCALE_PROMO, y = 0 * SCALE_PROMO}
local OFFSET_CREDITSLABEL = {x = -200 * SCALE_PROMO, y = 8 * SCALE_PROMO}
local OFFSET_GOPRO = {x = 155 * SCALE_PROMO, y = 0 * SCALE_PROMO}
----------------------------------------------- Functions 
local function createPromoGroup(promoGroup, previousScene)
	subscription.check(function(event)
		validSubscriptionCache = event.subscription == "valid"
		if not validSubscriptionCache and promoGroup and promoGroup.insert and "function" == type(promoGroup.insert) then
			local creditsAmount = credits.getAmount()
			local hasEnoughCredits = creditsAmount > 0
			
			promoGroup.alpha = 0

			local background = display.newRoundedRect(0, 0, SIZE_BACKGROUND.width, SIZE_BACKGROUND.height, 15)
			background:setFillColor(unpack((hasEnoughCredits and COLOR_GOOD or COLOR_BAD)))
			background.alpha = 0.9
			promoGroup:insert(background)

			local icon = display.newImage(hasEnoughCredits and "images/credits/creditos.png" or "images/credits/noCreditos.png", true)
			icon.x, icon.y = OFFSET_ICON.x, OFFSET_ICON.y
			icon.xScale, icon.yScale = SCALE_ICON, SCALE_ICON
			promoGroup:insert(icon)

			local creditsLabelOptions = {
				text = localization.getString(hasEnoughCredits and "onboardingCreditsLeft" or "onboardingNoCreditsLeft"),	 
				x = OFFSET_CREDITSLABEL.x,
				y = OFFSET_CREDITSLABEL.y,
				width = 140 * SCALE_PROMO,
				font = settings.fontName,   
				fontSize = SIZE_FONT_CREDITSLABEL,
				align = "right"
			}
			local creditsLabel = display.newText(creditsLabelOptions)
			promoGroup:insert(creditsLabel)

			local creditsTextOptions = {
				text = creditsAmount,	 
				x = OFFSET_CREDITS_TEXT.x,
				y = OFFSET_CREDITS_TEXT.y,
				width = 300 * SCALE_PROMO,
				font = settings.fontName,   
				fontSize = SIZE_FONT_CREDITS,
				align = "center"
			}
			local creditsText = display.newText(creditsTextOptions)
			promoGroup:insert(creditsText)
			promoGroup.creditsText = creditsText

			local goProOptions = {
				defaultFile = localization.format("images/credits/button_yogomepro_%s_01.png"),
				overFile = localization.format("images/credits/button_yogomepro_%s_02.png"),
				onPress = function()
					sound.play("onboardingClick")
				end,
				onRelease = function(event)
					local goProButton = event.target
					goProButton:setEnabled(false)

					local subscribeScene = require("scenes.login.subscribe")
					local thanksScene = require("scenes.login.thanks")

					local thanksSceneOptions = {
						titleText = localization.getString("thankYouForPurchase"),
						descriptionText = localization.getString("onboardingEndThanks"),
						imageParent = "images/onboarding/thanks/thanks_parent.png",
						nextSceneName = previousScene,
					}
					thanksScene.setupScene(thanksSceneOptions)
					subscribeScene.setNextScene(previousScene)
					
					local parentgate = require("scenes.login.parentgate")
					parentgate.setOnSuccess(nil)
					parentgate.setNextScene("scenes.login.subscribe")
					parentgate.setBackScene(previousScene)

					director.gotoScene("scenes.login.parentgate")
				end
			}
			local goProButton = widget.newButton(goProOptions)
			goProButton.xScale, goProButton.yScale = SCALE_GOPRO_BUTTON, SCALE_GOPRO_BUTTON
			goProButton.x, goProButton.y = OFFSET_GOPRO.x, OFFSET_GOPRO.y
			promoGroup:insert(goProButton)
			
			lastPromoGroup = promoGroup
			
			transition.to(promoGroup, {delay = 500, time = 600, alpha = 1, transition = easing.outQuad})
		end
	end)
	
end
----------------------------------------------- Module functions
function credits.getAmount()
	local amount = database.config(onboarding.minigameCredits.key)
	
	amount = validSubscriptionCache and AMOUNT_CREDITS_DEFAULT or amount
	
	if not amount then
		amount = AMOUNT_CREDITS_DEFAULT
		database.config(onboarding.minigameCredits.key, amount)
	end
	
	return amount
end

function credits.addCredits(amount)
	local creditsAmount = credits.getAmount()
	creditsAmount = creditsAmount + amount
	database.config(onboarding.minigameCredits.key, creditsAmount)
	
	if lastPromoGroup and lastPromoGroup.creditsText and lastPromoGroup.creditsText.scale and lastPromoGroup.creditsText.text then
		transition.cancel(lastPromoGroup.creditsText)
		lastPromoGroup.creditsText.text = creditsAmount
		lastPromoGroup.creditsText:scale(2, 2)
		transition.to(lastPromoGroup.creditsText, {xScale = 1, yScale = 1, time = 500})
	end
end

function credits.removeCredits(amount)
	local creditsAmount = credits.getAmount()
	creditsAmount = creditsAmount - amount
	creditsAmount = creditsAmount >= 0 and creditsAmount or 0
	database.config(onboarding.minigameCredits.key, creditsAmount)
	
	if lastPromoGroup and lastPromoGroup.creditsText and lastPromoGroup.creditsText.scale and lastPromoGroup.creditsText.text then
		transition.cancel(lastPromoGroup.creditsText)
		lastPromoGroup.creditsText.text = creditsAmount
		lastPromoGroup.creditsText:scale(2, 2)
		transition.to(lastPromoGroup.creditsText, {xScale = 1, yScale = 1, time = 500})
	end
end

function credits.getPromoGroup(options)
	options = options or {}
	
	local nextScene = options.nextScene or director.getSceneName("current")
	
	local promoGroup = display.newContainer(SIZE_BACKGROUND.width, SIZE_BACKGROUND.height)
	promoGroup.x = display.contentCenterX
	promoGroup.y = display.contentCenterY
	
	createPromoGroup(promoGroup, nextScene)
	
	return promoGroup
end

return credits
