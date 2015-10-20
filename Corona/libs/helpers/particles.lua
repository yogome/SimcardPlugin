------------------------------------------- Particle emitter and group builder, automatic removal and advanced features
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extrastring = require( folder.."extrastring" ) 
local extratable = require( folder.."extratable" ) 
local extrafile = require( "libs.helpers.extrafile" ) 
local json = require("json")

local particles = {}
------------------------------------------- Variables
local activeParticles
local initialized
------------------------------------------- Constants 
local JSON_EXTENSION = ".json"
local FILENAME_DEFAULT = "particle"..JSON_EXTENSION 
local LENGHT_JSON_EXTENSION = string.len(JSON_EXTENSION) 

local GL_SRC_COLOR = 768 
local GL_ONE_MINUS_SRC_COLOR = 769

local GL_ZERO = 0 
local GL_ONE = 1
local GL_SRC_ALPHA = 770
local GL_ONE_MINUS_SRC_ALPHA = 771
local GL_DST_ALPHA = 772
local GL_ONE_MINUS_DST_ALPHA = 773
local GL_DST_COLOR = 774
local GL_ONE_MINUS_DST_COLOR = 775
local GL_SOURCE_ALPHA_SATURATE = 776

local BLENDMODES = {
	[1] = GL_ZERO,
	[2] = GL_ONE,
	
	[3] = GL_DST_COLOR,
	[4] = GL_ONE_MINUS_DST_COLOR,

	[5] = GL_SRC_ALPHA,
	[6] = GL_ONE_MINUS_SRC_ALPHA,
	[7] = GL_DST_ALPHA,
	[8] = GL_ONE_MINUS_DST_ALPHA,
	[9] = GL_SOURCE_ALPHA_SATURATE,
}

local BLEND_DESCRIPTORS = {
	[1] = "GL_ZERO",
	[2] = "GL_ONE",
	
	[3] = "GL_DST_COLOR",
	[4] = "GL_ONE_MINUS_DST_COLOR",
	
	[5] = "GL_SRC_ALPHA",
	[6] = "GL_ONE_MINUS_SRC_ALPHA",
	[7] = "GL_DST_ALPHA",
	[8] = "GL_ONE_MINUS_DST_ALPHA",
	[9] = "GL_SOURCE_ALPHA_SATURATE",
}
------------------------------------------- Functions
local function removeActiveParticle(particle)
	extratable.removeItem(activeParticles, particle)
end

local function updateParticles(event)
	if activeParticles then
		for index = #activeParticles, 1, -1 do
			local particle = activeParticles[index]
			if particle.state == "stopped" then
				removeActiveParticle(particle)
				local maxDuration = (particle.particleLifespan + particle.particleLifespanVariance) * 1000
				particle.deleteTimer = timer.performWithDelay(maxDuration + 100, function()
					display.remove(particle)
				end)
			end
		end
	end
end

local function initialize()
	if not initialized then
		initialized = true
		
		activeParticles = {}
		
		particles.BLENDMODES = BLENDMODES
		particles.BLEND_DESCRIPTORS = BLEND_DESCRIPTORS
		
		Runtime:addEventListener("enterFrame", updateParticles)
	end
end

local function fixBlendModes(emitterParams, options)
	options = options or {}
	
	emitterParams.blendFuncSource = options.blendFuncSource or emitterParams.blendFuncSource
	emitterParams.blendFuncDestination = options.blendFuncDestination or emitterParams.blendFuncDestination
	
	if emitterParams.blendFuncSource == GL_ONE and emitterParams.blendFuncDestination == GL_ONE_MINUS_SRC_ALPHA then
		logger.error("[Particles] Source:GL_ONE and Destination:GL_ONE_MINUS_SRC_ALPHA particles are not represented correctly, using GL_SRC_ALPHA instead of GL_ONE")
		emitterParams.blendFuncSource = GL_SRC_ALPHA
	end
end

local function overrideStateFunctions(emitter)
	local lastState = nil
	emitter.oldPause = emitter.pause
	rawset(emitter, "pause", function(self)
		lastState = emitter.state
		if self.deleteTimer then
			timer.pause(self.deleteTimer)
		end
		self:oldPause()
	end)
	
	emitter.oldStop = emitter.stop
	emitter.oldStart = emitter.start
	rawset(emitter, "start", function(self)
		if self.deleteTimer then
			timer.resume(self.deleteTimer)
		end
		if lastState == "stopped" then
			self:oldStop()
		elseif lastState == "playing" then
			self:oldStart()
		end
		lastState = emitter.state
	end)
end

