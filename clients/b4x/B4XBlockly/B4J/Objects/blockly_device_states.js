/*
	Project:	HomeKit32
	File:		blockly_device_states.js
	Brief:		Handle device states of a custom block.
				The functions are called from B4J. 
				Examples:
				Dim engine As JavaObject = GetEngine(WebViewBlockly)
				engine.RunMethod("executeScript", Array("updateDeviceState('yellow_led', 'ON')"))
				Dim tempValue As Float = 22.3
				Dim humValue As Float = 54
				engine.RunMethod("executeScript", Array($"updateDeviceDHT11(${tempValue},${humValue})"$))
*/

/*
	List of devices
	The device block type must match the defined blockType (see blockly_custom_blocks.js).
*/
let DEV_YELLOW_LED = "yellow_led";
let DEV_DHT11 = "dht11_sensor";
let DEV_MOTION_SENSOR = "motion_sensor";

/*
	updateDeviceState
	Loop over all blocks to get the device as defined in the constants.
	Update the device property STATE (see example field name).
	Parameters:
		devblocktype - Block type as defined in the constants and in blockly_custom_blocks.js
		state - Block property state value for field "STATE"
	Example:
	B4J:
		engine.RunMethod("executeScript", Array("updateDeviceState('yellow_led', 'ON')"))
	blockly_custom_blocks.js:
		{
			"type": "yellow_led", "message0": "Yellow LED %1",
			"args0": [{"type": "field_dropdown","name": "STATE","options": [["OFF", "OFF"],["ON", "ON"]]}],
			"previousStatement": null,"nextStatement": null,"colour": 60
		},
*/
function updateDeviceState(devblocktype, state) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === devblocktype) {
			// update dropdown
			block.setFieldValue(state, "STATE");
        }
    });
}

/*
	updateDeviceSensor
	Loop over all blocks to get the device as defined in the constants.
	Update the device field with new value.
	Parameters:
		devblocktype - Block type as defined in the constants and in blockly_custom_blocks.js
		field - Block property field to update
		value - Block property field value
*/
function updateDeviceSensor(devblocktype, field, value) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === devblocktype) {
			block.setFieldValue(value, field);
        }
    });
}

//=======================================================================
// DEVICES
//=======================================================================

/*
	updateDeviceYellowLED
	Loop over all blocks to get the device as defined in the constants.
	Update the device property.
*/
function updateDeviceYellowLED(state) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === DEV_YELLOW_LED) {
			block.setFieldValue(state, "STATE");      	// update dropdown
            block.setColour(state === "ON" ? 90 : 60);	// update color
        }
    });
}

/*
	updateDeviceDHT11
	Loop over all blocks to get the device as defined in the constants.
	Update the device properties.
*/
function updateDeviceDHT11(temp, hum) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
		if (block.type === DEV_DHT11) {
			block.setFieldValue(temp, "DHT11TEMP");
			block.setFieldValue(hum, "DHT11HUM");
			// Set color based on humidity	
            if (hum > 80) block.setColour(30);   // warning orange
            else if (hum > 60) block.setColour(60); // safe yellow
            else block.setColour(120); // very safe green		
		}
    });
}

/*
	updateDeviceMotion
	Loop over all blocks to get the device as defined in the constants.
	Update the device properties.
*/
function updateDeviceMotion(isDetected) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === DEV_MOTION_SENSOR) {
            block.setFieldValue(isDetected ? "ON" : "OFF", "MOTION");
            block.setColour(isDetected ? 60 : 30); // green if detected
        }
    });
}
