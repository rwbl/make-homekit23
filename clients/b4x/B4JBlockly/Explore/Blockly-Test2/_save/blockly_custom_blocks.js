// --- Define blocks ---
Blockly.defineBlocksWithJsonArray([
  {
    "type": "open_door",
    "message0": "open door",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 20
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
      {
        "type": "field_number",
        "name": "DELAY",
        "value": 1000,
        "min": 0
      }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 120
  }
]);

// --- Modern JS generators ---
function defineGenerators(jsGenerator) {
  jsGenerator['open_door'] = function(block) {
    return "MQTT.Publish('homekit32/door','open');\n";
  };

  jsGenerator['yellow_on'] = function(block) {
    return "MQTT.Publish('homekit32/led/yellow','on');\n";
  };

  jsGenerator['delay'] = function(block) {
    const ms = block.getFieldValue('DELAY');
    return `await delay(${ms});\n`;
  };
}
