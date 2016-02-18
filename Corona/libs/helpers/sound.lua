---------------------------------------------- Sound - Audio wrapper - (c) Basilio Germán
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger")
local extrafile = require(folder.."extrafile")
local extrastring = require(folder.."extrastring")
local extratable = require(folder.."extratable")
local database = require(folder.."database")
local sound = require(folder.."music")
local al = require("al")
local json = require("json")
 
local sound = {}
--------------------------------------------- Variables
local enabled
local initialized

local usedChannels
local soundHandles
local timers
--------------------------------------------- Constants
--------------------------------------------- Functions
local function initialize()
	if not initialized then
		initialized = true
		
		usedChannels = {}
		soundHandles = {}
		
		timers = {}
		
		enabled = database.config("sound")
		
		if enabled == nil then
			enabled = true
			database.config("sound", enabled)
		end
		sound.setEnabled(enabled)
	end
end
--------------------------------------------- Module functions
function sound.isEnabled()
	return enabled
end

function sound.setEnabled(value)
	enabled = value and value
	database.config("sound", enabled)
	if not enabled then
		for index = 1, #usedChannels do
			if usedChannels[index] ~= nil then
				audio.stop(index)
			end
		end
	end
end

function sound.loadTable(luaTable)
	if not extratable.isEmpty(luaTable) then
		for handleID, filename in pairs(luaTable) do
			if not soundHandles[handleID] then
				soundHandles[handleID] = audio.loadSound(filename)
			else
				logger.warn([[Sound with ID "]]..tostring(handleID)..[[" already exists.]])
			end
		end
	end
end

function sound.loadFile(filename)
	local path = system.pathForFile(filename, system.ResourceDirectory )
	local jsonSoundlist

	if pcall(function()
		local soundFile = io.open(path, "r")
		local fileData = soundFile:read("*a")
		jsonSoundlist = json.decode(fileData)
		io.close(soundFile)
	end) then
		sound.loadTable(jsonSoundlist)
	else
		logger.error([[File "]]..tostring(filename)..[[" was not found.]])
	end
end

function sound.loadDirectory(directory)
	if directory and "string" == type(directory) then
		local files = extrafile.getFiles(directory)
		
		for index = 1, #files do
			local split = extrastring.split(files[index], ".")
			if split and #split == 2 and split[2] == "json" then
				sound.loadFile(directory..files[index])
			end
		end
	else
		logger.error([[Directory "]]..tostring(directory)..[[" was not found.]])
	end
end

function sound.stop(soundHandle)
	if soundHandle and "table" == type(soundHandle) and soundHandle.channel and "number" == type(soundHandle.channel) then
		if audio.isChannelActive(soundHandle.channel) then
			audio.stop(soundHandle.channel)
		elseif soundHandle.channel == 0 and not soundHandle.source and soundHandle.onCancel then -- Muted sound
			if soundHandle.completeTimer then
				timer.cancel(soundHandle.completeTimer)
			end
			soundHandle.onCancel()
		end
	end
end

function sound.stopAll(fadeTime)
	fadeTime = fadeTime or 0
	for index = 1, #usedChannels do
		if usedChannels[index] ~= nil then
			if audio.isChannelActive(index) then
				if fadeTime <=0 then
					audio.stop(index)
				else
					audio.fade({ channel = index, time = fadeTime, volume = 0})
				end
			end
		end
	end
end

function sound.setPitch(soundHandle, pitch)
	assert(type(soundHandle) == "table", "setPitch first parameter is the handle")
	pitch = pitch or 1
	
	if soundHandle.source and soundHandle.channel then
		if usedChannels[soundHandle.channel] == soundHandle.uniqueID then
			al.Source(soundHandle.source, al.PITCH, pitch)
		end
	end
end

function sound.setVolume(soundHandle, volume)
	assert(type(soundHandle) == "table", "setVolume first parameter is the handle")
	volume = volume or 1
	
	if soundHandle.source and soundHandle.channel then
		if usedChannels[soundHandle.channel] == soundHandle.uniqueID then
			audio.setVolume(volume, {source = soundHandle.source})
		end
	end
