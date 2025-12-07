# HomeKit32 -- Developer Notes & Guidelines

**Version:** 1.0
**Project:** HomeKit32
**Scope:** Firmware + BLE + MQTT + Client Ecosystem
**Audience:** Developers contributing to the HomeKit32 ecosystem
**Status:** Stable / Under active development

------------------------------------------------------------------------

# Introduction

HomeKit32 is a modular smart-home automation system built on the
Keyestudio KS5009 IoT kit using an ESP32 Plus microcontroller.
Firmware is developed in **B4R**, extended with **wrapped C++
libraries**, and communicates via **BLE** and **MQTT**.

This document defines: - Architecture
- Naming conventions
- File structure
- BLE protocol rules
- MQTT topic structure
- Coding guidelines
- Contribution & development workflow

These rules ensure consistency across firmware, C++ wrappers, Python/B4J
clients, and future B4A mobile apps.

------------------------------------------------------------------------

# System Architecture Overview

HomeKit32 consists of five layers:

1.  **Hardware Layer**
    -   ESP32 Plus board\
    -   13 sensors/actuators from KS5009\
    -   Includes LCD, PIR, gas sensor, servo motors, LEDs, motor driver,
        RFID, etc.
2.  **Firmware Layer (B4R)**
    -   Core logic controlling hardware\
    -   Unified device abstraction\
    -   BLE and MQTT protocol handlers\
    -   C++ libraries for performance-critical tasks
3.  **Communication Layer**
    -   BLE: binary commands + notifications\
    -   MQTT: JSON payloads + structured topics\
    -   Optional: Home Assistant autodiscovery
4.  **Client Layer**
    -   Python GUI client\
    -   B4J client\
    -   CLI test tools\
    -   B4A app (planned)
5.  **Integration Layer**
    -   Home Assistant\
    -   Mosquitto\
    -   Automation frameworks (Node-RED, Ignition)

------------------------------------------------------------------------

# Repository Structure

    HomeKit32/
    │
    ├── firmware/
    │   ├── B4R/
    │   │   ├── main.b4r
    │   │   ├── modules/
    │   │   ├── libs/        (C++ wrapper .h/.cpp files)
    │   │   └── config/
    │   └── tests/
    │
    ├── docs/
    │   ├── README.md
    │   ├── BLE_NOTES.md
    │   ├── MQTT_NOTES.md
    │   ├── DEV_NOTES.md     (this file)
    │   └── pinout.png
    │
    ├── clients/
    │   ├── python/
    │   ├── b4j/
    │   └── b4a/ (planned)
    │
    └── tools/
        ├── mqtt/
        └── ble/

------------------------------------------------------------------------

# Coding Guidelines (B4R)

## General Rules

- All code must be readable, modular, and self-documenting.
- Avoid long subs (\> 40 lines). Split into helpers.
- Use constants for all pin assignments and device IDs.
- No magic numbers in code.

## Naming Conventions

### Variables
B4X Class Variable Naming Guidelines
#### Private Class Variables
```
m + CamelCaseName
```
- Clearly marks it as a private member of the instance.
- Avoids naming conflicts with parameters or local variables.
- Matches typical Java/C# conventions — familiar and clean.
Examples
```
Private mBle As Bleak
Private mBleDevice As BleakDevice
Private mBleClient As BleakClient
Private mMainPage As B4XMainPage
```

#### Public Class Variables
```
CamelCaseName
```
- No prefix
- Should be rare (use Public only when absolutely needed)
- Intended for external access from other modules/pages
Example
```
Public IsConnected As Boolean = False
```

Additional Recommendations
- Use m for all “per-instance” class variables
- Even if not private, but public (rare case):
```
Public mCurrentMode As Int   ' only if necessary
```
- Avoid Hungarian notation (no bFlag, iIndex, etc.)
- Avoid “myVariable”, “theVariable” Clutters code.
- Use FullWords with proper PascalCase
```
Private mBleConnectionState As Int
Private mNotificationBuffer As Byte()
```
Local variables = simple and short
```
Dim msg As String
Dim x As Int
Dim p As B4XView
```

#### Summary
| Type                        | Prefix                 | Example                |
| --------------------------- | ---------------------- | ---------------------- |
| **Private class variables** | `m`                    | `mBleClient`           |
| **Public class variables**  | *(none)*               | `IsConnected`          |
| **Local variables**         | *(none)*               | `msg`, `i`, `temp`     |
| **Constants**               | `CONST_` or PascalCase | `Const MaxRetries = 3` |

