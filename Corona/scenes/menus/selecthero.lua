----------------------------------------------- Hero select (Boy or girl)
local director = require( "libs.helpers.director" )
local widget = require("widget")
local players = require( "models.players" )
local sound = require( "libs.helpers.sound" )
local buttonList = require( "data.buttonlist" )
local hatlist = require( "data.hatlist" )
local spine = require( "spine_temp.spine" )
local herolist = require( "data.herolist" )
local settings = require( "settings" )
local colors = require( "libs.helpers.colors" )

local scene = director.newScene() 
----------------------------------------------- Variables
local buttonOK, buttonBack 
local hero, heroPanel, heroBase
local currentPlayer
local buttonsEnabled
local buttonNext, buttonPrevious
local currentItems
local buyPriceText, priceLabel
local selectedItem
local buttonBuy, buttonChoose
local selectedStroke
local nameTextField, namePlaceholder
local nameBackground
local coinsText
----------------------------------------------- Constants
local MARGIN_BUTTON = 20 
local WIDTH_BACKGROUND = 1024
local OFFSET_Y_HEROBASE = 190
local SCALE_TABS = 0.6
local OFFSET_X_TABS = -20

local ITEMS_MENU = {
	["boys"] = {
		[1] = {price = 0, image = "images/selecthero/boys/eagle.png", heroIndex = 1},
		[2] = {price = 500, image = "images/selecthero/boys/dynamo.png", heroIndex = 3},
		[3] = {price = 500, image = "images/selecthero/boys/justice.png", heroIndex = 4},
		[4] = {price = 500, image = "images/selecthero/boys/mac.png", heroIndex = 5},
		--[5] = {price = 900, image = "images/selecthero/boys/nao.png", heroIndex = 1},
		[5] = {price = 1000, image = "images/selecthero/boys/arthurius.png", heroIndex = 2},
	},
	["girls"] = {
		[1] = {price = 0, image = "images/selecthero/girls/luna.png", heroIndex = 6},
		[2] = {price = 500, image = "images/selecthero/girls/quarky.png", heroIndex = 8},
		[3] = {price = 500, image = "images/selecthero/girls/paz.png", heroIndex = 9},
		[4] = {price = 500, image = "images/selecthero/girls/camilla.png", heroIndex = 10},
		--[5] = {price = 900, image = "images/selecthero/girls/tomiko.png", heroIndex = 1},
		[5] = {price = 1000, image = "images/selecthero/girls/theffanie.png", heroIndex = 7},
	},
	["hats"] = {
		[1] = {price = 0, image = "images/hats/s0a.png"},
		[2] = {price = 500, image = "images/hats/s1a.png"},
		[3] = {price = 500, image = "images/hats/s2a.png"},
		[4] = {price = 500, image = "images/hats/s3a.png"},
		[5] = {price = 500, image = "images/hats/s4a.png"},
		[6] = {price = 500, image = "images/hats/s5a.png"},
		[7] = {price = 500, image = "images/hats/s6a.png"},
		[8] = {price = 500, image = "images/hats/s7a.png"},
		[9] = {price = 500, image = "images/hats/s8a.png"},
		[10] = {price = 500, image = "images/hats/s9a.png"},
		[11] = {price = 500, image = "images/hats/s10a.png"},
		[12] = {price = 500, image = "images/hats/s11a.png"},
		[13] = {price = 500, image = "images/hats/s12a.png"},
		[14] = {price = 500, image = "images/hats/s13a.png"},
		[15] = {price = 500, image = "images/hats/s14a.png"},
		[16] = {price = 500, image = "images/hats/s15a.png"},
		[17] = {price = 500, image = "images/hats/s16a.png"},
		[18] = {price = 500, image = "images/hats/s17a.png"},
		[19] = {price = 500, image = "images/hats/s18a.png"},
		[20] = {price = 500, image = "images/hats/s19a.png"},
		[21] = {price = 500, image = "images/hats/s20a.png"},
		[22] = {price = 500, image = "images/hats/s21a.png"},
		[23] = {price = 500, image = "images/hats/s22a.png"},
		[24] = {price = 500, image = "images/hats/s23a.png"},
		[25] = {price = 1000, image = "images/hats/s24a.png"},
		[26] = {price = 5000, image = "images/hats/s25a.png"},
		[27] = {price = 9000, image = "images/hats/s26a.png"},
	},
}
local SIZE_IMAGE_RECT = 190

