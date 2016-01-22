----------------------------------------------- Button data list
----------------------------------------------- Functions
----------------------------------------------- Data
local buttonlist = {
	back = { width = 128, height = 128, defaultFile = "images/buttons/bnt_return.png", overFile = "images/buttons/bnt_return.png", onPress = playSound},
	ok = { width = 128, height = 128, defaultFile = "images/buttons/bnt_ok.png", overFile = "images/buttons/bnt_ok.png", onPress = playSound},
	play = { width = 256, height = 256, defaultFile = "images/buttons/bnt_play.png", overFile = "images/buttons/bnt_play.png", onPress = playSound},
	settings = { width = 128, height = 128, defaultFile = "images/buttons/bnt_settings.png", overFile = "images/buttons/bnt_settings.png", onPress = playSound},
	next = { width = 128, height = 112, defaultFile = "images/buttons/adelante.png", overFile = "images/buttons/adelante_02.png", onPress = playSound},
	previous = { width = 128, height = 112, defaultFile = "images/buttons/atras.png", overFile = "images/buttons/atras_02.png", onPress = playSound},
	retry = { width = 128, height = 128, defaultFile = "images/buttons/retry_01.png", overFile = "images/buttons/retry_02.png", onPress = playSound},
	pause = { width = 128, height = 128, defaultFile = "images/buttons/pause_01.png", overFile = "images/buttons/pause_02.png", onPress = playSound},
	yogodex = { width = 256, height = 256, defaultFile = "images/buttons/iconoyogodex_01.png", overFile = "images/buttons/iconoyogodex_02.png", onPress = playSound},
}

return buttonlist
