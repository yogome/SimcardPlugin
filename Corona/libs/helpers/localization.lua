------------------------------------------- Localization
local path = ...
local folder = path:match("(.-)[^%.]+$") 
local logger = require( folder.."logger" )
local database = require( folder.."database" )
local extrafile = require( folder.."extrafile" )
local extratable = require( folder.."extratable" )
local json = require ( "json" )

local localization = {}
------------------------------------------- Variables
local initialized
local dictionary
local customDictionary
local fileFamilyDictionary
------------------------------------------- Caches
local stringLen = string.len
local stringSub = string.sub
local ioOpen = io.open
local ioClose = io.close
local stringMatch = string.match
local stringFormat = string.format
------------------------------------------- Constants
local STRING_MISSING = "MISSING STRING"
local STRING_NOT_INIT = "LOCALIZATION NOT INITIALIZED"
local LANGUAGE_DEFAULT = "en"
------------------------------------------- Functions
local function addEntries(languageDictionary, fileName, language, family, overwrite)
	local path = system.pathForFile(localization.dataPath..fileName, system.ResourceDirectory )
	
	fileFamilyDictionary = fileFamilyDictionary or {}
	fileFamilyDictionary[family] = fileFamilyDictionary[family] or {}
	fileFamilyDictionary[family][language] = fileFamilyDictionary[family][language] or {}
	
	local fileEntries
	if pcall(function()
		local languageFile = ioOpen( path, "r" )
		local savedData = languageFile:read( "*a" )
		fileEntries = json.decode(savedData)
		ioClose(languageFile)
	end) then
		logger.log([[[Localization] File "]]..fileName..[[" was loaded to "]]..language..[[".]])
	else
		logger.error([[[Localization] File "]]..fileName..[[" for "]]..language..[[" was not found.]])
	end
	
	local errors = 0
	if fileEntries and not extratable.isEmpty(fileEntries) then
		for key, value in pairs(fileEntries) do
			if not languageDictionary[key] then
				languageDictionary[key] = value
				fileFamilyDictionary[family][language][key] = value
			elseif overwrite then
				languageDictionary[key] = value
			else
				errors = errors + 1
			end
		end
	end
	
	if errors > 0 then
		logger.error([[[Localization] There were ]]..tostring(errors)..[[ repeated strings.]])
	end
end

local function loadLanguageFiles(language)
	local fileList = extrafile.getFiles(localization.dataPath)
		
	local languageDictionary = {}
	if fileList and #fileList > 0 then
		for index = 1, #fileList do
			local fileName = fileList[index]
			if stringLen(fileName) >= 7 then -- Seven characters at least. "en.json"
				if stringSub(fileName, 1, 2) == language then
					
					local family = "general"
					if stringMatch(fileName, "_") then
						family = stringSub(stringMatch(fileName, "_%w+"), 2, -1)
					end
					local isMain = fileName == language.."_"..family..".json"

					addEntries(languageDictionary, fileName, language, family, not isMain)
				end
			end
		end
	end
	
	return languageDictionary
end
------------------------------------------- Module functions
function localization.setLanguage(language)
	language = language or LANGUAGE_DEFAULT
	localization.language = language
	
	dictionary = dictionary or {}
	
	dictionary[language] = loadLanguageFiles(language)
	
	if dictionary[language] and not extratable.isEmpty(dictionary[language]) then
		database.config("language", language)
	else
		logger.error([[[Localization] Language "]]..language..[[" contains no data.]])
	end
end

function localization.getFamilyStrings(family)
	return fileFamilyDictionary and fileFamilyDictionary[family]
end

function localization.format(stringIn)
	if initialized then
		return stringFormat(stringIn, localization.language)
	else
		logger.error("[Localization] You must initialize first.")
	end
	return ""
end

function localization.getLanguage()
	return localization.language or "en"
end

function localization.getAvailableLanguages()
	if initialized then
		local allFiles = extrafile.getFiles(localization.dataPath)
		
		local currentLanguage = localization.getLanguage()
		
		local languageTable = {}
		for index = 1, #allFiles do
			local language = stringSub(allFiles[index], 1, 2)
			languageTable[language] = true
		end
		
		local languageIndex = 1
		local languageList = {}
		for language, value in pairs(languageTable) do
			languageList[#languageList + 1] = language
			if language == currentLanguage then
				languageIndex = #languageList
			end
		end
		return unpack({languageList, languageIndex})
	end
end

function localization.initialize(parameters)
	parameters = parameters or {}
	if not initialized then 
		logger.log("[Localization] Initializing.")
		initialized = true
		customDictionary = {}
		
		local language = database.config( "language" )
		if not language then
			logger.log("[Localization] Autodetecting language.")
			local systemLanguage = system.getPreference( "locale", "language" )
			logger.log("[Localization] Detected language "..systemLanguage)
			language = systemLanguage
		end
		
		localization.debugLevel = parameters.debugLevel or 0
		localization.dataPath = parameters.dataPath or ""
		local languageFileExists = extrafile.exists(localization.dataPath..language..".json")
		localization.language = languageFileExists and language or "en"
		localization.setLanguage(localization.language)
	else
		logger.error("[Localization] Is already initialized.")
	end
end

function localization.addString(language, stringID, stringValue)
	if initialized then
		customDictionary[language] = customDictionary[language] or {}
		customDictionary[language][stringID] = stringValue
	else
		logger.error("[Localization] You must initialize first.")
	end
end

function localization.getString(stringID, language)
	language = language or localization.language
	if initialized then
		if dictionary[language] and dictionary[language][stringID] then
			return dictionary[language][stringID]
		else
			if customDictionary[language] and customDictionary[language][stringID] then
				return customDictionary[language][stringID]
			else
				if not dictionary[language] then
					dictionary[language] = loadLanguageFiles(language)
					-- TODO check if data was loaded
					if dictionary[language][stringID] then
						return dictionary[language][stringID]
					end
					return STRING_MISSING
				else
					logger.error([[[Localization] ID:"]]..tostring(stringID)..[[" in language:"]]..language..[[" does not contain a string.]])
				end
			end
		end
	else
		logger.error("[Localization] Not initialized yet.")
		return STRING_NOT_INIT
	end
	return STRING_MISSING
end

return localization