local SCALE_ITEMS = 0.6
local SCALE_BUY_PRICE_BG = 0.5
local SCALE_BUTTON_BUY = 0.5
local SCALE_HERO_BASE = 0.8
local SCALE_COINS_BG = 0.4
local SCALE_NAME_BG = 0.4

local SIZE_FONT_PRICE = 43
local SIZE_FONT_COINS = 55
local SIZE_FONT_NAME = 50
local SIZE_FONT_NAMEFIELD = 50

local OFFSET_NAME_PANEL = {xRatio = 0.35, y = 64 + MARGIN_BUTTON}
local OFFSET_COINS_PANEL = {xRatio = 0.7, y = 64 + MARGIN_BUTTON}
local OFFSET_ITEM_PRICE = {x = 35, y = 80}
local OFFSET_IMAGERECT = {x = 0, y = -34}
local OFFSET_BUY_PRICE = {x = 0, y = 30}
local OFFSET_BUTTON_PRICE = {x = 0, y = 130}
local OFFSET_PRICE_LABEL_TEXT = {x = 30, y = 0}
local OFFSET_COINS_TEXT = {x = 20, y = 4}
local OFFSET_NAME_TEXT = {x = -30, y = 4}

local ITEMS_PER_PAGE = 6
----------------------------------------------- Functions
local function onReleasedBack()
	director.gotoScene("scenes.menus.home", {effect = "fade", time = 600})
end

local function onReleasedOK()
	director.gotoScene("scenes.menus.worlds", {effect = "fade", time = 600})
end

local function enterFrame()
	hero:update()
end

local function removeHero()
	Runtime:removeEventListener("enterFrame", enterFrame)
	display.remove(hero.group)
end

local function previewItem(tabName, itemIndex)
	if tabName == "girls" or tabName == "boys" then
		hero:setSkin(herolist[ITEMS_MENU[tabName][itemIndex].heroIndex].skinName)
	elseif tabName == "hats" then
		hero:setHat(string.format("hat_extra_%02d", (itemIndex - 1)))
	end
end

local function chooseItem(tabName, itemIndex)
	if tabName == "girls" or tabName == "boys" then
		currentPlayer.heroIndex = ITEMS_MENU[tabName][itemIndex].heroIndex
	elseif tabName == "hats" then
		currentPlayer.hatIndex = itemIndex
	end
end

local function itemTouched(item)
	sound.play("pop")
	selectedStroke.x = item.x + OFFSET_IMAGERECT.x * SCALE_ITEMS
	selectedStroke.y = item.y + OFFSET_IMAGERECT.y * SCALE_ITEMS
	selectedStroke.isVisible = true
	
	previewItem(item.tabName, item.index)
							
	buyPriceText.text = item.price
	if item.locked then
		priceLabel.isVisible = true
		buttonBuy.isVisible = true
		buttonChoose.isVisible = false
		if item.price > currentPlayer.coins then
			buyPriceText:setFillColor(unpack(colors.red))
			buttonBuy:setFillColor(unpack(colors.darkGray))
			selectedStroke.stroke = colors.red
		else
			buyPriceText:setFillColor(unpack(colors.black))
			buttonBuy:setFillColor(unpack(colors.white))
			selectedStroke.stroke = colors.lime
		end
	else
		selectedStroke.stroke = colors.cyan
		priceLabel.isVisible = false
		buttonBuy.isVisible = false
		buttonChoose.isVisible = true
	end
	selectedItem = item
end

local function buyTapped()
	if buttonsEnabled then
		if selectedItem and selectedItem.locked then
			if currentPlayer.coins >= selectedItem.price then
				currentPlayer.coins = currentPlayer.coins - selectedItem.price
				coinsText.text = currentPlayer.coins
				currentPlayer.unlockedItems[selectedItem.tabName][selectedItem.index] = {locked = false}
				heroPanel:populateHeroPanel(selectedItem.tabName, selectedItem.pageNumber)
				itemTouched(currentItems[selectedItem.panelIndex])
				-- Play buy sound
			else
				-- Play wrong sound
			end
		end
	end
end
local function chooseTapped()
	if buttonsEnabled then
		sound.play("pop")
		if selectedItem and not selectedItem.locked then
			chooseItem(selectedItem.tabName, selectedItem.index)
		end
	end
end

