# HomeKit32

A modular smart-home automation framework for the Keyestudio Smart Home Kit (KS5009), powered by ESP32, BLE, MQTT and B4X.

## Overview

**HomeKit32** is a modular smart-home control system based on the Keyestudio Smart Home Kit (KS5009) and the Keyestudio ESP32 Plus microcontroller.
It provides real-time communication via BLE and MQTT, integrates 13 sensors and actuators, and exposes a clean, structured protocol for external applications.

The firmware is written in B4R, with performance-critical functionality implemented in wrapped C++ libraries.
Client applications currently exist for B4J, B4A, Python and Blockly to complete the cross-platform ecosystem.

**HomeKit32** is a personal hobby project intended for learning, experimentation, and reference.
It is not a commercial product and is not intended for production or safety-critical environments.

## Summary

* ESP32 (B4R) as a BLE Peripheral + GATT Server using UART services
* B4A (Android, HMI Tiles UI) as a BLE Central + GATT Client
* B4J (Desktop, HMI Tiles UI) with a PyBridge + Bleak BLE backend
* B4J (Desktop, Blockly + HMI Tiles UI) with a PyBridge + Bleak BLE backend
* Python + PySide6 UI client with HMI Tiles
* Optional MQTT gateway for Home Assistant integration
* Control of LEDs, relays, motors and sensors with bi-directional BLE communication

---

## Quick Start

1. Assemble the Keyestudio KS5009 hardware
2. Flash the HomeKit32 firmware to the ESP32
3. Power the board
4. Connect using a BLE client (B4J, B4A, Python or Blockly)
5. Toggle a device (e.g. Yellow LED) to verify communication

---

## Features

### Core System

* Full support for all 13 devices in the Keyestudio KS5009 kit
* Unified device abstraction inside the firmware
* Modular and extensible design
* Clear separation between hardware drivers, protocol layer, and application logic

### Communication

* Structured BLE protocol with framed binary packets
* ESP32 as BLE Peripheral + GATT Server
* MQTT communication for integration with external systems
* Optimized packet handling with adjustable MTU and efficient buffering

### Software

* Firmware written in [B4R](https://www.b4x.com/b4r.html)
* Development setup:

  * B4R 4.00 (64-bit)
  * arduino-cli 1.3.1
  * ESP32 board manager 3.3.3
  * BLE library 3.3.3
  * Wrapped C++ libraries for performance-critical tasks

### Client Applications

* B4J Desktop UI
* B4A Android UI
* Python GUI (PySide6)
* Blockly visual programming interface (B4J-integrated)

### MQTT Dashboards

* Mosquitto
* Home Assistant
* Ignition (planned)

---

## Architecture

| Layer           | Technology                        |
| --------------- | --------------------------------- |
| Microcontroller | ESP32 Plus (Keyestudio KS5016)    |
| Firmware        | B4R + wrapped C++ libraries       |
| Communication   | BLE and MQTT                      |
| Integration     | JSON payloads, binary BLE packets |
| Client Apps     | B4A, B4J, Python, Blockly         |

---

## Hardware

Microcontroller: **Keyestudio ESP32 Plus**
ESP32-D0WDQ6 (revision v1.1), Wi-Fi + Bluetooth, Dual Core, 240MHz

### Devices

* Buzzer
* Door and window servos
* Gas sensor (digital mode)
* LCD 1602 (I2C)
* Push buttons
* DC motor
* PIR motion detector
* RFID module (RC522)
* RGB LED (NeoPixel)
* Steam sensor
* Temperature / Humidity sensor (DHT11 or DHT22)
* Yellow LED

Reference: Keyestudio Wiki – [https://wiki.keyestudio.com/Main_Page](https://wiki.keyestudio.com/Main_Page)

---

## Getting Started

### 1. Assemble Hardware

Follow the Keyestudio KS5009 assembly guide and connect all sensors and actuators.

### 2. Flash the Firmware

Requirements:

* B4R 4.00
* Conditional symbols: `BLE`, `MQTT`, or `BLE,MQTT`
* Additional libraries copied to the B4R libraries folder (backup existing libraries first)
* Arduino CLI 1.3.1
* ESP32 board definition 3.3.4
* Board: **ESP32 Wrover Kit (all versions)**
* Partition scheme: **Huge App**

### 3. Configure MQTT (Optional)

* Local Mosquitto broker
* Raspberry Pi broker
* Home Assistant MQTT add-on

### 4. Connect a Client

* B4J Desktop
* B4A Android
* Python GUI
* Blockly (via B4J WebView)

The folder make-homekit32\clients\b4x\src\libs\ contains additional libraries required for B4X applications.
Copy to the B4J or B4A additional libraries folder.
---

## Project Status

* Firmware: Stable
* BLE protocol: Stable
* MQTT integration: Evolving
* Blockly integration: Experimental

---

## Development Information

Detailed documentation is provided in separate files:

* **DEV_NOTES.md** – Coding conventions, module structure, C++ integration
* **BLE_NOTES.md** – Services, characteristics, packet framing
* **MQTT_NOTES.md** – Topic layout, payload structure, QoS rules

---

## Non-Goals

* This project is **not** Apple HomeKit compatible
* No focus on security hardening or certification
* Not intended for production, commercial, or safety-critical use

---

## Future Roadmap

* B4J automation rule editor
* Expanded BLE protocol (group commands, bulk telemetry)
* Multi-node MQTT support
* Web dashboard (B4J or Node-RED)

---

## Credits

* Keyestudio – Smart Home Kit KS5009
* Anywhere Software – B4X tools
* Open-source libraries and community examples

---

## License

HomeKit32 is released under the MIT License.
Copyright © 2025 Robert W. W. Linn.
