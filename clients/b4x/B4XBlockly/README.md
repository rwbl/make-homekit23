# B4J Blockly HomeKit32 Interface

This project is a custom Blockly interface integrated into a **B4J WebView**, allowing visual programming of HomeKit32 devices. Commands generated in Blockly are sent to B4J via WebSocket (or later via BLE commands).

## Features

- **Custom Blocks** for HomeKit32 devices:
  - `yellow_on`, `yellow_off`, `open_door`, `delay`
  - `yellow_led` indicator block
  - `DHT11 sensor` block (temperature & humidity)
- **Looping & Conditional Control**:
  - `repeat_loop` (repeat N times)
  - `while_loop` (loop while condition is true)
- **Start/Stop blocks** for program flow
- **Visual indicators** for device states
- Save/load Blockly workspace as XML
- Modular JavaScript architecture:
  - `blockly_custom_blocks.js` – Device blocks
  - `blockly_standard_blocks.js` – Standard Blockly blocks (loops, math, logic)
  - `blockly_generators.js` – Code generators
  - `blockly_device_states.js` – Update device states in Blockly UI
  - `blockly_app.js` – Workspace initialization & execution logic

---

## Getting Started

### Blockly Setup

1. Define Blockly `<div>` in B4J WebView.
2. Create a toolbox XML with block categories:
   - HomeKit32 devices
   - Loops
   - Math
3. Load JavaScript files in the proper order:
   - `blockly_custom_blocks.js`
   - `blockly_standard_blocks.js`
   - `blockly_generators.js`
   - `blockly_device_states.js`
   - `blockly_app.js` (last)

> `blockly_app.js` initializes the workspace and handles execution and communication with B4J.

---

## Blockly Custom Blocks

- **Yellow LED indicator:**
  - Shows current LED state.
  - Can be updated dynamically from B4J using `updateDeviceState('yellow_led', 'ON')`.
- **DHT11 Sensor:**
  - Fields for temperature and humidity.
  - Values updated dynamically using `updateDeviceDHT11(temp, hum)`.
- **Repeat Loop:**
  - Input `TIMES` (number)
  - Contains inner blocks to repeat.
- **While Loop:**
  - Input `COND` (boolean)
  - Contains inner blocks.
  - Includes safety max iteration to prevent infinite loops.

---

## Execution Flow

1. User drags blocks into workspace.
2. Click **Generate Code** button.
3. Each top-level block is converted to an **async function** using a generator.
4. `runBlockQueue` executes blocks sequentially.
5. Blocks send commands to B4J via `sendCommandToB4JAsync({command: "yellow_on"})`.
   - Can later be adapted to send BLE commands to HomeKit32.

---

## Saving & Loading Workspace

- **Save Workspace:** Converts current workspace to XML.
- **Load Workspace:** Paste XML to restore blocks.
- All block types must be defined before loading XML.

---

## Updating Device States

- `yellow_led` or `DHT11` blocks can be updated in real-time:
  - `updateDeviceState('yellow_led', 'ON')`
  - `updateDeviceDHT11(24, 65)`
- Blocks visually update color or field values.

---

## Notes

- B4J WebView does not support native JS alert dialogs; communication is done using `JavaObject` and `executeScript`.
- Blockly block colors use **Blockly hues** (0–360):
  - Yellow LED: 60
  - DHT11 high humidity: 90
- Modular JS makes the project easy to extend.

---

## Future Ideas

- Add more HomeKit32 device blocks (fans, switches, RGB LEDs)
- Extend conditionals (`if/else`) and logical operators
- Integrate actual BLE command sending from B4J to HomeKit32
- Add visual "Start" and "Stop" indicators
