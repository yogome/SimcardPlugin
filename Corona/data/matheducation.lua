---------------------------------------------- Mini game dictionary
 
local ADDITION = "addition"
local SUBTRACTION = "subtraction"
local MULTIPLICATION = "multiplication"
local DIVISION = "division"

local mathedu = {}

--El 1, 8, 13, 19, 20 no deben usarse mas que del 1 al 10
--El 5 y el 17 no estan terminados
--miniGames(.*)

--COMPLETO
local MATH_ADD_DATA = {
	-- Grade
	[1] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {1,9,11,19,20,2,4,},
			--Level
			[1] = {
				hitsPerRound = {5},--{45,35,19},
				maxminResults = {2,6}, },
				--ORIGINAL se paso el lvl 2 al rank 2 por el maxResult
			[2] = {
				hitsPerRound = {5},--{45,35,19},
				maxminResults = {4,10}, },
		},

		-- Rank
		[2] = {
			miniGames = {2,3,4,6,7,10,11,12,15,18,},
			--Level
			{
				hitsPerRound = {10},
				maxminResults = {8,20}, },
			
			{	hitsPerRound = {10},
				maxminResults = {12,24}, },
			
			{	hitsPerRound = {10},
				maxminResults = {16,28}, }, 
				
			{	hitsPerRound = {10},
				maxminResults = {20,40}, },
			
			{	hitsPerRound = {10},
				maxminResults = {30,60}, }, 
				
			{	hitsPerRound = {10},
				maxminResults = {40,80}, },
		},				
	},
				
	-- Grade
	[2] = {	
		-- Rank
		[1] = {
			miniGames = {2,3,4,6,7,9,10,11,12,18,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {11,20},},
				
			{	hitsPerRound = {5},
				maxminResults = {15,30},},
				
			{	hitsPerRound = {10},
				maxminResults = {20,40},},
			
			{	hitsPerRound = {10},
				maxminResults = {30,50},},
			
			{	hitsPerRound = {11},
				maxminResults = {40,60},},
				
			{	hitsPerRound = {11},
				maxminResults = {50,70},},
				
			{	hitsPerRound = {11},
				maxminResults = {60,80},},
				
			{	hitsPerRound = {11},
				maxminResults = {80,90},},
				
			{	hitsPerRound = {10},
				maxminResults = {90,100}, }, 

			{	hitsPerRound = {10},
				maxminResults = {100,120}, },
			
			{	hitsPerRound = {10},
				maxminResults = {120,150}, }, 
		}
	},
				
	-- Grade
	[3] = {	
		-- Rank
		[1] = {
			miniGames = {2,6,7,9,3,10,12,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {20,30},},
				
			{	hitsPerRound = {5},
				maxminResults = {30,50},},

			{	hitsPerRound = {10},
				maxminResults = {50,90},},

			{	hitsPerRound = {10},
				maxminResults = {80,120},},
				
			{	hitsPerRound = {10},
				maxminResults = {100,150},},
				
			{	hitsPerRound = {10},
				maxminResults = {150,180},},
				
			{	hitsPerRound = {10},
				maxminResults = {180,200},},
		},	
	},
				
	-- Grade
	[4] = {	
		-- Rank
		[1] = {
			miniGames = {12,2,4,11,18,},
			--Level
			{	hitsPerRound = {10},
				maxminResults = {5,10},},

				
			{	hitsPerRound = {10},
				maxminResults = {80,120},},

				
			{	hitsPerRound = {10},
				maxminResults = {100,150},},
				
			{	hitsPerRound = {10},
				maxminResults = {150,200},},
				
			{	hitsPerRound = {10},
				maxminResults = {180,250},},
			
		},
				
	},
}

