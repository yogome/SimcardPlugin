
local ADDITION = "addition"
local SUBSTRACTION = "substraction"
local MULT = "multiplication"
local DIV = "division"

local mathModule = {
	["grades"] = {
		-----GRADE 1
		[1] = {
			[ADDITION] = {
				[1] = {
					hitsPerRound = 5,
					maxminResults = {2,6}, },
				[2] = {
					hitsPerRound = 5,
					maxminResults = {4,10}, },
				[3] = {
					hitsPerRound = 10,
					maxminResults = {8,20}, },
				[4] = {	
					hitsPerRound = 10,
					maxminResults = {12,24}, },
				[5] = {	
					hitsPerRound = 10,
					maxminResults = {16,28}, }, 
				[6] = {	
					hitsPerRound = 10,
					maxminResults = {20,40}, },
				[7] = {	
					hitsPerRound = 10,
					maxminResults = {30,60}, }, 
				[8] = {	
					hitsPerRound = 10,
					maxminResults = {40,80}, },
			},
			[SUBSTRACTION] = {
				[1] = {
					hitsPerRound = 5,
					maxminResults = {1,4}, },
				[2] = {
					hitsPerRound = 5,
					maxminResults = {4,10}, },
				[3] = {
					hitsPerRound = 10,
					maxminResults = {8,20}, },
				[4] = {
					hitsPerRound = 10,
					maxminResults = {12,24}, },
				[5] = {
					hitsPerRound = 10,
					maxminResults = {16,28}, }, 
				[6] = {
					hitsPerRound = 10,
					maxminResults = {20,40}, },
				[7] = {
					hitsPerRound = 10,
					maxminResults = {30,50}, },
				},
			},
		-----GRADE 2
		[2] = {
			[ADDITION] = {
				[1] = {
					hitsPerRound = 5,
					maxminResults = {11,20},},
				[2] = {
					hitsPerRound = 5,
					maxminResults = {15,30},},
				[3] = {
					hitsPerRound = 10,
					maxminResults = {20,40},},
				[4] = {
					hitsPerRound = 10,
					maxminResults = {30,50},},
				[5] = {
					hitsPerRound = 11,
					maxminResults = {40,60},},
				[6] = {
					hitsPerRound = 11,
					maxminResults = {50,70},},
				[7] = {
					hitsPerRound = 11,
					maxminResults = {60,80},},
				[8] = {
					hitsPerRound = 11,
					maxminResults = {80,90},},
				[9] = {
					hitsPerRound = 10,
					maxminResults = {90,100}, }, 
				[10] = {
					hitsPerRound = 10,
					maxminResults = {100,120}, },
				[11] = {
					hitsPerRound = 10,
					maxminResults = {120,150}, }, 
				},
			[SUBSTRACTION] = {
				[1] = {
					hitsPerRound = 5,
					maxminResults = {11,20},},
					hitsPerRound = 5,
				[2] = {	
					maxminResults = {15,30},},
				[3] = {	
					hitsPerRound = 10,
					maxminResults = {20,40},},
				[4] = {	
					hitsPerRound = 10,
					maxminResults = {30,50},},
				[5] = {	
					hitsPerRound = 20,
					maxminResults = {40,60},},
				[6] = {	
					hitsPerRound = 30,
					maxminResults = {50,70},},
				[7] = {	
					hitsPerRound = 40,
					maxminResults = {60,80},},
				[8] = {	
					hitsPerRound = 40,
					maxminResults = {80,90},},	
				},
			},
		-----GRADE 3
		[3] = {
			[ADDITION] = {
				[1] = {
					hitsPerRound = 5,
					maxminResults = {20,30},},
				[2] = {
					hitsPerRound = 5,
					maxminResults = {30,50},},
				[3] = {
					hitsPerRound = 10,
					maxminResults = {50,90},},
				[4] = {
					hitsPerRound = 10,
					maxminResults = {80,120},},
				[5] = {
					hitsPerRound = 10,
					maxminResults = {100,150},},
				[6] = {
					hitsPerRound = 10,
					maxminResults = {150,180},},
				[7] = {
					hitsPerRound = 10,
					maxminResults = {180,200},},
				},
			[SUBSTRACTION] = {
				[1] ={	
					hitsPerRound = 5,
					maxminResults = {20,30},},
				[2] ={	
					hitsPerRound = 5,
					maxminResults = {30,50},},
				[3] ={
					hitsPerRound = 10,
					maxminResults = {50,90},},
				[4] ={
					hitsPerRound = 10,
					maxminResults = {80,120},},
				[5] ={
					hitsPerRound = 10,
					maxminResults = {100,150},},
				},
			[MULT] = {
				[1] = {
					hitsPerRound = 6,
					maxminResults = {1,5},},
				[2] = {	
					hitsPerRound = 6,
					maxminResults = {5,15},},
				[3] = {	
					hitsPerRound = 6,
					maxminResults = {15,30},},
				[4] = {	
					hitsPerRound = 16,
					maxminResults = {30,80},},
				[5] = {	
					hitsPerRound = 16,
					maxminResults = {60,100},},
				[6] = {	
					hitsPerRound = 26,
					maxminResults = {90,130},},
				[7] = {	
					hitsPerRound = 26,
					maxminResults = {120,180},},
				[8] = {	
					hitsPerRound = 30,
					maxminResults = {150,200}, },
				},
			[DIV] = {
				[1] = {	
					hitsPerRound = 5,
					maxminResults = {1,5},},
			
				[2] = {	
					hitsPerRound = 5,
					maxminResults = {3,6},},
			
				[3] = {
					hitsPerRound = 5,
					maxminResults = {8,20},},
				},
			},
		-----GRADE 4
		[4] = {
			[ADDITION] = {
				[1] = {
					hitsPerRound = 10,
					maxminResults = {5,10},},

				[2] = {
					hitsPerRound = 10,
					maxminResults = {80,120},},

				[3] = {
					hitsPerRound = 10,
					maxminResults = {100,150},},

				[4] = {
					hitsPerRound = 10,
					maxminResults = {150,200},},

				[5] = {
					hitsPerRound = 10,
					maxminResults = {180,250},},
			},
			[SUBSTRACTION] = {
				[1] = {	
					hitsPerRound = 10,
					maxminResults = {5,10},},
				
				[2] = {	
					hitsPerRound = 10,
					maxminResults = {80,120},},
				
				[3] = {	
					hitsPerRound = 10,
					maxminResults = {100,150},},
				
				[4] = {	
					hitsPerRound = 10,
					maxminResults = {150,200},},
			},
			[MULT] = {
				[1] = {	hitsPerRound = 6,
					maxminResults = {3,5},},
			
				[2] = {	hitsPerRound = 6,
					maxminResults = {10,20},},

				[3] = {	hitsPerRound = 6,
					maxminResults = {20,40},},

				[4] = {	hitsPerRound = 6,
					maxminResults = {30,60},},

				[5] = {	hitsPerRound = 9,
					maxminResults = {40,80},},

				[6] = {	hitsPerRound = 9,
					maxminResults = {60,100},},

				[7] = {	hitsPerRound = 10,
					maxminResults = {90,130},},

				[8] = {	hitsPerRound = 10,
					maxminResults = {100,150},},

				[9] = {	hitsPerRound = 10,
					maxminResults = {130,200},},
			},
			[DIV] = {
				[1] = {	
					hitsPerRound = 5,
					maxminResults = {3,9},},
		
				[2] = {	
					hitsPerRound = 5,
					maxminResults = {8,20},},

				[3] = {	
					hitsPerRound = 6,
					maxminResults = {20,40},},

				[4] = {	
					hitsPerRound = 6,
					maxminResults = {30,60},},

				[5] = {	
					hitsPerRound = 9,
					maxminResults = {40,80},},
			},
		},
		-----GRADE 5
		[5] = {
			[MULT] = {
				[1] = {	
					hitsPerRound = 5,
					maxminResults = {3,5},},

				[2] = {	
					hitsPerRound = 6,
					maxminResults = {20,40},},

				[3] = {	
					hitsPerRound = 6,
					maxminResults = {30,60},},

				[4] = {	
					hitsPerRound = 9,
					maxminResults = {40,80},},

				[5] = {	
					hitsPerRound = 9,
					maxminResults = {60,100},},

				[6] = {	
					hitsPerRound = 15,
					maxminResults = {90,130},},

				[7] = {	
					hitsPerRound = 15,
					maxminResults = {100,150},},

				[8] = {	
					hitsPerRound = 10,
					maxminResults = {130,200},},

				[9] = {	
					hitsPerRound = 10,
					maxminResults = {150,300},},
			},
			[DIV] = {
				[1] = {	
					hitsPerRound = 5,
					maxminResults = {8,10},},

				[2] = {	
					hitsPerRound = 6,
					maxminResults = {20,40},},

				[3] = {	
					hitsPerRound = 6,
					maxminResults = {30,60},},

				[4] = {	
					hitsPerRound = 9,
					maxminResults = {40,80},},

				[5] = {	
					hitsPerRound = 9,
					maxminResults = {60,100},},	
			}
		},
	}
}

return mathModule
