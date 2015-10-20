---------------------------------------------- Spineboy
local spine = require( "spine_temp.spine" )
local unitsData = require( "data.unitsData" )
local herolist = require( "data.herolist" )
local indicator = require( "libs.helpers.indicator" )
local extramath = require( "libs.helpers.extramath" )
local players = require( "models.players" )
local hatlist = require( "data.hatlist" )
local sound = require( "libs.helpers.sound" )
local extratable = require( "libs.helpers.extratable" )

local unitFactory = {
	TAG_PROJECTILE_TRANSITIONS = "tagProjectiles"
}
---------------------------------------------- Variables
---------------------------------------------- Constants
local SPEED_ANIMATION = 0.04
local FACTOR_ANIMATION = 0.5 -- Use this to slow down animations and view frames
--FACTOR_ANIMATION = 0.05

-- TODO somehow add different projectile speeds
local TIME_PROJECTILE = 800
local TIME_PROJECTILE_HALF = TIME_PROJECTILE * 0.5

local TIME_IDLE_SPAWN = 30
local TIME_IDLE_ATTACK = 20
local TIME_IDLE_SPECIAL = 10

local PATH_SKELETON = "units/%s/%s.json"
local PATH_IMAGES = "units/%s/"
local PATH_ICON = "units/%s/%s/head_a.png"
local PATH_PROJECTILE_ATTACK = "units/%s/%s/proyectile1.png"
local PATH_PROJECTILE_SPECIAL = "units/%s/%s/proyectile2.png"

local SKINS_WORLDS = {
	[1] = "world1",
	[2] = "world2",
	[3] = "world3",
	[4] = "world1",
	[5] = "world1",
	[6] = "world1",
	[7] = "world1",
	[8] = "world1",
}

local SOUNDS_EXPLOSION = {
	["explosion1"] = "",
	["mocoVerde"] = "",
	["splashPastel"] = "",
}
---------------------------------------------- Functions
local function getExplosion(explosionName)
	local explosionSheetData = { width = 128, height = 128, numFrames = 16 }
	local explosionSheet = graphics.newImageSheet( "images/game/explosions/"..explosionName..".png", explosionSheetData )

	local sequenceData = {
		{ name = "explode", sheet = explosionSheet, start = 1, count = 16, time = 600, loopCount = 1 },
	}
	local explosion = display.newSprite( explosionSheet, sequenceData )
	function explosion:sprite(event)
		if "ended" == event.phase then
			display.remove(self)
			self = nil
		end
	end
	explosion:addEventListener("sprite")
	explosion:play()
	
	--sound.play("")
	return explosion
end

local function fireProjectile(parameters)
	local who = parameters.who
	local projectile = parameters.projectile
	local arcHeight = parameters.attack.arcHeight
	local targetX = parameters.targetX or 0
	local targetY = parameters.targetY or 0
	local targetOffset = parameters.targetOffset or {x = 0, y = 0}
	
	local onImpact = parameters.onImpact
	
	local rotationData = parameters.attack.rotates or {}
	local rotationFrom = rotationData.from or 0
	local rotationTo = rotationData.to or 0
	local rotationEasing = rotationData.from or easing.linear
	local timeProjectile = parameters.attack.timeProjectile or TIME_PROJECTILE
	local timeProjectileHalf = timeProjectile * 0.5
	
	projectile.rotation = rotationFrom
	projectile.alpha = parameters.attack.alphaFrom or 1
	transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, time = timeProjectile, rotation = rotationTo, easing = rotationEasing})
	transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, time = timeProjectileHalf, alpha = parameters.attack.alphaTo or 1, easing = easing.inQuad})
	if projectile.linear then
		transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, time = timeProjectileHalf * 2, y = targetY + targetOffset.y, transition = easing.linear})
	else
		transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, time = timeProjectileHalf, y = projectile.y - arcHeight, transition = easing.outQuad})
		transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, delay = timeProjectileHalf, time = timeProjectileHalf, y = targetY + targetOffset.y, transition = easing.inQuad})
	end
	transition.to(projectile, {tag = unitFactory.TAG_PROJECTILE_TRANSITIONS, time = timeProjectile, x = targetX , onComplete = function()
		local explosion = getExplosion(projectile.explosionName)
		if projectile.impactSound then
			sound.play(projectile.impactSound)
		end
		explosion.x = projectile.x
		explosion.y = projectile.y
		if projectile.parent and projectile.parent.insert then
			projectile.parent:insert(explosion)
		end
		display.remove(projectile)
		onImpact()
	end})