--COMPLETO
local MATH_SUB_DATA = {	
	-- Grade
	[1] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {1,9,11,19,20,2,4,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {1,4}, },
		},
		
		-- Rank
		[2] = {
			miniGames = {2,3,4,6,7,10,11,12,18,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {4,10}, },
				
			{	hitsPerRound = {10},
				maxminResults = {8,20}, },
				
			{	hitsPerRound = {10},
				maxminResults = {12,24}, },
			
			{	hitsPerRound = {10},
				maxminResults = {16,28}, }, 
				
			{	hitsPerRound = {10},
				maxminResults = {20,40}, },
			
			{	hitsPerRound = {10},
				maxminResults = {30,50}, },
		},
	},
	-- Grade
	[2] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {2,3,4,6,7,9,10,11,12,18,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {11,20},},
				
			{	hitsPerRound = {5},
				maxminResults = {15,30},},
				
			{	hitsPerRound = {10},
				maxminResults = {20,40},},
			
			{	hitsPerRound = {10},
				maxminResults = {30,50},},
			
			{	hitsPerRound = {20},
				maxminResults = {40,60},},
				
			{	hitsPerRound = {30},
				maxminResults = {50,70},},
				
			{	hitsPerRound = {40},
				maxminResults = {60,80},},
				
			{	hitsPerRound = {40},
				maxminResults = {80,90},},		
		},		
	},
	
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {2,6,7,9,3,10,12,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {20,30},},
				
			{	hitsPerRound = {5},
				maxminResults = {30,50},},

			{	hitsPerRound = {10},
				maxminResults = {50,90},},

				
			{	hitsPerRound = {10},
				maxminResults = {80,120},},

				
			{	hitsPerRound = {10},
				maxminResults = {100,150},},
		},
	},

	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {12,2,4,11,18,},
			--Level				
			{	hitsPerRound = {10},
				maxminResults = {5,10},},
				
			{	hitsPerRound = {10},
				maxminResults = {80,120},},
				
			{	hitsPerRound = {10},
				maxminResults = {100,150},},
				
			{	hitsPerRound = {10},
				maxminResults = {150,200},},
		},
	},
}
			
--Falta todo quinto (eperando a Mariana)
local MATH_MUL_DATA = {
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {15,8,11,18,3,15,2,7,9,},
			--Level
			{	hitsPerRound = {6},
				maxminResults = {1,5},},
		},
		-- Rank
		[2] = {
			--MiniGames
			miniGames = {15,11,18,3,15,2,6,7,9,},
			--Level
			
			{	hitsPerRound = {6},
				maxminResults = {5,15},},
			
			{	hitsPerRound = {6},
				maxminResults = {15,30},},
				
			{	hitsPerRound = {16},
				maxminResults = {30,80},},
				
			{	hitsPerRound = {16},
				maxminResults = {60,100},},
				
			{	hitsPerRound = {26},
				maxminResults = {90,130},},
				
			{	hitsPerRound = {26},
				maxminResults = {120,180},},
			
			{	hitsPerRound = {30},
				maxminResults = {150,200}, },
		},
	},
			
	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {3,12,15,18,6,9,7,10,15,},
			--Level
			{	hitsPerRound = {6},
				maxminResults = {3,5},},
			
			{	hitsPerRound = {6},
				maxminResults = {10,20},},
			
			{	hitsPerRound = {6},
				maxminResults = {20,40},},
				
			{	hitsPerRound = {6},
				maxminResults = {30,60},},
				
			{	hitsPerRound = {9},
				maxminResults = {40,80},},
			
			{	hitsPerRound = {9},
				maxminResults = {60,100},},
				
			{	hitsPerRound = {10},
				maxminResults = {90,130},},
				
			{	hitsPerRound = {10},
				maxminResults = {100,150},},
				
			{	hitsPerRound = {10},
				maxminResults = {130,200},},
		},
	},
				
	-- Grade
	[5] = {
		-- Rank
		[1] = {
			miniGames = {3,7,11,2,4,6,10,12,18,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {3,5},},
			
			{	hitsPerRound = {6},
				maxminResults = {20,40},},
				
			{	hitsPerRound = {6},
				maxminResults = {30,60},},
				
			{	hitsPerRound = {9},
				maxminResults = {40,80},},
			
			{	hitsPerRound = {9},
				maxminResults = {60,100},},
				
			{	hitsPerRound = {15},
				maxminResults = {90,130},},
				
			{	hitsPerRound = {15},
				maxminResults = {100,150},},
				
			{	hitsPerRound = {10},
				maxminResults = {130,200},},
				
			{	hitsPerRound = {10},
				maxminResults = {150,300},},
		},
	},
}

