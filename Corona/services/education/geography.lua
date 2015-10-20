----------------------------------------------- Geography education service
local questionManager = require("services.questions.manager") 
local localization  = require( "libs.helpers.localization" )
local extratable = require( "libs.helpers.extratable" )
local logger = require( "libs.helpers.logger" )
local json = require( "json" )

local geographyService = {}
----------------------------------------------- Variables
local flags
----------------------------------------------- Constants
local NAME_CATEGORY = "geography"
local PATH_FLAGDATA = "data/education/geography/flags.json"
----------------------------------------------- Functions 
local function getFlags(amount)
	if not flags or extratable.isEmpty(flags) then
		if pcall(function()
			local path = system.pathForFile(PATH_FLAGDATA, system.ResourceDirectory )
			local flagsFile = io.open( path, "r" )
			local savedData = flagsFile:read( "*a" )
			flags = json.decode(savedData)
			io.close(flagsFile)
		end) then
			logger.log([[[Geography] Loaded flag data]])
		else
			logger.error([[[Geography] Flag data was not loaded]])
		end
	end
	
	local returnFlags = {}
	if flags and not extratable.isEmpty(flags) and amount and amount > 0 and amount <= #flags then
		local flagsCopy = extratable.deepcopy(flags)
		
		returnFlags = extratable.getRandom(flagsCopy, amount)
	end

	return returnFlags
end

local function generateDataArray(questionType, totalQuestions)
return questionManager.generateQuestions(questionType, NAME_CATEGORY, totalQuestions)
end
----------------------------------------------- Module Functions
function geographyService.isEligible(minigameData, player)
	return true
end 

function geographyService.getEducationParameters(minigameInfo, player)
	local chosenSubcategory = minigameInfo.subcategories[math.random(1, #minigameInfo.subcategories)]

	local educationParameters = {
		subcategory = chosenSubcategory,
	}

	for index = 1, #minigameInfo.requires do
		local requireData = minigameInfo.requires[index]

		if requireData.id == "flags" then
			educationParameters.flags = getFlags(requireData.amount)
		elseif requireData.id == "countries" then
			-- TODO return countries and their info
		elseif requireData.id == "question" then
			local questionLanguage = requireData.language or localization.getLanguage()
			-- TODO return a question with its answer
			local questionDatabase = require("data.education.geography.questions")
			local languageQuestions = questionDatabase[questionLanguage]
			
			local selectedQuestions = {}
			local amount = requireData.amount
			
			
			if not requireData.amount or requireData.amount <= 1 then
				local randomIndex = math.random(1, #languageQuestions)
				local selectedQuestion = languageQuestions[randomIndex]
				educationParameters.question = extratable.deepcopy(selectedQuestion.question)
				educationParameters.answer = extratable.deepcopy(selectedQuestion.answers[selectedQuestion.correctId])
			elseif requireData.amount > 1 then
				
				if questionDatabase and not extratable.isEmpty(questionDatabase) and amount and amount > 0 and amount <= #languageQuestions then
					local languageQuestionDatabase = extratable.deepcopy(questionDatabase[questionLanguage])
					selectedQuestions = extratable.getRandom(languageQuestionDatabase, amount)
				end
				
				educationParameters.questions = {}
				educationParameters.answers = {}
				for index = 1, requireData.amount do
					educationParameters.questions[index] = selectedQuestions[index].question
					educationParameters.answers[index] = selectedQuestions[index].answers[selectedQuestions[index].correctId]
				end
			end
			
		elseif requireData.id == "words" then
			local wordLanguage = requireData.language or localization.getLanguage()
			
			educationParameters.words = {}
			for index = 1, requireData.amount do
				educationParameters.words[index] = wordLanguage == "en" and "WORD" or "PALABRA"-- TODO this is temporary.
				-- TODO if maxLength is present, return words with a length equal or less than the maxLength.
			end
			
		elseif requireData.id == "wrongAnswer" then
			local answerLanguage = requireData.language or localization.getLanguage()
			
			local questionDatabase = require("data.education.geography.questions")
			local languageQuestions = extratable.deepcopy(questionDatabase[answerLanguage])
			
			educationParameters.wrongAnswers = {}
			for index = 1, requireData.amount do
				local randomQuestionIndex = math.random(1, #languageQuestions)
				local randomAnswer = math.random(1, #languageQuestions[randomQuestionIndex].answers)
				educationParameters.wrongAnswers[index] = languageQuestions[randomQuestionIndex].answers[randomAnswer]
			end
			
		elseif requireData.id == "multipleAnswerQuestion" then
			local questionLanguage = requireData.language or localization.getLanguage()
			
			educationParameters.question = questionLanguage == "en" and "This is a question" or "Esta es una pregunta"
			educationParameters.answers = {}
			local amount = requireData.maxAnswers or 2
			for index = 1, amount do
				educationParameters.answers[index] = (questionLanguage == "en" and "Correct answer" or "Respuesta correcta")..index -- TODO this is temporary
			end
		end
	end

	return educationParameters
end

return geographyService