end

local function updateMovement(unit)
--	if unit.isDefending then
--		if unit.currentFrameDefense == unit.unitData.defense.framePause then
--			unit:setAnimation("ATTACK") --todo: setAnimation to defense
--		end
--		unit.currentFrameDefense = unit.currentFrameDefense + 1 * FACTOR_ANIMATION
--		if unit.currentFrameDefense >= unit.unitData.defense.frameReset then
--			unit.isDefending = false
--			unit.currentFrameDefense = 0
--			unit:setAnimation("WALK")
--		end
--	else
		unit.group.x = unit.group.x + unit.currentSpeed * unit.direction
	--end
end

local function updateDefense(unit)
	if unit.currentFrameDefense == 0 then
		unit:setAnimation("ATTACK") --todo: setAnimation to defense
	end
	if unit.currentFrameDefense <= unit.unitData.defense.framePause then
		unit.currentFrameDefense = unit.currentFrameDefense + 1 * FACTOR_ANIMATION
	else
		unit.currentFrameDefense = unit.unitData.defense.framePause
		unit.paused = true
	end
end

local function updateSummon(unit, unitSummon) --attack to normal summon, special for special summon
	if unit.currentFrameSummon == 0 then
		unit:setAnimation("ATTACK")
	end
	
	unit.currentFrameSummon = unit.currentFrameSummon + 1 * FACTOR_ANIMATION
	unit.nextFrameToSummon = unit.nextFrameToSummon + 1 * FACTOR_ANIMATION
	if unit.currentFrameSummon >= unitSummon.frameReset then
		unit.currentFrameSummon = 0
		unit.nextFrameToSummon = 0
		unit.debugText:setFillColor(1)
	end
	
	if math.floor(unit.nextFrameToSummon) == unitSummon.summonFrame then
		local direction = unit.unitData.flipX and -1 or 1
		local spawnX = unit.group.x + (80 * direction)
		unit.spawnUnit(unitSummon.unitSummon, unit.worldIndex, unit.lane, unit.team, spawnX)
		unit.nextFrameToSummon = 0
		unit.isAttackingSpecial = false
	end
end

local function impactProjectile(unit)
	local attackDamage = unit.unitData.attack.damage * unit.attackMultiplier
	if unit.enemyTarget and not unit.enemyTarget.dead then
					local enemy = unit.enemyTarget
					local enemyEndurance = enemy.isDefending and enemy.unitData.defense.endurance or 1
					enemy.currentHealth = enemy.currentHealth - (attackDamage * enemyEndurance)
					if unit.unitData.attack.freeze then
						enemy.freeze = true
						enemy:setColor( 0.5, 0.5, 1, 0.78 )
						enemy.unfreeze = unit.unitData.attack.freeze
					end
					if unit.unitData.push and enemyEndurance == 1 and enemy.unitData.name ~= "building" then
						local forceDirection = enemy.team == 1 and -1 or 1
						enemy.group.x = enemy.group.x + (unit.unitData.push * forceDirection)
					end
					if enemy.currentHealth <= 0 then
						enemy.currentHealth = 0.005
						enemy.dead = true
						enemy.paused = false
						enemy:setAnimation("DEAD")
					end
					enemy.healthbar:setFillAmount(enemy.currentHealth / enemy.unitData.health)
				end
end

