B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevPIRSensor.bas
' Brief:	Getter / setter for the PIR sensor device (Motion Detector).
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### PIR Motion Sensor (0x0D)
'| Command    | Name      | Payload                       | Example    | Description             |
'| ---------- | --------- | ----------------------------- | ---------- | ----------------------- |
'| 0x01       | SET_STATE | 1 byte (0=Disable,1=Enable)   | `0D 01 01` | Enable motion detection |
'| 0x02       | GET_STATE | none                          | `0D 02`    | Request motion state    |
'| -> Response|           | 1 byte (0=No motion,1=Motion) | `0D 02 01` | Motion detected         |
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
' 	deviceid:	0x0D
' 	command:	0x01
' 	value:		0x00 (Disabled), 0x01 (Enabled)
' Parameters:
'	enabled - Boolean False=Disabled, True=Enabled
Public Sub SetEnabled(state As Boolean)
	Dim deviceid As Byte 	= BLEConstants.DEV_PIR_SENSOR
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

' Parses a 3-byte PIR sensor BLE payload.
' Example motion detected: 0D0201 -> DeviceID=0x0D, Command=0x02, Value=1
Public Sub Parse(data() As Byte) As Map
	Log($"[DevPIRSensor.Parse] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As Map

	result.Initialize
	If data.Length < 3 Then
		Log("[DevPIRSensor.Parse][E] Data too short, expect 3 bytes.")
		Return result
	End If
	result.Put("deviceid", data(0))
	result.Put("command", data(1))
	result.Put("value", data(2))
	Return result
End Sub
