local restrictions = {
	grade = {
		[1] = {
			topics = {
				["counting"] = {maxNumber = 10, countSteps = 1},
				["addition"] = {operands = 2, maxAnswer = 10, minAnswer = 2, maxOperand = 9, minOperand = 0, operandOrder = "descending"},
				["subtraction"] = {operands = 2, maxAnswer = 6, minAnswer = 2, maxOperand = 9, minOperand = 0},
				["clock"] = {timeStep = 60},
			},
		},
		[2] = {
			topics = {
				["counting"] = {maxNumber = 120, countSteps = 10},
				["addition"] = {operands = 2, minAnswer = 2, maxAnswer = 20, maxOperand = 15, minOperand = 0},
				["subtraction"] = {operands = 2, minAnswer = 1, maxAnswer = 10,  maxOperand = 15, minOperand = 0},
				["clock"] = {timeStep = 15},
			},
		},
		[3] = {
			topics = {
				["addition"] = {operands = 2, minAnswer = 5, maxAnswer = 50, maxOperand = 25, minOperand = 0},
				["subtraction"] = {operands = 2, minAnswer = 5, maxAnswer = 20, maxOperand = 30, minOperand = 0},
				["multiplication"] = {operands = 2, maxAnswer = 90, maxOperand = 10},
			},
		},
		[4] = {
			topics = {
				["addition"] = {operands = 2, minAnswer = 10, maxAnswer = 100, maxOperand = 50, minOperand = 0},
				["subtraction"] = {operands = 2, minAnswer = 6, maxAnswer = 40, maxOperand = 50, minOperand = 0},
				["multiplication"] = {operands = 2, minAnswer = 0, maxAnswer = 144, maxOperand = 12},
				["division"] = {operands = 2, minAnswer = 1, maxAnswer = 10, maxOperand = 100},
				["fractions"] = {maxDenominator = 8, maxNumerator = 8},
			},
		},
		[5] = {
			topics = {
				["addition"] = {operands = 2, minAnswer = 20, maxAnswer = 200, maxOperand = 99, minOperand = 10},
				["subtraction"] = {operands = 2, minAnswer = 10, maxAnswer = 40, maxOperand = 60, minOperand = 0},
				["multiplication"] = {operands = 2, minAnswer = 10, maxAnswer = 400, maxOperand = 20},
				["division"] = {operands = 2, minAnswer = 1, maxAnswer = 20, maxOperand = 160},
				["fractions"] = {maxDenominator = 25, maxNumerator = 25},
			},
		},
	},
}

return restrictions