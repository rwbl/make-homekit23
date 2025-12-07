# HomeKit32 – MQTT Communication Notes

## 1. Overview
Describes the MQTT interface for HomeKit32, topic structure, messages,
QoS rules, autodiscovery, and integration notes (e.g., Home Assistant).

---

## 2. MQTT Broker Requirements
- Protocol: MQTT 3.1 or 3.1.1
- Default port: 1883
- No TLS (for now)

---

## 3. Topic Structure

### 3.1 General

The idea is that topics should be simple, descriptive, and structured, but not too deep.
This is the recommended naming convention and mapping for this Keyestudio Smart Home project — optimized for clarity, scalability, and educational readability.

**Topic Naming Rules**
- lowercase, hierarchical using `/`
- structure: `<prefix>/<home>/<device>/<function>`
- payloads in JSON format - Keep short and use strings for values
- devices: function `/set` to device, `/status` from device

This convention balances clarity, scalability, and compatibility (works with B4R/B4J, Home Assistant, Node-RED, etc.).
The prefix is fixed: `homekit32`.

**JSON Payload Conventions**
| Type    | Example                    | Description                |
| ------- | -------------------------- | -------------------------- |
| Boolean | `{"pressed":true}`         | On/off or pressed/released |
| Numeric | `{"temperature":22.4}`     | Numeric sensor values      |
| String  | `{"state":"open"}`         | Status or mode             |
| Object  | `{"r":255,"g":120,"b":60}` | Complex control like RGB   |
| Error   | `{"error":"timeout"}`      | Standardized error message |

**Direction Indicators**
| Symbol   | Meaning                                 |
| -------- | --------------------------------------- |
| > Device | Topic client *publishes* to ESP32       |
| > Server | ESP32 *publishes* back to broker/client |

**Multi-Home Support Example**
| Home  | Example Topic                   | Meaning                          |
| ----- | ------------------------------- | -------------------------------- |
| home1 | `homekit32/home1/door/set`    | Open/close the door of Home #1   |
| home2 | `homekit32/home2/dht11/get`   | Request temperature from Home #2 |
| home3 | `homekit32/home3/rgb_led/set` | Set RGB LED color in Home #3     |

**MQTT Topic Reference**
| #  | Component                               | Direction | Topic                                 | Example Payload                         | Description                |
| -- | --------------------------------------- | --------- | ------------------------------------- | --------------------------------------- | -------------------------- |
| 1  | **Yellow LED**                          | > Device  | `homekit32/home1/yellow_led/set`    | `{"state":"on"}`                        | Turn LED on/off            |
|    |                                         | > Server  | `homekit32/home1/yellow_led/status` | `{"state":"off"}`                       | LED reports its state      |
| 2  | **RGB LED**                             | > Device  | `homekit32/home1/rgb_led/set`       | `{"r":255,"g":120,"b":60}`              | Set RGB color              |
|    |                                         | > Server  | `homekit32/home1/rgb_led/status`    | `{"r":255,"g":120,"b":60}`              | Confirm color/state        |
| 3  | **Push Button 1**                       | > Server  | `homekit32/home1/button1/action`    | `{"pressed":true}`                      | Button press event         |
| 4  | **Push Button 2**                       | > Server  | `homekit32/home1/button2/action`    | `{"pressed":false}`                     | Button release event       |
| 5  | **Door Servo**                          | > Device  | `homekit32/home1/door/set`          | `{"state":"open"}`                      | Open/close the door        |
|    |                                         | > Server  | `homekit32/home1/door/status`       | `{"state":"closed"}`                    | Report servo state         |
| 6  | **Passive Buzzer**                      | > Device  | `homekit32/home1/buzzer/set`        | `{"tone":1000,"duration":500}`          | Play tone (Hz + ms)        |
|    |                                         | > Server  | `homekit32/home1/buzzer/status`     | `{"state":"idle"}`                      | Report buzzer activity     |
| 7  | **DHT11 Temperature & Humidity Sensor** | > Device  | `homekit32/home1/dht11/get`         | `{"request":"temperature"}`             | Request reading            |
|    |                                         | > Server  | `homekit32/home1/dht11/status`      | `{"temperature":22.4,"humidity":45.0}`  | Report reading             |
| 8  | **Analog Gas Sensor**                   | > Server  | `homekit32/home1/gas/status`        | `{"ppm":87}`                            | Report gas level           |
| 9  | **PIR Motion Detector**                 | > Server  | `homekit32/home1/motion/status`     | `{"motion":"detected"}`                 | Motion detection event     |
| 10 | **Steam Sensor**                        | > Server  | `homekit32/home1/steam/status`      | `{"steam":"present"}`                   | Detect steam or humidity   |
| 11 | **130 Motor**                           | > Device  | `homekit32/home1/motor/set`         | `{"speed":150}`                         | Set motor speed (0–255)    |
|    |                                         | > Server  | `homekit32/home1/motor/status`      | `{"speed":150}`                         | Report current speed       |
| 12 | **RFID Module**                         | > Server  | `homekit32/home1/rfid/status`       | `{"card_id":"12345678"}`                | Report scanned card        |
| 13 | **LCD 1602 I2C**                        | > Device  | `homekit32/home1/lcd/set`           | `{"text":"Welcome Home!"}`              | Display text message       |
|    |                                         | > Server  | `homekit32/home1/lcd/status`        | `{"text":"Welcome Home!"}`              | Acknowledge current text   |
| 14 | **System Error Reporting**              | > Server  | `homekit32/home1/error`             | `{"message":"sensor timeout"}`          | Send error information     |
| 15 | **System Info / Debug**                 | > Server  | `homekit32/home1/system/info`       | `{"uptime":123456,"ip":"192.168.1.55"}` | General system diagnostics |


