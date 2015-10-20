-------------------------------------------- Colors
local path = ...
local folder = path:match("(.-)[^%.]+$")
local extratable = require( folder.."extratable" )

local colors = {
	white = {1, 1, 1},
	lighterGray = {0.9, 0.9, 0.9},
	lightGray = {0.75, 0.75, 0.75},
	gray = {0.5, 0.5, 0.5},
	darkGray = {0.25, 0.25, 0.25},
	darkestGray = {0.1,0.1,0.1},
	black = {0, 0, 0},
	lime = {0, 1, 0},
	green = {0, 0.5, 0},
	red = {1, 0, 0},
	yellow = {1, 1, 0},
	blue = {0, 0, 1},
	cyan = {0, 1, 1},
	teal = {0,0.5,0.5},
	purple = {0.5,0,0.5},
	magenta = {1, 0, 1},
	lightcyan = {0.878, 1.000, 1.000},	
	iosgrey = {0.573, 0.573, 0.573},	
	neonpink = {0.906, 0.325, 0.694},	
	indianred = {0.804, 0.361, 0.361},	
	northtexasgreen = {0.020, 0.565, 0.200},	
	kcred = {0.812, 0.000, 0.000},	
	skyblue = {0.529, 0.808, 0.980},	
	lightseagreen = {0.125, 0.698, 0.667},	
	brown = {0.545, 0.271, 0.075},	
	neoncyan = {0.063, 0.682, 0.937},	
	orange = {1.000, 0.518, 0.259},	
	iosgreen = {0.196, 0.608, 0.169},	
	mediumspringgreen = {0.000, 0.980, 0.604},	
	whitesmoke = {0.961, 0.961, 0.961},	
	iosblue = {0.000, 0.478, 1.000},	
	limegreen = {0.196, 0.804, 0.196},	
	kellygreen = {0.298, 0.733, 0.090},	
	turquoise = {0.251, 0.878, 0.816},	
	deepskyblue = {0.000, 0.749, 1.000},	
	darkbrown = {0.373, 0.231, 0.094},	
	tan = {0.545, 0.353, 0.169},	
	woolgrey = {0.561, 0.580, 0.596},	
	khaki = {0.941, 0.902, 0.549},	
	petal = {0.678, 0.353, 1.000},	
	mustard = {1.000, 0.753, 0.012},	
	oldlace = {0.976, 0.941, 0.886},	
	wheat = {0.961, 0.871, 0.702},	
	neonyellow = {0.906, 0.894, 0.145},	
	yellowgreen = {0.604, 0.804, 0.196},	
	bamboo = {0.847, 0.780, 0.663},	
	brownbag = {0.753, 0.537, 0.404},	
	maroon = {0.690, 0.188, 0.376},	
	thistle = {0.847, 0.749, 0.847},	
	darkwood = {0.522, 0.369, 0.259},	
	darksalmon = {0.914, 0.588, 0.478},	
	lavenderblush = {1.000, 0.941, 0.961},	
	deeppink = {1.000, 0.078, 0.576},	
	dodgerblue = {0.118, 0.565, 1.000},	
	palegreen = {0.596, 0.984, 0.596},	
	brightpink = {1.000, 0.753, 0.796},	
	darkgreen = {0.000, 0.392, 0.000},	
	lightskyblue = {0.529, 0.808, 0.980},	
	peach = {1.000, 0.725, 0.561},	
	navy = {0.000, 0.000, 0.502},	
	lemonchiffon = {1.000, 0.980, 0.804},	
	lightgoldenrodyellow = {0.980, 0.980, 0.824},	
	neongreen = {0.016, 0.894, 0.145},	
	darkolivegreen = {0.333, 0.420, 0.184},	
	gold = {1.000, 0.843, 0.000},	
	forestgreen = {0.133, 0.545, 0.133},	
	pink = {1.000, 0.000, 1.000},	
	orangeRed = {1.000, 0.218, 0.059},
	honeydew = {0.941, 1.000, 0.941},	
	hotpink = {1.000, 0.412, 0.706},	
	powderblue = {0.690, 0.878, 0.902},	
	darkred = {0.627, 0.000, 0.000},	
	limeGreen = {0.196, 0.804, 0.196},	
	violetred = {0.816, 0.125, 0.565},
}
------------------------------------------- Variables
------------------------------------------- Constants
local ONE_DIVIDED_BY_256 = 0.00390625 
------------------------------------------- Functions
local function modifyObject(object)
	local oldMetatable = getmetatable(object)
	local metatable = {
		r = 1,
		g = 1,
		b = 1,
		a = 1,
		__index = function(self, key)
			if key == "r" or key == "g" or key == "b" or key == "a" then
				return getmetatable(self)[key]
			else
				return oldMetatable.__index(self, key)
			end
		end,
		__newindex = function(self, key, value)
			getmetatable(self)[key] = value
			if key == "r" or key == "g" or key == "b" or key == "a" then
				self:setFillColor(self.r or 1, self.g or 1, self.b or 1, self.a or 1)
			else
				return oldMetatable.__newindex(self, key, value)
			end
		end
	}
	local originalSetFillColor = object.setFillColor
	object.setFillColor = function(...)
		local colorData = {...}
		if #colorData == 2 then
			metatable.r = colorData[2]
			metatable.g = colorData[2]
			metatable.b = colorData[2]
		elseif #colorData == 3 then
			metatable.r = colorData[2]
			metatable.g = colorData[2]
			metatable.b = colorData[2]
			metatable.a = colorData[3]
		elseif #colorData == 4 then
			metatable.r = colorData[2]
			metatable.g = colorData[3]
			metatable.b = colorData[4]
		elseif #colorData == 5 then
			metatable.r = colorData[2]
			metatable.g = colorData[3]
			metatable.b = colorData[4]
			metatable.a = colorData[5]
		end
		originalSetFillColor(...)
	end
	setmetatable(object, metatable)
