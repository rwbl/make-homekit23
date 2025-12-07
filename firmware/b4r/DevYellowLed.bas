B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
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

Private Sub Process_Globals
	Private YellowLed As Pin
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   pinnr - GPIO pin number
Public Sub Initialize(pinnr As Byte)
	YellowLed.Initialize(pinnr, YellowLed.MODE_OUTPUT)
	YellowLed.DigitalWrite(False)
	Log("[DevYellowLed.Initialize][I] OK, pin=", pinnr)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' GetState
' Reads the current digital value.
' Parameters:
'   storeindex - Index in the global store buffer
' Returns:
'   Boolean - True if on, False otherwise
Public Sub Get As Boolean
	Return YellowLed.DigitalRead
End Sub

' SetState
' Sets the state to on or off.
' Parameters:
'   state - Boolean.
Public Sub Set(state As Boolean)
	YellowLed.DigitalWrite(state)
End Sub

' SetPWM
' Sets the PWM value (analog).
' Parameters:
'   value - UInt 0-255
Public Sub SetPWM(value As UInt)
	YellowLed.AnalogWrite(value)
End Sub

' Toggle
' Toggle button state to on or off.
Public Sub Toggle()
	Dim newstate As Boolean = Not(Get)
	Set(newstate)
	Log("[DevYellowLed.Toggle][I] newstate=", newstate)
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Sets the state to on or off based on MQTT action payload.
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevYellowLed.ProcessMQTT] storeindex=", storeindex, ", payload=", payload)

	' Get the state on or off
	Dim state() As Byte = MQTTClient.GetTextFromKey(payload, MQTTTopics.KEY_STATE)
	' Log("[YellowLed.Set] state=", Convert.ByteConv.StringFromBytes(state))
	
	' Turn the yellow led on or off or brightness (PWM pins only)
	If state == MQTTTopics.STATE_ON Then
		Set(True)
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_YELLOW_LED_STATUS), _
					   	   Array As String(Convert.ByteConv.StringFromBytes(MQTTTopics.PAYLOAD_YELLOW_LED_ON)))
	else if state == MQTTTopics.STATE_OFF Then
		Set(False)
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_YELLOW_LED_STATUS), _
					   	   Array As String(Convert.ByteConv.StringFromBytes(MQTTTopics.PAYLOAD_YELLOW_LED_OFF)))
	Else
		' This is only supported for PWM pins
		' Cast string to uint
		Dim value As UInt = Convert.UIntFromString(state)
		SetPWM(value)
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_YELLOW_LED_STATUS), _
					   	   Array As String(Convert.ByteConv.StringFromBytes(state)))
	End If
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x01
' Sets the state to on or off (Command 0x01).
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x01
' 	Byte 1 Command:	0x01 > Set
' 	Byte 2 State:	0x01 > ON or 0x00 > OFF
'	Example: Set ON = 010101
'
' Get the state (Command 0x02)
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x01
' 	Byte 1 Command:	0x02 > Get
'	Returns Byte 0=ON, 1=ON
'	Example Get State = 0102
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevYellowLed.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	' [DevYellowLed.ProcessBLE] storeindex=1, payload=010101
	
	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_SET_STATE
			Dim value As Byte = payload(2)
			Set(IIf(value == 1, True, False))
			WriteToBLE(command, value)
		Case CommBLE.CMD_GET_STATE
			Dim state As Byte = IIf(Get, 1, 0)
			WriteToBLE(command, state)
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	state - Byte
Public Sub WriteToBLE(command As Byte, state As Byte)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_YELLOW_LED, command, state)
	CommBLE.BLEServer_Write(payload)
	Log("[DevYellowLed.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
