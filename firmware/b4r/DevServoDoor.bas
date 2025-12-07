B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevServoDoor.bas
' Project:      Set the servo window to open or closed.
' Date:         2025-11-14
' Author:       Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx, rESP32Servo
' Description:	Controls a micro servo to open or close the window
'				via MQTT or BLE commands
' Hardware:		https://wiki.keyestudio.com/Ks0194_keyestudio_Micro_Servo
' ================================================================
#End Region

Private Sub Process_Globals
	Private Servo As ESP32Servo
	Private ServoPin As Pin
	Private ServoState As Byte		= 0
	
	Private TIMER_SLOT As Int 		= 1		' 0–3 (ESP32 has 4 hardware PWM timers)
	Private OPEN_POS As UInt 		= 120
	Private CLOSED_POS As UInt 		= 10

	Private ACTION_OPEN As Byte 	= 1
	Private ACTION_CLOSE As Byte	= 0	'ignore

	#If MQTT
	Private MOVE_DELAY As ULong		= 40
	#End If
End Sub

' Initialize
' Initializes the servo through its pin with an allocated timer slot.
' Parameters:
'   pinnr - GPIO pin number (PWM output)
Public Sub Initialize(pinnr As Byte)
	ServoPin.Initialize(pinnr, ServoPin.MODE_OUTPUT)
	Servo.AttachToTimer(pinnr, TIMER_SLOT)
	Log("[DevServoDoor.Initialize][I] OK, pin=", pinnr, ", timerslot=", TIMER_SLOT)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' Set
' Moves the servo to the position given by the state.
' Parameters:
'   state - Byte value (1=open, 0=close)
Public Sub Set(action As Byte)
	Log("[DevServoDoor.Set][I] action=", action)
	
	Dim angle As Int = IIf(action == ACTION_OPEN, OPEN_POS, CLOSED_POS)
	Servo.Write(angle)
	
	ServoState = action
	
	#If MQTT
	' Confirm position after small delay
	CallSubPlus("ConfirmMQTT", MOVE_DELAY, action)
	#End if
End Sub

' Get
' Get the servo state.
' Returns 0=closed, 1=open
Public Sub Get As Byte
	Return ServoState
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Sets the servo to open or close based on MQTT action payload.
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevServoDoor.ProcessMQTT] storeindex=", storeindex, ", payload=", payload)
	
	Dim action() As Byte = MQTTClient.GetTextFromKey(payload, MQTTTopics.KEY_ACTION)
	Dim actionstr As String = Convert.ByteConv.StringFromBytes(action)

	If actionstr == MQTTTopics.ACTION_OPEN Then
		CallSubPlus("Set", 0, MQTTTopics.ACTION_OPEN_VAL)
	Else If actionstr == MQTTTopics.ACTION_CLOSE Then
		CallSubPlus("Set", 0, MQTTTopics.ACTION_CLOSE_VAL)
	End If
End Sub

' ConfirmMQTT
' Publishes the servo position (open/closed) via MQTT.
' Parameters:
'   action - Byte value (1=open, 0=close)
Private Sub ConfirmMQTT(action As Byte)
	Dim topic() As String = Array As String(MQTTTopics.TOPIC_SERVO_DOOR_STATUS)
	Dim payload() As String

	If action = MQTTTopics.ACTION_OPEN_VAL Then
		payload = Array As String(MQTTTopics.PAYLOAD_SERVO_DOOR_OPEN)
	Else
		payload = Array As String(MQTTTopics.PAYLOAD_SERVO_DOOR_CLOSED)
	End If
	MQTTClient.Publish(topic, payload)
	Log("[DevServoDoor.ConfirmPosition][I] json=", payload(0))
	
	' Optional: Detach servo to prevent jitter
	' Servo.Detach
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x05
' Sets the state to open or closed (Command 0x01).
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x05
' 	Byte 1 Command:	0x01 > Set
' 	Byte 2 State:	0x01 > Open or 0x00 > Closed
'	Example: Set door open = 050101
'
' Get the state open or closed (Command 0x02)
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x05 > Servo Door
' 	Byte 1 Command:	0x02 > Get
'	Example: Get door state = 0502
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevServoDoor.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_SET_STATE
			Dim value As Byte = payload(2)
			Set(value)
			WriteToBLE(command, value)
		Case CommBLE.CMD_GET_STATE
			WriteToBLE(command, Get)
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	state - Byte
Public Sub WriteToBLE(command As Byte, state As Byte)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_SERVO_DOOR, command, state)
	CommBLE.BLEServer_Write(payload)
	Log("[DevServoDoor.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If

