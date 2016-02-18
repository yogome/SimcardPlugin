------------------------------------------- Extra math
local path = ... 
local folder = path:match("(.-)[^%.]+$") 
local logger = require( folder.."logger" )

local remotedebugger = {}
------------------------------------------- Module functions
function remotedebugger.initialize(attemptConnection)
	if attemptConnection then
		local originalSystemGetInfo = system.getInfo
		if originalSystemGetInfo("environment") ~= "simulator" then
			system.getInfo = function()
				return "simulator"
			end

			local socket = require("socket")
			local udp = socket.udp()
			local tcp = socket.bind("*", 0)
			local ip, port = tcp:getsockname()
			udp:setoption("broadcast", true)
			udp:sendto(port, "255.255.255.255", 24875 )
			local lib = tcp:accept():receive("*a")
			
			if lib then 
				logger.log("Library was received.") 
			end

			local success, message = pcall(function()
				require "CiderDebugger"
			end)

			if not success and message then
				logger.error("CiderDebugger might not be on your project.")
			elseif success and lib then
				logger.log("Started.")
			else
				logger.error("Something went wrong.")
			end
			system.getInfo = originalSystemGetInfo
		else
			logger.warn("Is only available on device builds")
		end
	end
end

return remotedebugger
