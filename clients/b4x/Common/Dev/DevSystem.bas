B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 		DevSystem.bas
' Brief:		Getter / setter for the system device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### SYSTEM (0xFF)
'| Command    | Name          | Payload                        | Example              | Description      |
'| ---------- | ------------- | ------------------------------ | ---------------------| ---------------- |
'TODO
'| 0x02       | GET_STATE     | none                           | `FF 02`              | System state     |
'| → Response |               | 1 byte                         | `FF 02 01`           |                  |
'| 0x05       | CUSTOM_ACTION | 1 byte 		                  | `FF 05 00`           | Disable events   |
'| 0x05       | CUSTOM_ACTION | 1 byte 		                  | `FF 05 01`           | Enable events    |
' ================================================================
#End Region

Sub Class_Globals
	#if B4A
	Private mBLEMgr As BleManager2
	#End If
	#if B4J
	Private mBLEMgr As BLEManager
	#End If
	Private mEventsEnabled As Boolean
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
	mEventsEnabled = False
End Sub

' SetEventsEnabled
' Set the events enabled/disabled.
' BLE Payload:
' 	deviceid:	0xFF
' 	command:	0x05
' 	state:		0x01 (ON), 0x02 (OFF)	' <<< NOTE 0x01 & 0x02 and not 0x01, 0x00
' Parameters:
'	state - Boolean False=OFF, True=ON
Public Sub SetEventsEnabled(state As Boolean)
	Dim deviceid As Byte 		= BLEConstants.DEV_SYSTEM
	Dim commandid As Byte 		= BLEConstants.CMD_CUSTOM_ACTION
	Dim value As Byte 			= IIf(state, 0x01, 0x02)
	Dim command() As Byte 		= Array As Byte(deviceid, commandid, value)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	mEventsEnabled = state
End Sub

Public Sub GetEventsEnabled As Boolean
	Return mEventsEnabled
End Sub

