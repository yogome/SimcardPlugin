------------------------------------------------ Question Manager
local logger = require( "libs.helpers.logger" ) 

local questionManager = {}
----------------------------------------------- Variables
local quizMode
----------------------------------------------- Functions
local function checkExistingMode(questionType, questionlist)
		for key,val in pairs(questionlist) do
			if key == questionType then
				return true
			end
		end
	return false
end

local function shuffleNumbers(number)
	local randomInit = math.random(1, number)
	local numberStack = {}
	
	for stackIndex = 1, number do
		numberStack[stackIndex] = stackIndex
	end
	
	for randomIndex = 1, number * 5 do
		local indexPosition = math.random(1, #numberStack)
		local lastIndexPosition = math.random(1, #numberStack)
		local tempNumber = 0
		if indexPosition == lastIndexPosition then
			indexPosition = math.random(1, #numberStack)
		end

		tempNumber = numberStack[indexPosition]
		numberStack[indexPosition] = numberStack[lastIndexPosition]
		numberStack[lastIndexPosition] = tempNumber
	end
	
	return numberStack
end

local function randomizeQuestions(questionArray, totalQuestions)
	local generatedQuestions = {}
	local shuffledIndexes

	if totalQuestions > #questionArray.questions then
		totalQuestions = #questionArray.questions
	end
	
	shuffledIndexes = shuffleNumbers(#questionArray.questions)
	
	for generatedIndex = 1, totalQuestions do
		local shuffledIndex = shuffledIndexes[generatedIndex]
		generatedQuestions[generatedIndex] = questionArray.questions[shuffledIndex]
	end
	
	return generatedQuestions
end
----------------------------------------------- Module functions
function questionManager.generateQuestions(questionType, category, totalQuestions)
	
	questionManager.posibleAnswers = {}
	
	local answers = {}
	local data = {}
	local questionlist
	local success, errorMessage = pcall(function()
		questionlist = require("data.questions." .. category)
	end)
	
	if not success and errorMessage then
		logger.error("[Question Manager] Error loading question module for "..category)
	else
		if checkExistingMode(questionType, questionlist) then
			data.questions = randomizeQuestions(questionlist[questionType], totalQuestions)
			quizMode = questionType
			data.answers = questionlist[questionType].answers
		end
		return data
	end
end

function questionManager.getAnswers()
	return questionManager.answers
end

return questionManager