**Example B4R Handling**

B4R pseudo-code for the DHT11 sensor:
```b4r
Sub HandleMQTTMessage(Topic As String, Payload() As Byte)
    Dim msg As String = Payload
    If Topic = "homekit32/home1/dht11/get" Then
        Dim t As Float = ReadTemperature
        Dim h As Float = ReadHumidity
        Dim response As String = $"{"temperature":${t},"humidity":${h}}"$
        MQTTPublish("homekit32/home1/dht11/status", response)
    End If
End Sub
```

**Summary**

- Readable — immediately see which device and action is targeted
- Modular — each smart home and device is isolated
- Scalable — supports many homes, devices, and client systems
- Compatible — with B4R, B4J, Home Assistant, Node-RED, and Mosquitto
- Standardized — aligns with /set and /status MQTT best practices

---

## Example Scenario

Automation:

“Door opened > LED turns on”

Logic flow:
home/node1/door/state = open
> home/node1/led/cmd = on

**B4R Pseudocode**
```b4r
Sub HandleMQTTMessage(topic As String, payload() As Byte)
    If topic = TOPIC_DOOR_STATE Then
        Dim msg As String = payload
        If msg = "open" Then SetLED(True) Else SetLED(False)
    End If
End Sub
```

---

## Utilities
These are Window batch files used for mosquitto.
Mosquitto is running local on the developent device.

### Start mosquitto
```
@echo off
setlocal

REM Path to mosquitto executable and config
set MOSQUITTO_EXE=C:\prog\mosquitto\mosquitto.exe
set MOSQUITTO_CONF=C:\prog\mosquitto\mosquitto.conf

echo Checking for running mosquitto…

REM Check if mosquitto is running
tasklist /FI "IMAGENAME eq mosquitto.exe" | find /I "mosquitto.exe" >nul

if %ERRORLEVEL%==0 (
    echo Mosquitto is running. Stopping it…
    taskkill /F /IM mosquitto.exe >nul
    timeout /t 2 >nul
) else (
    echo Mosquitto is not running.
)

echo Starting Mosquitto...
"%MOSQUITTO_EXE%" -v -c "%MOSQUITTO_CONF%"

echo Mosquitto exited.
endlocal
exit
```

### Stop mosquitto
```
@echo off
REM Stop Mosquitto manually for dev (no admin required)
setlocal

echo Checking for running Mosquitto...
tasklist /FI "IMAGENAME eq mosquitto.exe" | find /I "mosquitto.exe" >nul

if %ERRORLEVEL%==0 (
    echo Mosquitto is running. Stopping it...
    taskkill /F /IM mosquitto.exe >nul
    timeout /t 2 >nul
    echo Mosquitto stopped.
) else (
    echo Mosquitto is not running.
)
endlocal
pause
```

### Subscribe mosquitto
```
REM Subscribe to mosquitto payload homekit32/home1/#

c:\Prog\mosquitto\mosquitto_sub.exe -v -t homekit32/home1/#
```

### Test Commands mosquitto
```
REM Test Commands

REM Remove retained messages
c:\Prog\mosquitto\mosquitto_sub.exe --remove-retained -t "#" -W 1

REM Yellow LED
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/yellow_led/set -m {\"s\":\"on\"}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/yellow_led/set -m {\"s\":\"off\"}

REM RGBLED pixel 0 to blue with all pixels cleared
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/rgb_led/set -m {\"i\":0,\"r\":0,\"g\":0,\"b\":50,\"c\":1}

REM Servo
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/servo_door/set -m {\"a\":\"open\"}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/servo_door/set -m {\"a\":\"close\"}

REM Buzzer
REM Single tone
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"t\":440,\"d\":500}
REM Buzzer off
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"t\":0,"\d":0}
REM Alarm melody 1 (police siren)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"a\":1}

REM DHT11
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/dht11/get -m ''

REM Moisture
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/moisture/get -m ''

REM FAN
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/fan/set -m {\"s\":10}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/fan/set -m {\"s\":0}

REM LCD
REM write Hello first row with clear display (x=1)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/lcd/set -m {\"c\":0,\"r\":0,\"t\":\"Hello\",\"x\":1}
REM write World with NO clear display (x=0)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/lcd/set -m {\"c\":0,\"r\":1,\"t\":\"World\",\"x\":0}
```