local function updateAttack(unit)
	if unit.currentFrameAttack == 0 then
		unit:setAnimation("ATTACK")
	end
	if unit.unitData.autoDestroy then
		unit.group.x = unit.group.x + unit.currentSpeed * 0.5 * unit.direction
	end
	unit.currentFrameAttack = unit.currentFrameAttack + 1 * FACTOR_ANIMATION
	if math.floor(unit.currentFrameAttack) == unit.nextAttackProjectileFrame  then
		if not unit.isShootingAttack then
			unit.isShootingAttack = true
			unit.projectilesFiredAttack = unit.projectilesFiredAttack + 1
			if unit.projectilesFiredAttack < unit.unitData.attack.projectiles then
				unit.nextAttackProjectileFrame = unit.unitData.attack.projectileFrame or unit.unitData.attack.projectileFrames and unit.unitData.attack.projectileFrames[unit.projectilesFiredAttack + 1]
			else
				unit.nextAttackProjectileFrame = unit.unitData.attack.projectileFrame or unit.unitData.attack.projectileFrames and unit.unitData.attack.projectileFrames[1]
				unit.projectilesFiredAttack = 0
			end

			local targetX = unit.enemyTarget.group.x
			local targetY = unit.enemyTarget.group.y
			local targetOffset = unit.enemyTarget.unitData.hitOffset
			local projectile = unit:getProjectile(unit.unitData.attack, unit.projectileAttackPath, targetX)
			fireProjectile({who = unit, projectile = projectile, attack = unit.unitData.attack, targetX = targetX, targetY = targetY, targetOffset = targetOffset, onImpact = function()
				impactProjectile(unit)
			end})
			if unit.unitData.autoDestroy then
				unit.currentHealth = 0.005
				unit.despawn = true
				--unit:setAnimation("DEAD")
			end
		end
		unit.debugText:setFillColor(1,0,0)
	else
		unit.isShootingAttack = false
		unit.debugText:setFillColor(1)
	end

	if unit.currentFrameAttack >= unit.unitData.attack.frameReset then
		unit.currentFrameAttack = 0
		unit.isShootingAttack = false
		unit.debugText:setFillColor(1)
		unit.projectilesFiredAttack = 0
	end
end

local function updateSpecial(unit)
	if unit.currentFrameSpecial == 0 then
		unit:setAnimation("SPECIAL")
	end
	unit.currentFrameSpecial = unit.currentFrameSpecial + 1 * FACTOR_ANIMATION
	if math.floor(unit.currentFrameSpecial) == unit.nextSpecialProjectileFrame then
		if not unit.isShootingSpecial then
			unit.isShootingSpecial = true
			unit.projectilesFiredSpecial = unit.projectilesFiredSpecial + 1
			if unit.projectilesFiredSpecial < unit.unitData.special.projectiles then
				unit.nextSpecialProjectileFrame = unit.unitData.special.projectileFrame or unit.unitData.special.projectileFrames and unit.unitData.special.projectileFrames[unit.projectilesFiredSpecial + 1]
			else
				unit.nextSpecialProjectileFrame = unit.unitData.special.projectileFrame or unit.unitData.special.projectileFrames and unit.unitData.special.projectileFrames[1]
				unit.projectilesFiredSpecial = 0
			end

			local targetX = unit.enemyTarget.group.x
			local targetY = unit.enemyTarget.group.y
			local targetOffset = unit.enemyTarget.unitData.hitOffset
			local projectile = unit:getProjectile(unit.unitData.special, unit.projectileSpecialPath, targetX)
			fireProjectile({who = unit, projectile = projectile, attack = unit.unitData.special, targetX = targetX, targetY = targetY, targetOffset = targetOffset, onImpact = function()
				impactProjectile(unit)
			end})
		end
		unit.debugText:setFillColor(1,0,0)
	else
		unit.isShootingSpecial = false
		unit.debugText:setFillColor(1)
	end

	if unit.currentFrameSpecial >= unit.unitData.special.frameReset then		
		unit.currentFrameSpecial = 0
		unit.isShootingSpecial = false
		unit.debugText:setFillColor(1)
		unit.projectilesFiredSpecial = 0
		unit.isAttackingSpecial = false
		unit.isAttacking = false
		
		unit.idleTime = unit.idleTimeSpecialDefault
		unit:setAnimation("IDLE")
	end
