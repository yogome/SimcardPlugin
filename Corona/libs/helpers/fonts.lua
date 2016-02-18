----------------------------------------------- Fonts manager
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extrastring = require( folder.."extrastring" ) 
local extrafile = require( folder.."extrafile" ) 
local logger = require( folder.."logger" ) 

local fonts = {}
----------------------------------------------- Variables
local initialized
local fontList
local fontCache
----------------------------------------------- Constants
local PLATFORMNAME = system.getInfo("platformName") 
----------------------------------------------- Caches
local stringMatch = string.match
local stringLower = string.lower
local stringLen = string.len
----------------------------------------------- Local functions
local function initialize()
	if not initialized then
		initialized = true
		
		fontList = native.getFontNames()
		
		local rootFonts = 0
		local rootFiles = extrafile.getFiles("")
		for index = 1, #rootFiles do
			if rootFiles[index] and "string" == type(rootFiles[index]) then
				local splitString = extrastring.split(rootFiles[index], ".")
				if splitString and "table" == type(splitString) and #splitString == 2 then
					local extension = splitString[2]
					if stringLower(extension) == "otf" or stringLower(extension) == "ttf" then
						fontList[#fontList + 1] = rootFiles[index]
						rootFonts = rootFonts + 1
					end
				end
			end
		end
		logger.log("Found "..tostring(#fontList).." system fonts, and "..tostring(rootFonts).." extra fonts")
		
		fontCache = {}
	end
end
----------------------------------------------- Module functions

function fonts.get(fontName, style)
	fontName = fontName and "string" == type(fontName) and stringLower(fontName) or ""
	style = style and "string" == type(style) and stringLower(style) or ""
	local fontID = fontName.."-"..style
	if fontName and stringLen(fontName) > 0 then
		if not fontCache[fontID] then
			for index = 1, #fontList do
				if stringMatch(stringLower(fontList[index]), fontName) then
					if stringMatch(stringLower(fontList[index]), style) then
						fontCache[fontID] = fontList[index]
						break
					end
				end
			end
		end
	end
	return fontCache[fontID] or style == "bold" and native.systemFontBold or native.systemFont
end

initialize()

return fonts
