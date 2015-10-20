---------------------------------------------- Sound
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" )
local extrafile = require( folder.."extrafile" )
local extrastring = require( folder.."extrastring" )
local database = require( folder.."database" )
local al = require( "al" )
local json = require( "json" )
 
local sound = {}
--------------------------------------------- Variables
local enabled
local soundTable
local currentChannel
local completeFlagTable
local pitchSource, resultingChannel
local initialized
--------------------------------------------- Constants
local CHANNEL_PITCH = 31 -- TODO play pitched sounds on any channel
--------------------------------------------- Functions
local function nextChannel()
	currentChannel = currentChannel + 1
	if currentChannel >= CHANNEL_PITCH then
		currentChannel = 1
	end
end

local function playSound(sound, completeSound, onComplete)
	audio.setVolume(1, { channel = currentChannel})
	local playedChannel = currentChannel
	completeFlagTable[currentChannel] = completeSound
	if completeSound then
		audio.play(sound, { channel = currentChannel, onComplete = function()
			completeFlagTable[currentChannel] = false
		end})
	else
		if not completeFlagTable[currentChannel] then
			if audio.isChannelActive(currentChannel) then
				audio.stop(currentChannel)
			end
			audio.play(sound, { channel = currentChannel, onComplete = onComplete})
		end
	end
	
	nextChannel()
	return {channel = playedChannel}
end

local function initialize()
	if not initialized then
		initialized = true
		enabled = database.config("sound")
		completeFlagTable = {}
		currentChannel = 1
		for index = currentChannel, CHANNEL_PITCH - 1 do
			completeFlagTable[index] = false
		end
		
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
		for channelIndex = 1, CHANNEL_PITCH - 1 do
			audio.stop(channelIndex)
		end
	end
end

function sound.stop(soundHandle)
	if soundHandle and "table" == type(soundHandle) and soundHandle.channel and "number" == type(soundHandle.channel) then
		if audio.isChannelActive(soundHandle.channel) then
			audio.stop(soundHandle.channel)
		end
	end
end

function sound.stopAll(fadeTime)
	fadeTime = fadeTime or 0
	for index = 1, CHANNEL_PITCH - 1 do
		if audio.isChannelActive(index) then
			if fadeTime <=0 then
				audio.stop(index)
			else
				audio.fade({ channel = index, time = fadeTime, volume = 0})
			end
		end
	end
end

function sound.loadSounds(soundlist)
	soundlist = soundlist or {}
	if not soundTable then
		soundTable = {}
	end
	
	if "table" == type(soundlist) then
		if #soundlist > 0 then
			logger.log("[Sound] Will load "..#soundlist.." sounds...")
			for index = 1, #soundlist do
				if soundlist[index] and soundlist[index].id and soundlist[index].path then
					soundTable[soundlist[index].id] = audio.loadSound(soundlist[index].path)
				end
			end
		else
			logger.log("[Sound] There were no sounds to load.")
		end
	elseif "string" == type(soundlist) then
		local soundFile = soundlist
		
		local path = system.pathForFile(soundFile, system.ResourceDirectory )
		local jsonSoundlist
		
		if pcall(function()
			local soundFile = io.open( path, "r" )
			local fileData = soundFile:read( "*a" )
			jsonSoundlist = json.decode(fileData)
			io.close(soundFile)
		end) then
			local realSoundList = {}
			for key, value in pairs(jsonSoundlist) do
				realSoundList[#realSoundList + 1] = {id = key, path = value}
			end
			sound.loadSounds(realSoundList)
		else
			logger.error([[[Sound] File "]]..soundlist..[[" was not found.]])
		end
	end
end

function sound.loadDirectory(directoryPath)
	local allFiles = extrafile.getFiles(directoryPath)
	for index = 1, #allFiles do
		local fileName = allFiles[index]
		if string.len(fileName) >= 5 then -- "a.aaa"
			local split = extrastring.split(fileName, ".")
			if #split == 2 then
				if split[2] == "json" then
					sound.loadSounds(directoryPath..fileName)
				end
			end
		end
	end
end

function sound.playPitch( soundID , loopForever, pitch)
	if enabled then
		local loops = loopForever and -1 or 0
		pitch = pitch or 1
		if not audio.isChannelActive( CHANNEL_PITCH ) then
			audio.setVolume(1, { channel = CHANNEL_PITCH})
			resultingChannel, pitchSource = audio.play(soundTable[soundID], { channel = CHANNEL_PITCH, loops = loops,})
			al.Source(pitchSource, al.PITCH, pitch)
			if resultingChannel == 0 then
				-- TODO handle not playing the sound
			end
		end
	end
end

function sound.setPitch( pitch )
	if audio.isChannelActive( CHANNEL_PITCH ) then
		pitch = pitch or 1
		if pitch and type(pitch) == "number" then
			al.Source(pitchSource, al.PITCH, pitch)
		end
	end
end

function sound.stopPitch()
	if audio.isChannelActive( CHANNEL_PITCH ) then
		al.Source(pitchSource, al.PITCH, 1)
		audio.stop(CHANNEL_PITCH)
	end
end

function sound.playRepeat(soundID) -- TODO implement playRepeat
	logger.log("[Sound] playRepeat is not implemented yet")
end

function sound.play( soundID, options)
	options = options or {}
	local onComplete = nil
	local completeSound = false
	if options and "boolean" == type(options) then
		completeSound = options
	else
		completeSound = options.completeSound
		
		if options.onComplete and "function" == type(options.onComplete) then
			onComplete = options.onComplete
		end
	end
	
	if enabled then	
		if soundTable[soundID] then
			return playSound(soundTable[soundID], completeSound, onComplete)
		else
			logger.error("[Sound] "..tostring(soundID).." is nil.")
		end
	end
end

function sound.playSequence(soundIDs, options) -- TODO return handle
	options = options or {}
	local onComplete = options.onComplete
	local debugSequence = options.debug
	
	if soundIDs and "table" == type(soundIDs) and #soundIDs > 0 then
		local function playNextSound(soundIndex)
			local soundID = soundIDs[soundIndex]
			if soundID then
				if debugSequence then
					logger.log([[[Sound] Will now play "]]..tostring(soundID)..[["]])
				end
				sound.play(soundIDs[soundIndex], {onComplete = function()
					playNextSound(soundIndex + 1)
				end})
			else
				if onComplete and "function" == type(onComplete) then
					onComplete()
				end
			end
		end
		
		playNextSound(1)
	end
end

function sound.testSounds()
	local sequence = {}
	for index, value in pairs(soundTable) do
		sequence[#sequence + 1] = index
	end
	
	sound.playSequence(sequence)
end

initialize()

return sound