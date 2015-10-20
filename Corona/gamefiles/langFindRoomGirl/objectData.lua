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
			isCorrect = true,
			text = "Lamp",
			asset = assetPath.."lamp.png",
			x = CENTERX-180,
			y = CENTERY-140,
		},
		[3] = {
			isCorrect = true,
			text = "DollHouse",
			asset = assetPath.."dollHouse.png",
			x = CENTERX+100,
			y = CENTERY-50,
		},
		[4] = {
			isCorrect = true,
			text = "Mirror",
			asset = assetPath.."mirror.png",
			x = SCREEN_WIDTH*0.25,
			y = CENTERY - 235,
		},
		[5] = {
			isCorrect = true,
			text = "Trash Can",
			asset = assetPath.."trashBin.png",
			x = SCREEN_WIDTH*0.20,
			y = CENTERY-40,
		},
		[6] = {
			isCorrect = false,
			text = "Chair",
			asset = assetPath.."chair.png",
			x = SCREEN_WIDTH*0.75,
			y = CENTERY,
		},
		[7] = {
			isCorrect = true,
			text = "Boudoir",
			asset = assetPath.."boudoir.png",
			x = SCREEN_WIDTH*0.10,
			y = CENTERY+120,
		},
		[8] = {
			isCorrect = false,
			text = "Parasol",
			asset = assetPath.."parasol.png",
			x = CENTERX+230,
			y = CENTERY+205,
		},
		[9] = {
			isCorrect = true,
			text = "Tea set",
			asset = assetPath.."kettle.png",
			x = CENTERX-165,
			y = CENTERY+65,
		},
	},
	movingElements = {
		[1] = {
			isCorrect = false,
			text = "Purse",
			asset = assetPath.."purse.png",
		},
		[2] = {
			isCorrect = true,
			text = "Penholder",
			asset = assetPath.."penholder.png",
		},
		[3] = {
			isCorrect = false,
			text = "Cup",
			asset = assetPath.."cup.png",
		},
		[4] = {
			isCorrect = false,
			text = "Notebook",
			asset = assetPath.."notebook.png",
		},
		[5] = {
			isCorrect = false,
			text = "Shoes",
			asset = assetPath.."shoes.png",
		},
		[6] = {
			isCorrect = false,
			text = "Spoon",
			asset = assetPath.."spoon.png",
		},
		[7] = {
			isCorrect = true,
			text = "Comb",
			asset = assetPath.."brush.png",
		},
		[8] = {
			isCorrect = true,
			text = "Doll",
			asset = assetPath.."doll.png",
		},
		[9] = {
			isCorrect = true,
			text = "Bracelet",
			asset = assetPath.."bracelet.png",
		},
		[10] = {
			isCorrect = false,
			text = "Radio",
			asset = assetPath.."radio.png",
		},
		[11] = {
			isCorrect = false,
			text = "Keys",
			asset = assetPath.."keys.png",
		},
		[12] = {
			isCorrect = false,
			text = "Smartphone",
			asset = assetPath.."telephone.png",
		},
	},
	positions = {
		[1] = {
			x = CENTERX-300,
			y = CENTERY+75,
		},
		[2] = {
			x = CENTERX-300,
			y = CENTERY+195,
		},
		[3] = {
			x = CENTERX-65,
			y = CENTERY+255,
		},
		[4] = {
			x = CENTERX-15,
			y = CENTERY+120,
		},
		[5] = {
			x = CENTERX-165,
			y = CENTERY+185,
		},
		[6] = {
			x = CENTERX-215,
			y = CENTERY+280,
		},
		[7] = {
			x = CENTERX+80,
			y = CENTERY+80,
		},
		[8] = {
			x = CENTERX+60,
			y = CENTERY+195,
		},
		[9] = {
			x = CENTERX+60,
			y = CENTERY+310,
		},
		[10] = {
			x = CENTERX+230,
			y = CENTERY+100,
		},
		[11] = {
			x = CENTERX-430,
			y = CENTERY+300,
		},
		[12] = {
			x = CENTERX+205,
			y = CENTERY+285,
		},
	},
}

return objectData