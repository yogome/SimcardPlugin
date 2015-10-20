----------------------------------------------- Library - main collection
local path = ...
local folder = path:match("(.-)[^%.]+$")
local folderPath = string.gsub(folder,"[%.]","/")
local logger = require( folder.."logger" ) 

local library = {
	banners = require( folder.."banners" ),
	charts = require( folder.."charts" ),
	colorpicker = require( folder.."colorpicker" ),
	colors = require( folder.."colors" ),
	database = require( folder.."database" ),
	dialog = require( folder.."dialog" ),
	director = require( folder.."director" ),
	eventcounter = require( folder.."eventcounter" ),
	eventmanager = require( folder.."eventmanager" ),
	
	extracollision = require( folder.."extracollision" ),
	extrafacebook = require( folder.."extrafacebook" ),
	extrafile = require( folder.."extrafile" ),
	extrajson = require( folder.."extrajson" ),
	extramath = require( folder.."extramath" ),
	extrastring = require( folder.."extrastring" ),
	extratable = require( folder.."extratable" ),
	extratime = require( folder.."extratime" ),
	
	indicator = require( folder.."indicator" ),
	internet = require( folder.."internet" ),
	keyboard = require( folder.."keyboard" ),
	localization = require( folder.."localization" ),
	logger = require( folder.."logger" ),
	mixpanel = require( folder.."mixpanel" ),
	music = require( folder.."music" ),
	offlinequeue = require( folder.."offlinequeue" ),
	parentgate = require( folder.."parentgate" ),
	particles = require( folder.."particles" ),
	patterns = require( folder.."patterns" ),
	performance = require( folder.."performance" ),
	perspective = require( folder.."perspective" ),
	protector = require( folder.."protector" ),
	robot = require( folder.."robot" ),
	sceneloader = require( folder.."sceneloader" ),
	screen = require( folder.."screen" ),
	screenfocus = require( folder.."screenfocus" ),
	scrollmenu = require( folder.."scrollmenu" ),
	sound = require( folder.."sound" ),
	spine = require( folder.."spine" ),
	storefront = require( folder.."storefront" ),
	testmenu = require( folder.."testmenu" ),
	textbox = require( folder.."textbox" ),
	tutorials = require( folder.."tutorials" ),
	uifx = require( folder.."uifx" ),
	video = require( folder.."video" ),
}

function library.runTests()
	logger.line("TESTS")
	local testFiles = library.extrafile.getFiles(folderPath.."tests/")
	for index = 1, #testFiles do
		local splitFile = library.extrastring.split(testFiles[index], ".")
		local filename = splitFile[1]
		local extension = splitFile[2]
		if filename and extension == "lua" then
			local testNumber = 0
			local failedTests = 0
			local requireSuccess, requireMessage = pcall(function()
				local testRequire = require(folder.."tests."..filename)
				if not library.extratable.isEmpty(testRequire) then
					for index, testFunction in pairs(testRequire) do
						if testRequire[index] and "function" == type(testRequire[index]) then
							testNumber = testNumber + 1
							local testSuccess, testMessage = pcall(function()
								testRequire[index]()
							end)

							if not testSuccess and testMessage then
								logger.error([[[Testing] ]]..filename.."."..index..[[ test failed]])
								failedTests = failedTests + 1
							end
						end
					end
				end
			end)

			if not requireSuccess and requireMessage then
				logger.error([[[Testing] All tests on "]]..filename..[[" failed.]])
			else
				local loggerFunction = failedTests == 0 and logger.log or logger.error
				loggerFunction([[[Testing] ]]..filename..[[ Total:]]..testNumber..[[ Failed:]]..failedTests)
			end
		end
		
	end
	logger.line()
end

return library
