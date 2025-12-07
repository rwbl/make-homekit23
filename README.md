# HomeKit32
A modular smart-home automation framework for the Keyestudio Smart Home Kit (KS5009), powered by ESP32, BLE, MQTT and B4X.

## Overview

**HomeKit32** is a modular smart-home control system based on the Keyestudio Smart Home Kit (KS5009) and the Keyestudio ESP32 Plus microcontroller.
It provides real-time communication via BLE and MQTT, integrates 13 sensors and actuators, and exposes a clean, structured protocol for external applications.

The firmware is written in B4R, with performance-critical functionality implemented in wrapped C++ libraries.
Client applications currently exist for B4J, B4A and Python to complete the cross-platform ecosystem.

**HomeKit32** is ideal for education, prototyping, IoT experiments, and as a reference architecture for a clean, extensible, multi-protocol smart-home system.

## Features

### Core System
- Full support for all 13 devices in the Keyestudio KS5009 kit
(LEDs, PIR, gas sensor, servo motors, buzzer, buttons, LCD, DHT11/22, motor driver, and more)
- Unified device abstraction inside the firmware
- Easily extendable modular design
- Clean separation between hardware drivers, protocol layer, and application logic

### Communication
- Structured BLE protocol with commands, notifications, and framed binary packets
- MQTT communication
- Support for multiple simultaneous BLE clients (ESP32 multi-connect mode)
- Optimized packet handling with adjustable MTU and efficient buffering

### Software
- [B4R](www.b4x.com/b4r.html) firmware (primary)
- Development setup:
	- B4R 4.00 (64-bit)
	- arduino-cli 1.3.1
	- ESP32 board manager 3.3.3
	- BLE 3.3.3
	- C++ wrapped libraries for high-performance operations

### Client applications
- [B4J](www.b4x.com/b4j.html) Desktop
- [B4A](www.b4x.com/b4r.html) Android
- [Python](www.python.org) GUI

### MQTT dashboards supported
- Mosquitto
- Home Assistant
- Ignition (planned)

## Architecture
| Layer           | Technology                        |
| --------------- | --------------------------------- |
| Microcontroller | ESP32 Plus Keyestudio [KS5016](wiki.keyestudio.com/KS5016_Keyestudio_ESP32_PLUS_Development_Board)    |
| Firmware        | B4R + wrapped C++ libraries       |
| Communication   | BLE and MQTT                      |
| Integration     | JSON payloads, binary BLE packets |
| Client Apps     | B4A, B4J, Python                  |

## Hardware

Microcontroller: `Keyestudio ESP32 Plus` - Chip type: ESP32-D0WDQ6 (revision v1.1), 
A Wi-Fi + Bluetooth capable development board based on ESP32-WROOM-32.
Features: Wi-Fi, BT, Dual Core + LP Core, 240MHz, Vref calibration in eFuse, Coding Scheme None

**Devices**
- [Buzzer] (https://wiki.keyestudio.com/Ks0019_keyestudio_Passive_Buzzer_module)
- [Door servo + window servo] (https://wiki.keyestudio.com/Ks0194_keyestudio_Micro_Servo)
- [Gas sensor](https://Ks0040_keyestudio_Analog_Gas_Sensor) - Digital mode (detected / clear)
- [LCD 1602 display](https://wiki.keyestudio.com/Ks0061_keyestudio_1602_I2C_Module)
- [Left/Right push buttons](https://wiki.keyestudio.com/Ks0029_keyestudio_Digital_Push_Button)
- [Motor](https://wiki.keyestudio.com/KS0347_Keyestudio_130_Motor_DC3-5V_Driving_Module) - On / Off supported
- [PIR motion detector](https://wiki.keyestudio.com/Ks0052_keyestudio_PIR_Motion_Sensor) - Digital mode (detected / clear)
- [RFID module](https://wiki.keyestudio.com/Ks0067_keyestudio_RC522_RFID_Module_for_Arduino) - Mifare supported
- [RGB LED](https://www.keyestudio.com/products/keyestudio-6812-rgb-module-for-arduino-diy-programming-projects-compatible-lego-blocks) - 4 Neo Pixels
- [Steam sensor](https://wiki.keyestudio.com/Ks0203_keyestudio_Steam_Sensor)
- [Temperature/Humidity sensor](https://https://wiki.keyestudio.com/Ks0034_keyestudio_DHT11_Temperature_and_Humidity_Sensor)  - DHT11/DHT22 depending on kit version
- [Yellow LED](https://wiki.keyestudio.com/Ks0234_keyestudio_Yellow_LED_Module)
**Notes**
- Keyestudio [Wiki](https://wiki.keyestudio.com/Main_Page) - Reference for all devices.

## Getting Started
1. Assemble Hardware
Follow the Keyestudio KS5009 guide and ensure all sensors/actuators are wired correctly.

2. Flash the Firmware
Requirements:
- B4R 4.00 (recommended)
- B4R Conditional Communication Mode: BLE or MQTT or BLE,MQTT
- Arduino-CLI 1.3.1
- ESP32 board definitions (min 3.3.3)
- Board: **ESP32 Wrover Kit (all versions)**
- Partition scheme: **Huge App**

3. Configure MQTT Broker (optional)
Supported setups:
- Local Mosquitto installation
- Raspberry Pi broker
- Home Assistant MQTT add-on

4. Connect a Client
- B4J 
- B4A
- Python GUI client

## Development Information

Documentation for developers who want to extend the firmware or build custom clients.

### DEV_NOTES.md
Development and contribution guidelines.
- Naming and module structure.
- B4R coding conventions.
- C++ library integration rules.
- Tips for BLE/MQTT devugging

### BLE_NOTES.md
Describes:
- Services and characteristics
- Packet framing format
- Commands and response structure
- Notification structure

### MQTT_NOTES.md
Describes:
- Topic layout and naming rules
- QoS recommendations
- Payload structures

## Future Roadmap

- B4J client HomeKitBlocks32.
- B4A client for Android.
- Web dashboard (B4J or Node-RED).
- Expanded MQTT structure for multi-node networks.
- Extended BLE protocol (group commands, bulk telemetry).
- B4J automation rule editor.

## Credits

- Keyestudio – KS5009 IoT Kit.
- Anywhere Software – B4X development tools.
- Open-source libraries and examples that inspired parts of this project.

## License

Released under the MIT License — Copyright © 2025 Robert W.W. Linn.
See LICENSE for details.
