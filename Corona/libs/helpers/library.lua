----------------------------------------------- Library - main collection
local path = ...
local folder = path:match("(.-)[^%.]+$")
local folderPath = string.gsub(folder,"[%.]","/")
local logger = require( folder.."logger" ) 

local library = {
	banners = require( folder.."banners" ),
	charts = require( folder.."charts" ),
	colorpicker = require( folder.."colorpicker" ),
	colors = require( folder.."colors" ),
	database = require( folder.."database" ),
	dialog = require( folder.."dialog" ),
	director = require( folder.."director" ),
	eventcounter = require( folder.."eventcounter" ),
	eventmanager = require( folder.."eventmanager" ),
	
	extracollision = require( folder.."extracollision" ),
	extrafacebook = require( folder.."extrafacebook" ),
	extrafile = require( folder.."extrafile" ),
	extrajson = require( folder.."extrajson" ),
	extramath = require( folder.."extramath" ),
	extrastring = require( folder.."extrastring" ),
	extratable = require( folder.."extratable" ),
	extratime = require( folder.."extratime" ),
	
	indicator = require( folder.."indicator" ),
	internet = require( folder.."internet" ),
	keyboard = require( folder.."keyboard" ),
	localization = require( folder.."localization" ),
	logger = require( folder.."logger" ),
	mixpanel = require( folder.."mixpanel" ),
	music = require( folder.."music" ),
	offlinequeue = require( folder.."offlinequeue" ),
	parentgate = require( folder.."parentgate" ),
	particles = require( folder.."particles" ),
	patterns = require( folder.."patterns" ),
	performance = require( folder.."performance" ),
	perspective = require( folder.."perspective" ),
	protector = require( folder.."protector" ),
	robot = require( folder.."robot" ),
	sceneloader = require( folder.."sceneloader" ),
	screen = require( folder.."screen" ),
	screenfocus = require( folder.."screenfocus" ),
	scrollmenu = require( folder.."scrollmenu" ),
	sound = require( folder.."sound" ),
	spine = require( folder.."spine" ),
	storefront = require( folder.."storefront" ),
	testmenu = require( folder.."testmenu" ),
	textbox = require( folder.."textbox" ),
	tutorials = require( folder.."tutorials" ),
	uifx = require( folder.."uifx" ),
	video = require( folder.."video" ),
}

return library