--COMPLETO
local MATH_DIV_DATA = {
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {4,6,12,2,10,16,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {1,5},},
			
			{	hitsPerRound = {5},
				maxminResults = {3,6},},
			
			{	hitsPerRound = {5},
				maxminResults = {8,20},},
		},	
	},
			
	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {3,12,15,18,6,9,7,10,15,},
			--Level
			{	hitsPerRound = {5},
				maxminResults = {3,9},},
		
			{	hitsPerRound = {5},
				maxminResults = {8,20},},
			
			{	hitsPerRound = {6},
				maxminResults = {20,40},},
				
			{	hitsPerRound = {6},
				maxminResults = {30,60},},
				
			{	hitsPerRound = {9},
				maxminResults = {40,80},},
		},
	},
	
	-- Grade
	[5] = {
		-- Rank
		[1] = {
			miniGames = {3,7,11,2,4,6,10,12,18,},
			--Level				
			{	hitsPerRound = {5},
				maxminResults = {8,10},},
			
			{	hitsPerRound = {6},
				maxminResults = {20,40},},
				
			{	hitsPerRound = {6},
				maxminResults = {30,60},},
				
			{	hitsPerRound = {9},
				maxminResults = {40,80},},
			
			{	hitsPerRound = {9},
				maxminResults = {60,100},},			
		},
	},
}

local MATH_FRA_DATA = {}

mathedu.SUBCATEGORIES = {
	-- Grade
	[1] = {ADDITION, SUBTRACTION},
	[2] = {ADDITION, SUBTRACTION},
	[3] = {ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION},
	[4] = {ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION},
	[5] = {MULTIPLICATION, DIVISION},
--	[6] = {MULTIPLICATION, DIVISION}
}

mathedu.TABLESBYNAME = {
	[ADDITION] = MATH_ADD_DATA,
	[SUBTRACTION] = MATH_SUB_DATA,
	[MULTIPLICATION] = MATH_MUL_DATA,
	[DIVISION] = MATH_DIV_DATA,	
}

--tablas originales

