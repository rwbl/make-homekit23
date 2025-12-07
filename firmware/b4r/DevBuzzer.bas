B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevBuzzer.bas
' Project:      make-homekit32
' Brief:        Plays tones or melodies.
' Date:         2025-11-12
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rESP32Buzzer, rGlobalStoreEx
' Description:	Tone and melody playback using passive buzzer.
' Hardware: 	https://wiki.keyestudio.com/Ks0019_keyestudio_Passive_Buzzer_module
' ================================================================
#End Region

Private Sub Process_Globals
	Private Buzzer As ESP32Buzzer
	Private IsEnabled As Boolean = True
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   pinnr - GPIO pin number
Public Sub Initialize(pinnr As Byte)
	Buzzer.Initialize(pinnr)
	Log("[DevBuzzer.Initialize][I] OK, pin=", pinnr)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
Public Sub PlayTone(freq As ULong, duration As ULong)
	Buzzer.PlayTone(freq, duration)
End Sub

Public Sub PlayAlarm(mode As Byte, repeats As Byte)
	Buzzer.PlayAlarm(mode, repeats)
End Sub

' Enabled
' Sets the enabled state of the PIR sensor.
' Parameters:
'   state - true (enabled), false (disabled)
Public Sub Enabled(state As Boolean)
	Log("[DevBuzzer.Enabled][I] state=", state)
	IsEnabled = state
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Play tone or melody.
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	If Not(IsEnabled) Then Return
	
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevBuzzer.ProcessMQTT] storeindex=", storeindex, ", payload=", payload)

	' Get the tone and duration
	Dim tone As Double = MQTTClient.GetNumberFromKey(payload, MQTTTopics.KEY_TONE)
	Dim duration As Double = MQTTClient.GetNumberFromKey(payload, MQTTTopics.KEY_DURATION)
	Dim alarm As Double = MQTTClient.GetNumberFromKey(payload, MQTTTopics.KEY_ALARM)
	Dim repeats As Double = MQTTClient.GetNumberFromKey(payload, MQTTTopics.KEY_REPEATS)
	Log("[DevBuzzer.Set] tone=", tone, ", duration=", duration, ", alarm=", alarm, ", repeats=", repeats)
	
	' If no alarm melody then play tone
	If alarm == -1 Then
		Buzzer.PlayTone(tone, duration)
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_BUZZER_STATUS), _
					   	   Array As String(MQTTTopics.PAYLOAD_BUZZER_TONE))
	Else
		' Play alarm with repeat
		Buzzer.PlayAlarm(alarm, Round(repeats))
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_BUZZER_STATUS), _
					   	   Array As String(MQTTTopics.PAYLOAD_BUZZER_ALARM))
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
' DeviceID: 0x07
' Play Tone
' 	Length: 6 Bytes
' 	Byte 0 Device:		0x07
' 	Byte 1 Command:		0x03 > Set value
'	Tone (frequency Hz) as UInt 2 Bytes:
' 	Byte 2 Tone:		0x01-0xFF
' 	Byte 3 Tone:		0x01-0xFF
'	Duration (ms) as UInt 2 Bytes:
'	Byte 4 Duration:	0x01-0xFF
'	Byte 5 Duration:	0x01-0xFF
'	Example: Play Tone 440 (HEX 01B8), Duration 500ms (HEX 01F4) = 070301B801F4

' Play Alarm
' 	Length: 4 Bytes
' 	Byte 0 Device:		0x07
' 	Byte 1 Command:		0x05 > Custom action
' 	Byte 2 Mode:		0x01-0x05 > Alarm melody (mode)
' 	Byte 3 Repeats:		0xNN
'	Example: Play alarm 1, repeat 2 = 07050102
'
' Set Buzzer enabled/disabled
' 	Length: 3 Bytes
' 	Byte 0 Device:		0x07
' 	Byte 1 Command:		0x01 > Set
' 	Byte 2 State:		0x00 (Off), 0x01 (On)
'	Example: Set buzzer disabled = 070100 or enabled 070101
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	If Not(IsEnabled) Then Return
	
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevBuzzer.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	' [DevBuzzer.ProcessBLE] storeindex=1, payload=
	
	' Get the command and the value
	Dim command As Byte = payload(1)

	' Select command set or get
	Select command
		Case CommBLE.CMD_SET_VALUE
			' HINT: Little endian so byte swap
			Dim freq As UInt = Convert.BytesToUInt(Array As Byte(payload(3), payload(2)))
			Dim duration As UInt = Convert.BytesToUInt(Array As Byte(payload(5), payload(4)))
			Buzzer.PlayTone(freq, duration)
			WriteToBLE(command, True)
			Log("[DevBuzzer.ProcessBLE] tone freq=", freq, ", duration=", duration)
		Case CommBLE.CMD_CUSTOM_ACTION
			Dim mode As Byte = payload(2)
			Dim repeats As Byte = payload(2)
			Buzzer.PlayAlarm(mode, repeats)
			WriteToBLE(command, True)
			Log("[DevBuzzer.ProcessBLE] custom mode=", mode, ", repeats=", repeats)
		Case CommBLE.CMD_SET_STATE
			Dim value As Byte = payload(2)
			Dim state As Boolean = IIf(value == 1, True, False)
			Enabled(state)
			WriteToBLE(command, state)
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	state - Byte
Public Sub WriteToBLE(command As Byte, state As Boolean)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_BUZZER, command, Convert.BoolToByte(state))
	CommBLE.BLEServer_Write(payload)
	Log("[DevBuzzer.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