local function createHero(sceneGroup)
	local SPEED_ANIMATION = 0.02
	local FACTOR_ANIMATION = 0.5

	local json = spine.SkeletonJson.new()

	json.scale = 0.85
	local skinName = herolist[currentPlayer.heroIndex].skinName
	local skeletonPath = "units/hero/skeleton.json"
	local skeletonData = json:readSkeletonDataFile(skeletonPath)
	hero = spine.Skeleton.new(skeletonData)

	hero.flipX = false
	hero.flipY = false

	function hero:createImage(attachment)
		if string.find(attachment.name, "hat") then
			return display.newImage("units/hero/hats/"..attachment.name..".png")
		else
			return display.newImage("units/hero/"..self.skin.name.."/"..attachment.name..".png")
		end
	end

	hero:setToSetupPose()
	hero:setSkin(skinName)

	local animationStateData = spine.AnimationStateData.new(skeletonData)
	animationStateData:setMix("IDLE", "WALK", 0.05)
	animationStateData:setMix("WALK", "ATTACK", 0.05)
	animationStateData:setMix("ATTACK", "SPECIAL", 0.05)
	animationStateData:setMix("WIN", "WIN", 1)
	animationStateData:setMix("SPECIAL", "ATTACK", 0.05)
	local animationState = spine.AnimationState.new(animationStateData)

	function hero:update()
		animationState:update(SPEED_ANIMATION * FACTOR_ANIMATION)
		animationState:apply(self)
		self:updateWorldTransform()
	end

	function hero:setAnimation(animation)
		animationState:setAnimationByName(1, animation, true)
	end
	
	function hero:setHat(hatName)
		local attachHat = hero:getAttachment ("hat", "hat")
		attachHat.name = hatName
		hero:setSlotAttachment("hat", nil)
		hero:update()
		if hatName then
			hero:setSlotAttachment("hat", attachHat)
		end
	end
	
	hero:setAnimation("IDLE")
	hero.currentState = "IDLE"
	hero.group.x = heroBase.x
	hero.group.y = display.contentCenterY - 55
	hero.group.anchorChildren = true
	
	local attachHat = hero:getAttachment ("hat", "hat")
	attachHat.name = hatlist[currentPlayer.hatIndex].name
	hero:setSlotAttachment("hat", attachHat)
	Runtime:addEventListener("enterFrame", enterFrame)
	
	sceneGroup:insert(hero.group)
end

local function textboxOnComplete(value)
	currentPlayer.characterName = value
	scene.enableButtons()
end

local function nameListener( event )
	if event.phase == "began" then

	elseif event.phase == "ended" or event.phase == "submitted" then
		local text = event.target.text
		display.remove(nameTextField)
		textboxOnComplete(text)
		namePlaceholder.text = text
		namePlaceholder.isVisible = true
		native.setKeyboardFocus( nil )
	elseif event.phase == "editing" then

	end
end

local function createTextbox()
	nameTextField = native.newTextField( nameBackground.x + OFFSET_NAME_TEXT.x, nameBackground.y + OFFSET_NAME_TEXT.y, 300, SIZE_FONT_NAMEFIELD + 2)
	nameTextField:addEventListener( "userInput", nameListener )
	nameTextField.font = native.newFont( settings.fontName, 18 )
	nameTextField.align = "center"
	nameTextField.size = SIZE_FONT_NAMEFIELD
	nameTextField.inputType = "default"
	nameTextField.hasBackground = false
	nameTextField:setReturnKey("done")
	nameTextField:setTextColor(0)
	nameTextField.alpha = 1
	nameTextField.isEditable = true
	scene.view:insert(nameTextField)
	nameTextField.text = currentPlayer.characterName
end


local function editName()
	if buttonsEnabled then
		namePlaceholder.isVisible = false
		createTextbox()
		timer.performWithDelay(10, function()
			native.setKeyboardFocus(nameTextField)
		end)
		scene.disableButtons()
	end
end

----------------------------------------------- Module functions
function scene.enableButtons()
	buttonPrevious:setEnabled(true)
	buttonNext:setEnabled(true)
	buttonsEnabled = true
end

function scene.disableButtons()
	buttonPrevious:setEnabled(false)
	buttonNext:setEnabled(false)
	buttonsEnabled = false
end