--[[
local MATH_ADD_DATA = {
	-- Grade
	[1] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {1,9,11,19,20,},
			--Level
			[1] = {
				hitsPerRound = {5},--{45,35,19},
				maxminResults = {2,6}, },
				--ORIGINAL se paso el lvl 2 al rank 2 por el maxResult
			[2] = {
				hitsPerRound = {5},--{45,35,19},
				maxminResults = {4,10}, },
		},

		-- Rank
		[2] = {
			miniGames = {2,4,7,12,},
			--Level
			{
				hitsPerRound = {10},--ORIGINAL {45,35,19},
				maxminResults = {8,20}, }, --ORIGINAL {11,18}, }, },
			{
				hitsPerRound = {10},--ORIGINAL {45,35,19},
				maxminResults = {12,24}, },
			{
				hitsPerRound = {10},--ORIGINAL {45,35,19},
				maxminResults = {16,28}, }, },

		-- Rank
		[3] = {
			miniGames = {6,10,},
			--Level
			[1] = {
				hitsPerRound = {45,35,19},
				maxminResults = {20,100}, },
			[2] = {
				hitsPerRound = {45,35,19},
				maxminResults = {110,180}, }, },

		-- Rank
		[4] = {
			miniGames = {4,6,11,15,},
			--Level
			[1] = {
				hitsPerRound = {45,35,19},
				maxminResults = {21,40}, },
			[2] = {
				hitsPerRound = {45,35,19},
				maxminResults = {20,50}, }, },

		-- Rank
		[5] = {
			miniGames = {18,},
			--Level
			[1] = {
				hitsPerRound = {45,35,19},
				maxminResults = {21,40}, },
			[2] = {
				hitsPerRound = {45,35,19},
				maxminResults = {20,50}, }, }, },
				
	-- Grade
	[2] = {
	
		-- Rank
		[1] = {
			miniGames = {3,10,12,18},
			--Level
			[1] = {
				hitsPerRound = {45,45,45},
				maxminResults = {11,30},},},--ORIGINAL {2,100}, },},

		-- Rank
		[2] = {
			miniGames = {2,4,},
			--Level
			[1] = {
				hitsPerRound = {45,45,45},
				maxminResults = {15,40},},},--ORIGINAL {2,100}, },},

		-- Rank
		[3] = {
			miniGames = {6,7,9,},
			--Level
			[1] = {
				hitsPerRound = {45,45,45},
				maxminResults = {20,100}, }, },

		-- Rank
		[4] = {
			miniGames = {3,11,},
			--Level
			[1] = {
				hitsPerRound = {45,45,45},
				maxminResults = {2,1000}, },},

	},
				
	-- Grade
	[3] = {
	
		-- Rank
		[1] = {
			miniGames = {2,6,7,9,},
			--Level
			[1] = {
				hitsPerRound = {45,45,45},
				maxminResults = {50,100},},--ORIGINAL {2,1000}, },},
			--Level
			[2] = { --ORIGINAL no hay nivel 2
				hitsPerRound = {45,45,45},
				maxminResults = {75,150},},
		},	
	},
				
	-- Grade
	[4] = {	
		-- Rank
		[1] = {
			miniGames = {12,},
			--Level
			[1] = {
				hitsPerRound = {25,25,25},
				maxminResults = {75,150},},--ORIGINAL {1000,2000}, },
			--Level
			[2] = { --ORIGINAL no hay nivel 2
				hitsPerRound = {45,45,45},
				maxminResults = {100,200},},
		},
				
	},
}

local MATH_SUB_DATA = {	
	-- Grade
	[1] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {2,4,},
			--Level
			[1] = {
				hitsPerRound = {30,30,30},
				maxminResults = {1,10}, },--ORIGINAL {1,21}, },
		},
		
		-- Rank
		[2] = {
			miniGames = {3,},
			--Level
			[1] = {
				hitsPerRound = {15,15,15},
				maxminResults = {1,21}, },
		},

		-- Rank
		[3] = {
			miniGames = {6,7,},
			--Level
			[1] = {
				hitsPerRound = {30,30,30},
				maxminResults = {10,51}, },
		},

		-- Rank
		[4] = {
			miniGames = {10,11,12,},
			--Level
			[1] = {
				hitsPerRound = {20,20,20},
				maxminResults = {1,99}, },
			[2] = {
				hitsPerRound = {20,20,20},
				maxminResults = {10,99}, }, },

		-- Rank
		[5] = {
			miniGames = {18,},
			--Level
			[1] = {
				hitsPerRound = {5,5,5},
				maxminResults = {1,99}, },
		},
	},
	-- Grade
	[2] = {	
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {2,9,12,},
			--Level
			[1] = {
				hitsPerRound = {100},--ORIGINAL {30,30,30},
				maxminResults = {10,20}, },--ORIGINAL {90,40}, },
		},
		
		-- Rank
		[2] = {
			miniGames = {3,10,18,},
			--Level
			[1] = {
				hitsPerRound = {100},--ORIGINAL {30,30,30},
				maxminResults = {20,30}, },--ORIGINAL {90,40}, },
		},

		-- Rank
		[3] = {
			miniGames = {4,7,},
			--Level
			[1] = {
				hitsPerRound = {30,30,30},
				maxminResults = {100,890}, },
		},
	},
	
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {3,10,12,},
			--Level
			[1] = {
				hitsPerRound = {35,20,35},
				maxminResults = {50,100},},--ORIGINAL {100,400}, },
			[2] = {
				hitsPerRound = {35,20,35},
				maxminResults = {75,150},},--ORIGINAL {400,700}, },
			[3] = {
				hitsPerRound = {35,20,35},
				maxminResults = {800,999}, },
		},
	},

	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {2,4,11,18,},
			--Level
			[1] = {
				hitsPerRound = {25,25,25},
				maxminResults = {75,150},},--ORIGINAL {350,850}, },
			[2] = {--ORIGINAL no había nivel 2
				hitsPerRound = {35,20,35},
				maxminResults = {100,200},},
		},
	},
}
			