### Subroutines:
Parameter:
	lowercase - parameter
Local vars: 
	lowercase - localvar
Local constants:
	UPPERCASE - LOCAL_CONST

### Constants
CamelCase & Uppercase
CONST_MAX_CLIENTS = 3
PIN_LED = 12

### Subroutines
Events:
	CamelCase: Device_StateChanged
Non-Events:
	PascalCase: Function

### Modules
CamelCase:
CodeModule

### C++ function wrappers
rfid_Init()
rfid_ReadBlock()
rfid_WriteBlock()

## Commenting Rules

- Every module must have an header:
**B4R**
```
#Region Code Module Header
' ================================================================
' File:        	DevYellowLed.bas
' Project:     	make-homekit32
' Brief:       	Set/Get the state of the yellow led ON or OFF.
' Date:        	2025-11-14
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx.b4x
' Description:	See brief.
' Hardware:		https://wiki.keyestudio.com/Ks0234_keyestudio_Yellow_LED_Module
' ================================================================
#End Region
```

**B4J**
```
#Region Code Module Header
' ================================================================
' File: 	DevYellowLed.bas
' Brief:	Getter / setter for the yellow led device.
' ================================================================
#End Region
```

- Every sub must have a 1--2 line summary.
```
' SetState
' Sets the state to on or off.
' Parameters:
'   state - Boolean.
Public Sub Set(state As Boolean)
	YellowLed.DigitalWrite(state)
End Sub
```
- Use Regions
```
#Region Code Module Header
...
#End Region
```
- Logging
Use Module.Sub:
	Log($"[DevRFID.Parse] uid length=${uidlength}"$)
- C++ files use **Doxygen** format (`///`).

## Instance vs. Object
In B4X:
A variable declared with a class type always refers to an object.
When created (Initialize), it gets an instance of that class.

Example
Private mBle As Bleak            	' object VARIABLE (will hold a Bleak INSTANCE)
Private mBleDevice As BleakDevice   ' same
Private mBleClient As BleakClient   ' same

Detailed Explanation
1. Class vs Object vs Instance
Class
A template or blueprint.
Example:
Bleak
BleakDevice
BleakClient

Object / Instance
A created version of a class, with data and behavior.
In almost all modern languages (including B4X):
OBJECT == INSTANCE
They are the same thing.
“Instance” emphasizes that it comes from a class.
“Object” emphasizes that it exists in memory.

Variables Explained
```
Private mBle As Bleak
```
This is an object reference variable.
It will hold one instance of Bleak (after you call Initialize).
Before Initialize → it is Null.
```
Private mBleDevice As BleakDevice
```
Also an object reference, intended to hold an instance of BleakDevice.
```
Private mBleClient As BleakClient
```
Also an object reference, intended to hold an instance of BleakClient.

When does it become an instance?
When callling:
```
mBle.Initialize
mBleDevice.Initialize(deviceId)
mBleClient.Initialize
```
Only after Initialize does the variable refer to a living instance in memory.
Before that, it's just a reference variable pointing to nothing.

**Visualization**
Before Initialize:
```
mBle → null
mBleDevice → null
mBleClient → null
```
After Initialize:
```
mBle → (instance of Bleak)
mBleDevice → (instance of BleakDevice)
mBleClient → (instance of BleakClient)
```

**Summary Table**
| Term                   | Meaning                                | Example                 |
| ---------------------- | -------------------------------------- | ----------------------- |
| **Class**              | Blueprint / type                       | `Bleak`                 |
| **Object**             | A created thing in memory              | `mBle` after Initialize |
| **Instance**           | A specific object created from a class | Same as above           |
| **Reference variable** | Variable pointing to an object         | `mBle`, `mBleDevice`    |

**Easiest rule to remember**

👉 “Object” and “Instance” are the same thing.
A class variable becomes an object/instance after Initialize.

## Logging
Recommended Logging Format
```
[ClassName.SubName][Level] Message
```
Suggested Level Codes
- [I] — Info
- [W] — Warning
- [E] — Error
- [D] — Debug (useful in early firmware development)
- [V] — Verbose (for low-level BLE or MQTT packet dumps)

