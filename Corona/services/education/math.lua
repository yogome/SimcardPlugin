----------------------------------------------- Math education service
local logger = require("libs.helpers.logger")
local mathRestrictions = require("data.education.math.restrictions")
local extramath = require("libs.helpers.extramath")
local extratable = require("libs.helpers.extratable")

local mathService = {}
----------------------------------------------- Variables
----------------------------------------------- Constants
local TOLERANCE_MULTIPLIER = 2
local MAX_WRONG_REPEAT_ATTEMPTS = 100

local OPERATORS = {
	["addition"] = "+",
	["subtraction"] = "-",
	["division"] = "/",
	["multiplication"] = "*",
} 
----------------------------------------------- Caches
local mathMax = math.max 
local mathMin = math.min
local mathRandom = math.random
local mathCeil = math.ceil
local unpack = unpack
----------------------------------------------- Functions 
local function createOperation(topic, requireData, level, player)
	player = player or {}
	local grade = player.grade or 1
	
	local topicRestrictions = mathRestrictions.grade[grade].topics[topic] or {}
	
	local operands = requireData.operands or 2
	local minAnswer = requireData.minAnswer or topicRestrictions.minAnswer or 0
	local maxAnswer = requireData.maxAnswer or topicRestrictions.maxAnswer
	local minOperand = requireData.minOperand or topicRestrictions.minOperand or 0
	local maxOperand = requireData.maxOperand or topicRestrictions.maxOperand
	local operandOrder = topicRestrictions.operandOrder
	
	if topic == "addition" then
		return mathService.createAddition(level, operands, maxAnswer, minAnswer, maxOperand, minOperand, operandOrder)
	elseif topic == "subtraction" then
		return mathService.createSubtraction(level, operands, maxAnswer, minAnswer, maxOperand, minOperand)
	elseif topic == "multiplication" then
		return mathService.createMultiplication(level, operands, maxAnswer, minAnswer, maxOperand)
	elseif topic == "division" then
		return mathService.createDivision(level, maxAnswer, minAnswer, maxOperand)
	elseif topic == "fractions" then
		
		local unique = requireData.unique or topicRestrictions.unique
		local maxDenominator = requireData.maxDenominator
		local maxNumerator = requireData.maxNumerator
		
		return mathService.createFractions(level, maxNumerator, maxDenominator, unique)
	else
		logger.error("[Math education] topic was not found")
	end
end

