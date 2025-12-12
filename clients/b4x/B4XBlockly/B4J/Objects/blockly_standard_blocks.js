/*
	Project:	HomeKit32
	File:		blockly_standard_blocks.js
	Brief:		Definition of Blockly standard blocks.
				JSON block definitions for standard control blocks.
				Use Blockly.defineBlocksWithJsonArray to define the UI blocks.
*/

Blockly.defineBlocksWithJsonArray([
  // Program flow / simple blocks
  {
    "type": "start_block",
    "message0": "Start",
    "nextStatement": null,
    "colour": 0,
    "tooltip": "Program entry point"
  },
  {
    "type": "stop_block",
    "message0": "Stop",
    "previousStatement": null,
    "colour": 0,
    "tooltip": "Stop"
  },
  {
    "type": "comment_block",
    "message0": "Comment: %1",
    "args0": [
      { "type": "field_input", "name": "COMMENT", "text": "note" }
    ],
    "colour": 160,
    "tooltip": "Comment (no effect)"
  },
  {
    "type": "log_block",
    "message0": "log %1",
    "args0": [
      { "type": "input_value", "name": "TEXT", "check": null }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 160
  },
  {
    "type": "text_literal",
    "message0": "\"%1\"",
    "args0": [{ "type": "field_input", "name": "TEXT", "text": "" }],
    "output": "String",
    "colour": 160
  },

  // Loops
  {
    "type": "repeat_loop",
    "message0": "repeat %1 times do %2",
    "args0": [
      { "type": "input_value", "name": "TIMES", "check": "Number" },
      { "type": "input_statement", "name": "DO" }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 120
  },
  {
    "type": "while_loop",
    "message0": "while %1 do %2",
    "args0": [
      { "type": "input_value", "name": "COND", "check": "Boolean" },
      { "type": "input_statement", "name": "DO" }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 120
  },

  // Logic primitives (UI only)
  /*
  {
    "type": "logic_boolean",
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
    "colour": 210,
    "tooltip": "Returns either true or false."
  },
  {
    "type": "logic_compare",
    "message0": "%1 %2 %3",
    "args0": [
      { "type": "input_value", "name": "A" },
      {
        "type": "field_dropdown",
        "name": "OP",
        "options": [
          ["=", "EQ"],
          ["≠", "NEQ"],
          ["<", "LT"],
          ["≤", "LTE"],
          [">", "GT"],
          ["≥", "GTE"]
        ]
      },
      { "type": "input_value", "name": "B" }
    ],
    "inputsInline": true,
    "output": "Boolean",
    "colour": 210,
    "tooltip": "Comparison operators."
  },
  {
    "type": "logic_operation",
    "message0": "%1 %2 %3",
    "args0": [
      { "type": "input_value", "name": "A", "check": "Boolean" },
      { 
        "type": "field_dropdown", 
        "name": "OP", 
        "options": [
          ["and", "AND"],
          ["or", "OR"]
        ]
      },
      { "type": "input_value", "name": "B", "check": "Boolean" }
    ],
    "inputsInline": true,
    "output": "Boolean",
    "colour": 210,
    "tooltip": "Logical AND / OR"
  },
  {
    "type": "logic_negate",
    "message0": "not %1",
    "args0": [
      { "type": "input_value", "name": "BOOL", "check": "Boolean" }
    ],
    "output": "Boolean",
    "colour": 210,
    "tooltip": "Logical NOT"
  },
	*/
	
  // If / If-Else / Else-If UI blocks (statements)
  {
    "type": "logic_if",
    "message0": "if %1 do %2",
    "args0": [
      { "type": "input_value", "name": "COND", "check": "Boolean" },
      { "type": "input_statement", "name": "DO" }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 210
  },
  {
    "type": "logic_else_if",
    "message0": "else if %1 do %2",
    "args0": [
      { "type": "input_value", "name": "COND", "check": "Boolean" },
      { "type": "input_statement", "name": "DO" }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 210
  },
  {
    "type": "logic_if_else",
    "message0": "if %1 do %2 else %3",
    "args0": [
      { "type": "input_value", "name": "COND", "check": "Boolean" },
      { "type": "input_statement", "name": "DO" },
      { "type": "input_statement", "name": "ELSE" }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 210
  }

  // Variables are provided by the toolbox custom="VARIABLE"
]);