Examples
```
[BLEMgr.PyBridge][I] Python process started successfully.
[BLEMgr.PyBridge][W] Device response timeout, retrying...
[BLEMgr.PyBridge][E] Failed to start Python process.
```

Constants
```
Public Const LOG_I As String = "[I]"
Public Const LOG_W As String = "[W]"
Public Const LOG_E As String = "[E]"
```

------------------------------------------------------------------------

# C++ Wrapper Guidelines

## File Layout

Every wrapped library must contain:
- LibraryName.h
- LibraryName.cpp
- manifest.txt (optional)

## Header Rules

- Doxygen blocks required for every public function.
- Must include example usage where helpful.
- Function names must match B4R naming style where possible.

## B4R Exposure

Wrap functions using:

- B4R::Object* rfid_ReadBlock(Byte block);

## Memory Rules

- No dynamic allocation unless unavoidable.
- Avoid malloc/free inside called functions.
- Keep interrupt usage minimal.

------------------------------------------------------------------------

# BLE Protocol Rules

## Packet Structure

    | 0xAA | LENGTH | CMD | DATA... | CHECKSUM |

-   `0xAA` --- Start marker\
-   `LENGTH` --- Byte count including CMD + DATA\
-   `CMD` --- Command ID\
-   `DATA` --- Variable length\
-   `CHECKSUM` --- XOR of all bytes except start marker

## 6.2 Command Groups

-   `0x10` Sensor read commands\
-   `0x20` Actuator commands\
-   `0x30` System commands\
-   `0x40` Configuration

## 6.3 Notifications

-   Sent automatically on state change\
-   Same packet format as commands\
-   Always start with `0xAA`

## 6.4 Error Handling

Errors reply using:

    CMD | 0x80

------------------------------------------------------------------------

# 7. MQTT Protocol Rules

## 7.1 Topic Structure

    homekit32/<device>/<property>

Examples:

    homekit32/door/state
    homekit32/temp/value
    homekit32/light/set

## 7.2 JSON Payload Format

    {
      "value": <number|string>,
      "unit": "°C" | "%" | ...,
      "ts": 1714095955
    }

## 7.3 MQTT QoS Rules

-   Default QoS: **1**\
-   Retain: **false**\
-   Autodiscovery: optional via Home Assistant

------------------------------------------------------------------------

# 8. File & Module Structure

## 8.1 B4R File Structure

    main.b4r
    Device_*.bas
    Comm_BLE.bas
    Comm_MQTT.bas
    System_Config.bas
    Utils_Checksum.bas

## 8.2 Client File Naming

    client_ble.py
    client_mqtt.py
    client_dashboard.b4j

------------------------------------------------------------------------

# 9. Development Workflow

1.  Create a branch:

```{=html}
<!-- -->
```
    feature/<description>

2.  Commit frequently with meaningful messages.\
3.  Run local tests (BLE + MQTT).\
4.  Submit a pull request.\
5.  All code must compile without warnings.

------------------------------------------------------------------------

# 10. Testing Guidelines

## 10.1 Unit Tests (B4R)

-   Test each device module individually.
-   Verify all BLE commands.
-   Validate MQTT JSON structure.

## 10.2 Integration Tests

-   Full smart-home scenario test:
    -   Door servo
    -   Motion sensor
    -   LCD update
    -   Button events

## 10.3 Stress Tests

-   Multi-client BLE test\
-   MQTT flooding test (100 messages/sec)

------------------------------------------------------------------------

# 11. Release Policy

-   Versioning: **Semantic Versioning (SemVer)**\
-   Tag format:

```{=html}
<!-- -->
```
    v1.2.0

Release checklist: - BLE protocol updated?\
- MQTT topics updated?\
- Firmware compiled?\
- Docs updated?

------------------------------------------------------------------------

# 12. Roadmap (Developer Perspective)

-   Finish BLE full spec\
-   C++ auto-generated wrappers\
-   Add encrypted BLE mode\
-   Multi-node MQTT mesh\
-   B4A Android control app\
-   Web dashboard via B4J or Node-RED

------------------------------------------------------------------------

# 13. License

This project is open source under the **MIT License**.

------------------------------------------------------------------------

# 14. Contact

For questions, suggestions, or collaboration:\
**Robert W.W. Linn**