local function getMultiplication(number, maxDepth, multiplication, currentDepth)
	currentDepth = currentDepth or 1
	currentDepth = currentDepth + 1
	multiplication = multiplication or {number}
	local answerFactors = extramath.factors(number)


	local multiplications = mathCeil(#answerFactors * 0.5)
	local selectedMultiplication = mathRandom(1,multiplications)

	multiplication[#multiplication] = answerFactors[selectedMultiplication]
	multiplication[#multiplication + 1] = answerFactors[#answerFactors - selectedMultiplication + 1]

	if currentDepth < maxDepth then
		getMultiplication(multiplication[#multiplication], maxDepth, multiplication, currentDepth)
	end

	return multiplication
end

local function selectTopic(minigameInfo, player)
	player = player or {}
	
	local minigameTopics = minigameInfo.subcategories
	
	local playerGrade = player.grade or 1
	local gradeTopicRestrictions = mathRestrictions.grade[playerGrade].topics or {}
	local gradeTopics = {}
	for topic, data in pairs(gradeTopicRestrictions) do
		gradeTopics[#gradeTopics + 1] = topic
	end

	local matchingTopics = {}
	for gradeIndex = 1, #gradeTopics do
		for minigameIndex = 1, #minigameTopics do
			if minigameTopics[minigameIndex] == gradeTopics[gradeIndex] then
				matchingTopics[#matchingTopics + 1] = minigameTopics[minigameIndex]
			end
		end
	end
	
	if #matchingTopics <= 0 then
		logger.error([[[Math Service] there were no matching topics for minigame "]]..tostring(minigameInfo.folderName)..[[". Will use "]]..tostring(minigameTopics[1])..[["]])
		matchingTopics[1] = minigameTopics[1]
	end
	
	local selectedTopic = matchingTopics[mathRandom(1, #matchingTopics)]
	
	player.educationData = player.educationData or {}
	player.educationData["math"] = player.educationData["math"] or {}
	player.educationData["math"][selectedTopic] = player.educationData["math"][selectedTopic] or {level = 1}
	player.educationData["math"][selectedTopic].level = player.educationData["math"][selectedTopic].level or 1
	
	return unpack({selectedTopic, player.educationData["math"][selectedTopic].level})
end

local function createWrongAnswers(amount, requireData, operations, unique)
	local tolerance = requireData.tolerance or (TOLERANCE_MULTIPLIER * amount)
	local target = requireData.target or "result" -- Can be "operand"

	local correctAnswers = {}
	for index = 1, #operations do
		if target == "result" then
			correctAnswers[#correctAnswers + 1] = operations[index].result
		elseif target == "operand" then
			for operandIndex = 1, #operations.operands do
				correctAnswers[#correctAnswers + 1] = operations.operands[operandIndex]
			end
		end
	end
	
	local maxNumber = requireData.maxNumber or mathMax(unpack(correctAnswers)) + tolerance
	local minNumber = requireData.minNumber or mathMin(unpack(correctAnswers)) - tolerance
	minNumber = minNumber >= 0 and minNumber or 0

	local maxCombinations = maxNumber - minNumber
	for index = 1, #operations do
		if target == "result" then
			if minNumber <= operations[index].result and operations[index].result <= maxNumber then
				maxCombinations = maxCombinations - 1
			end
		elseif target == "operand" then
			for operandIndex = 1, #operations.operands do
				if minNumber <= operations.operands[operandIndex] and operations.operands[operandIndex] <= maxNumber then
					maxCombinations = maxCombinations - 1
				end
			end
		end
	end
	if maxCombinations < amount then
		logger.log("[Math Service] Wrong numbers cannot be unique, not enough combinations!")
		unique = false
	end
		
	local wrongNumbers = {}
	for index = 1, amount do
		local numberOK = true
		local number = mathRandom(minNumber, maxNumber)
		local repeatAttempts = 0
		repeat
			repeatAttempts = repeatAttempts + 1
			numberOK = true
			number = mathRandom(minNumber, maxNumber)
			
			for correctIndex = 1, #correctAnswers do
				if number == correctAnswers[correctIndex] then
					numberOK = false
				end
			end
			
			if unique then
				for index = 1, #wrongNumbers do
					if number == wrongNumbers[index] then
						numberOK = false
					end
				end
			end
		until numberOK or repeatAttempts >= MAX_WRONG_REPEAT_ATTEMPTS
		
		if repeatAttempts >= MAX_WRONG_REPEAT_ATTEMPTS then
			logger.error("[Math education] could not calculate wrong number")
		end
		
		wrongNumbers[index] = number
	end
	
	return wrongNumbers
end
----------------------------------------------- Module Functions
function mathService.createAddition(level, numOperands, maxAnswer, minAnswer, maxOperand, minOperand, operationOrder)
	minOperand = minOperand or 0
	local answer, operands, operationOK
	local operationOrder = operationOrder or "random"
	
	numOperands = numOperands > 1 and numOperands or 2
	
	repeat 
		operationOK = true
		answer = mathRandom(minAnswer, maxAnswer)

		operands = {}
		repeat
			operands[1] = mathRandom(0, answer - (numOperands - 2))
		until operands[1] <= maxOperand

		local totalSum = operands[1]
		local operandsLeft = numOperands - 1
		for index = 1, operandsLeft do
			if operandsLeft <= 1 then
				local operand = answer - operands[1]
				operands[#operands + 1] = operand
			else
				if index == operandsLeft then
					local operand = answer - totalSum
					operands[#operands + 1] = operand
				else
					local operand = mathRandom(0, answer - totalSum)
					operands[#operands + 1] = operand
					totalSum = totalSum + operand
				end
			end
		end
		
		for index = 1, #operands do
			if operands[index] > maxOperand then
				operationOK = false
			elseif operands[index] < minOperand then
				operationOK = false
			end
		end
	until operationOK
	
	if operationOrder == "descending" then
		table.sort(operands, function(a,b) return a > b end)
	elseif operationOrder == "ascending" then
		table.sort(operands)
	end
	
	local operationString = ""
	for index = 1, #operands do
		operationString = operationString..operands[index]
		if index < #operands then
			operationString = operationString.."+"
		end
	end
	operationString = operationString.."="..answer
	
	local operation = {
		operands = operands,
		result = answer,
		operator = "+",
		operationString = operationString,
	}
	
	return operation
end 

function mathService.createSubtraction(level, numOperands, maxAnswer, minAnswer, maxOperand, minOperand)
	minOperand = minOperand or 0
	local answer, operands, operationOK
	
	numOperands = numOperands > 1 and numOperands or 2
	
	if maxOperand < maxAnswer then
		logger.error("maxOperand must be greater or equal than maxAnswer on subctractions, setting maxOperand to maxAnswer")
		maxOperand = maxAnswer
	end
	
	repeat 
		operationOK = true
		
		local operandsLeft = numOperands - 1
		operands = {}
		repeat
			operands[1] = mathRandom(maxAnswer, maxOperand)
		until operands[1] - maxOperand * operandsLeft <= maxAnswer
		answer = mathRandom(minAnswer, maxAnswer)
		
		local amountLeft = operands[1] - answer
		for index = 1, operandsLeft do
			if operandsLeft <= 1 then
				operands[#operands + 1] = operands[1] - answer
			else
				if index == operandsLeft then
					local operand = amountLeft
					operands[#operands + 1] = operand
				else
					local operand = mathRandom(0, amountLeft)
					operands[#operands + 1] = operand
					amountLeft = amountLeft - operand
				end
			end
		end
		
		for index = 1, #operands do
			if operands[index] > maxOperand then
				operationOK = false
			elseif operands[index] < minOperand then
				operationOK = false
			end
		end
	until operationOK
	
	local operationString = ""
	for index = 1, #operands do
		operationString = operationString..operands[index]
		if index < #operands then
			operationString = operationString.."-"
		end
	end
	operationString = operationString.."="..answer
	
	local operation = {
		operands = operands,
		result = answer,
		operator = "-",
		operationString = operationString,
	}
	
	return operation
end 

function mathService.createMultiplication(level, numOperands, maxAnswer, minAnswer, maxOperand)
	local answer, operands, operationOK
	
	numOperands = numOperands > 1 and numOperands or 2
	
	repeat 
		operationOK = true
		repeat
			answer = mathRandom(minAnswer, maxAnswer)
			operands = getMultiplication(answer, numOperands)
		until #operands >= numOperands
		
		for index = 1, #operands do
			if operands[index] > maxOperand then
				operationOK = false
			end
--			if operands[index] == 1 then -- We could filter out 1s in the multiplication
--				operationOK = false
--			end
		end
	until operationOK
	
	local operationString = ""
	for index = 1, #operands do
		operationString = operationString..operands[index]
		if index < #operands then
			operationString = operationString.."x"
		end
	end
	operationString = operationString.."="..answer
	
	local operation = {
		operands = operands,
		result = answer,
		operator = "x",
		operationString = operationString,
	}
	
	return operation
end

function mathService.createDivision(level, maxAnswer, minAnswer, maxOperand)
	local answer, operands, operationOK
	local numOperands = 2
	
	local operands = {}
	
	operationOK = false
	repeat
		answer = mathRandom(minAnswer, maxAnswer)
		operands[2] = mathRandom(1, maxOperand)
		operands[1] = answer * operands[2]
		
		operationOK = operands[1] <= maxOperand
	until operationOK
	
	local operationString = ""
	for index = 1, #operands do
		operationString = operationString..operands[index]
		if index < #operands then
			operationString = operationString.."/"
		end
	end
	operationString = operationString.."="..answer
	
	local operation = {
		operands = operands,
		result = answer,
		operator = "/",
		operationString = operationString,
	}
	
	return operation
end

function mathService.isEligible(minigameData, player)
	player = player or {}
	local playerGrade = player.grade or 1

	local gradeTopicRestrictions = mathRestrictions.grade[playerGrade].topics or {}
	local availableTopics = {}
	for topic, data in pairs(gradeTopicRestrictions) do
		availableTopics[#availableTopics + 1] = topic
	end
	
	for availableIndex = 1, #availableTopics do
		for mimigameTopicIndex = 1, #minigameData.subcategories do
			if minigameData.subcategories[mimigameTopicIndex] == availableTopics[availableIndex] then
				return true
			end
		end
	end
	
	return false
end

function mathService.getEducationParameters(minigameInfo, player)
	player = player or {}
	local chosenTopic, level = selectTopic(minigameInfo, player)
	
	local parameters = {
		topic = chosenTopic,
	}
	
	for requireIndex = 1, #minigameInfo.requires do
		local requireData = minigameInfo.requires[requireIndex]
		if requireData.id == "operation" then
			local amount = requireData.amount or 1

			if amount <= 1 then
				parameters.operation = createOperation(chosenTopic, requireData, level, player)
			else
				parameters.operations = {}
				for index = 1, amount do
					local operation = createOperation(chosenTopic, requireData, level, player)
					parameters.operations[index] = operation
				end
			end
		elseif requireData.id == "wrongAnswer" then
			local amount = requireData.amount or 1
			local unique = requireData.unique
			if parameters.operations then
				parameters.wrongAnswers = createWrongAnswers(amount, requireData, parameters.operations, unique)
			elseif parameters.operation then
				parameters.wrongAnswers = createWrongAnswers(amount, requireData, {parameters.operation}, unique)
			else
				logger.error([[[Math education] No wrong answers can be provided for "]]..tostring(minigameInfo.folderName)..[[" because there are no operations.]])
			end
		elseif requireData.id == "number" then
			parameters.numbers = parameters.numbers or {}
			local amount = requireData.amount or 1
			local minimum = requireData.minimum or 0
			local maximum = requireData.maximum or 100
			for index = 1, amount do
				parameters.numbers[#parameters.numbers + 1] = mathRandom(minimum, maximum)
			end
		end
	end
	
	return parameters
end

function mathService.testOperationCreation()
	local ADD_MAXRESULT = 50
	local ADD_MINRESULT = 10
	local ADD_MAXOPERAND = 20
	
	for indexA = 1, 5 do
		for index = 1, 50 do
			local addition = mathService.createAddition(1, indexA, ADD_MAXRESULT, ADD_MINRESULT, ADD_MAXOPERAND)
			assert(extramath.sum(addition.operands) == addition.result)
			for operandIndex = 1, #addition.operands do
				assert(addition.operands[operandIndex] <= ADD_MAXOPERAND, tostring(addition.operands[operandIndex]).." is greater than "..ADD_MAXOPERAND)
			end
			assert(addition.result <= ADD_MAXRESULT)
			assert(addition.result >= ADD_MINRESULT)
		end
	end
	logger.log("[Math Test] createAddition test passed")
	
	local SUB_MAXRESULT = 20
	local SUB_MINRESULT = 10
	local SUB_MAXOPERAND = 50
	
	local function subtractAll(subTable)
		local subtraction = subTable[1]
		for index = 2, #subTable do
			subtraction = subtraction - subTable[index]
		end
		return subtraction
	end
	for indexA = 1, 5 do
		for index = 1, 50 do
			local subtraction = mathService.createSubtraction(1, indexA, SUB_MAXRESULT, SUB_MINRESULT, SUB_MAXOPERAND)
			assert(subtractAll(subtraction.operands) == subtraction.result)
			for operandIndex = 1, #subtraction.operands do
				assert(subtraction.operands[operandIndex] <= SUB_MAXOPERAND, tostring(subtraction.operands[operandIndex]).." is greater than "..SUB_MAXOPERAND)
			end
			assert(subtraction.result <= SUB_MAXRESULT)
			assert(subtraction.result >= SUB_MINRESULT)
		end
	end
	
	logger.log("[Math Test] createSubtraction test passed")
	
	local MULT_MAXRESULT = 200
	local MULT_MINRESULT = 10
	local MULT_MAXOPERAND = 100
	
	local function multiplyAll(multTable)
		local multiplication = multTable[1]
		for index = 2, #multTable do
			multiplication = multiplication * multTable[index]
		end
		return multiplication
	end
	for indexA = 1, 5 do
		for index = 1, 50 do
			local multiplication = mathService.createMultiplication(1, indexA, MULT_MAXRESULT, MULT_MINRESULT, MULT_MAXOPERAND)
			assert(multiplyAll(multiplication.operands) == multiplication.result)
			for operandIndex = 1, #multiplication.operands do
				assert(multiplication.operands[operandIndex] <= MULT_MAXOPERAND, tostring(multiplication.operands[operandIndex]).." is greater than "..MULT_MAXOPERAND)
			end
			assert(multiplication.result <= MULT_MAXRESULT)
			assert(multiplication.result >= MULT_MINRESULT)
		end
	end
	logger.log("[Math test] createMultiplication test passed")
	
	local DIV_MAXRESULT = 10
	local DIV_MINRESULT = 2
	local DIV_MAXOPERAND = 200
	
	for index = 1, 50 do
		local division = mathService.createDivision(1, DIV_MAXRESULT, DIV_MINRESULT, DIV_MAXOPERAND)
		assert(division.operands[1]/division.operands[2] == division.result)
		for operandIndex = 1, #division.operands do
			assert(division.operands[operandIndex] <= DIV_MAXOPERAND, tostring(division.operands[operandIndex]).." is greater than "..DIV_MAXOPERAND)
		end
		assert(division.result <= DIV_MAXRESULT)
		assert(division.result >= DIV_MINRESULT)
	end
	logger.log("[Math test] createDivision test passed")
end

return mathService