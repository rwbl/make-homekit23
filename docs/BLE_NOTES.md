# BLE_NOTES make-homekit32

## 1. Overview
This document describes the **BLE interface** of HomeKit32, including
services, characteristics, packet structure, commands, and response formats.

---

## 2. Generic BLE Information
The communication over Bluetooth Low Energy (BLE) is using the Nordic UART Service.

- **Device Name:** `HomeKit32`
- **Primary Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`			(UART)
- **RX/TX Characteristic UUID:**  
  - Write (Client > ESP32) (TX) : `6E400002-B5A3-F393-E0A9-E50E24DCCA9E`
  - Notify (ESP32 > Client) (RX) : `6E400003-B5A3-F393-E0A9-E50E24DCCA9E`	(Flags read,notify,write)

**MAC Address**): `88:13:BF:F6:4D:96`
The MAC address depends on the used hardware ESP32 Plus.
Check out B4R IDE compiler log, i.e. `MAC: 88:13:bf:f6:4d:94`.

---

## 3. Packet Structure

### BLE Message Format
| Byte(s) | Description         | Notes                                        |
| ------- | ------------------- | -------------------------------------------- |
| 0       | **DeviceID**        | 1 byte → uniquely identifies a device module |
| 1       | **Command**         | 1 byte → what action (set, get, PWM, etc.)   |
| 2..n    | **Value / Payload** | Variable length → value(s) for the command   |

### BLE Frame
[DeviceID][Command][Payload...]
Optional response (for “GET” or request commands):
[DeviceID][Command][Response...]

### BLE Device ID
Each device must have an unique ID.
| DeviceID | Device          | Notes                 |
| -------- | --------------- | --------------------- |
| 0x01     | Yellow LED      | Digital / PWM         |
| 0x02     | RGB LED         | 3 bytes for RGB       |
| 0x03     | Left Button     | Read only             |
| 0x04     | Right Button    | Read only             |
| 0x05     | Servo Door      | Angle 10–120          |
| 0x06     | Servo Window    | Angle 10–90           |
| 0x07     | Buzzer          | Tone / Melody ID      |
| 0x08     | Fan             | On/Off / PWM          |
| 0x09     | DHT11           | Request temp/humidity |
| 0x0A     | Gas Sensor      | Request value         |
| 0x0B     | Moisture Sensor | Request value         |
| 0x0C     | LCD 1602        | Text display          |
| 0x0D     | PIR Sensor      | Enable / Disable      |
| 0x0E     | RFID Reader     | Request / card scan   |

### BLE Command Table
| CommandID | Command       | Notes                      |
| --------- | ------------- | -------------------------- |
| 0x01      | SET_STATE     | Digital On/Off / PWM value |
| 0x02      | GET_STATE     | Request current state      |
| 0x03      | SET_VALUE     | For analog or complex data |
| 0x04      | GET_VALUE     | Read sensor value          |
| 0x05      | CUSTOM_ACTION | Reserved / future use      |

---

### BLE Value/Payload
List of device IDs, commands and payloads.
List Device name (ID).

---

#### YellowLED (0x01)

| Command    | Name      | Payload              | Example    | Description           |
| ---------- | --------- | -------------------- | ---------- | --------------------- |
| 0x01       | SET_STATE | 1 byte (0=Off, 1=On) | `01 01 01` | Turns LED On          |
| 0x02       | GET_STATE | none                 | `01 02`    | Requests LED state    |
| ->Response |           | 1 byte (0 or 1)      | `01 02 01` | Reports current state |

---

#### RGB LED (0x02)

| Command    | Name      | Payload                                | Example                                | Description                                                          |
| ---------- | --------- | -------------------------------------- | -------------------------------------- | -------------------------------------------------------------------- |
| 0x01       | SET_COLOR | 5 bytes (I,R,G,B,C)                    | `02 01 01 00 00 FF 01`                 | Set color Blue (FF) for pixel index 1 (01) and clear all pixels (01) |
| 0x02       | GET_COLOR | none                                   | `02 02`                                | Request current color for all 4 pixels                               |
| ->Response |           | 14 bytes (I,C,I,R,G,B,I,R,G,B,I,R,G,B) | `020200000000010000FF0200000003000000` | Reports current RGB color for all pixels. Pixel Blue all other off   |
| 0x03       | SET_VALUE | 3 byte (R,G,B)                         | `02 03 00 00 FF`                       | Set color blue for all pixels                                        |
| ->Response |           | 14 bytes (I,C,I,R,G,B,I,R,G,B,I,R,G,B) | `020200000000010000FF0200000003000000` | Reports current RGB color for all pixels. Pixel Blue all other off   |


Abbreviations: I=Index, R=Red, G=Green, B=Blie, C=Clear

---

#### Left Button (0x03) [NOT USED]

| Command    | Name      | Payload                        | Example    | Description          |
| ---------- | --------- | ------------------------------ | ---------- | -------------------- |
| 0x04       | GET_VALUE | none                           | `03 04`    | Request button state |
| ->Response |           | 1 byte (0=Released, 1=Pressed) | `03 04 01` | Button pressed       |

---

#### Right Button (0x04) [NOT USED]

| Command    | Name      | Payload | Example    | Description          |
| ---------- | --------- | ------- | ---------- | -------------------- |
| 0x04       | GET_VALUE | none    | `04 04`    | Request button state |
| ->Response |           | 1 byte  | `04 04 00` | Button released      |

---

#### Servo Door (0x05)

| Command    | Name      | Payload                     | Example    | Description           |
| ---------- | --------- | --------------------------- | ---------- | --------------------- |
| 0x01       | SET_STATE | 1 byte (0=close, 1=open)    | `05 01 01` | Set door open         |
| 0x02       | GET_STATE | none                        | `05 02`    | Request current state |
| ->Response |           | 1 byte                      | `05 02 01` | Reports open          |
| 0x03       | SET_VALUE | 1 byte (0–180)              | `05 03 90` | Set servo angle       |
| 0x04       | GET_VALUE | none                        | `05 04`    | Request current angle |
| ->Response |           | 1 byte                      | `05 04 90` | Reports 90°           |

**Note:** Commands 0x03, 0x04 are NOT USED because positions are fixed.

---

#### Servo Window (0x06)

| Command    | Name      | Payload                     | Example    | Description           |
| ---------- | --------- | --------------------------- | ---------- | --------------------- |
| 0x01       | SET_STATE | 1 byte (0=close, 1=open)    | `06 01 01` | Set window open       |
| 0x02       | GET_STATE | none                        | `06 02`    | Request current state |
| 0x03       | SET_VALUE | 1 byte (0–180)              | `05 03 90` | Set servo angle       |
| 0x04       | GET_VALUE | none                        | `05 04`    | Request current angle |
| ->Response |           | 1 byte                      | `05 04 90` | Reports 90°           |

**Note:** Commands 0x03, 0x04 are NOT USED because positions are fixed.

---

#### Buzzer (0x07)

| Command    | Name          | Payload                                  | Example             | Description                                         |
| ---------- | ------------- | ---------------------------------------- | ------------------- | --------------------------------------------------- |
| 0x01       | SET_STATE     | 1 byte (0=Off,1=On) | `07 01 01`         | Enable buzzer       |                                                     |
| 0x03       | SET_VALUE     | 4 bytes (freq UInt, duration UInt)       | `07 03 01 B8 01 F4` | Play Tone 440 (HEX 01B8), Duration 500ms (HEX 01F4) |
| ->Response |               | 1 byte (play tone)                       | `07 05 01`          | Tone played                                         |
| 0x05       | CUSTOM_ACTION | 2 bytes (mode 0x01-0x05, repeats 0xNN)   | `07 05 01 02`       | Play alarm 1 with 2 repeats                         |
| ->Response |               | 1 byte (alarm mode)                      | `07 05 01`          | Alarm mode 1 played                                 |

**Alarm Modes:** POLICE_SIREN = 1, FIRE_ALARM = 2, WAIL_SWEEP = 3, INTRUDER_ALARM	= 4, DANGER_ALARM = 5

---

#### Fan (0x08)

| Command | Name      | Payload             | Example    | Description             |
| ------- | --------- | ------------------- | ---------- | ----------------------- |
| 0x01    | SET_STATE | 1 byte (0=Off,1=On) | `08 01 01` | Turn fan on             |
| 0x02    | GET_STATE | none                | `08 02`    | Request state on or off |
| 0x03    | SET_VALUE | 1 byte (0–255 PWM)  | `08 03 C8` | Set fan speed 200       |

**Note:** Command 0x03 NOT SUPPORTED because the fan can only be turned on or off.

---

#### DHT11 Sensor (0x09)

| Command    | Name          | Payload                                            | Example      | Description                 |
| ---------- | ------------- | -------------------------------------------------- | ------------ | --------------------------- |
| 0x04       | GET_VALUE     | none                                               | `09 04`      | Request temp+humidity       |
| ->Response |               | 2 bytes (Temp, Humidity)                           | `09 04 1E32` | 30°C / 50% RH               |
| 0x05       | CUSTOM_ACTION | 1 byte (state changed event=0x00 (on), 0x01 (off)) | `09 05 00`   | Disable state changed event |

---

#### Gas Sensor (0x0A)

| Command    | Name      | Payload             | Example      | Description                   |
| ---------- | --------- | ------------------- | ------------ | ----------------------------- |
| 0x02       | GET_STATE | none                | `0A 02`      | Request gas detected or clear |
| ->Response |           | 1 bytes (ADC value) | `0A 02 01`   | Reports gas detected          |

---

#### Moisture Sensor (0x0B)

| Command    | Name          | Payload                | Example      | Description            |
| ---------- | ------------- | ---------------------- | ------------ | ---------------------- |
| 0x04       | GET_VALUE     | none                   | `0B 04`      | Request moisture level |
| ->Response |               | 2 bytes                | `0B 04 00FA` | Reports 250            |
| 0x05       | CUSTOM_ACTION | 1 byte (state changed event=0x00 (on), 0x01 (off)) | `0B 05 00`   | Disable state changed event |

---

#### LCD1602 (0x0C)

| Command | Name          | Payload                | Example                         | Description     |
| ------- | ------------- | ---------------------- | ------------------------------- | --------------- |
| 0x03    | SET_VALUE     | ASCII text (<=32 bytes)| `0C 03 00 00 05 68 65 6C 6C 6F` | Display "hello" |
| 0x05    | CUSTOM_ACTION | 1 byte (clear=0x00)    | `0C 05 01`                      | Clear screen    |

---

##### LCD1602 Command SET VALUE 0x03:
**Payload format <row><col><text length><text>**
- 0x00 - 0x01 (1 Byte) - Row 0 - 1
- 0x00 - 0x0F (1 Byte) - Col 0 - 15
- 0x00 - 0x0F (1 Byte) - Text length
- 0xNN, 0x... (N Bytes) - Text characters max 16
```
Example: display hello (5 bytes) at row 0, col 0
Payload (10 bytes): 0x0C 0x03 0x00 0x00 0x05 0x68 0x65 0x6C 0x6C 0x6F
          Byte Pos: 0    1    2    3    4    5    6    7    8    9
					ID   CMD  Row  Col  Len  h    e    l    l    o