end

local function setupMetatable()
	local metatable = {
		__index = function(self, key)
		   local value = getmetatable(self)[key]
		   return value or {1}
		end,
		__newindex = function()
			
		end
	}
	setmetatable(colors, metatable)
end
------------------------------------------- Module functions
function colors.addColorTransition(displayObject)
	if displayObject and "table" == type(displayObject) and displayObject.setFillColor then
		modifyObject(displayObject)
	end
end

function colors.convertFrom256(color)
	if color then
		local newColor = extratable.deepcopy(color)
		for index = 1, #newColor do
			newColor[index] = newColor[index] * ONE_DIVIDED_BY_256
		end
		return newColor
	end
end

function colors.convertFromHex(hex)
	if hex and "string" == type(hex) then
		local colorAmount = math.ceil(string.len(hex) * 0.5)
		if colorAmount > 0 then
			local color = {}
			for index = 1, colorAmount do
				local offset = ((index - 1) * 2)
				local hexColor = string.sub(hex, 1 + offset, 2 + offset)
				local color256 = tonumber(hexColor, 16)
				color[index] = color256
			end
			return colors.convertFrom256(color)
		end
	end
end

function colors.HSLToRGB(h, s, l)
	if s == 0 then return l*.01,l*.01,l*.01 end
	local c, h = (1-math.abs(2*(l*.01)-1))*(s*.01), (h%360)/60
	local x, m = (1-math.abs(h%2-1))*c, ((l*.01)-.5*c)
	c = ({{c,x,0},{x,c,0},{0,c,x},{0,x,c},{x,0,c},{c,0,x}})[math.ceil(h)] or {c,x,0}
	return (c[1]+m),(c[2]+m),(c[3]+m)
end

function colors.HSVToRGB(h,s,v)
	if s == 0 then return v*.01,v*.01,v*.01 end
	local c, h = ((s*.01)*(v*.01)), (h%360)/60
	local x, m = c*(1-math.abs(h%2-1)), (v*.01)-c
	c = ({{c,x,0},{x,c,0},{0,c,x},{0,x,c},{x,0,c},{c,0,x}})[math.ceil(h)] or {c,x,0}
	return (c[1]+m),(c[2]+m),(c[3]+m)
end

setupMetatable()

return colors
