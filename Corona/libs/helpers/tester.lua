----------------------------------------------- Library - main collection
local path = ...
local folder = path:match("(.-)[^%.]+$")
local folderPath = string.gsub(folder,"[%.]","/")
local logger = require(folder.."logger") 
local logger = require(folder.."logger") 
local extrafile = require(folder.."extrafile") 
local extrastring = require(folder.."extrastring") 
local extratable = require(folder.."extratable") 
local extrafile = require(folder.."extrafile") 

local tester = {}

----------------------------------------------- Module functions
function tester.run()
	logger.line("TESTS")
	local testFiles = extrafile.getFiles(folderPath.."tests/")
	for index = 1, #testFiles do
		local splitFile = extrastring.split(testFiles[index], ".")
		local filename = splitFile[1]
		local extension = splitFile[2]
		if filename and extension == "lua" then
			local testNumber = 0
			local failedTests = 0
			local requireSuccess, requireMessage = pcall(function()
				local testRequire = require(folder.."tests."..filename)
				if not extratable.isEmpty(testRequire) then
					for index, testFunction in pairs(testRequire) do
						if testRequire[index] and "function" == type(testRequire[index]) then
							testNumber = testNumber + 1
							local testSuccess, testMessage = pcall(function()
								testRequire[index]()
							end)

							if not testSuccess and testMessage then
								logger.error(filename.."."..index..[[ test failed]])
								failedTests = failedTests + 1
							end
						end
					end
				end
			end)

			if not requireSuccess and requireMessage then
				logger.error([[All tests on "]]..filename..[[" failed.]])
			else
				local loggerFunction = failedTests == 0 and logger.log or logger.error
				loggerFunction(tostring(filename)..[[ Total:]]..testNumber..[[ Failed:]]..failedTests)
			end
		end
		
	end
	logger.line()
end

return tester
