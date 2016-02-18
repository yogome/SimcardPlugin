----------------------------------------------- Early table script interpreter
local scripts = {}

local OPERATOR_FUNCTIONS = {
	["+"] = function(a, b) return a + b end,
	["-"] = function(a, b) return a - b end,
	["/"] = function(a, b) return a / b end,
	["*"] = function(a, b) return a * b end,
	["%"] = function(a, b) return a % b end,
	["and"] = function(a, b) return a and b end,
	["or"] = function(a, b) return a or b end,
	["not"] = function(a) return not a end,
	[">"] = function(a, b) return a > b end,
	["<"] = function(a, b) return a < b end,
	["=="] = function(a, b) return a == b end,
	["<="] = function(a, b) return a <= b end,
	[">="] = function(a, b) return a >= b end,
	["~="] = function(a, b) return a ~= b end,
}

local variables = {}
local functions = {}
	
function scripts.run(script)
	for index = 1, #script do
		local instruction = script[index]
		if instruction.id == "set" then
			if instruction.value then
				variables[instruction.name] = instruction.value
			elseif instruction.instructions then
				functions[instruction.name] = instruction.instructions
			end
		elseif instruction.id == "get" then
			if instruction.variable then
				if instruction.index then
					local variable = _G[instruction.variable] or variables[instruction.variable]
					variables[instruction.name] = variable[instruction.index]
				else
					variables[instruction.name] = _G[instruction.variable] or variables[instruction.variable]
				end
			end
		elseif instruction.id == "operation" then
			local value1 = variables[instruction.variable1] or instruction.value1
			local value2 = variables[instruction.variable2] or instruction.value2
			local storeReturnID = instruction.storeReturn or "lastReturn"
			
			variables[storeReturnID] = OPERATOR_FUNCTIONS[instruction.operation](value1, value2)
		elseif instruction.id == "execute" then
			local iterations = instruction.iterations or 1
			for index = 1, iterations do
				local storeReturnID = instruction.storeReturn or "lastReturn"

				local params = {}
				if instruction.useSelf then
					params[1] = _G[instruction.variable] or variables[instruction.variable]
				end

				if instruction.parameters then
					for index = 1, #instruction.parameters do
						params[index + (instruction.useSelf and 1 or 0)] = variables[instruction.parameters[index]]
					end
				end

				if _G[instruction.variable] then
					if instruction.index then
						variables[storeReturnID] = _G[instruction.variable][instruction.index](unpack(params))
					else
						variables[storeReturnID] = _G[instruction.variable](unpack(params))
					end
				else
					if instruction.index then
						variables[storeReturnID] = variables[instruction.variable][instruction.index](unpack(params))
					else
						variables[storeReturnID] = scripts.run(functions[instruction.variable])
					end
				end
			end
		elseif instruction.id == "compare" then
			if variables[instruction.variable] then
				if functions[instruction.executeOnTrue] then
					scripts.run(functions[instruction.executeOnTrue])
				end
			else
				if functions[instruction.executeOnFalse] then
					scripts.run(functions[instruction.executeOnFalse])
				end
			end
		end
	end
end

return scripts
