B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:			MQTTTopics.bas
' Project:		make-homekit32
' Brief:		MQTT topic and payload definitions.
' Date:			2025-11-10
' Author:		Robert W.B. Linn (c) 2025 MIT
' MQTT:			Topics & Payloads
'				Topics:
'				- use prefix homekit32/home1/<device>/<action>
'					Example: "homekit32/home1/yellow_led/set"
'				- /set - Incoming commands
'				- /status - Outgoing state
'				- /status or /event - Sensor events
'				- /action - Button
'				- /get are empty payloads and request-only.
'					Examples: TOPIC_DHT11_GET, TOPIC_MOISTURE_GET
'				Payloads: 
'				- No spaces → saves bytes in MQTT payload
'				- One-letter JSON keys → very compact
'				- Distinguish placeholder keys (#X) from JSON keys ("x")
'				- JSON stays valid And minimal
'				| Meaning  | JSON Key | Placeholder | Example        |
'				| -------- | -------- | ----------- | -------------- |
'				| action   |   a      |   #A        | "a":"open"     |
'				| tone     |   t      |   #T        | "t":1000       |
'				| duration |   d      |   #D        | "d":500        |
'				| state    |   s      |   #S        | "s":"on"       |
'				| index    |   i      |   #I        | "i":0          |
'				| red      |   r      |   #R        | "r":255        |
'				| green    |   g      |   #G        | "g":128        |
'				| blue     |   b      |   #B        | "b":64         |
'				| uid      |   u      |   #U        | "u":"AB12CD34" |
'				| group    |   g      |   #G        | "g":1          |
'				| command  |   c      |   #C        | "c":2          |
'				| moisture |   m      |   #M        | "m":250        |
'				| humidity |   h      |   #H        | "h":45         |
'				| clear    |   c      |   #C        | "c":1          |
'				| message  |   m      |   #M        | "m":"message"  |
'				| uptime   |   u      |   #U        | "u":123        |
'				| ip       |   p      |   #P        | "p":"N.N.N.N"  |
'				| fan speed|   v      |   #V        | "v":50         |
'				| events   |   e      |   #S        | "e":0 | 1      |
' Dependencies:	n/a
' ================================================================
#End Region

