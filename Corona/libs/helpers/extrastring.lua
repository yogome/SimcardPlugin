-------------------------------------------- Extra string functions
local path = ...
local folder = path:match("(.-)[^%.]+$") 
local logger = require( folder.."logger" )

local extraString = {}
-------------------------------------------- Module Variables
local initialized
local compressDictionary
local dictionaryLenght
-------------------------------------------- Caches
local stringLen = string.len
local stringSub = string.sub
local stringGmatch = string.gmatch
local stringUpper = string.upper
local stringGsub = string.gsub
local tableConcat = table.concat
-------------------------------------------- Local functions

local function initialize()
	if not initialized then
		initialized = true
		compressDictionary = {}
		dictionaryLenght = 0
	end
end

local function initDictionary(isEncode)
	compressDictionary = {}
	local dictionaryString = " !#$%&'\"()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	dictionaryLenght = string.len(dictionaryString)
	
	for index = 1, dictionaryLenght do
		if isEncode then
			compressDictionary[string.sub(dictionaryString, index, index)] = index		
		else
			compressDictionary[index] = string.sub(dictionaryString, index, index)
		end
	end
	
end
-------------------------------------------- Module functions
function extraString.split(inputstr, separator)
	if separator == nil then
		separator = "%s"
	end
	local result = {}
	local iteration = 1
	for str in stringGmatch(inputstr, "([^"..separator.."]+)") do
		result[iteration] = str
		iteration = iteration + 1
	end
	return result
end

function extraString.firstToUpper(str)
	return (str:gsub("^%l", stringUpper))
end

function extraString.isValidEmail(str)
	return str:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?")
end

function extraString.addCommas(inputNumber)
	if inputNumber and "number" == type(inputNumber) then
		local outputStr = string.gsub(inputNumber, "(%d)(%d%d%d)$", "%1,%2", 1)
		local found
		while true do
			outputStr, found = string.gsub(outputStr, "(%d)(%d%d%d),", "%1,%2,", 1)
			if found == 0 then break end
		end
		return outputStr
	else
		logger.error("[Extra String] inputNumber must be a number")
	end
	return ""
end
function extraString.encode(sInput)
	initDictionary(true)
	
	local s = ""
	local ch
	
	local stringLenght = stringLen(sInput)
	local result = {}	
	
	local dic = compressDictionary
	local temp
		
	for index = 1, stringLenght do
		ch = stringSub(sInput, index, index)
		temp = s..ch
		if dic[temp] then
			s = temp
		else
			result[#result + 1] = dic[s]
			dictionaryLenght = dictionaryLenght + 1	
			dic[temp] = dictionaryLenght			
			s = ch
		end
	end
	result[#result + 1] = dic[s]
	
	return result
end

function extraString.decode(data)
	initDictionary(false)
	
	local dic = compressDictionary
	
	local entry
	local ch
	local prevCode, currCode
	
	local result = {}
	
	prevCode = data[1]
	result[#result + 1] = dic[prevCode]
	
	for index = 2, #data do
		currCode = data[index]
		entry = dic[currCode]
		if entry then
			ch = stringSub(entry, 1, 1)		
			result[#result + 1] = entry
		else	
			ch = stringSub(dic[prevCode], 1, 1)
			result[#result + 1] = dic[prevCode]..ch
		end
		
		dic[#dic + 1] = dic[prevCode]..ch
		
		prevCode = currCode
	end
	
	return tableConcat(result)
end

initialize()

return extraString
