Blockly.defineBlocksWithJsonArray([
  {
    "type": "open_door",
    "message0": "Open Door",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 160
  },
  {
    "type": "yellow_on",
    "message0": "yellow LED on",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },
  {
    "type": "delay",
    "message0": "wait %1 ms",
    "args0": [
      { "type": "field_number", "name": "DELAY", "value": 1000, "min": 0 }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 120
  }
]);

Blockly.JavaScript['open_door'] = () => "console.log('Door opened');\n";
Blockly.JavaScript['yellow_on'] = () => "console.log('Yellow on');\n";
Blockly.JavaScript['delay'] = block => {
    let ms = block.getFieldValue("DELAY");
    return `console.log('Delay ${ms}');\n`;
};