local function addScale(emitter)
	local scale = 1
	
	local startParticleSize = emitter.startParticleSize * scale
	local startParticleSizeVariance = emitter.startParticleSizeVariance * scale
	local finishParticleSize = emitter.finishParticleSize * scale
	local finishParticleSizeVariance = emitter.finishParticleSizeVariance * scale
	local maxRadius = emitter.maxRadius * scale
	local maxRadiusVariance = emitter.maxRadiusVariance * scale
	local minRadius = emitter.minRadius * scale
	local minRadiusVariance = emitter.minRadiusVariance * scale
	local sourcePositionVariancex = emitter.sourcePositionVariancex * scale
	local sourcePositionVariancey = emitter.sourcePositionVariancey * scale
	local radialAcceleration = emitter.radialAcceleration * scale
	local radialAccelVariance = emitter.radialAccelVariance * scale
	local tangentialAcceleration = emitter.tangentialAcceleration * scale
	local tangentialAccelVariance = emitter.tangentialAccelVariance * scale
	local speed = emitter.speed * scale
	local speedVariance = emitter.speedVariance * scale
		
	local oldEmitterMetatable = getmetatable(emitter)
	setmetatable(emitter, {
		__index = function(self, key)
			return oldEmitterMetatable.__index(self, key)
		end,
		__newindex = function(self, key, value)
			getmetatable(self)[key] = value
			if key == "scale" or key == "xScale" or key == "yScale" then
				scale = value
				self.startParticleSize = startParticleSize * scale
				self.startParticleSizeVariance = startParticleSizeVariance * scale
				self.finishParticleSize = finishParticleSize * scale
				self.finishParticleSizeVariance = finishParticleSizeVariance * scale
				self.maxRadius = maxRadius * scale
				self.maxRadiusVariance = maxRadiusVariance * scale
				self.minRadius = minRadius * scale
				self.minRadiusVariance = minRadiusVariance * scale
				self.sourcePositionVariancex = sourcePositionVariancex * scale
				self.sourcePositionVariancey = sourcePositionVariancey * scale
				self.radialAcceleration = radialAcceleration * scale
				self.radialAccelVariance = radialAccelVariance * scale
				self.tangentialAcceleration = tangentialAcceleration * scale
				self.tangentialAccelVariance = tangentialAccelVariance * scale
				self.speed = speed * scale
				self.speedVariance = speedVariance * scale
			end
			return oldEmitterMetatable.__newindex(self, key, value)
		end
	})
end
------------------------------------------- Module functions
function particles.newGroup(fileNames, options) 
	if fileNames and "table" == type(fileNames) and #fileNames > 0 then
		local particleGroup = display.newGroup()
		
		local maxDuration = 0
		local maxDurationIndex = 1
		local particleList = {}
		for index = 1, #fileNames do
			local particle = particles.new(fileNames[index], options)
			
			local particleDuration = ((particle.particleLifespan + particle.particleLifespanVariance) * 1000)
			if particleDuration > maxDuration then
				maxDuration = particleDuration
				maxDurationIndex = index
			end
			
			particleGroup:insert(particle)
			particleList[index] = particle
		end
		
		particleList[maxDurationIndex]:addEventListener("finalize", function()
			timer.performWithDelay(1, function()
				display.remove(particleGroup)
			end)
		end)
	
		return particleGroup
	end
end

function particles.new(filename, options)
	options = options or {}
	local originalFilename = filename
	
	if filename and "string" == type(filename) then
		local path = system.pathForFile(filename, system.ResourceDirectory )
		
		local hasValidExtension = filename and string.len(filename) >= LENGHT_JSON_EXTENSION and string.sub(filename, -LENGHT_JSON_EXTENSION, -1) == JSON_EXTENSION
		local newFilename = filename..(hasValidExtension and "" or JSON_EXTENSION)
		
		if not path then
			path = system.pathForFile(newFilename, system.ResourceDirectory )
			
			if not path then
				local guessFilename = filename.."/"..FILENAME_DEFAULT
				path = system.pathForFile(guessFilename, system.ResourceDirectory )

				if not path then
					local splitDirectory = extrastring.split(filename, "/")
					guessFilename = splitDirectory[#splitDirectory] or ""
					guessFilename = filename.."/"..guessFilename..JSON_EXTENSION
					
					path = system.pathForFile(guessFilename, system.ResourceDirectory )
					
					if not path then
						logger.error([[[Particles] "]]..tostring(filename)..[[" is not a valid particle file or id]])
					else
						filename = guessFilename
					end
				else
					filename = guessFilename
				end
			else
				filename = newFilename
			end
		end
		
		local emitterParams = nil
		
		if path then
			if not pcall(function()
				local languageFile = io.open( path, "r" )
				local savedData = languageFile:read( "*a" )
				io.close(languageFile)

				emitterParams = json.decode(savedData)

				local splitPath = extrastring.split(filename, "/")

				local jsonFilename = splitPath[#splitPath]
				local jsonFilenameLenght = string.len(jsonFilename)

				local directory = string.sub(filename, 1, -jsonFilenameLenght - 1)
				emitterParams.textureFileName = directory..emitterParams.textureFileName

				fixBlendModes(emitterParams, options)
			end) then
				logger.error([[[Particles] Failed to load particle file "]]..filename..[["]])
			end
		end

		if emitterParams then
			local emitter = display.newEmitter(emitterParams)
			addScale(emitter)
			overrideStateFunctions(emitter)

			if emitterParams.duration > 0 then
				activeParticles[#activeParticles + 1] = emitter
				emitter:addEventListener("finalize", function(event)
					local particle = event.target
					removeActiveParticle(particle)

					particle.deleteTimer = nil
					rawset(particle, "start", nil)
					rawset(particle, "pause", nil)
					rawset(particle, "scale", nil)
					particle.oldStart = nil
					particle.oldPause = nil
					particle.oldStop = nil
				end)
			end
			return emitter
		else
			return display.newGroup()
		end
	else
		logger.error([[[Particles] "]]..tostring(filename)..[[" is not a string]])
	end
end

initialize()

return particles
