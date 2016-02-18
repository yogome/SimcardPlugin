----------------------------------------------- Extra file - File management for iOS, Android, Windows and OSX - (c) Basilio Germán
local path = ...
local folder = path:match("(.-)[^%.]+$")
local logger = require( folder.."logger" ) 
local extrastring = require(folder.."extrastring")
local extratime = require(folder.."extratime")
local lfs = require( "lfs" )
local json = require( "json" )

local extrafile = {}
---------------------------------------------- Variables
local cacheFilesystem 
local gitRemoteSHA, gitLastAuthor, showingGitVersion, submodules
local gitTimestamp
local debugMessages
local initialized
---------------------------------------------- Constants 
local ioLines = io.lines
local stringGsub = string.gsub
local stringFind = string.find
local ioOpen = io.open
---------------------------------------------- Constants 
local DATA_DIRECTORY = "data"
local FILESYSTEM_CACHE_FILENAME = "filesystem.json"
---------------------------------------------- Functions
local function initialize()
	if not initialized then
		initialized = true
		
		debugMessages = system.getInfo("environment") == "simulator"
		extrafile.cacheFileSystem()
	end
end

local function loggerError(...)
	if debugMessages then
		logger.error(...)
	end
end

local function loggerLog(...)
	if debugMessages then
		logger.log(...)
	end
end

local function fileExists(fileName, directory)
	directory = directory or system.ResourceDirectory
	local absolutePath = system.pathForFile(fileName, directory) -- Works on mac
	if absolutePath then
		local openFile = ioOpen(absolutePath, "r")
		if openFile then
			loggerLog([[File "]]..tostring(fileName)..[[" was found]])
			openFile:close()
			return true
		end
	end
	return false
end

local function getFiles(directoryName)
	local filenames = {}
	local rootPath = system.pathForFile(nil, system.ResourceDirectory)
	local baseDir = rootPath and (rootPath.."/") or ""
	local absolutePath = baseDir..directoryName
	
	local success, message = pcall(function()
		for fileName in lfs.dir(absolutePath) do
			if fileName and string.sub(fileName, 1, 1) ~= "." then
				table.insert(filenames, fileName)
			end
		end
	end)
	
	if not success and message then
		logger.error([[directory "]]..tostring(directoryName)..[[" not found.]])
	end
		
	if #filenames == 0 then return false end
	return filenames
end

local function showGraphicGitVersion()
	if gitTimestamp and gitRemoteSHA and gitLastAuthor and not showingGitVersion then
		showingGitVersion = true
		
		local gitGroup = display.newGroup()
		gitGroup.x = display.screenOriginX + display.viewableContentWidth
		gitGroup.y = display.screenOriginY
		gitGroup.isHitTestable = true

		local gitBG = display.newRect(0, 0, 20, 20)
		gitBG.anchorX = 1
		gitBG.anchorY = 0
		gitBG:setFillColor(0.5, 0.8)
		gitGroup:insert(gitBG)

		local gitDate = display.newText(gitTimestamp, 0, 0, native.systemFont, 25)
		gitDate.anchorX = 1
		gitDate.anchorY = 0
		gitGroup:insert(gitDate)

		local clippedSHA = string.sub(gitRemoteSHA, 1, 12)
		local gitCommit = display.newText(clippedSHA, 0, gitDate.height + 1, native.systemFont, 25)
		gitCommit.anchorX = 1
		gitCommit.anchorY = 0
		gitGroup:insert(gitCommit)
		
		local gitAuthor = display.newText(gitLastAuthor, 0, gitCommit.y + gitCommit.height + 1, native.systemFont, 25)
		gitAuthor.anchorX = 1
		gitAuthor.anchorY = 0
		gitGroup:insert(gitAuthor)

		gitBG.width = gitDate.width + 2
		gitBG.height = gitDate.height * 3 + 3

		gitGroup:addEventListener("tap", function()
			gitGroup.isVisible = not gitGroup.isVisible
			return not gitGroup.isVisible
		end)
	else
		loggerError("Git version was not available")
	end
end
---------------------------------------------- Module functions
function extrafile.testPNGFiles()
	if cacheFilesystem then
		local function checkDirectory(directory, parentString)
			parentString = parentString and parentString.."/" or ""
			for name, data in pairs(directory) do
				if data == "file" then
					if string.match(name, "%.png") then
						local width, height = extrafile.getPNGDimensions(parentString..name)
						
						if (width > 1024 or height > 1024) or (width == 0 or height == 0) then
							logger.error("Excesive dimensions: "..(parentString..name).." "..width..","..height)
						end
					end
				elseif "table" == type(data) then
					checkDirectory(data, parentString..name)
				end
			end
		end
		
		checkDirectory(cacheFilesystem)
	else
		loggerError("Filesystem has to be cached")
	end