Private Sub Process_Globals

	'==============================
	' Generic Keyes (lowercase)
	'==============================
	' Device
	Public KEY_DEVICE As String = "d"

	' State
	Public KEY_STATE As String = "s"
	' Action
	Public KEY_ACTION As String = "a"
	
	' Topic Index
	Public KEY_INDEX As String = "i"
	
	' RGBLED
	Public KEY_RED As String = "r"
	Public KEY_BLUE As String = "b"
	Public KEY_GREEN As String = "g"

	' LCD
	Public KEY_CLEAR As String = "c"

	' RFID
	Public KEY_UID As String = "u"
	Public KEY_GROUP As String = "g"
	Public KEY_COMMAND As String = "c"

	' Buzzer
	Public KEY_TONE As String = "t"
	Public KEY_DURATION As String = "d"
	Public KEY_MELODY As String = "m"
	Public KEY_ALARM As String = "a"
	Public KEY_REPEATS As String = "r"

	' DHT
	Public KEY_TEMPERATURE As String = "t"
	Public KEY_HUMIDITY As String = "h"

	' Moisture
	Public KEY_MOISTURE As String = "m"
	
	'==============================
	' Generic States (lowercase)
	'==============================
	Public STATE_ON As String 						= "on"
	Public STATE_OFF As String 						= "off"
	Public STATE_ON_VAL As Byte 					= 1
	Public STATE_OFF_VAL As Byte 					= 0

	Public ACTION_OPEN As String 					= "open"
	Public ACTION_CLOSE As String 					= "close"
	Public ACTION_OPEN_VAL As Byte 					= 1
	Public ACTION_CLOSE_VAL As Byte					= 0
	Public STATE_OPEN As String 					= "open"
	Public STATE_CLOSED As String 					= "closed"

	' State returned from device operations
	Public PAYLOAD_STATE As String					= "{""s"":#S}"

	'==============================
	' Generic Command Topic
	'==============================
	Public TOPIC_COMMAND As String					= "homekit32/home1/command"

	'==============================
	' Yellow LED
	' Set the status on or off of the yellow led.
	'==============================
	Public TOPIC_YELLOW_LED_SET As String			= "homekit32/home1/yellow_led/set"
	Public TOPIC_YELLOW_LED_STATUS As String		= "homekit32/home1/yellow_led/status"
	Public PAYLOAD_YELLOW_LED_ON As String			= "{""s"":""on""}"
	Public PAYLOAD_YELLOW_LED_OFF As String			= "{""s"":""off""}"
	' Note: Also excepts value 0-255 as string to set brightness if pin is PWM.

	'==============================
	' RGB LED (6812 4 NeoPixel)
	' Set the color of the 4 neopixel.
	'==============================
	Public TOPIC_RGB_LED_SET As String 				= "homekit32/home1/rgb_led/set"
	Public TOPIC_RGB_LED_STATUS As String 			= "homekit32/home1/rgb_led/status"
	Public PAYLOAD_RGB_LED As String 				= "{""i"":#I,""r"":#R,""g"":#G,""b"":#B,""c"":#C}"
	Public PAYLOAD_RGB_LED_CLEAR As String			= "{""c"":#C}"
	' JSON key:value pairs: i=index 0-3, r=red 0-255, g=green 0-255, b=blue 0-255, c=clear 0-1
	' Example: {"i":0,"r":255,"g":0,"b":0,"c":1}

	'==============================
	' Push Buttons
	' Action a pushbutton pressed or released.
	'==============================
	Public TOPIC_BUTTON_LEFT_ACTION As String 			= "homekit32/home1/button_left/action"
	Public TOPIC_BUTTON_RIGHT_ACTION As String			= "homekit32/home1/button_right/action"
	Public PAYLOAD_BUTTON_PRESSED As String 			= "{""p"":1}"
	Public PAYLOAD_BUTTON_RELEASED As String			= "{""p"":0}"

	'==============================
	' Door Servo
	' Set the door servo to open or closed.
	'==============================
	' Sending a command to open / close the door
	Public TOPIC_SERVO_DOOR_SET As String				= "homekit32/home1/servo_door/set"
	Public PAYLOAD_SERVO_DOOR_ACTION_OPEN As String		= "{""a"":""open""}"
	Public TOPIC_SERVO_DOOR_STATUS As String			= "homekit32/home1/servo_door/status"
	Public PAYLOAD_SERVO_DOOR_ACTION_CLOSE As String	= "{""a"":""close""}"
	' Reporting that the door is now open / closed
	Public PAYLOAD_SERVO_DOOR_OPEN As String 			= "{""s"":""open""}"
	Public PAYLOAD_SERVO_DOOR_CLOSED As String 			= "{""s"":""closed""}"

	'==============================
	' Window Servo
	' Set the window servo to open or closed.
	'==============================
	' Sending a command to open / close the window
	Public TOPIC_SERVO_WINDOW_SET As String				= "homekit32/home1/servo_window/set"
	Public PAYLOAD_SERVO_WINDOW_ACTION_OPEN As String	= "{""a"":""open""}"
	Public TOPIC_SERVO_WINDOW_STATUS As String			= "homekit32/home1/servo_window/status"
	Public PAYLOAD_SERVO_WINDOW_ACTION_CLOSE As String	= "{""a"":""close""}"
	' Reporting that the window is now open / closed
	Public PAYLOAD_SERVO_WINDOW_OPEN As String 			= "{""s"":""open""}"
	Public PAYLOAD_SERVO_WINDOW_CLOSED As String 		= "{""s"":""closed""}"

	'==============================
	' Buzzer
	' Set the buzzer tone for N ms (non-blocking) or
	' play alarm melody (blocking)
	'==============================
	Public TOPIC_BUZZER_SET As String					= "homekit32/home1/buzzer/set"
	Public PAYLOAD_BUZZER_SET As String 				= "{""t"":#T,""d"":#D,""a"":#A,""r"":#R}"
	' Example play single tone: {"t":440,"d":500} or {"t":0,"d":0}
	' Example play melody alarm 1 with 2 repeats: {"a":1, "r":2}
	Public TOPIC_BUZZER_STATUS As String 				= "homekit32/home1/buzzer/status"
	Public PAYLOAD_BUZZER_STATUS As String 				= "{""s"":#S}"
	Public PAYLOAD_BUZZER_IDLE As String 				= "{""s"":""idle""}"
	Public PAYLOAD_BUZZER_TONE As String 				= "{""s"":""tone""}"
	Public PAYLOAD_BUZZER_ALARM As String 				= "{""s"":""alarm""}"

	'==============================
	' Fan
	' Set the speed of the fan 0-255.
	'==============================
	Public TOPIC_FAN_SET As String 						= "homekit32/home1/fan/set"
	Public PAYLOAD_FAN_SET As String 					= "{""s"":#S}"
	' Example: {"v":50 }
	Public TOPIC_FAN_STATUS As String 					= "homekit32/home1/fan/status"
	Public PAYLOAD_FAN_STATUS As String 				= "{""s"":#S}"

	'==============================
	' Temperature & Humidity Sensor
	' Get the temp and hum.
	'==============================
	Public TOPIC_DHT11_GET As String 					= "homekit32/home1/dht11/get"
	Public PAYLOAD_DHT11_GET As String 					= ""
	Public TOPIC_DHT11_STATUS As String 				= "homekit32/home1/dht11/status"
	Public PAYLOAD_DHT11_STATUS As String 				= "{""t"":#T,""h"":#H}"
	' Example: {"t":22.4,"h":45.0}

	'==============================
	' Gas Sensor (Analog)
	' Get gas detected or clear
	' Set the gas detection status - see Event. 
	'==============================
	Public TOPIC_GAS_SENSOR_GET As String 				= "homekit32/home1/gas/get"
	Public PAYLOAD_GAS_SENSOR_GET As String 			= ""
	Public TOPIC_GAS_SENSOR_STATUS As String 			= "homekit32/home1/gas/status"
	Public PAYLOAD_GAS_SENSOR_STATUS As String 			= "{""s"":#S}"
	Public PAYLOAD_GAS_DETECTED As String 				= "{""s"":""detected""}"
	Public PAYLOAD_GAS_CLEAR As String 					= "{""s"":""clear""}"
	' Example: see payload

	'==============================
	' Moisture Sensor (Steam Sensor)
	' Get the moisture level.
	' Set the moisture status - see Event.
	'==============================
	Public TOPIC_MOISTURE_GET As String 				= "homekit32/home1/moisture/get"
	Public PAYLOAD_MOISTURE_GET As String 				= ""
	Public TOPIC_MOISTURE_STATUS As String 				= "homekit32/home1/moisture/status"
	Public PAYLOAD_MOISTURE_STATUS As String 			= "{""s"":#S}"
	' Example: {"m":250 }

	'==============================
	' PIR Sensor
	' Get state detected or not detected.
	'==============================
	Public TOPIC_PIR_SENSOR_STATUS As String 			= "homekit32/home1/motion/status"
	Public PAYLOAD_PIR_DETECTED As String 				= "{""s"":""detected""}"
	Public PAYLOAD_PIR_CLEAR As String 					= "{""s"":""clear""}"
	' Example: see payload

	'==============================
	' RFID Module
	' Set the RFID status - see Event.
	'==============================
	Public TOPIC_RFID_STATUS As String 					= "homekit32/home1/rfid/status"
	Public PAYLOAD_RFID_STATUS As String 				= "{""u"":""#U"",""g"":#G,""c"":#C}"
	' Example: 

	'==============================
	' LCD 1602 I2C
	'==============================
	Public TOPIC_LCD_SET As String 						= "homekit32/home1/lcd/set"
	Public PAYLOAD_LCD_SET As String					="{""c"":#C,""r"":#R,""t"":""#T"",""x"":#X}"
	Public TOPIC_LCD_STATUS As String 					= "homekit32/home1/lcd/status"
	' JSON key:value pairs: c=column 0-15, r=row 0-1, t=text, x=clear 0-1
	' Example: {"c":0-15,"r":0-1,"t":"string","x":0-1}
	' Example: {"t":"Welcome Home!"}
	Public PAYLOAD_LCD_STATUS As String 				= "{""s"":#S}"

	'==============================
	' System
	' Special device for system custom actions
	'==============================
	Public TOPIC_SYSTEM_SET As String					= "homekit32/home1/system/set"
	Public TOPIC_SYSTEM_STATUS As String				= "homekit32/home1/system/status"
	Public PAYLOAD_SYSTEM_EVENTS_ENABLED As String		= "{""e"":#S}"
	' Example: {"e":1}
	Public TOPIC_SYSTEM_INFO As String 					= "homekit32/home1/system/info"
	' Example: {"u":123456, "a":"192.168.1.55"} holding uptime, ip address

	'==============================
	' System Info / Debug / Error
	'==============================
	Public TOPIC_SYSTEM_ERROR As String 				= "homekit32/home1/error"
	' Example: {"m":"sensor timeout" }

	'==============================
	' Global Topics Table
	'==============================

	' Define all topics in the same order as handler subs.
	' Max number of topics is 254
	Public TopicTable() As String = Array As String( _ 
		TOPIC_COMMAND, _ 
		TOPIC_YELLOW_LED_SET, _ 
		TOPIC_RGB_LED_SET, _ 
		TOPIC_BUTTON_LEFT_ACTION, _ 
		TOPIC_BUTTON_RIGHT_ACTION, _ 
		TOPIC_SERVO_DOOR_SET, _ 
		TOPIC_SERVO_WINDOW_SET, _ 
		TOPIC_BUZZER_SET, _ 
		TOPIC_FAN_SET, _ 
		TOPIC_DHT11_GET, _ 
		TOPIC_GAS_SENSOR_GET, _ 
		TOPIC_MOISTURE_GET, _ 
		TOPIC_LCD_SET)

	' Max number of topics is 254 > 255 is used in case topic not found
	Public TOPIC_NOT_FOUND As Byte = 255
End Sub

' Get the topic index for a topic.
' Returns index found or 255 if not found
Public Sub GetTopicIndex(topic As String) As Byte
	For i = 0 To TopicTable.Length - 1
		If topic = TopicTable(i) Then 
			Return i
		End If
	Next
	Return 255
End Sub