--Falta todo quinto (eperando a Mariana)
local MATH_MUL_DATA = {
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {15,},
			--Level
			[1] = {
				hitsPerRound = {20,20,20},
				maxminResults = {1,5},},--ORIGINAL {1,50}, },
		},

		-- Rank
		[2] = {
			miniGames = {8,11,18,},
			--Level
			[1] = {
				hitsPerRound = {30,30,30},
				maxminResults = {3,7},},--ORIGINAL {1,100}, },
		},			

		-- Rank
		[3] = {
			miniGames = {3,15,},
			--Level
			[1] = {
				hitsPerRound = {10,10,10},
				maxminResults = {1,100}, },
			[2] = {
				hitsPerRound = {10,10,10},
				maxminResults = {1,100}, },
			[3] = {
				hitsPerRound = {10,10,10},
				maxminResults = {1,100}, },
		},

		-- Rank
		[4] = {
			miniGames = {2,6,7,9,},
			--Level
			[1] = {
				hitsPerRound = {15,15,15},
				maxminResults = {1,200}, },
		},
	},
			
	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {6,9,},
			--Level
			[1] = {
				hitsPerRound = {20,25,30},
				maxminResults = {3,9},},--ORIGINAL {1,150}, },
		},

		-- Rank
		[2] = {
			miniGames = {7,10,},
			--Level
			[1] = {
				hitsPerRound = {15,15,15},
				maxminResults = {5,15},},--ORIGINAL {1,9801}, },
			[2] = {
				hitsPerRound = {15,15,15},
				maxminResults = {1,9801}, },
			[3] = {
				hitsPerRound = {15,15,15},
				maxminResults = {1,9801}, },
		},			

		-- Rank
		[3] = {
			miniGames = {15,},
			--Level
			[1] = {
				hitsPerRound = {20,20,30},
				maxminResults = {1,9801}, },
			[2] = {
				hitsPerRound = {20,20,30},
				maxminResults = {1,9801}, },
		},
	},
				
	-- Grade
	[5] = {
		-- Rank
		[1] = {
			miniGames = {2,4,6,10,12,18,},
			--Level
			[1] = {
				hitsPerRound = {20,20,30},
				maxminResults = {8,20},},--ORIGINAL {}, },
			[2] = {
				hitsPerRound = {20,20,30},
				maxminResults = {9,25},},--ORIGINAL {}, },
		},
	},
}

--COMPLETO
local MATH_DIV_DATA = {
	-- Grade
	[3] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {4,6,12,},
			--Level
			[1] = {
				hitsPerRound = {20,20,20},
				maxminResults = {1,5},},--ORIGINAL {1,81}, },
		},

		-- Rank
		[2] = {
			miniGames = {2,10,16,},
			--Level
			[1] = {
				hitsPerRound = {20,20,20},
				maxminResults = {3,6},},--ORIGINAL {1,81}, },
		},	
	},
			
	-- Grade
	[4] = {
		-- Rank
		[1] = {
			--MiniGames
			miniGames = {3,12,15,18,},
			--Level
			[1] = {
				hitsPerRound = {30,30,40},
				maxminResults = {3,9},},--ORIGINAL {1000,2000}, },
		
			[2] = {
				hitsPerRound = {30,30,40},
				maxminResults = {5,15},},--ORIGINAL {2000,3000}, },
		},
	},
	
	-- Grade
	[5] = {
		-- Rank
		[1] = {
			miniGames = {3,7,11,},
			--Level
			[1] = {
				hitsPerRound = {20,20,30},
				maxminResults = {8,20},},--ORIGINAL {}, },
			[2] = {
				hitsPerRound = {20,20,30},
				maxminResults = {9,25},},--ORIGINAL {}, },
		},
	},
}

]]

return mathedu

