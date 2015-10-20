----------------------------------------------- Music
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local database = require( folder.."database" )

local music = {
	channel = 32,
}
---------------------------------------------- Variables
local enabled
local locked
local disposing

local currentTrackIndex
local currentMusic
local nextMusic
local tracks
local currentVolume
local initialized
---------------------------------------------- Constants
local VOLUME_DEFAULT = 1
---------------------------------------------- Functions
local function initialize()
	if not initialized then
		initialized = true
		currentVolume = VOLUME_DEFAULT
		enabled = database.config("music")
		locked = false
		disposing = false
		
		if enabled == nil then
			enabled = true
			database.config("music", enabled)
		end
		music.setEnabled(enabled, true)
	end
end
---------------------------------------------- Module functions
function music.isEnabled()
	return enabled
end

function music.setEnabled( value, instant)
	enabled = value and value
	database.config("music", enabled)
	if instant then
		if enabled then
			audio.setVolume( currentVolume, { channel = music.channel } )
		else
			audio.setVolume( 0, { channel = music.channel } )
		end
	else
		if enabled then
			audio.fade({ channel = music.channel, time = 1000, volume = currentVolume } )
		else
			audio.fade({ channel = music.channel, time = 1000, volume = 0 } )
		end
	end
end

function music.setVolume(value, fadeTime)
	value = value or VOLUME_DEFAULT
	fadeTime = fadeTime or 50
	
	if value <= 0 then
		value = VOLUME_DEFAULT
		logger.error("[Music] volume can not be set to 0 or less.")
	end
	
	currentVolume = value
	if not locked then
		locked = true
		if currentMusic then
			if enabled then -- TODO record actual volume
				audio.fade({ channel = music.channel, time = fadeTime, volume = currentVolume } )
				timer.performWithDelay(fadeTime + 1, function()
					locked = false	
				end)
			end
		else
			locked = false
		end
	else
		logger.log("[Music] Music is locked!")
	end
end

function music.setTracks(trackTable)
	trackTable = trackTable or {}
	tracks = trackTable
	logger.log("[Music] Setting track list with "..#tracks.." tracks.")
end

function music.fade(fadeTime)
	fadeTime = fadeTime or 50
	if not locked then
		locked = true
		if currentMusic then
			audio.fade({ channel = music.channel, time = fadeTime, volume = 0 } )
			timer.performWithDelay(fadeTime + 1, function()
				audio.stop(music.channel)
				timer.performWithDelay(1, function()
					audio.dispose(currentMusic)
					currentMusic = nil
					locked = false
				end)	
			end)
		else
			locked = false
		end
	else
		logger.log("[Music] Music is locked!")
	end
end

local function playMusicFade(filePath, fadeTime)
	fadeTime = fadeTime or 50
	if not locked and filePath then
		locked = true
		
		local function disposeCurrentMusic()
			disposing = true
			if currentMusic then
				audio.stop(music.channel)
				audio.dispose(currentMusic)
				currentMusic = nil
				disposing = false
			else
				disposing = false
			end
		end
		
		local function playNextMusic()
			if not disposing then
				currentMusic = nextMusic
				audio.play( currentMusic, { channel = music.channel, loops=-1})
				if enabled then
					audio.fade({ channel = music.channel, time = fadeTime, volume = currentVolume } )
				else
					audio.setVolume( 0, { channel = music.channel } )
				end
				locked = false
			else
				logger.log("[Music] Music is disposing!")
			end
		end
		
		nextMusic = audio.loadStream(filePath)
		audio.fade({ channel = music.channel, time = fadeTime, volume = 0 } )
		timer.performWithDelay(fadeTime + 1, function()
			timer.performWithDelay(5, disposeCurrentMusic)
			timer.performWithDelay(10, playNextMusic)
		end)
	else
		logger.log("[Music] Music is locked!")
	end
end

function music.playTrack( trackIndex, fadeTime )
	fadeTime = fadeTime or 50
	if #tracks > 0 then
		if trackIndex > #tracks then
			trackIndex = #tracks
		elseif trackIndex < 0 then
			trackIndex = 1
		end
		if currentMusic then
			if trackIndex ~= currentTrackIndex then
				playMusicFade(tracks[trackIndex], fadeTime)
				currentTrackIndex = trackIndex
			end
		else
			playMusicFade(tracks[trackIndex], fadeTime)
			currentTrackIndex = trackIndex
		end
	else
		logger.log("[Music] There are no tracks to play.")
	end
end

initialize()

return music


