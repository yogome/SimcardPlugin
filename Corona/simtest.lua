local simcard = require "plugin.simcard"

timer.performWithDelay( 1000, function()
	local infoText = display.newText("TEST", display.screenOriginX, display.screenOriginY, native.systemFont, 12)
	infoText.anchorX = 0
	infoText.anchorY = 0
	infoText:setFillColor(1,0,0)
	local string = ""
	string = string .. "Device ID: " .. simcard.getInfo("DeviceId") .. "\n"
	string = string .. "Device Software Version: " .. simcard.getInfo("DeviceSoftwareVersion") .. "\n"
	string = string .. "Network Operator: " .. simcard.getInfo("NetworkOperator") .. "\n"
	string = string .. "Operator Name: " .. simcard.getInfo("NetworkOperatorName") .. "\n"
	string = string .. "MCC/MNC: " .. simcard.getInfo("SimOperator") .. "\n"
	string = string .. "SIM Serial No.: " .. simcard.getInfo("SimSerialNumber") .. "\n"
	string = string .. "SIM State: " .. simcard.getInfo("SimState") .. "\n"
	string = string .. "is SMS Capable: " .. simcard.getInfo("isSMSCapable") .. "\n"
	infoText.text = string
end )

