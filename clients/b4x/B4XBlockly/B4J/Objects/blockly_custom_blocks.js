/*
	Project:	HomeKit32
	File:		blockly_custom_blocks.js
	Brief:		Definition of custom blocks.
				JSON block definitions for HomeKit32 blocks.
				Use Blockly.defineBlocksWithJsonArray to define the UI blocks.
*/

Blockly.defineBlocksWithJsonArray([
	{
		"type": "connect",
		"message0": "Connect",
		"previousStatement": null,
		"nextStatement": null,
		"colour": 30
	},
	{
		"type": "disconnect",
		"message0": "Disconnect",
		"previousStatement": null,
		"nextStatement": null,
		"colour": 30
	},
	{
		"type": "yellow_led_on",
		"message0": "Yellow LED on",
		"previousStatement": null,
		"nextStatement": null,
		"colour": 60
	},
	{
		"type": "yellow_led_off",
		"message0": "Yellow LED off",
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
		"type": "door_open",
		"message0": "Open Door",
		"previousStatement": null,
		"nextStatement": null,
		"colour": 160
	},
	{
		"type": "door_close",
		"message0": "Close Door",
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
		  { "type": "field_number", "name": "TEMP", "value": 0 },
		  { "type": "field_number", "name": "HUM", "value": 0 }
		],
		"previousStatement": null,
		"nextStatement": null,
		"colour": 60
	},
	
	{
		"type": "show_variable",
		"message0": "show variable %1 value %2",
		"args0": [
			{
				"type": "field_variable",
				"name": "VAR",
				"variable": "BLE_CONNECTED"
			},
{
				"type": "field_label",   
				"name": "VALUE",
				"variable": ""  
			}
		],
		"previousStatement": null,
		"nextStatement": null,
		"colour": 230
	}

]);