end

function sound.play(soundID, options)
	options = options or {}
	
	assert("table" == type(options), "options must be a table")
	
	local pitch = options.pitch or 1
	local volume = options.volume or 1
	local onComplete = options.onComplete
	local onCancel = options.onCancel
	local fadeTime = options.fadeTime
	local duration = options.duration
	local loops = options.loops or 0
	local forcedChannel = options.forcedChannel
	
	if enabled then
		local handle = soundHandles[soundID]
		if handle then
			local freeChannel = forcedChannel or audio.findFreeChannel()
			
			if freeChannel ~= 0 then
				if audio.isChannelActive(freeChannel) then -- Stop channel if forced on channel
					audio.stop(freeChannel)
				end

				local uniqueID = system.getTimer()
				usedChannels[freeChannel] = uniqueID

				audio.setVolume(volume, {channel = freeChannel})
				local source = audio.getSourceFromChannel(freeChannel)
				al.Source(source, al.PITCH, pitch)
				
				local function onCompleteWrapper(event)
					if event.completed then
						if onComplete and "function" == type(onComplete) then
							onComplete()
						end
					elseif onCancel and "function" == type(onCancel) then
						onCancel()
					end
				end

				local channel, source = audio.play(handle, {channel = freeChannel, loops = loops, onComplete = onCompleteWrapper, fadein = fadeTime, duration = duration})
				
				local variablePitch = pitch
				local variableVolume = volume
				return setmetatable({source = source, channel = channel, uniqueID = uniqueID}, {
					__newindex = function(self, key, value)
						if key == "pitch" then
							variablePitch = value
							sound.setPitch(self, variablePitch)
						elseif key == "volume" then
							variableVolume = value
							sound.setVolume(self, variableVolume)
						else
							rawset(self, key, value)
						end
					end,
					__index = function(self, key)
						if key == "pitch" then
							return variablePitch
						elseif key == "volume" then
							return variableVolume
						else
							return rawget(self, key)
						end
					end
				})
			else
				
			end
		else
			logger.warn([[The soundID "]]..tostring(soundID)..[[" has no sound associated with it]])
		end
	else -- Play muted sound
		local emptyHandle = {channel = 0, source = nil, onComplete = onComplete, onCancel = onCancel}
		if onComplete then
			local delay = sound.getDuration(soundID)
			emptyHandle.completeTimer = timer.performWithDelay(delay, function()
				emptyHandle.completeTimer = nil
				onComplete()
			end)
		end
		
		return emptyHandle
	end
end

function sound.playSequence(soundIDs, options)
	options = options or {}
	
	local pitch = options.pitch or 1
	local volume = options.volume or 1
	local onComplete = options.onComplete
	local onCancel = options.onCancel
	local loops = options.loops or 0
	
	if not extratable.isEmpty(soundIDs) then
		
		local freeChannel = audio.findFreeChannel()
		if freeChannel == 0 then -- Failed to find free channel, use last channel.
			freeChannel = #usedChannels
		end
				
		local function playNextSound(soundIndex)
			local soundID = soundIDs[soundIndex]
			if soundID then
				return sound.play(soundIDs[soundIndex], {forcedChannel = freeChannel, pitch = pitch, volume = volume, loops = loops, 
					onComplete = function(event)
						playNextSound(soundIndex + 1)
					end,
					onCancel = function()
						if onCancel and "function" == type(onCancel) then
							onCancel()
						end
					end,
				})
			else
				if onComplete and "function" == type(onComplete) then
					onComplete()
				end
			end
		end
		
		playNextSound(1)
	end
end

function sound.getDuration(soundID)
	return audio.getDuration(soundHandles[soundID])
end
--------------------------------------------- Deprecated functions
function sound.playPitch()
	logger.warn("playPitch is deprecated, use .play with pitch option")
end

function sound.stopPitch()
	logger.warn("stopPitch is deprecated, use .stop instead")
end

function sound.playRepeat(soundID) -- TODO implement playRepeat
	logger.log("playRepeat was never implemented and is now deprecated, use .play with repeat option")
end
--------------------------------------------- Execution
initialize()

return sound