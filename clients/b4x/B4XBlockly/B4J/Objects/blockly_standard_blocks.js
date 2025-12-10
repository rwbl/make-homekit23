/*
	HomeKit32 Standard Blocks
*/
 
Blockly.defineBlocksWithJsonArray([
	{
	  "type": "comment_block",
	  "message0": "Comment: %1",
	  "args0": [
		{
		  "type": "field_input",
		  "name": "COMMENT",
		  "text": "Enter note"
		}
	  ],
	  "colour": 160,
	  "tooltip": "This block does nothing, only a comment",
	  "helpUrl": ""
	},
	{
    "type": "log_block",
    "message0": "log %1",
    "args0": [
      {
        "type": "input_value",
        "name": "TEXT",
        "check": "String"
      }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 160,
    "tooltip": "Logs a message to console",
    "helpUrl": ""
	},
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

	{
    "type": "text_literal",
    "message0": "\"%1\"",
    "args0": [
      { "type": "field_input", "name": "TEXT", "text": "" }
    ],
    "output": "String",
    "colour": 160
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
