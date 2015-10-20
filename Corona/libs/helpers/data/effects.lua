local CONTENT_CENTER_X = display.contentCenterX
local CONTENT_CENTER_Y = display.contentCenterY
local VIEWABLE_CONTENT_WIDTH = display.viewableContentWidth
local VIEWABLE_CONTENT_HEIGHT = display.viewableContentHeight

local LIST_EFFECTS = {
	["fade"] = {
		["from"] = {
			alphaStart = 1.0,
			alphaEnd = 0,
		},

		["to"] = {
			alphaStart = 0,
			alphaEnd = 1.0
		}
	},
	
	["zoomOutIn"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 0.001,
			yScaleEnd = 0.001
		},

		["to"] = {
			xScaleStart = 0.001,
			yScaleStart = 0.001,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0
		},
		hideOnOut = true
	},
	
	["zoomOutInFade"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 0.001,
			yScaleEnd = 0.001,
			alphaStart = 1.0,
			alphaEnd = 0
		},

		["to"] = {
			xScaleStart = 0.001,
			yScaleStart = 0.001,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			alphaStart = 0,
			alphaEnd = 1.0
		},
		hideOnOut = true
	},
	
	["zoomInOut"] = {
		["from"] = {
			xEnd = -CONTENT_CENTER_X,
			yEnd = -CONTENT_CENTER_Y,
			xScaleEnd = 2.0,
			yScaleEnd = 2.0
		},

		["to"] = {
			xScaleStart = 2.0,
			yScaleStart = 2.0,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = -CONTENT_CENTER_X,
			yStart = -CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0
		},
		hideOnOut = true
	},
	
	["zoomInOutFade"] = {
		["from"] = {
			xEnd = -CONTENT_CENTER_X,
			yEnd = -CONTENT_CENTER_Y,
			xScaleEnd = 2.0,
			yScaleEnd = 2.0,
			alphaStart = 1.0,
			alphaEnd = 0
		},

		["to"] = {
			xScaleStart = 2.0,
			yScaleStart = 2.0,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = -CONTENT_CENTER_X,
			yStart = -CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			alphaStart = 0,
			alphaEnd = 1.0
		},
		hideOnOut = true
	},
	
	["flip"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			xScaleEnd = 0.001
		},

		["to"] = {
			xScaleStart = 0.001,
			xScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			xEnd = 0
		}
	},
	
	["flipFadeOutIn"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			xScaleEnd = 0.001,
			alphaStart = 1.0,
			alphaEnd = 0
		},

		["to"] = {
			xScaleStart = 0.001,
			xScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			xEnd = 0,
			alphaStart = 0,
			alphaEnd = 1.0
		}
	},
	
	["zoomOutInRotate"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 0.001,
			yScaleEnd = 0.001,
			rotationStart = 0,
			rotationEnd = -360
		},

		["to"] = {
			xScaleStart = 0.001,
			yScaleStart = 0.001,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			rotationStart = -360,
			rotationEnd = 0
		},
		hideOnOut = true
	},
	
	["zoomOutInFadeRotate"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 0.001,
			yScaleEnd = 0.001,
			rotationStart = 0,
			rotationEnd = -360,
			alphaStart = 1.0,
			alphaEnd = 0
		},

		["to"] = {
			xScaleStart = 0.001,
			yScaleStart = 0.001,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			rotationStart = -360,
			rotationEnd = 0,
			alphaStart = 0,
			alphaEnd = 1.0
		},
		hideOnOut = true
	},
	
	["zoomInOutRotate"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 2.0,
			yScaleEnd = 2.0,
			rotationStart = 0,
			rotationEnd = -360
		},

		["to"] = {
			xScaleStart = 2.0,
			yScaleStart = 2.0,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			rotationStart = -360,
			rotationEnd = 0
		},
		hideOnOut = true
	},
	
	["zoomInOutFadeRotate"] = {
		["from"] = {
			xEnd = CONTENT_CENTER_X,
			yEnd = CONTENT_CENTER_Y,
			xScaleEnd = 2.0,
			yScaleEnd = 2.0,
			rotationStart = 0,
			rotationEnd = -360,
			alphaStart = 1.0,
			alphaEnd = 0
		},

		["to"] = {
			xScaleStart = 2.0,
			yScaleStart = 2.0,
			xScaleEnd = 1.0,
			yScaleEnd = 1.0,
			xStart = CONTENT_CENTER_X,
			yStart = CONTENT_CENTER_Y,
			xEnd = 0,
			yEnd = 0,
			rotationStart = -360,
			rotationEnd = 0,
			alphaStart = 0,
			alphaEnd = 1.0
		},
		hideOnOut = true
	},
	
	["fromRight"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = VIEWABLE_CONTENT_WIDTH,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["fromLeft"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = -VIEWABLE_CONTENT_WIDTH,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["fromTop"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = 0,
			yStart = -VIEWABLE_CONTENT_HEIGHT,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["fromBottom"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = 0,
			yStart = VIEWABLE_CONTENT_HEIGHT,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["slideLeft"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = -VIEWABLE_CONTENT_WIDTH,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = VIEWABLE_CONTENT_WIDTH,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["slideRight"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = VIEWABLE_CONTENT_WIDTH,
			yEnd = 0,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = -VIEWABLE_CONTENT_WIDTH,
			yStart = 0,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["slideDown"] = { 
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = VIEWABLE_CONTENT_HEIGHT,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = 0,
			yStart = -VIEWABLE_CONTENT_HEIGHT,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["slideUp"] = {
		["from"] = {
			xStart = 0,
			yStart = 0,
			xEnd = 0,
			yEnd = -VIEWABLE_CONTENT_HEIGHT,
			transition = easing.outQuad
		},

		["to"] = {
			xStart = 0,
			yStart = VIEWABLE_CONTENT_HEIGHT,
			xEnd = 0,
			yEnd = 0,
			transition = easing.outQuad
		},
		concurrent = true,
		sceneAbove = true
	},
	
	["crossFade"] = {
		["from"] = {
			alphaStart = 1.0,
			alphaEnd = 0,
		},

		["to"] = {
			alphaStart = 0,
			alphaEnd = 1.0
		},
		concurrent = true
	}
}

return LIST_EFFECTS
