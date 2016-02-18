----------------------------------------------- Extra zip - Zip plugin wrapper
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require(folder.."logger") 

local extrazip = {}
---------------------------------------------- Variables
local zip
---------------------------------------------- Constants
---------------------------------------------- Functions
local function initialize()
	local success, message = pcall(function()
		zip = require("plugin.zip")
	end)
	
	if not success then
		logger.error([[Could not load plugin. make sure it is specified on build.settings]])
		zip = {}
		setmetatable(zip, {
			__index = function()
				return function()
					logger.error([[Zip plugin not installed. Add in build.settings!]])
					return true
				end
			end,
			__newindex = function()
				return function()
					logger.error([[Zip plugin not installed. Add in build.settings!]])
					return true
				end
			end
		})
	end
end

---------------------------------------------- Module functions
function extrazip.decompress(zipFilename, options)
	local baseDir = options.baseDir or system.DocumentsDirectory
	local onComplete = options.onComplete
	local onFail = options.onFail
	
	local function unzipListener(event)
		if event.isError then
			if onFail then
				onFail(event)
			end
		else
			if onComplete then
				onComplete(event)
			end
		end
	end
	
	local unzipOptions = {
		zipFile = zipFilename,
		zipBaseDir = baseDir,
		dstBaseDir = baseDir,
		files = {},
		listener = unzipListener
	}

	local function listZipListener(event)
		if not event.isError then
			local fileList = {}
			for index = 1, #event.response do
				local fileData = event.response[index]
				fileList[#fileList + 1] = fileData.file
			end
			unzipOptions.files = fileList
			zip.uncompress(unzipOptions)
		else
			if onFail then
				onFail(event)
			end
		end
	end
	
	local listZipOptions = {
		zipFile = zipFilename,
		zipBaseDir = system.DocumentsDirectory,
		listener = listZipListener
	}

	zip.list(listZipOptions)
end
---------------------------------------------- Execution
initialize()

return extrazip