```

##### LCD1602 Command CUSTOM_ACTION 0x05: 
```
0x01 (1 byte) = Clear display
Example payload (3 bytes): 0x0C 0x05 0x01
				 Byte Pos: 0    1    2   
0x02 0x00-0x01 (2 bytes) = Clear row (0x00) or on (0x01)
Example payload set clear botton row (row 1)(4 bytes): 0x0C 0x05 0x02 0x01
				                             Byte Pos: 0    1    2    3    	
0x03 0x00-0x01 (2 bytes) = Set backlight off (0x00) or on (0x01)
Example payload set backlight off (4 bytes): 0x0C 0x05 0x03 0x00
				                   Byte Pos: 0    1    2    3    	
TODO
0x04 0x00-0xFF (2 bytes) = Set brightness
Example payload set full brightness (4 bytes): 0x0C 0x05 0x04 0xFF
				                     Byte Pos: 0    1    2    3    	
```

---

#### PIR Sensor (0x0D)

| Command    | Name      | Payload                       | Example    | Description             |
| ---------- | --------- | ----------------------------- | ---------- | ----------------------- |
| 0x01       | SET_STATE | 1 byte (0=Disable,1=Enable)   | `0D 01 01` | Enable motion detection |
| 0x02       | GET_STATE | none                          | `0D 02`    | Request motion state    |
| ->Response |           | 1 byte (0=No motion,1=Motion) | `0D 02 01` | Motion detected         |

---

#### RFID (0x0E)

| Command    | Name          | Payload                 | Example             | Description      |
| ---------- | ------------- | ----------------------- | ------------------- | ---------------- |
| 0x04       | GET_VALUE     | none                    | `0E 04`             | Request last tag |
| ->Response |               | 4–16 bytes (UID)        | `0E 04 01 02 03 04` | Tag UID          |
| 0x05       | CUSTOM_ACTION | 1 byte (0=reset buffer) | `0E 05 00`          | Clear last tag   |

**Note:** Command 0x05 NOT USED.

##### RFID Message Payload
The RFID message is a N-byte BLE payload. The message depends on the Mifare version used.
The payload has structure:
```
<devid><commandid><uidlength><uid><payloadlength><payload>
```
Example payload:
```
0E04048C4B71C11202040000000000000000000000000000BF75
0E 04 04 8C4B71C1 12 02040000000000000000000000000000BF75
1  2  3  4 5 6 7  8  9
Byte N (Index N-1)
Byte 1 (0): 	Device ID - 0E
Byte 2 (1): 	Command ID - 04
Byte 3 (2):		UID Length - 04
Byte 4-7 (3): 	UID 8C 4B 71 C1 
Byte 8 (7):		Payload Length - 12
Byte 9-NN (8):	Payload 02040000000000000000000000000000BF75
Payload:
Byte 9 (8): 	Group - 02
Byte 10 (9):	Command - 04
Remaining bytes not used.
```

---

#### SYSTEM (0xFF)

| Command    | Name          | Payload                        | Example              | Description      |
| ---------- | ------------- | ------------------------------ | ---------------------| ---------------- |
| 0x02 TODO  | GET_STATE     | none                           | `FF 02`              | System state     |
| ->Response |               | 1 byte                         | `FF 02 01`           |                  |
| 0x05       | CUSTOM_ACTION | 1 byte 		                  | `FF 05 01`           | Enable events   |
| 0x05       | CUSTOM_ACTION | 1 byte 		                  | `FF 05 02`           | Disable events    |

---

### Notes
| Topic                                                                        | Description           |
| ---------------------------------------------------------------------------- | --------------------- |
| All payloads are raw bytes                                                   | No ASCII unless noted |
| Responses always start with `[DeviceID][Command]`                            |                       |
| Numeric values are **big-endian** (`0x00FA` = 250)                           |                       |
| You can directly mirror BLE messages to MQTT topics, e.g. `/device/01/state` |                       |
| All GET commands trigger a BLE response message                              |                       |

---


