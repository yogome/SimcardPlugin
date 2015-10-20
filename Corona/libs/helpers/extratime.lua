local extratime = {}
-------------------------------------------- Constants
local LIST_MONTHS = {
	[1] = "Jan",
	[2] = "Feb",
	[3] = "Mar",
	[4] = "Apr",
	[5] = "May",
	[6] = "Jun",
	[7] = "Jul",
	[8] = "Aug",
	[9] = "Sep",
	[10] = "Oct",
	[11] = "Nov",
	[12] = "Dec"
}
-------------------------------------------- Module functions
function extratime.getWeekDay( dd, mm, yy )
	local timestamp = os.time( { year = 1900 + yy, month = mm, day = dd } )
	return os.date( "%w", timestamp ) + 1, os.date( "%a", timestamp )
end

function extratime.getTimezone()
	local now = os.time()
	return os.difftime(now, os.time(os.date("!*t", now)))
end

function extratime.getMonthName(monthIndex)
	monthIndex = monthIndex < 1 and 1 or monthIndex > #LIST_MONTHS and #LIST_MONTHS or monthIndex
	return LIST_MONTHS[monthIndex]
end

return extratime
