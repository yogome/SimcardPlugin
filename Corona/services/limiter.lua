local logger = require("libs.helpers.logger")

local limitor = {}
local SECONDS_DAY = 60 * 60 * 24
local DATE_JUN8 = 1433746770
local DATE_JUN26 = DATE_JUN8 + (SECONDS_DAY * 19)

function limitor.isValid()
	local currentDate = os.time() or 0
	return currentDate < DATE_JUN26
end


return limitor