function scene:create(event)
	local sceneGroup = self.view
	
	local scaleBackground = display.viewableContentWidth / WIDTH_BACKGROUND
	local background = display.newImage("images/selecthero/background.png")
	background.x = display.contentCenterX
	background.y = display.screenOriginY + display.viewableContentHeight
	background.xScale = scaleBackground
	background.yScale = scaleBackground
	background.anchorY = 1
	sceneGroup:insert(background)
	
	buttonList.back.onRelease = onReleasedBack
	buttonBack = widget.newButton(buttonList.back)
	buttonBack.x = display.screenOriginX + buttonBack.width * 0.5 + MARGIN_BUTTON
	buttonBack.y = display.screenOriginY + buttonBack.height * 0.5 + MARGIN_BUTTON
	sceneGroup:insert(buttonBack)

	buttonList.ok.onRelease = onReleasedOK
	buttonOK = widget.newButton(buttonList.ok)
	buttonOK.x = display.screenOriginX + display.viewableContentWidth - buttonOK.width * 0.5 - MARGIN_BUTTON
	buttonOK.y = display.screenOriginY + buttonOK.height * 0.5 + MARGIN_BUTTON
	sceneGroup:insert(buttonOK)
	
	heroPanel = display.newGroup()
	sceneGroup:insert(heroPanel)
	
	local panelBackground = display.newImage("images/selecthero/panel.png")
	panelBackground.anchorX = 1
	panelBackground.anchorY = 1
	panelBackground.x = display.screenOriginX + display.viewableContentWidth
	panelBackground.y = display.screenOriginY + display.viewableContentHeight
	local oldHeight = panelBackground.height
	local newHeight = display.viewableContentHeight * 0.8
	panelBackground.height = newHeight
	panelBackground.width = panelBackground.width * (panelBackground.height / oldHeight)
	heroPanel:insert(panelBackground)
	
	local tabBoy = display.newImage("images/selecthero/boys.png")
	tabBoy.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width + OFFSET_X_TABS
	tabBoy.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.78)
	tabBoy:scale(SCALE_TABS, SCALE_TABS)
	heroPanel:insert(tabBoy)
	
	local tabGirl = display.newImage("images/selecthero/girls.png")
	tabGirl.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width + OFFSET_X_TABS
	tabGirl.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.55)
	tabGirl:scale(SCALE_TABS, SCALE_TABS)
	heroPanel:insert(tabGirl)
	
	local tabHats = display.newImage("images/selecthero/sombreros.png")
	tabHats.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width + OFFSET_X_TABS
	tabHats.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.32)
	tabHats:scale(SCALE_TABS, SCALE_TABS)
	heroPanel:insert(tabHats)
	
	selectedStroke = display.newRoundedRect(0,0, SIZE_IMAGE_RECT, SIZE_IMAGE_RECT, 50 )
	selectedStroke:scale(SCALE_ITEMS * 0.95, SCALE_ITEMS * 0.95)
	selectedStroke.isVisible = false
	selectedStroke.stroke = colors.lime
	selectedStroke.fill = {0, 0}
	selectedStroke.strokeWidth = 14
	heroPanel:insert(selectedStroke)
	
	heroPanel.tabs = {
		["boys"] = tabBoy,
		["girls"] = tabGirl,
		["hats"] = tabHats,
	}
	
	function heroPanel:populateHeroPanel(tabName, pageNumber)
		self.currentPage = pageNumber
		local selectedItems = ITEMS_MENU[tabName]
		
		hero:setSkin(herolist[currentPlayer.heroIndex].skinName)
		if tabName ~= "hats" then
			hero:setHat(string.format("hat_extra_%02d", currentPlayer.hatIndex - 1))
		end
		
		if selectedItems then
			currentPlayer.unlockedItems = currentPlayer.unlockedItems or {}
			currentPlayer.unlockedItems[tabName] = currentPlayer.unlockedItems[tabName] or {}
			if currentItems then
				for index = #currentItems, 1, -1 do
					display.remove(currentItems[index])
					currentItems[index] = nil
				end
			end
			currentItems = {}
			
			local maxPages = math.ceil(#selectedItems / ITEMS_PER_PAGE)
			if #selectedItems > ITEMS_PER_PAGE then
				buttonNext.isVisible = true
				buttonPrevious.isVisible = true
				if pageNumber == 1 then
					buttonPrevious.isVisible = false
				elseif pageNumber == maxPages then
					buttonNext.isVisible = false
				end
			else
				buttonNext.isVisible = false
				buttonPrevious.isVisible = false
			end
			
			local itemCounter = 1
			for itemIndex = (ITEMS_PER_PAGE * (pageNumber - 1)) + 1, (ITEMS_PER_PAGE * pageNumber) do
				local item = selectedItems[itemIndex]
				if item then
					local playerItemData = currentPlayer.unlockedItems[tabName][itemIndex] or {locked = true}
					
					local xMultiplier = 1 - (itemCounter % 2)
					local yMultiplier = math.floor((itemCounter - 1)/2)
					local itemGroup = display.newGroup()
					itemGroup.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width * 0.65 + (panelBackground.width * 0.4 * (xMultiplier))
					itemGroup.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.8) + (yMultiplier * newHeight * 0.24)
					itemGroup.xScale = SCALE_ITEMS
					itemGroup.yScale = SCALE_ITEMS
					self:insert(itemGroup)
					
					itemGroup.price = item.price
					itemGroup.locked = playerItemData.locked
					itemGroup.tabName = tabName
					itemGroup.index = itemIndex
					itemGroup.pageNumber = pageNumber
					
					if itemGroup.locked then
						display.newImage(itemGroup, "images/selecthero/item.png")
						
						local priceTextOptions = {
							text = item.price,
							x = OFFSET_ITEM_PRICE.x,
							y = OFFSET_ITEM_PRICE.y,
							width = 120,
							align = "left",
							font = settings.fontName,
							fontSize = SIZE_FONT_PRICE,
						}
						local priceText = display.newText( priceTextOptions )
						priceText:setFillColor(0)
						itemGroup:insert(priceText)
					else
						display.newImage(itemGroup, "images/selecthero/item0.png")
					end
					
					local imageRect = display.newRoundedRect(OFFSET_IMAGERECT.x, OFFSET_IMAGERECT.y, SIZE_IMAGE_RECT, SIZE_IMAGE_RECT, 25 )
					imageRect.fill = { type = "image", filename = item.image }
					itemGroup:insert(imageRect)
					
					itemGroup:addEventListener("touch", function(event)
						if event.phase == "began" then
							itemTouched(itemGroup)
						end
					end)
					itemGroup.panelIndex = #currentItems + 1
					currentItems[itemGroup.panelIndex] = itemGroup
				end
				itemCounter = itemCounter + 1
			end
		end
		priceLabel.isVisible = false
		selectedStroke.isVisible = false
		buttonChoose.isVisible = false
		buttonBuy.isVisible = false
		selectedStroke:toFront()
	end

	function heroPanel:selectTab(tabName, silent)
		if buttonsEnabled or silent then
			local selectedTab = self.tabs[tabName]
			if selectedTab then
				if not silent then sound.play("pop") end
				self.selectedTab = tabName
				self:populateHeroPanel(tabName, 1)
				for tanName, tab in pairs(self.tabs) do
					tab:toBack()
				end
				selectedTab:toFront()
			end
		end
	end
	
	tabBoy:addEventListener("tap", function()
		heroPanel:selectTab("boys")
	end)
	tabGirl:addEventListener("tap", function()
		heroPanel:selectTab("girls")
	end)
	tabHats:addEventListener("tap", function()
		heroPanel:selectTab("hats")
	end)
	
	local function onReleasedNext()
		if buttonsEnabled then
			heroPanel:populateHeroPanel(heroPanel.selectedTab, heroPanel.currentPage + 1)
		end
	end

	local function onReleasedPrevious()
		if buttonsEnabled then
			heroPanel:populateHeroPanel(heroPanel.selectedTab, heroPanel.currentPage - 1)
		end
	end
	
	buttonList.next.onRelease = onReleasedNext
	buttonNext = widget.newButton(buttonList.next)
	buttonNext.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width * 0.25
	buttonNext.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.12)
	sceneGroup:insert(buttonNext)
	
	buttonList.previous.onRelease = onReleasedPrevious
	buttonPrevious = widget.newButton(buttonList.previous)
	buttonPrevious.x = display.screenOriginX + display.viewableContentWidth - panelBackground.width * 0.65
	buttonPrevious.y = display.screenOriginY + display.viewableContentHeight - (newHeight * 0.12)
	sceneGroup:insert(buttonPrevious)
	
	local coinsPanel = display.newGroup()
	coinsPanel.x = display.screenOriginX + (display.viewableContentWidth * OFFSET_COINS_PANEL.xRatio)
	coinsPanel.y = display.screenOriginY + OFFSET_COINS_PANEL.y
	sceneGroup:insert(coinsPanel)
	
	local coinsPanelBg = display.newImage("images/selecthero/coin.png")
	coinsPanelBg:scale(SCALE_COINS_BG, SCALE_COINS_BG)
	coinsPanel:insert(coinsPanelBg)
	
	local priceTextOptions = {
		text = "0",
		x = OFFSET_COINS_TEXT.x,
		y = OFFSET_COINS_TEXT.y,
		width = 180,
		align = "left",
		font = settings.fontName,
		fontSize = SIZE_FONT_COINS,
	}
	coinsText = display.newText( priceTextOptions )
	coinsText:setFillColor(0)
	coinsPanel:insert(coinsText)
	
	nameBackground = display.newImage("images/selecthero/name.png")
	nameBackground.x = display.screenOriginX + (display.viewableContentWidth * OFFSET_NAME_PANEL.xRatio)
	nameBackground.y = display.screenOriginY + OFFSET_NAME_PANEL.y
	nameBackground:scale(SCALE_NAME_BG, SCALE_NAME_BG)
	nameBackground:addEventListener("tap", editName)
	sceneGroup:insert(nameBackground)
	
	local nameTextOptions = {
		x = nameBackground.x + OFFSET_NAME_TEXT.x,
		y = nameBackground.y + OFFSET_NAME_TEXT.y,
		align = "center",
		font = settings.fontName,
		text = "textholder",
		fontSize = SIZE_FONT_NAME,
	}
	
	namePlaceholder = display.newText(nameTextOptions)
	namePlaceholder:setFillColor(0)
	sceneGroup:insert(namePlaceholder)
	
	heroBase = display.newImage("images/selecthero/base.png")
	heroBase.x = display.screenOriginX + (display.viewableContentWidth - panelBackground.width) * 0.45
	heroBase.y = display.contentCenterY + OFFSET_Y_HEROBASE
	heroBase:scale(SCALE_HERO_BASE, SCALE_HERO_BASE)
	sceneGroup:insert(heroBase)
	
	priceLabel = display.newGroup()
	priceLabel.x = heroBase.x + OFFSET_BUY_PRICE.x
	priceLabel.y = heroBase.y + OFFSET_BUY_PRICE.y
	sceneGroup:insert(priceLabel)
	
	local priceBg = display.newImage("images/selecthero/price.png")
	priceBg:scale(SCALE_BUY_PRICE_BG, SCALE_BUY_PRICE_BG)
	priceLabel:insert(priceBg)
	
	local priceTextOptions = {
		text = "PRICE",
		x = OFFSET_PRICE_LABEL_TEXT.x,
		y = OFFSET_PRICE_LABEL_TEXT.y,
		font = settings.fontName,
		fontSize = SIZE_FONT_PRICE,
	}
						
	buyPriceText = display.newText(priceTextOptions)
	buyPriceText:setFillColor(0)
	priceLabel:insert(buyPriceText)
	
	buttonBuy = display.newImage("images/selecthero/buy.png")
	buttonBuy.x = heroBase.x + OFFSET_BUTTON_PRICE.x
	buttonBuy.y = heroBase.y + OFFSET_BUTTON_PRICE.y
	buttonBuy:scale(SCALE_BUTTON_BUY, SCALE_BUTTON_BUY)
	buttonBuy:addEventListener("tap", buyTapped)
	sceneGroup:insert(buttonBuy)
	
	buttonChoose = display.newImage("images/selecthero/seleccionar.png")
	buttonChoose.x = heroBase.x + OFFSET_BUTTON_PRICE.x
	buttonChoose.y = heroBase.y + OFFSET_BUTTON_PRICE.y
	buttonChoose:scale(SCALE_BUTTON_BUY, SCALE_BUTTON_BUY)
	buttonChoose:addEventListener("tap", chooseTapped)
	sceneGroup:insert(buttonChoose)
end

function scene:destroy()
	
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		currentPlayer = players.getCurrent()
		createHero(sceneGroup)
		namePlaceholder.text = currentPlayer.characterName
		coinsText.text = currentPlayer.coins
		heroPanel:selectTab("boys", true)
		nameBackground:toFront()
		namePlaceholder:toFront()
		self.disableButtons()
	elseif ( phase == "did" ) then
		self.enableButtons()
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		self.disableButtons()
	elseif ( phase == "did" ) then
		removeHero()
		players.save(currentPlayer)
	end
end

----------------------------------------------- Execution
scene:addEventListener( "create", scene )
scene:addEventListener( "destroy", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "show", scene )

return scene
