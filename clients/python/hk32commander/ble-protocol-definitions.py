"""
BLE Protocol Definitions
========================

This module defines all device IDs, command codes, and payload formats
for the homekit32 BLE communication protocol. Each device provides a
set of commands for controlling actuators or reading sensor values.

All values are represented as bytes and transmitted in the format:

    [DEVICE_ID] [COMMAND_ID] [PAYLOAD...]

Example:
    0x01 0x01 0x01   # Yellow LED: SET_STATE → ON
"""

# ---------------------------------------------------------------------------
# Device Identifiers
# ---------------------------------------------------------------------------
DEV_YELLOW_LED = 0x01
DEV_RGB_LED = 0x02
DEV_LEFT_BUTTON = 0x03        # Not used
DEV_RIGHT_BUTTON = 0x04       # Not used
DEV_SERVO_DOOR = 0x05
DEV_SERVO_WINDOW = 0x06
DEV_BUZZER = 0x07
DEV_FAN = 0x08
DEV_DHT11 = 0x09
DEV_GAS_SENSOR = 0x0A
DEV_MOISTURE_SENSOR = 0x0B
DEV_LCD1602 = 0x0C
DEV_PIR_SENSOR = 0x0D
DEV_RFID = 0x0E

# ---------------------------------------------------------------------------
# Common Command Identifiers
# ---------------------------------------------------------------------------
CMD_SET_STATE = 0x01      # Usually 1 byte payload (0=Off, 1=On)
CMD_GET_STATE = 0x02      # No payload, device returns state
CMD_SET_VALUE = 0x03      # Device-specific value payload
CMD_GET_VALUE = 0x04      # No payload, device returns value
CMD_CUSTOM_ACTION = 0x05  # Device-specific custom command


# ---------------------------------------------------------------------------
# Yellow LED (0x01)
# ---------------------------------------------------------------------------
"""
SET_STATE: 1 byte (0 = Off, 1 = On)
    Example: 01 01 01     → Turn LED on

GET_STATE: no payload
    Example: 01 02

Response:
    Example: 01 02 01     → State = On
"""

# ---------------------------------------------------------------------------
# RGB LED (0x02)
# ---------------------------------------------------------------------------
"""
SET_COLOR:
    Payload: 5 bytes (Index, Red, Green, Blue, ClearFlag)
    Example: 02 01 01 00 00 FF 01
             Set pixel index 1 to Blue (FF), clear pixels flag = 1.

GET_COLOR:
    Payload: none
    Example: 02 02

Response:
    Payload: 14 bytes, representing all 4 pixel RGB values.
    Example: 02 02 00 00 00 01 00 00 FF ...
"""

# ---------------------------------------------------------------------------
# Left Button (0x03) / Right Button (0x04) — Not used
# ---------------------------------------------------------------------------
"""
GET_VALUE:
    Example: 03 04
Response:
    1 byte (0 = Released, 1 = Pressed)
"""

# ---------------------------------------------------------------------------
# Servo Door (0x05)
# ---------------------------------------------------------------------------
"""
SET_STATE:
    Payload: 1 byte (0 = Closed, 1 = Open)
    Example: 05 01 01

GET_STATE:
    Example: 05 02

SET_VALUE (Not used):
    Payload: 1 byte (0–180 degrees)
"""

# ---------------------------------------------------------------------------
# Servo Window (0x06)
# Same structure as Servo Door
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Buzzer (0x07)
# ---------------------------------------------------------------------------
"""
SET_VALUE:
    Payload: 4 bytes (Freq UInt16, Duration UInt16)
    Example: 07 03 01 B8 01 F4   → 440 Hz, 500 ms

SET_STATE:
    Payload: 1 byte (0=Off, 1=On)

CUSTOM_ACTION:
    Payload: 2 bytes (Mode, RepeatCount)
    Example: 07 05 01 02
"""

# ---------------------------------------------------------------------------
# Fan (0x08)
# ---------------------------------------------------------------------------
"""
SET_STATE:
    Payload: 1 byte (0 = Off, 1 = On)
    Example: 08 01 01

GET_STATE:
    Example: 08 02

SET_VALUE (Not supported on hardware):
    Payload: 1 byte (0–255 PWM)
"""

# ---------------------------------------------------------------------------
# DHT11 Sensor (0x09)
# ---------------------------------------------------------------------------
"""
GET_VALUE:
    Example: 09 04

Response:
    Payload: 2 bytes (Temperature, Humidity)
    Example: 09 04 1E 32   → 30°C, 50%
"""

# ---------------------------------------------------------------------------
# Gas Sensor (0x0A)
# ---------------------------------------------------------------------------
"""
GET_STATE:
    Example: 0A 02

Response:
    Payload: 1 byte (ADC value or detection flag)
"""

# ---------------------------------------------------------------------------
# Moisture Sensor (0x0B)
# ---------------------------------------------------------------------------
"""
GET_VALUE:
    Example: 0B 04

Response:
    Payload: 2 bytes (ADC value)
    Example: 00 FA → 250
"""

# ---------------------------------------------------------------------------
# LCD1602 Display (0x0C)
# ---------------------------------------------------------------------------
"""
SET_VALUE:
    Payload: up to 32 bytes ASCII text
    Example: 0C 03 48 65 6C 6C 6F   → "Hello"

CUSTOM_ACTION:
    Payload: 1 byte (0x00 = clear screen)
"""

# ---------------------------------------------------------------------------
# PIR Motion Sensor (0x0D)
# ---------------------------------------------------------------------------
"""
SET_STATE:
    Payload: 1 byte (0 = Disable, 1 = Enable)

GET_STATE:
    Example: 0D 02

Response:
    Payload: 1 byte (0 = No motion, 1 = Motion)
"""

# ---------------------------------------------------------------------------
# RFID Reader (0x0E)
# ---------------------------------------------------------------------------
"""
GET_VALUE:
    Example: 0E 04

Response:
    Payload: 4–16 byte UID
    Example: 0E 04 01 02 03 04

CUSTOM_ACTION:
    Payload: 1 byte (0 = reset buffer)
"""
