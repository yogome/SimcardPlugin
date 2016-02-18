----------------------------------------------- Music
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger") 
local database = require(folder.."database")
local extratable = require(folder.."extratable")
local extrastring = require(folder.."extrastring")
local extrafile = require(folder.."extrafile")
local json = require("json")

local music = {}
---------------------------------------------- Variables
local enabled

local musicList
local currentVolume
local initialized
local disposeMusicTimer, nextMusicTimer
local currentMusicStream
---------------------------------------------- Constants
local VOLUME_DEFAULT = 1
local CHANNEL_MUSIC = 1
local TIME_FADE = 500
---------------------------------------------- Functions
local function initialize()
	if not initialized then
		initialized = true
		currentVolume = VOLUME_DEFAULT
		enabled = database.config("music")
		
		musicList = {}
		
		audio.reserveChannels(1)
		
		if enabled == nil then
			enabled = true
			database.config("music", enabled)
		end
		music.setEnabled(enabled, true)
	end
end

local function resetVolume()
	if enabled then
		audio.setVolume(currentVolume, {channel = CHANNEL_MUSIC})
	else
		audio.setVolume(0, {channel = CHANNEL_MUSIC})
	end
end

local function cancelMusicTimers()
	if disposeMusicTimer then
		timer.cancel(disposeMusicTimer)
		disposeMusicTimer = nil
	end
	
	if nextMusicTimer then
		timer.cancel(nextMusicTimer)
		nextMusicTimer = nil
	end
end
---------------------------------------------- Module functions
function music.isEnabled()
	return enabled
end

function music.setEnabled(value, instant)
	enabled = value and value
	database.config("music", enabled)
	if instant then
		if enabled then
			audio.setVolume(currentVolume, {channel = CHANNEL_MUSIC})
		else
			audio.setVolume(0, {channel = CHANNEL_MUSIC})
		end
	else
		if enabled then
			audio.fade({channel = CHANNEL_MUSIC, time = 500, volume = currentVolume})
		else
			audio.fade({channel = CHANNEL_MUSIC, time = 500, volume = 0})
		end
	end
end

function music.stop(fadeTime)
	fadeTime = fadeTime or TIME_FADE
	audio.fade({volume = 0, channel = CHANNEL_MUSIC, time = fadeTime})
	
	cancelMusicTimers() -- Cancel if a user used play with a fade in time
	
	audio.fade({channel = CHANNEL_MUSIC, time = fadeTime, volume = 0})
	disposeMusicTimer = timer.performWithDelay(fadeTime, function()
		if audio.isChannelActive(CHANNEL_MUSIC) then
			audio.stop(CHANNEL_MUSIC)
		end
		
		if currentMusicStream then
			audio.dispose(currentMusicStream.handle)
			currentMusicStream = nil
		end
	end)
end

function music.setVolume(value, fadeTime)
	value = value or 1
	fadeTime = fadeTime or TIME_FADE
	
	currentVolume = value
	if enabled then
		audio.fade({volume = currentVolume, channel = CHANNEL_MUSIC, time = fadeTime})
	end
end

function music.loadFile(filename)
	local path = system.pathForFile(filename, system.ResourceDirectory )
	local jsonMusiclist

	if pcall(function()
		local musicFile = io.open(path, "r")
		local fileData = musicFile:read("*a")
		jsonMusiclist = json.decode(fileData)
		io.close(musicFile)
	end) then
		musicList = extratable.merge(musicList, jsonMusiclist)
	else
		logger.error([[File "]]..tostring(filename)..[[" was not found.]])
	end
end

function music.loadDirectory(directory)
	if directory and "string" == type(directory) then
		local files = extrafile.getFiles(directory)
		
		for index = 1, #files do
			local split = extrastring.split(files[index], ".")
			if split and #split == 2 and split[2] == "json" then
				music.loadFile(directory..files[index])
			end
		end
	else
		logger.error([[Directory "]]..tostring(directory)..[[" was not found.]])
	end
end

function music.play(musicID, fadeTime) -- We do not check if enabled or not, because volume is the only thing affected
	local filename = musicList[musicID]
	if filename then
		fadeTime = fadeTime or TIME_FADE
		local ignore = currentMusicStream and currentMusicStream.filename == filename

		if not ignore then
			local musicStream = {handle = audio.loadStream(filename), filename = filename}
			if currentMusicStream then
				audio.fade({channel = CHANNEL_MUSIC, time = fadeTime, volume = 0})

				cancelMusicTimers() -- Cancel if user used stop with fade time

				nextMusicTimer = timer.performWithDelay(fadeTime, function()
					audio.stop(CHANNEL_MUSIC)
					audio.dispose(currentMusicStream.handle)

					resetVolume()
					audio.play(musicStream.handle, {loops = -1, channel = CHANNEL_MUSIC, fadein = fadeTime})
					currentMusicStream = musicStream
				end)
			else
				if audio.isChannelActive(CHANNEL_MUSIC) then
					audio.stop(CHANNEL_MUSIC)
				end
				
				cancelMusicTimers() -- Cancel if user used stop with fade time
				resetVolume()
				audio.play(musicStream.handle, {loops = -1, channel = CHANNEL_MUSIC, fadein = fadeTime})
				currentMusicStream = musicStream
			end
		end
	else
		logger.warn([[The ID has no music associated with it]])
	end
end
---------------------------------------------- Deprecated functions
function music.setTracks()
	logger.error("Please use music.loadFile(filename) with a JSON object path, .setTracks()c function is deprecated")
end

function music.fade(fadeTime)
	music.stop(fadeTime)
	logger.error("Please use music.stop(fade) instead, .fade() function is now deprecated")
end

function music.playTrack(trackNumber)
	music.play(tostring(trackNumber))
	logger.error("Please use music.play(musicID) instead, .playTrack() function is deprecated")
end

---------------------------------------------- Execution
initialize()

return music


