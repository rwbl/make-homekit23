B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' Class:        BLECommands
' Brief:        Registry of BLE command definitions.
' Date:         2025-11-21
' Author:       Robert W.B. Linn (c) 2025 MIT
' Description:  Provides TCommand definitions and utilities.
' Note:			B4R uses unsigned bytes (0–255)
'				B4J uses signed bytes (–128 to +127) > use Int for DeviceID and CommandID and NOT Byte
#End Region

Private Sub Class_Globals
	' Command definition
	Type TCommand (Name As String, DeviceId As Int, CommandId As Int, Description As String, Value() As Byte)

	' List of commands
	Public ListCommands As List
End Sub

' Initializes the object.
' The list must contain unique command names.
Public Sub Initialize
	' Init the list
	ListCommands.Initialize

	Add("Connect",  BLEConstants.DEV_SYSTEM, BLEConstants.CMD_SET_STATE, "Connect HK32",  Array As Byte(BLEConstants.STATE_ON))
	Add("Disconnect",  BLEConstants.DEV_SYSTEM, BLEConstants.CMD_SET_STATE, "Disconnect HK32",  Array As Byte(BLEConstants.STATE_OFF))

	Add("Yellow LED ON",  BLEConstants.DEV_YELLOW_LED, BLEConstants.CMD_SET_STATE, "Turn Yellow LED on",  Array As Byte(BLEConstants.STATE_ON))
	Add("Yellow LED OFF", BLEConstants.DEV_YELLOW_LED, BLEConstants.CMD_SET_STATE, "Turn Yellow LED off", Array As Byte(BLEConstants.STATE_OFF))

	Add("RGB ON",  BLEConstants.DEV_RGB_LED, BLEConstants.CMD_SET_VALUE, "Turn RGB LED on (Neopixel)",  Array As Byte(0x4, 0x4, 0x4))
	Add("RGB OFF",  BLEConstants.DEV_RGB_LED, BLEConstants.CMD_SET_VALUE, "Turn RGB LED on (Neopixel)",  Array As Byte(0x00, 0x00, 0x00))

	Add("Door Open",  BLEConstants.DEV_SERVO_DOOR, BLEConstants.CMD_SET_STATE, "Open Entrance Door (Servo)",  Array As Byte(BLEConstants.ACTION_OPEN))
	Add("Door Close",  BLEConstants.DEV_SERVO_DOOR, BLEConstants.CMD_SET_STATE, "Close Entrance Door (Servo)",  Array As Byte(BLEConstants.ACTION_CLOSE))
	Add("Window Open",  BLEConstants.DEV_SERVO_WINDOW, BLEConstants.CMD_SET_STATE, "Open Window (Servo)",  Array As Byte(BLEConstants.ACTION_OPEN))
	Add("Window Close",  BLEConstants.DEV_SERVO_WINDOW, BLEConstants.CMD_SET_STATE, "Close Window (Servo)",  Array As Byte(BLEConstants.ACTION_CLOSE))

	Add("Temperature",  BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE, "Request Temperature (DHT11)",  Null)
	Add("Humidity",  BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE, "Request Humidity (DHT11)",  Null)

	Add("Police Siren",  BLEConstants.DEV_BUZZER, BLEConstants.CMD_CUSTOM_ACTION, "Police siren once (Buzzer)",  Array As Byte(0x01, 0x01))
	Add("Danger Alarm",  BLEConstants.DEV_BUZZER, BLEConstants.CMD_CUSTOM_ACTION, "Danger alarm once (Buzzer)",  Array As Byte(0x05, 0x01))
	' POLICE_SIREN 1, FIRE_ALARM 2, WAIL_SWEEP 3, INTRUDER_ALARM 4, DANGER_ALARM 5

	Add("Fan",  BLEConstants.DEV_FAN, BLEConstants.CMD_SET_STATE, "Turn Fan on (Motor)",  Array As Byte(BLEConstants.STATE_ON))
	Add("Fan",  BLEConstants.DEV_FAN, BLEConstants.CMD_SET_STATE, "Turn Fan off (Motor)",  Array As Byte(BLEConstants.STATE_OFF))

	' LCD1602 - Custom Action
	Add("LCD Clear",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, "Clear (LCD1602)",  Array As Byte(0x01))
	' Payload (3 bytes): 0x0C 0x05 0x01
	Add("LCD Clear Row 0",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, "Clear top row (LCD1602)",  Array As Byte(0x02, 0x00))
	' Payload clear top row (row 0)(4 bytes): 0x0C 0x05 0x02 0x00
	Add("LCD Clear Row 1",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, "Clear bottom row (LCD1602)",  Array As Byte(0x02, 0x01))
	' Payload clear botton row (row 1)(4 bytes): 0x0C 0x05 0x02 0x01
	Add("LCD Backlight ON",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, "Backlight ON (LCD1602)",  Array As Byte(0x03, 0x01))
	' Payload set backlight on (4 bytes): 0x0C 0x05 0x03 0x01
	Add("LCD Backlight OFF",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, "Backlight OFF(LCD1602)",  Array As Byte(0x03, 0x00))
	' Payload set backlight off (4 bytes): 0x0C 0x05 0x03 0x00

	' LCD1602 - Set Value
	Dim text As String = "Hello"
	Dim row As Byte = 0x00
	Dim col As Byte = 0x00
	Dim len As Byte = text.Length
	Dim textbytes() As Byte = text.GetBytes("UTF8")
	' Payload buffer has 8 bytes = row (1) + col (1) + text length (5)
	Dim payload(1 + 1 + 1 + len) As Byte
	' Set the payload buffer - the manual way
	payload(0) = row
	payload(1) = col
	payload(2) = len	
	For i = 0 To textbytes.Length - 1
		payload(i + 3) = textbytes(i)
	Next
	Log($"[BLECommands.Initialize] LCD Hello=${Convert.ByteConv.HexFromBytes(payload)}, len=${payload.Length} (expect 8)"$)
	Add("LCD Hello",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_SET_VALUE, "Display Hello (LCD1602)",  payload)

	' Using helper sub
	' Date & Time
	Add("LCD Date",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_SET_VALUE, "Display Date (LCD1602)",  SetLCD1602TextPayload(0,0,DateTime.Date(DateTime.Now)))
	Add("LCD Time",  BLEConstants.DEV_LCD1602, BLEConstants.CMD_SET_VALUE, "Display Time (LCD1602)",  SetLCD1602TextPayload(1,0,DateTime.Time(DateTime.Now)))

	Log($"[BLECommands.Initialize] commands=${ListCommands.Size}"$)