end

local function updateSpecialEnergy(unit)
	if unit.currentSpecialEnergy < unit.unitData.specialEnergy then
		unit.currentSpecialEnergy = unit.currentSpecialEnergy + 1
		if unit.currentSpecialEnergy >= unit.unitData.specialEnergy then
			if unit.enemyTarget then
				if not unit.glowSprite.enabled then
					unit.glowSprite:enable()
				end
			end
		end
	else
		if unit.enemyTarget then
			if not unit.glowSprite.enabled then
				unit.glowSprite:enable()
			end
		else
			if unit.glowSprite.enabled then
				unit.glowSprite:disable()
			end
		end
	end
end

local function checkUnitCollisions(unit)
	if unit.idleTime == 0 then
		local unitLane = unit.lane
		local laneUnits = unitLane.unitList
		local unitX = unit.group.x
		local effectiveRange = unitX + unit.unitData.attackRange * unit.direction

		local enemyUnit
		for index = 1, #laneUnits do
			local otherUnit = laneUnits[index]
			if unit.team ~= otherUnit.team then
				if not otherUnit.dead and not otherUnit.despawn then
					local otherX = otherUnit.group.x
					if unit.direction < 0 then
						if otherX >= effectiveRange and otherX <= unitX then
							enemyUnit = otherUnit
						end
					else
						if otherX <= effectiveRange and otherX >= unitX then
							enemyUnit = otherUnit
						end
					end
				end
			end
		end
		
		if not enemyUnit then
			unit.isAttacking = false
			unit.isAttackingSpecial = false
			if unit.enemyTarget then
				unit.enemyTarget = nil
				if unit.idleTime == 0 then
					unit.idleTime = unit.idleTimeAttackDefault
					unit:setAnimation("IDLE")
				end
			end
		else
			if enemyUnit ~= unit.enemyTarget then
				if not unit.isAttackingSpecial and not unit.isDefending then
					if unit.canDefense then
						unit.isDefending = true
					elseif unit.canSummon then
						unit.isSummoning = true
					else
						unit.isAttacking = true
					end
					unit.currentFrameAttack = 0
					unit.enemyTarget = enemyUnit
					unit:setAnimation("ATTACK")
				end
			else
				if not unit.isAttacking then
					if unit.isDefense then
						unit.isDefending = true
					else
						unit.isAttacking = true
					end
					unit.currentFrameAttack = 0
					unit.enemyTarget = enemyUnit
					unit:setAnimation("ATTACK")
				end
			end
		end
	end
end

local function addSpecialAttack(unit)
	local energySheetData = { width = 256, height = 256, numFrames = 16 }
	local energySheet = graphics.newImageSheet( "images/game/specialglow.png", energySheetData )

	local sequenceData = {
		{ name = "glow", sheet = energySheet, start = 1, count = 16, time = 400, loopCount = 0 },
	}

	local glowSprite = display.newSprite( energySheet, sequenceData )
	glowSprite.anchorY = 1
	glowSprite.x = 0
	glowSprite.y = 26
	glowSprite.xScale = 1
	glowSprite.yScale = 1
	
	function glowSprite:enable()
		glowSprite.enabled = true
		self:setSequence("glow")
		self:setFrame(1)
		self:play()
		self.isVisible = true
		sound.play("charge")
	end
	
	function glowSprite:disable()
		self.enabled = false
		self.isVisible = false
	end
	
	glowSprite:disable()
	unit.group:insert(glowSprite)
	unit.glowSprite = glowSprite
	
	unit.group:addEventListener("tap", function()
		if unit.unitData.special and not unit.dead then
			if unit.currentSpecialEnergy >= unit.unitData.specialEnergy and unit.enemyTarget then
				unit.currentSpecialEnergy = 0
				
				unit.glowSprite:disable()
				unit.isAttackingSpecial = true
				if not unit.unitData.summoner then
					unit:setAnimation("SPECIAL")
				else
					unit:setAnimation("ATTACK")
				end
				if unit.group.onSpecialComplete then
					unit.group.onSpecialComplete()
				end
			end
		end
	end)