end

function extrafile.getPNGDimensions(filename, baseDir)
	local function unpackUInt(str)
		local a,b,c,d = str:byte(1, #str)
		local num = (((a * 256) + b) * 256 + c) * 256 + d
		return num
	end

	local function readUInt(fh)
		return unpackUInt(fh:read(4))
	end
	
	baseDir = baseDir or system.ResourceDirectory
	local absolutePath = system.pathForFile(filename, baseDir)
	if absolutePath then
		local openFile = ioOpen(absolutePath, "rb")
		if openFile then
			local bytes = openFile:read(8)
			local expect = "\137\080\078\071\013\010\026\010"
			if bytes ~= expect then
				loggerError(""..tostring(filename).." is not a png")
				return unpack({0, 0})
			end
			
			local width, height = 0, 0
			local foundDimension = false
			while true do
				local dataLenght = readUInt(openFile)
				local chunkType = openFile:read(4)

				if chunkType == "IHDR" then
					if dataLenght ~= 13 then -- 13 is the normal IHDR data lenght
						loggerError(""..tostring(filename).." has a format error")
					end
					width = readUInt(openFile)
					height = readUInt(openFile)
					foundDimension = true
					
					break
				end

				if chunkType == "IEND" then
					break
				end
			end
			
			openFile:close()
			if not foundDimension then
				logger.error("Could not get "..tostring(filename).." dimnesions")
			end
			return unpack({width, height})
		else
			logger.error("Could not open "..tostring(filename))
		end
	end
	return unpack({0, 0})
end

function extrafile.showGitVersion()
	showGraphicGitVersion()
end

function extrafile.exists(fileName, directory)
	if fileName and "string" == type(fileName) then
		if cacheFilesystem and (directory == system.ResourceDirectory or directory == nil) then
			local fileStrings = extrastring.split(fileName, "/")
			local lastPathTable = cacheFilesystem
			local existsInCache = false
			for index = 1, #fileStrings do
				if lastPathTable then
					lastPathTable = lastPathTable[fileStrings[index]]
					existsInCache = lastPathTable == "file" or type(lastPathTable) == "table"
				else
					existsInCache = false
				end
			end
			if existsInCache then
				return true
			else
				loggerLog([[File "]]..tostring(fileName)..[[" does not exist in cache]])
				return fileExists(fileName, directory)
			end
		else
			if not string.match(fileName, "%.lua") then
				return fileExists(fileName, directory)
			else
				loggerError("LUA files are not present in device builds, cache the filesystem first.")
				return false
			end
		end
	else
		loggerError("filename must be a string")
		return false
	end
end

function extrafile.getBlame(filename, line)
	local environment = system.getInfo("environment")
	if environment == "simulator" then
		local blamedUser
		pcall(function()
			local currentPath = system.pathForFile(nil, system.ResourceDirectory)
			local blameCommand = "cd "..currentPath..";git blame --porcelain -L"..line..",+1 -- '"..filename.."'"
			local blameHandle = io.popen(blameCommand)
			
			for line in blameHandle:lines() do
				if string.find(line, "author ") then
					blamedUser = string.gsub(line, "author ", "")
					if blamedUser == "Not Committed Yet" then
						blamedUser = "You"
					end
					break
				end
			end
		end)
		return blamedUser
	end
end

function extrafile.getFiles(directoryName)
	if cacheFilesystem then
		local directoryStrings = extrastring.split(directoryName, "/")
		local lastPathTable = cacheFilesystem
		local existsInCache = false
		
		if #directoryStrings == 0 then -- Root folder
			existsInCache = true
		else
			for index = 1, #directoryStrings do
				if lastPathTable then
					lastPathTable = lastPathTable[directoryStrings[index]]
					existsInCache = lastPathTable ~= nil
				else
					existsInCache = false
				end
			end
		end
		
		if existsInCache then
			local files = {}
			for key, value in pairs(lastPathTable) do
				files[#files + 1] = key
			end
			return files
		else
			return getFiles(directoryName)
		end
	else
		return getFiles(directoryName)
	end
end

function extrafile.cacheFileSystem()
	local function getFileSystemTable(path)
		local files = extrafile.getFiles(path)
		local fileTable = {}
		if files then
			for index = 1, #files do
				local fileName = files[index]
				if not stringFind(fileName, "%.") then
					fileTable[fileName] = getFileSystemTable(path.."/"..fileName)
				else
					fileTable[fileName] = "file"
				end
			end
		end
		return fileTable
	end
	
	local environment = system.getInfo("environment")
	if environment == "simulator" and not cacheFilesystem then
		loggerLog("Caching filesystem")
		local baseDir = system.pathForFile().."/"
		logger.log(baseDir)
		local fileSystemFile = io.open(baseDir..DATA_DIRECTORY.."/"..FILESYSTEM_CACHE_FILENAME, "w")
		if fileSystemFile then
			cacheFilesystem = getFileSystemTable("")
							
			local currentPath = system.pathForFile(nil, system.ResourceDirectory)

			pcall(function() -- Last git commit hash
				local commitHandle = io.popen("git --git-dir '"..currentPath.."/.git' rev-parse master")
				gitRemoteSHA = commitHandle:read("*a")
				commitHandle:close()
			end)
			
			pcall(function() -- Date from last remove commit
				local dateHandle = io.popen("git --git-dir '"..currentPath.."/.git' show -s --format=%ct "..gitRemoteSHA)
				local unixDate = dateHandle:read("*a")
				dateHandle:close()

				local commitDate = os.date("*t", unixDate)
				gitTimestamp = string.format("%s-%s-%s %s:%s", tostring(commitDate.day), extratime.getMonthName(tonumber(commitDate.month)), tostring(commitDate.year), tostring(commitDate.hour), string.format("%02d", tonumber(commitDate.min)))
			end)
			
			pcall(function() -- Last git author
				local authorHandle = io.popen("git --git-dir '"..currentPath.."/.git' show -s --format=%cn "..gitRemoteSHA)
				gitLastAuthor = authorHandle:read("*a")
				authorHandle:close()
			end)
			
			submodules = {}
			pcall(function() -- Submodules
				local submoduleHandle = io.popen("cd '"..currentPath.."';git submodule status")
				for submodule in submoduleHandle:lines() do
					submodules[#submodules + 1] = submodule
					logger.log("Using submodule: "..tostring(submodule))
				end
				submoduleHandle:close()
			end)
			
			local filesystemData = {
				cacheFilesystem = cacheFilesystem,
				commitSHA = gitRemoteSHA,
				timeStamp = gitTimestamp,
				lastAuthor = gitLastAuthor,
				submodules = submodules,
			}
			
			logger.log("Cache git timestamp: "..(gitTimestamp ~= nil and tostring(gitTimestamp) or ""))
			
			local fileSystemJson = json.encode(filesystemData)
			fileSystemFile:write(tostring(fileSystemJson))
			io.close(fileSystemFile)
		end
	else
		if not cacheFilesystem then
			local path = system.pathForFile(DATA_DIRECTORY.."/"..FILESYSTEM_CACHE_FILENAME, system.ResourceDirectory )
			local fileSystemFile = io.open(path, "r")
			if fileSystemFile then
				local fileString = fileSystemFile:read("*a")
				local filesystemData = json.decode(fileString)
				cacheFilesystem = filesystemData.cacheFilesystem
				
				gitRemoteSHA = filesystemData.commitSHA
				gitTimestamp = filesystemData.timeStamp
				gitLastAuthor = filesystemData.lastAuthor
				submodules = filesystemData.submodules
				
				if gitTimestamp then
					logger.log("Cache git timestamp: "..tostring(gitTimestamp))
				end
				if submodules and #submodules > 0 then
					for index = 1, #submodules do
						logger.log("Cache registered submodule: "..tostring(submodules[index]))
					end
				end
			else
				loggerError("Could not load filesystem cache")
			end
		end
	end
end

function extrafile.setDebug(doDebug)
	debugMessages = doDebug
end

function extrafile.getGitData()
	return {gitRemoteSHA = gitRemoteSHA, gitTimestamp = gitTimestamp}
end

function extrafile.getLines(fileName)
	if not extrafile.exists(fileName) then
		return {}
	end
	local absolutePath = system.pathForFile(fileName, system.ResourceDirectory)
	local fileLines = {}
	for readLine in ioLines(absolutePath) do 
		fileLines[#fileLines + 1] = stringGsub(stringGsub(readLine, "\r", ""), "\n", "")
	end
	return fileLines
end

initialize()

return extrafile
