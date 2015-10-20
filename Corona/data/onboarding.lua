----------------------------------------------- Onboarding data

---------------------------------------------- Variables
local nextSceneName
local onLanguageChosen
local isShort
local notificationList
---------------------------------------------- Constants
local NAME_FIRST_SCENE = "scenes.login.language"
local NAME_NEXT_SCENE_DEFAULT = "scenes.menus.home"

local onboardingData = {
	[1] = {key = "validLogin", description = "Used to check if login user is valid"},
	[2] = {key = "currentUserEmail", description = "Used to make connections to server"},
	[3] = {key = "currentUserPassword", description = "Used to make connections to server"},
	
	[4] = {key = "validSubscription", description = "True if user is subscribed"},
	[5] = {key = "tempValidSubscription", description = "Time in seconds from 1970 to have a temporary valid subscription"},
	[6] = {key = "minigameCredits", description = "Number used to play minigames"},
}

function onboardingData.setNextScene(sceneName)
	nextSceneName = sceneName
end

function onboardingData.getFirstSceneName()
	return NAME_FIRST_SCENE
end

function onboardingData.getNextSceneName()
	return nextSceneName or NAME_NEXT_SCENE_DEFAULT
end

function onboardingData.getOnLanguageChosen()
	return onLanguageChosen
end

function onboardingData.setOnLanguageChosen(newFunction)
	if newFunction and "function" == type(newFunction) then
		onLanguageChosen = newFunction
	end
end

function onboardingData.getNotificationList()
	return notificationList
end

function onboardingData.setNotificationList(newNotificationList)
	notificationList = newNotificationList
end

function onboardingData.setIsShort(short)
	isShort = short
end

function onboardingData.isShort()
	return isShort and isShort
end

---------------------------------------------- Execution
for index = 1, #onboardingData do
	onboardingData[onboardingData[index].key] = onboardingData[index]
end

return onboardingData
