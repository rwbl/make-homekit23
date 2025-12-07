B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevBuzzer.bas
' Brief:	Getter / setter / parser for the buzzer device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### Buzzer (0x07)
'| Command | Name          | Payload                                  | Example             | Description                                         |
'| ------- | ------------- | ---------------------------------------- | ------------------- | --------------------------------------------------- |
'| 0x01    | SET_STATE     | 1 byte (0=Off,1=On) | `07 01 01`         | Enable buzzer       |
'| 0x03    | SET_VALUE     | 4 bytes (freq UInt, duration UInt)       | `07 03 01 B8 01 F4` | Play Tone 440 (HEX 01B8), Duration 500ms (HEX 01F4) |
'| 0x05    | CUSTOM_ACTION | 2 bytes (mode 0x01-0x05, repeats 0xNN)   | `07 05 01 02`       | Play alarm 1 with 2 repeats                         |
'| Alarm Modes: POLICE_SIREN = 1, FIRE_ALARM = 2, WAIL_SWEEP = 3, INTRUDER_ALARM	= 4, DANGER_ALARM = 5
' ================================================================
#End Region

Sub Class_Globals
	Type TDevBuzzer( DeviceId As Byte, CommandId As Byte, State As Boolean )
	Private SET_STATE_PAYLOAD_LENGTH As Byte = 3	'ignore
	Private GET_STATE_PAYLOAD_LENGTH As Byte = 3

	#if B4A
	Private mBLEMgr As BleManager2
	#End If
	#if B4J
	Private mBLEMgr As BLEManager
	#End If
End Sub

' Initialize
' Parameters:
'	blemgr BLEManager - Instance of the BLE manager (B4J) or BLE manager2 (B4A)
#if B4A
Public Sub Initialize(blemgr As BleManager2)
#End If
#if B4J
Public Sub Initialize(blemgr As BLEManager)
#End If
	mBLEMgr = blemgr
End Sub

' Play Tone
' deviceid:	0x07
' command:	0x03
' payload:	4 bytes (freq UInt, duration UInt) 
' Example:  07 03 01 B8 01 F4, Play Tone 440 (HEX 01B8), Duration 500ms (HEX 01F4) 
' Parameters:
'	freq - Short Frequency 0-NNNNHz.
'	duration - Short Duration of the tone on ms.
Public Sub PlayTone(freq As Short, duration As Short)
	Dim deviceid As Byte 	= BLEConstants.DEV_BUZZER
	Dim commandid As Byte 	= BLEConstants.CMD_SET_VALUE
	Dim payload() As Byte 	= Convert.ByteConv.ShortsToBytes(Array As Short(freq, duration))
	Log($"[DevBuzzer.PlayTone] payload=${Convert.ByteConv.HexFromBytes(payload)}, length=${payload.length}"$)
	Dim commandlen As Byte = 2 + payload.length
	Dim command(commandlen) As Byte
	command(0) = deviceid
	command(1) = commandid
	For i = 0 To payload.Length - 1
		command(i+2) = payload(i)
	Next
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
End Sub

' Play  Alarm
' deviceid:	0x07
' command:	0x05
' payload:	2 bytes (mode 0x01-0x05, repeats 0xNN)
' Example: 07 05 01 02, Play alarm 1 with 2 repeats
Public Sub PlayAlarm(mode As Byte, repeats As Byte)
	Dim deviceid As Byte 	= BLEConstants.DEV_BUZZER
	Dim commandid As Byte 	= BLEConstants.CMD_CUSTOM_ACTION
	Dim command() As Byte = Array As Byte(deviceid, commandid, mode, repeats)
	Log($"[DevBuzzer.PlayAlarm] command=${command}"$)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
End Sub

' Parse
' Parses the BLE payload into type.
' Parameters:
'	data Byte Array
' Returns:
'	Type TDevBuzzer - Parsed data or null.
Public Sub Parse(data() As Byte) As TDevBuzzer
	Log($"[DevBuzzer.Parse][I] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As TDevBuzzer

	If data.Length < GET_STATE_PAYLOAD_LENGTH Then
		Log($"[DevBuzzer.Parse][E] Data too short, expect ${GET_STATE_PAYLOAD_LENGTH} bytes."$)
		Return result
	End If

	result.Initialize
	result.DeviceId		= data(0)
	result.CommandId	= data(1)
	result.State		= Convert.ByteToBool(data(2).As(Byte))
	Return result
End Sub
