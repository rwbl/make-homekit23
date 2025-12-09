/*
	HomeKit32 Standard Blocks
*/
 
Blockly.defineBlocksWithJsonArray([
	{
    "type": "start_block",
    "message0": "Start",
    "nextStatement": null,
    "colour": 0,
    "tooltip": "Program entry point",
    "helpUrl": ""
	},
	{
    "type": "stop_block",
    "message0": "Stop",
    "previousStatement": null,
    "colour": 0,
    "tooltip": "Stops program execution",
    "helpUrl": ""
	},
	// Repeat loop: has a value input TIMES (a number) and a statement input DO (stack of blocks)
	{
	"type": "repeat_loop",
	"message0": "repeat %1 times do %2",
	"args0": [
		{ "type": "input_value", "name": "TIMES", "check": "Number" },   // numeric input (can be math_number)
		{ "type": "input_statement", "name": "DO" }                     // statement input for inner blocks
	],
	"previousStatement": null,
	"nextStatement": null,
	"colour": 120
	},

	// While loop: has a value input COND (a boolean expression) and a statement input DO (stack of blocks)
	{
	"type": "while_loop",
	"message0": "while %1 do %2",
	"args0": [
		{ "type": "input_value", "name": "COND", "check": "Boolean" },  // boolean expression input
		{ "type": "input_statement", "name": "DO" }                     // statement input for inner blocks
	],
	"previousStatement": null,
	"nextStatement": null,
	"colour": 120
	},
	{
	"type": "logic_boolean_custom",
	"message0": "%1",
	"args0": [
		{
			"type": "field_dropdown",
			"name": "BOOL",
			"options": [
			["true", "TRUE"],
			["false", "FALSE"]
			]
			}
	],
	"output": "Boolean",
	"colour": 210
	},
	{
		"type": "logic_compare_custom",
		"message0": "%1 %2 %3",
		"args0": [
			{ 
				"type": "input_value", 
				"name": "A"
			},
			{
				"type": "field_dropdown",
				"name": "OP",
				"options": [
					["=", "EQ"],
					["!=", "NEQ"],
					["<", "LT"],
					[">", "GT"],
					["<=", "LE"],
					[">=", "GE"]
				]
			},
			{ 
				"type": "input_value", 
				"name": "B" 
			}
		],
		"output": "Boolean",
		"colour": 210
	}

]);
