# B4J Blockly HomeKit32 Interface

This project provides a custom **Blockly** integration inside a **B4J WebView**, enabling visual programming of **HomeKit32** devices.
Blockly programs are executed in JavaScript and communicate back to **B4J** via `executeScript` / WebView callbacks (currently WebSocket-style commands, with BLE planned).

The project is **experimental** and optimized for Blockly **v12.x**.
(See clients > b4x > src > B4XBlockly)

---

## Features

* **Custom HomeKit32 blocks**

  * LED control (`yellow_led`, `yellow_on`, `yellow_off`)
  * Door control (`open_door`, `close_door`)
  * Delay / timing block
  * DHT11 sensor display (temperature & humidity)

* **Control flow blocks**

  * Repeat loop (repeat *N* times)
  * While loop (boolean condition)
  * For / step loops (with runtime safety checks)

* **Variables support (Blockly v12 compatible)**

  * Runtime variable store (`blocklyVars.runtime`)
  * `setVariable()` / `getVariable()` API
  * `show_variable` block to display current values

* **Asynchronous execution model**

  * Each block generates an `async` function
  * Sequential execution using `runBlockQueue`

* **Live UI updates from B4J**

  * Device state changes pushed from B4J into Blockly
  * Variable updates reflected without re-running the program

* **Workspace persistence**

  * Save / load workspaces as Base64-encoded JSON

---

## Folder Structure

All Blockly-related files are located in the **B4J project Objects folder**.

### Blockly Source Files

* `blockly_index.html`
  Main Blockly HTML page loaded by the B4J WebView

* `blockly_app.js`
  Core application logic (Blockly v12 setup, execution, B4J communication)

* `blockly_standard_blocks.js`
  Definitions for standard blocks (loops, logic, math)

* `blockly_custom_blocks.js`
  Definitions for HomeKit32-specific blocks

* `blockly_generators.js`
  Runtime generators producing async JavaScript code

* `blockly_device_states.js`
  UI helpers to update block visuals from external events

### Workspace Files

* `led-loop.ws`
* `ledonoff.ws`

> Workspace files contain **Base64-encoded JSON**, not XML.

---

## Blockly Setup

1. Define the Blockly `<div>` inside the WebView HTML.
2. Create a toolbox XML defining categories:

   * HomeKit32 Devices
   * Variables
   * Loops
   * Logic / Math
3. Load JavaScript files **in this order**:

```text
blockly_custom_blocks.js
blockly_standard_blocks.js
blockly_generators.js
blockly_device_states.js
blockly_app.js   (must be last)
```

`blockly_app.js`:

* Injects Blockly into the page
* Registers all generators
* Initializes runtime variables
* Manages execution and B4J communication

---

## Custom Blocks Overview

### LED Blocks

* **yellow_led**

  * Visual indicator of LED state
  * Updated from B4J using:

    ```js
    updateDeviceState('yellow_led', 'ON');
    ```

* **yellow_on / yellow_off**

  * Command blocks executed during runtime

---

### DHT11 Sensor Block

* Displays:

  * Temperature (°C)
  * Humidity (%)

* Updated dynamically:

  ```js
  updateDeviceDHT11(24, 65);
  ```

This block is **display-only** and does not generate execution code.

---

### Variable Display Block (`show_variable`)

* Displays:

  ```text
  Show variable <NAME> value <CURRENT_VALUE>
  ```

* Value is read from the runtime store

* Updates when:

  * The program is run
  * `setVariable()` is called from B4J

This block is **read-only** and does not allow editing the value.

---

## Execution Flow

1. User assembles blocks in the workspace
2. User presses **Run**
3. Top-level blocks are collected using:

   ```js
   workspace.getTopBlocks(true)
   ```
4. Each block generates an `async` function
5. `runBlockQueue` executes blocks sequentially using `await`
6. Commands are sent back to B4J:

   ```js
   sendCommandToB4JAsync({ command: 'yellow_on' });
   ```

> This design prevents UI blocking and supports delays, loops, and async device actions.

---

## Runtime Variables

### Initialization

All variables must be **preloaded** before execution:

```js
window.blocklyVars = {
  runtime: {
    BLE_CONNECTED: false,
    COUNTER: 0
  }
};
```

### API

```js
setVariable(name, value);
getVariable(name, defaultValue);
```

* Variables are shared between:

  * Blockly execution
  * B4J external updates

---

## Saving & Loading Workspaces

* **Save**: Workspace serialized to JSON and Base64 encoded
* **Load**: JSON decoded and restored

Important:

* All block definitions **must be loaded before** restoring a workspace
* Missing block definitions will cause load errors

---

## Device State Updates from B4J

B4J can update Blockly UI without running the program:

```java
engine.RunMethod("executeScript", Array("setVariable('BLE_CONNECTED', true)"))
engine.RunMethod("executeScript", Array("updateDeviceState('yellow_led','ON')"))
```

This keeps the visual workspace synchronized with real device states.

---

## Notes & Compatibility

* Target Blockly version: **v12.3.x**
* Deprecated APIs avoided:

  * `getAllVariables()` → replaced by VariableMap
* All loops include **safety checks** to prevent infinite execution
* Block colors follow Blockly hue system (0–360)

---

## Future Ideas

* Additional HomeKit32 devices (fans, relays, RGB LEDs)
* Advanced logic blocks (`if / else if / else`)
* Direct BLE command integration
* Visual execution tracing (highlight active block)
* Export / import workspaces from B4J UI
* B4A Client
---
