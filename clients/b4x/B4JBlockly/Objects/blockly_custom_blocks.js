/*
	HomeKit32 Custom Blocks
*/
 
Blockly.defineBlocksWithJsonArray([
	{
    "type": "yellow_on",
    "message0": "yellow LED on",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },
  {
    "type": "yellow_off",
    "message0": "yellow LED off",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },
	{
    "type": "yellow_led",
    "message0": "Yellow LED %1",
    "args0": [
      {
        "type": "field_dropdown",
        "name": "STATE",
        "options": [
          ["OFF", "OFF"],
          ["ON", "ON"]
        ]
      }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  },

  {
    "type": "open_door",
    "message0": "Open Door",
    "previousStatement": null,
    "nextStatement": null,
    "colour": 160
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
  },
  {
    "type": "dht11_sensor",
    "message0": "DHT11 Sensor Temp %1 °C Hum %2 %",
    "args0": [
      { "type": "field_number", "name": "DHT11TEMP", "value": 0 },
      { "type": "field_number", "name": "DHT11HUM", "value": 0 }
    ],
    "previousStatement": null,
    "nextStatement": null,
    "colour": 60
  }

]);
