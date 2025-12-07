B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevMoisture.bas
' Brief:	Getter / setter for the moisture device (Steam Sensor).
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### Moisture Sensor (0x0B)
'| Command    | Name      | Payload | Example      | Description            |
'| ---------- | --------- | ------- | ------------ | ---------------------- |
'| 0x04       | GET_VALUE | none    | `0B 04`      | Request moisture level |
'| -> Response|           | 2 bytes | `0B 04 00FA` | Reports 250            |
'| 0x05       | CUSTOM_ACTION | 1 byte (state changed event=0x00 (on), 0x01 (off)) | `0B 05 00`   | Disable state changed event |
' ================================================================
#End Region

Sub Class_Globals
	#if B4A
	Private mBLEMgr As BleManager2
	#End If
	#if B4J
	Private mBLEMgr As BLEManager
	#End If
	Private mEnabled As Boolean = False
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

' Enabled
' Set enabled/disabled
' BLE Payload:
' 	deviceid:	0x0B
' 	command:	0x01
' 	value:		0x00 (Disabled), 0x01 (Enabled)
' Parameters:
'	enabled - Boolean False=Disabled, True=Enabled
Public Sub SetEnabled(state As Boolean)
	Dim deviceid As Byte 	= BLEConstants.DEV_MOISTURE
	Dim commandid As Byte 	= BLEConstants.CMD_SET_STATE
	Dim value As Byte		= IIf(state, 1, 0)
	mEnabled = state
	Dim command() As Byte = Array As Byte(deviceid, commandid, value)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
End Sub

Public Sub GetEnabled As Boolean
	Return mEnabled
End Sub

' Parses a 4-byte moisture sensor BLE payload
' Example: 0B04CC02 -> DeviceID=0x0B, Command=0x04, Value=716
Public Sub Parse(data() As Byte) As Map
	Log($"[DevMoisture.Parse] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As Map

	result.Initialize
	If data.Length < 4 Then
		Log("[DevMoisture.Parse][E] Data too short, expect 4 bytes.")
		Return result
	End If

	result.Put("deviceid", data(0))
	result.Put("command", data(1))

	' Data: little-endian 2-byte integer
	Dim value As Int = Convert.BytesToInt(Array As Byte(data(2), data(3) ))
	Log($"[DevMoisture.Parse] value=${value}"$)

	result.Put("value", value)

	Return result
End Sub
