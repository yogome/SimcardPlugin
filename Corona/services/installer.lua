------------------------------------------------ Installer
local extraFile = require( "libs.helpers.extrafile" )

local installer = {}
------------------------------------------------ Constants
local FILENAME_FILELIST = "pack.txt"
local FILEPATH_FILELIST = system.pathForFile( FILENAME_FILELIST, system.DocumentsDirectory )

local FILENAME_INSTALL = "install.command" 

local PACK_LITE = {
	FOLDERS = {
		"scenes/login/",
		"scenes/intro/",
		
		"sounds/onboarding/",
		"sounds/intro/",
		
		"images/education/",
		"images/onboarding/",
		"images/subjects/",
		"images/credits/",
		
		"images/intro/",
		"images/parentgate/",
	},
	FILES = {
		"data/languages/en_onboarding.json",
		"data/languages/es_onboarding.json",
		"data/languages/pt_onboarding.json",
		
		"data/sounds/onboarding.json",
		"data/sounds/intro.json",
		
		"data/onboarding.lua",
		"data/skinlist.lua",
		
		"services/subscription.lua",
		"services/installer.lua",
		"services/credits.lua",
	},
}

local PACK_FULL = {
	FOLDERS = {
		"scenes/minigames/",
		"scenes/login/",
		"scenes/intro/",
		
		"data/education/",
		
		"gamefiles/",
		
		"sounds/manager/",
		"sounds/minigames/",
		"sounds/onboarding/",
		"sounds/intro/",
		
		"services/education/",
		"services/questions/",
		
		"images/education/",
		"images/manager/",
		"images/minigames/",
		"images/onboarding/",
		"images/subjects/",
		"images/credits/",
		
		"images/intro/",
		"images/parentgate/",
	},
	FILES = {
		"data/languages/en_onboarding.json",
		"data/languages/es_onboarding.json",
		"data/languages/pt_onboarding.json",
		
		"data/languages/en_manager.json",
		"data/languages/es_manager.json",
		"data/languages/pt_manager.json",
		
		"data/languages/en_minigames.json",
		"data/languages/es_minigames.json",
		"data/languages/pt_minigames.json",
		
		"data/sounds/manager.json",
		"data/sounds/minigames.json",
		"data/sounds/onboarding.json",
		"data/sounds/intro.json",
		
		"data/onboarding.lua",
		"data/skinlist.lua",
		
		"services/subscription.lua",
		"services/education.lua",
		"services/installer.lua",
		"services/credits.lua",
	},
}

local PACK_MINIGAMES = {
	FOLDERS = {
		"scenes/minigames/",
		
		"data/education/",
		
		"gamefiles/",
		
		"sounds/manager/",
		"sounds/minigames/",
		
		"services/education/",
		"services/questions/",
		
		"images/education/",
		"images/manager/",
		"images/minigames/",
		"images/subjects/",
		"images/credits/",
		
		"images/intro/",
	},
	FILES = {
		"data/languages/en_manager.json",
		"data/languages/es_manager.json",
		"data/languages/pt_manager.json",
		
		"data/languages/en_minigames.json",
		"data/languages/es_minigames.json",
		"data/languages/pt_minigames.json",
		
		"data/sounds/manager.json",
		"data/sounds/minigames.json",
		
		"data/onboarding.lua", -- Needed for database keys
		
		"services/subscription.lua",
		"services/education.lua",
		"services/installer.lua",
		"services/credits.lua",
	},
}

local PACKS = {
	["full"] = PACK_FULL,
	["lite"] = PACK_LITE,
	["minigames"] = PACK_MINIGAMES,
}
------------------------------------------------ Functions
 
local function generateInstallFileList(pack)
	pack = pack or PACK_FULL
	pack.FOLDERS = pack.FOLDERS or {}
	pack.FILES = pack.FILES or {}
	
	local fileList = {}
	local function addFiles(folder)
		local lastChar = string.sub(folder, -1, -1)
		if lastChar ~= "/" then
			folder = folder.."/"
		end

		local files = extraFile.getFiles(folder)
		for fileIndex = 1, #files do
			local fileName = files[fileIndex]
			if string.match(fileName, "%.") then
				fileList[#fileList + 1] = folder..fileName
			else -- its a folder
				addFiles(folder..fileName)
			end
		end
	end

	for index = 1, #pack.FOLDERS do
		addFiles(pack.FOLDERS[index])
	end

	for fileIndex = 1, #pack.FILES do
		fileList[#fileList + 1] = pack.FILES[fileIndex]
	end
	return fileList
end
------------------------------------------------ Module functions
function installer.pack(packName) -- Please note that stuff here might render your computer useless please take care.
	if "simulator" == system.getInfo("environment") then
		native.setActivityIndicator(true)
		
		local pack = PACKS[packName]
		local fileList = generateInstallFileList(pack)
		
		local resourceDirectory = system.pathForFile(nil, system.ResourceDirectory)
		local installFile = io.open( resourceDirectory.."/"..FILENAME_INSTALL, "w" )
		installFile:write( [[cd "`dirname "$0"`";rm ]]..FILENAME_INSTALL..[[;cp -r * ..;rm -rf ../pack;rm -rf ../pack.zip]] )
		io.close( installFile )
		
		local executeHandle = io.popen("cd '"..resourceDirectory.."';chmod +x "..FILENAME_INSTALL)
		executeHandle:close()
		
		fileList[#fileList + 1] = FILENAME_INSTALL
		
		local fileString = ""
		for index = 1, #fileList do
			fileString = fileString..fileList[index].."\n"
		end
		
		local fileObject = io.open( FILEPATH_FILELIST, "w" )
		fileObject:write( fileString )
		io.close( fileObject )
		
		local absolutePath = system.pathForFile(nil, system.ResourceDirectory)
		
		local zipCommand = [[cd ]]..absolutePath..[[;cat ']]..FILEPATH_FILELIST..[[' | zip pack.zip -@]]
		local zipHandle = io.popen(zipCommand)
		local result = zipHandle:read("*a")
		zipHandle:close()
		
		local removeInstallHandle = io.popen("cd '"..resourceDirectory.."';rm "..FILENAME_INSTALL)
		removeInstallHandle:close()
		
		local alertMessage = string.match(result, "error") and "There was an error" or "Success"
		native.showAlert("Packing complete", alertMessage, {"OK"}, function() 
			timer.performWithDelay(100, function()
				native.setActivityIndicator(false)
			end)
		end)
	end
end

function installer.uninstall()
	if "simulator" == system.getInfo("environment") then
		local fileList = generateInstallFileList()
		
		local fileString = ""
		for index = 1, #fileList do
			fileString = fileString..fileList[index].."\n"
		end
		
		local fileObject = io.open( FILEPATH_FILELIST, "w" )
		fileObject:write( fileString )
		io.close( fileObject )
		
		local projoectPath = system.pathForFile(nil, system.ResourceDirectory)
		
		local zipCommand = [[cd ']]..projoectPath..[[';xargs rm < ']]..FILEPATH_FILELIST..[[']]
		local deleteHandle = io.popen(zipCommand)
		local result = deleteHandle:read("*a")
		deleteHandle:close()
		
		native.showAlert("Uninstall complete", result, {"OK"}, function() 
			os.exit(1) -- Since we are in simulator we can do it.
		end)
	end
end

return installer