end

local function createUnitSpine(unitIndex, worldIndex, lane, teamIndex, extraUnitData, skin, hatIndex) --unitOptions is the unit data you want change before creating the unit
	extraUnitData = extraUnitData or {}
	
	local upgradeLevel = extraUnitData.upgradeLevel or 1
	
	local function getRandomness(from, to)
		if extraUnitData.allowRandomness then
			return math.random(from, to)
		end
		return 0
	end
	
	local function addRandomnessToUnit(unit)
		unit.unitData.attackRange = unit.unitData.attackRange + getRandomness(-10,25)
		unit.unitData.coinsReward = unit.unitData.coinsReward + getRandomness(-2,2)
		unit.unitData.speed = unit.unitData.speed + (getRandomness(-10,10) * 0.01)
		unit.currentSpeed = unit.unitData.speed
		
		unit.unitData.health = unit.unitData.health + getRandomness(-10,10)
		unit.currentHealth = unit.unitData.health
		
		unit.idleTimeDefault = TIME_IDLE_SPAWN + getRandomness(-10,10)
		unit.idleTimeAttackDefault = TIME_IDLE_ATTACK + getRandomness(-10,10)
		unit.idleTimeSpecialDefault = TIME_IDLE_SPECIAL + getRandomness(-10,10)
	end

	local json = spine.SkeletonJson.new()
	
	local unitData = unitIndex == "hero" and unitsData["hero"].stats or unitsData[worldIndex][teamIndex][unitIndex].stats
	
	json.scale = unitData.scale
	local unitName = unitData.name
	local unitSpine = unitData.spine
	local skeletonPath = string.format(PATH_SKELETON, unitName, unitSpine)
	local skeletonData = json:readSkeletonDataFile(skeletonPath)
	local unit = spine.Skeleton.new(skeletonData)
	
	unit.unitData = extratable.deepcopy(unitData)
	unit.worldIndex = worldIndex
	unit.skinName = skin or SKINS_WORLDS[unit.worldIndex]
	unit.imagePath = string.format(PATH_IMAGES, unitName)..unit.skinName.."/"
	unit.projectileSpecialPath = string.format(PATH_PROJECTILE_SPECIAL, unitName, unit.skinName)
	unit.projectileAttackPath = string.format(PATH_PROJECTILE_ATTACK, unitName, unit.skinName)
	unit.unitData.health = unit.unitData.health + (upgradeLevel * unit.unitData.healthMultiplier * unit.unitData.health)
	unit.currentHealth = unit.unitData.health
	unit.currentSpeed = unit.unitData.speed + (unit.unitData.speedMultiplier * unit.unitData.speed * upgradeLevel)
	unit.currentSpecialEnergy = 0
	unit.currentProjectile = 1
	unit.unitIndex = unitIndex
	unit.direction = -(teamIndex * 2 - 3)
	unit.team = teamIndex
	unit.flipX = unit.team == 2 and true or false
	unit.flipY = false
	unit.currentFrameAttack = 0
	unit.currentFrameDefense = 0
	unit.currentFrameSummon = 0
	unit.currentFrameSpecial = 0
	unit.currentFrameFreeze = 0
	unit.lane = lane
	local extraAttack = unit.unitData.attack and (upgradeLevel * (unit.unitData.attack.multiplier or 0)) or 0
	unit.attackMultiplier = 1 + extraAttack
	local extraSpecial = unit.unitData.special and (upgradeLevel * (unit.unitData.special.multiplier or 0)) or 0
	unit.specialMultiplier = 1 + extraSpecial
	unit.enemyTarget = nil
	unit.dead = false
	unit.despawn = false
	unit.group.unit = unit
	unit.canSpecial = unit.unitData.special and extraUnitData.unitsCanSpecial
	unit.canAttack = unit.unitData.attack and true or false
	unit.canDefense = unit.unitData.defense and true or false
	unit.canSummon = unit.unitData.summoner and true or false
	unit.paused = false
	unit.freeze = false
	unit.unfreeze = 0
	unit.nextFrameToSummon = 0
	
	addRandomnessToUnit(unit)
	
	if 	unitData.flipX then
		unit.isInverted = true
		unit.flipX = not unit.flipX
	end
	
	unit.projectilesFiredAttack = 0
	unit.projectilesFiredSpecial = 0
	if unit.canAttack then
		unit.nextAttackProjectileFrame = unit.unitData.attack.projectileFrame or unit.unitData.attack.projectileFrames and unit.unitData.attack.projectileFrames[1]
	end
	if unit.canSpecial then
		unit.nextSpecialProjectileFrame = unit.unitData.special.projectileFrame or unit.unitData.special.projectileFrames and unit.unitData.special.projectileFrames[1]
	end
	
	function unit:createImage(attachment)
		if string.find(attachment.name, "hat") then
			return display.newImage("units/hero/hats/"..attachment.name..".png")
		else
			return display.newImage(self.imagePath..attachment.name..".png")
		end
	end
	
	unit:setToSetupPose()
	unit:setSkin(unit.skinName)
	
	if hatIndex then
		local currentPlayer = players.getCurrent()
		local attachHat = unit:getAttachment ("hat", "hat")
		attachHat.name = hatlist[currentPlayer.hatIndex].name
		unit:setSlotAttachment("hat", attachHat)
	end

	local animationStateData = spine.AnimationStateData.new(skeletonData)
	animationStateData:setMix("IDLE", "WALK", 0.05)
    animationStateData:setMix("WALK", "ATTACK", 0.05)
	animationStateData:setMix("ATTACK", "SPECIAL", 0.05)
	animationStateData:setMix("SPECIAL", "ATTACK", 0.05)
	local animationState = spine.AnimationState.new(animationStateData)

	local debugTextOptions = {
		x = 0,
		y = 20,
		width = 200,
		text = "0",
		fontSize = 25,
	}
	
	unit.debugText = display.newText(debugTextOptions)
	unit.debugText.isVisible = false
	unit.group:insert(unit.debugText)
	addSpecialAttack(unit)
	
	function unit:getProjectile(attackData, projectilePath, targetX)
		local projectile
		if attackData.usesSpriteSheet then
			local projectileData1 = attackData.usesSpriteSheet.contentSheet
			local projectileSheet = graphics.newImageSheet( projectilePath, projectileData1 )
			local data = attackData.usesSpriteSheet.sequenceData
			local sequenceData = {
				{ name = "projectile", sheet = projectileSheet, start = data.start, count = data.count, time = data.time, loopCount = data.loopCount},
			}
	
			projectile = display.newSprite( projectileSheet, sequenceData )
			projectile:play()
		else
			projectile = display.newImage(projectilePath)
		end
		projectile.xScale = self.unitData.scale * unit.direction * attackData.scale
		projectile.yScale = self.unitData.scale * attackData.scale
		local attackOffset = attackData.offset
		if attackData.appearUp then
			projectile.x = targetX - (attackOffset.x * unit.direction)
		else
			projectile.x = unit.group.x + (attackOffset.x * unit.direction)
		end
		projectile.y = unit.group.y + attackOffset.y
		unit.group.parent:insert(projectile)
		if self.isInverted then
			projectile.xScale = projectile.xScale * -1
		end
		if attackData.shootSound then
			sound.play(attackData.shootSound)
		end
		projectile.impactSound = attackData.impactSound
		projectile.explosionName = attackData.explosionName
		projectile.linear = attackData.linear or false
		return projectile
	end
	
	function unit:update()
		self.debugText.text = "IDLE "..self.idleTime.."\nAttacking "..tostring(self.currentFrameAttack)
		
		if not self.dead and not self.freeze then
			if self.idleTime == 0 then
				checkUnitCollisions(self)
				if not self.enemyTarget and not self.paused then
					updateMovement(self)
				elseif not self.paused then
					if self.isAttackingSpecial and self.canSpecial then
						if self.isSummoning and self.canSummon then 
							updateSummon(self, self.unitData.special)
						else
							updateSpecial(self)
						end
					elseif self.isAttacking and self.canAttack then
						if self.isSummoning and self.canSummon then 
							updateSummon(self, self.unitData.attack)
						else
							updateAttack(self)
						end
					elseif self.isDefending and self.canDefense then 
						updateDefense(self)
					end
				end
				
				if not self.isAttackingSpecial and (self.unitData.special and self.canSpecial) then
					updateSpecialEnergy(self)
				end
			else
				self.idleTime = self.idleTime - 1
				if self.idleTime == 0 then
					self.paused = false 
					self.currentFrameSummon = 0
					self.currentFrameSpecial = 0
					self.nextFrameToSummon = 0
					self:setAnimation("WALK")
					self.currentFrameDefense = 0
					self.isDefending = false
				end
			end
		end
	end
	
	function unit:updateAnimation()
		if not self.paused and not self.freeze then
			animationState:update(SPEED_ANIMATION * FACTOR_ANIMATION)
		elseif self.freeze then
			self.currentFrameFreeze = self.currentFrameFreeze + 1 * FACTOR_ANIMATION
			if self.currentFrameFreeze == self.unfreeze then
				self.currentFrameFreeze = 0
				self.unfreeze = 0
				self.freeze = false
				self:setColor(1, 1, 1, 1)
			end
		end
		animationState:apply(self)
		self:updateWorldTransform()
	end
	
	function unit:setAnimation(animation)
		animationState:setAnimationByName(1, animation, true)
	end
	
	unit.idleTime = unit.idleTimeDefault
	unit:setAnimation("IDLE")
	unit.group.x = extraUnitData.spawnX or lane.spawnX[teamIndex]
	unit.group.y = 0
	lane:addUnit(unit)
	
	local healthbarOptions = {
		width = 64,
		height = 8,
		barPadding = 2,
--		background = "images/general/xpbar_background.png",
--		foreground = "images/general/xpbar_foreground.png",
--		bar = "images/general/xpbar_bar.png",
		barColors = {empty = {1,0.5,0}, full = {0,1,0}},
	}
	
	local healthbar = indicator.newBar(healthbarOptions)
	healthbar.x = 0
	healthbar.y = unit.unitData.healthbarY
	unit.group:insert(healthbar)
	unit.healthbar = healthbar
	
	return unit
end
---------------------------------------------- Module functions
function unitFactory.getUnitIconPath(worldIndex, unitIndex)
	return string.format(PATH_ICON, unitsData[worldIndex][1][unitIndex].stats.name, SKINS_WORLDS[worldIndex])
end

function unitFactory.newUnit(unitIndex, worldIndex, lane, teamIndex, extraUnitData, skin)
	if unitIndex == "hero" then
		local currentPlayer = players.getCurrent()
		local skinName = herolist[currentPlayer.heroIndex].skinName
		local hatIndex = currentPlayer.hatIndex
		
		local hero = createUnitSpine(unitIndex, worldIndex, lane, teamIndex, extraUnitData, skinName, hatIndex)
		hero.isHero = true
		return hero
	else
		return createUnitSpine(unitIndex, worldIndex, lane, teamIndex, extraUnitData, skin)
	end
end
---------------------------------------------- Execution 

return unitFactory