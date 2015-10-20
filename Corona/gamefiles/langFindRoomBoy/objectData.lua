local scenePath = ...
local folder = scenePath:match("(.-)[^%.]+$")
local assetPath = string.gsub(folder,"[%.]","/")

local CENTERX = display.contentCenterX
local CENTERY = display.contentCenterY
local SCREEN_LEFT = display.screenOriginX
local SCREEN_WIDTH = display.viewableContentWidth - SCREEN_LEFT * 2
local SCREEN_TOP = display.screenOriginY
local SCREEN_HEIGHT = display.viewableContentHeight - SCREEN_TOP * 2

local objectData = {
	fixedElements = {
		[1] = {
			isCorrect = false,
			text = "Nightstand",
			asset = assetPath.."nightstand.png",
			x = CENTERX-180,
			y = CENTERY-40,
		},
		[2] = {
			isCorrect = false,
			text = "Lamp",
			asset = assetPath.."lamp.png",
			x = CENTERX-180,
			y = CENTERY-140,
		},
		[3] = {
			isCorrect = false,
			text = "Frame",
			asset = assetPath.."frame.png",
			x = SCREEN_WIDTH*0.22,
			y = CENTERY-250,
		},
		[4] = {
			isCorrect = false,
			text = "Portrait",
			asset = assetPath.."portrait.png",
			x = CENTERX+100,
			y = SCREEN_HEIGHT*0.20,
		},
		[5] = {
			isCorrect = false,
			text = "Desk",
			asset = assetPath.."desk.png",
			x = CENTERX+250,
			y = CENTERY-40,
		},
		[6] = {
			isCorrect = true,
			text = "Clock",
			asset = assetPath.."clock.png",
			x = CENTERX+200,
			y = CENTERY-125,
		},
		[7] = {
			isCorrect = true,
			text = "Bed",
			asset = assetPath.."bed.png",
			x = CENTERX,
			y = CENTERY,
		},
		[8] = {
			isCorrect = false,
			text = "Rug",
			asset = assetPath.."rug.png",
			x = CENTERX,
			y = SCREEN_HEIGHT*0.83,
		},
		[9] = {
			isCorrect = true,
			text = "Toy Box",
			asset = assetPath.."toybox.png",
			x = SCREEN_WIDTH*0.19,
			y = CENTERY-20,
		},
		[10] = {
			isCorrect = false,
			text = "Trash Bin",
			asset = assetPath.."trashBin.png",
			x = SCREEN_LEFT+50,
			y = SCREEN_HEIGHT-80,
		},
		[11] = {
			isCorrect = false,
			text = "Toy Hiway",
			asset = assetPath.."toyHiway.png",
			x = CENTERX-300,
			y = SCREEN_HEIGHT-100,
		},
		[12] = {
			isCorrect = false,
			text = "Hanger",
			asset = assetPath.."hanger.png",
			x = SCREEN_WIDTH*0.11,
			y = SCREEN_HEIGHT-270,
		},
	},
	movingElements = {
		[1] = {
			isCorrect = true,
			text = "Book",
			asset = assetPath.."book.png",
		},
		[2] = {
			isCorrect = true,
			text = "Backpack",
			asset = assetPath.."backpack.png",
		},
		[3] = {
			isCorrect = true,
			text = "Ball",
			asset = assetPath.."ball.png",
		},
		[4] = {
			isCorrect = true,
			text = "Skateboard",
			asset = assetPath.."skateboard.png",
		},
		[5] = {
			isCorrect = true,
			text = "Teddy Bear",
			asset = assetPath.."bear.png",
		},
		[6] = {
			isCorrect = false,
			text = "Glass",
			asset = assetPath.."glass.png",
		},
		[7] = {
			isCorrect = false,
			text = "Toy Car",
			asset = assetPath.."toyCar.png",
		},
		[8] = {
			isCorrect = true,
			text = "Piggy Bank",
			asset = assetPath.."piggyBank.png",
		},
	},
	positions = {
		[1] = {
			x = CENTERX+300,
			y = CENTERY-120,
		},
		[2] = {
			x = SCREEN_WIDTH*0.20,
			y = SCREEN_HEIGHT-300,
		},
		[3] = {
			x = CENTERX-200,
			y = CENTERY+60,
		},
		[4] = {
			x = CENTERX+185,
			y = CENTERY+100,
		},
		[5] = {
			x = CENTERX+215,
			y = CENTERY+180,
		},
		[6] = {
			x = CENTERX-30,
			y = SCREEN_HEIGHT-40,
		},
		[7] = {
			x = CENTERX+300,
			y = CENTERY+80,
		},
		[8] = {
			x = CENTERX-160,
			y = CENTERY+195,
		},
	},
}

return objectData