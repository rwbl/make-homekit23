/*
	HomeKit32 Device States
*/

let DEV_YELLOW_LED = "yellow_led";
let DEV_DHT11 = "dht11_sensor";


// JS: update device state
function updateDeviceSensor(deviceId, value) {
    const el = document.getElementById(deviceId);
    if (el) el.textContent = value;
}

// Called from B4J to update block state
function updateDeviceState(blockType, state) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
		// Update color or dropdown depending on state
        if (block.type === "yellow_led") {
			block.setFieldValue(state, "STATE");      // update dropdown
			block.setColour(state === "ON" ? 90 : 60); // update color
        }
    });
}

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

function updateDeviceMotion(isDetected) {
    const allBlocks = workspace.getAllBlocks();
    allBlocks.forEach(block => {
        if (block.type === "motion_sensor") {
            block.setFieldValue(isDetected ? "ON" : "OFF", "MOTION");
            block.setColour(isDetected ? 60 : 30); // green if detected
        }
    });
}
