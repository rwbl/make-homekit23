B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevPIRSensor.bas
' Project:      make-homekit32
' Brief:        Read and handle the PIR (Passive Infrared) sensor.
' Note:			Sensor Pin AddListener State: True (HIGH)=Clear, False (LOW)=Detected
'				Output Delay Time (High Level): About 2.3 to 3 Seconds
'				Clear: Sensor Output Indicator LED OFF
'				Detected: Sensor Output Indicator LED ON
' Date:         2025-11-29
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx, rMQTT
' Description:	Motion detection with event callback logic.
' Hardware: 	https://wiki.keyestudio.com/Ks0052_keyestudio_PIR_Motion_Sensor
' ================================================================
#End Region

Private Sub Process_Globals
	Private DEBOUNCE_MS As UInt = 800
	
	Private Sensor As Pin
	Private IsEnabled As Boolean = True
	Private PrevState As Boolean = False
	Private LastChange As ULong = 0
End Sub

' Initialize
' Initializes the PIR sensor pin and attaches a listener.
' Parameters:
'   pinnr - GPIO pin number (digital input)
Public Sub Initialize(pinnr As Byte)
	Sensor.Initialize(pinnr, Sensor.MODE_INPUT)
	' Add a listener to detect motion
	Sensor.AddListener("Sensor_StateChanged")
	Log("[DevPIRSensor.Initialize][I] OK, pin=", pinnr)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' Get
' Reads the current digital PIR sensor value.
' Parameters:
'   storeindex - Index in the global store buffer
' Returns:
'   Boolean - True if motion detected, False otherwise
Public Sub Get(storeindex As Byte) As Boolean
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevPIRSensor.Get] storeindex=", storeindex, ", payload=", payload)

	Dim State As Boolean = Sensor.DigitalRead
	Log("[DevPIRSensor.Get] state=", State)
	Return State
End Sub

' Enabled
' Sets the enabled state of the PIR sensor.
' Parameters:
'   state - true (enabled), false (disabled)
Public Sub Enabled(state As Boolean)
	Log("[DevPIRSensor.Enabled][I] state=", state)
	IsEnabled = state
End Sub

' State_Changed
' Sensor listener event for state changes.
' Publishes MQTT status as JSON payload:
'   {"s":"detected"} when motion is detected
'   {"s":"clear"} when motion is clear
Sub Sensor_StateChanged(state As Boolean)
	If Not(IsEnabled) Then Return
	Dim detected As Boolean
	
	' Debounce: ignore changes faster than NNN ms
	If (Millis - LastChange) < DEBOUNCE_MS Then Return
	LastChange = Millis
	
	Log("[DevPIRSensor.State_Changed] state=", state, ", prev=", PrevState)

	If state <> PrevState Then
		
		DevLCD1602.Clear
		DevLCD1602.WriteAt(0, 0, "Motion")
		If Not(state) Then
			detected = True
			DevLCD1602.WriteAt(0, 1, "Detected")
		Else
			detected = False
			DevLCD1602.WriteAt(0, 1, "Clear")
		End If
		
		#If MQTT
		PublishToMQTT(detected)
		#End If
		
		#If BLE
		WriteToBLE(CommBLE.CMD_GET_STATE, detected)
		#End If
		PrevState = state
	End If
End Sub
#End Region

#If MQTT
#Region MQTT Control
' PublishToMQTT
' Publish the state.
' Parameters
'	state - true (detected) or false (clear)
Private Sub PublishToMQTT(state As Boolean)
	Dim topic() As String = Array As String(MQTTTopics.TOPIC_PIR_SENSOR_STATUS)
	Dim payload() As String
		
	If not(state) Then
		payload = Array As String(MQTTTopics.PAYLOAD_PIR_DETECTED)
	Else
		payload = Array As String(MQTTTopics.PAYLOAD_PIR_CLEAR)
	End If
		
	MQTTClient.Publish(topic, payload)
	Log("[DevPIRSensor.PublishToMQTT][I] json=", payload(0))
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x0D
' Get sensor data.
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x0D
' 	Byte 1 Command:	0x02 > Get state
'	Returns Byte 0=Clear, 1=Detected
'	Example Get State = 0D02
'
' Set sensor enabled
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x0D
' 	Byte 1 Command:	0x01 > Set state
' 	Byte 2 State:	0x00 > Disabled or 0x01 Enabled
'	Returns Byte 0=Clear, 1=Detected
'	Example Set State = 0D0101
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevPIRSensor.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_GET_STATE
			Dim value As Byte = payload(2)
			' Important to reverse the state to get state byte 0x01=Detected, ox00=Cleared
			Dim state As Boolean = IIf(value == 1, False, True)
			WriteToBLE(CommBLE.CMD_GET_STATE, state)
		Case CommBLE.CMD_SET_STATE
			Dim value As Byte = payload(2)
			Dim state As Boolean = IIf(value == 1, True, False)
			Enabled(state)
			WriteToBLE(CommBLE.CMD_SET_STATE, state)
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	command - Byte 
'	state - Boolean True or False
Public Sub WriteToBLE(command As Byte, state As Boolean)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_PIR_SENSOR, command, Convert.BoolToByte(state))
	CommBLE.BLEServer_Write(payload)
	Log("[DevPIRSensor.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