End Sub

#Region CommandList
' Adds a command definition
Public Sub Add(name As String, devid As Int, cmdid As Int, desc As String, value() As Byte)
	Dim c As TCommand
	c.Initialize
	c.Name = name
	c.DeviceId = devid
	c.CommandId = cmdid
	c.Description = desc
	c.Value = value
	ListCommands.Add(c)
End Sub

' Get a command (must match both Device + Command)
Public Sub Get(deviceId As Byte, commandId As Byte) As TCommand
	For Each c As TCommand In ListCommands
		If c.DeviceId = deviceId And c.CommandId = commandId Then
			Return c
		End If
	Next
	Return Null
End Sub

' Find a command by name
Public Sub Find(name As String) As TCommand
	For Each c As TCommand In ListCommands
		If c.Name.ToLowerCase = name.ToLowerCase Then
			Return c
		End If
	Next
	Return Null
End Sub

' Build BLE payload: <deviceid> <commandid> <value...>
Public Sub BuildPayload(c As TCommand) As Byte()
	If c = Null Then Return Null

	Dim val() As Byte = c.Value
	Dim vlen As Int = IIf(val = Null, 0, val.Length)

	Dim payload(2 + vlen) As Byte
	payload(0) = c.DeviceId
	payload(1) = c.CommandId

	If vlen > 0 Then
		For i = 0 To vlen - 1
			payload(2 + i) = val(i)
		Next
	End If
	Return payload
End Sub
#End Region

#Region LCD1602
Public Sub SetLCD1602TextPayload(row As Byte, col As Byte, text As String) As Byte()
	' LCD1602 - Set Value
	Dim len As Byte = text.Length
	Dim textbytes() As Byte = text.GetBytes("UTF8")
	' Payload buffer has 8 bytes = row (1) + col (1) + text length (5)
	' This as an example for the text hello
	Dim payload(1 + 1 + 1 + len) As Byte
	' Set the payload buffer - the manual way
	payload(0) = row
	payload(1) = col
	payload(2) = len	
	For i = 0 To textbytes.Length - 1
		payload(i + 3) = textbytes(i)
	Next
	Log($"[SetLCD1602TextPayload] text=${text}, payload=${Convert.ByteConv.HexFromBytes(payload)}, len=${payload.Length}"$)
	Return payload
End Sub
