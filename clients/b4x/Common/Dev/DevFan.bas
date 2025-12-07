B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 		DevFan.bas
' Brief:		Setter/Getter for the fan device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### Fan (0x08)
'| Command | Name      | Payload             | Example    | Description             |
'| ------- | --------- | ------------------- | ---------- | ----------------------- |
'| 0x01    | SET_STATE | 1 byte (0=Off,1=On) | `08 01 01` | Turn fan on             |
'| 0x02    | GET_STATE | none                | `08 02`    | Request state on Or off |
' ================================================================
#End Region

Sub Class_Globals
	#if B4A
	Private mBLEMgr As BleManager2
	#End If
	#if B4J
	Private mBLEMgr As BLEManager
	#End If
	Private mState As Boolean = False
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

' Set
' Set fan on or off
' BLE Payload:
' 	deviceid:	0x08
' 	command:	0x01
' 	state:		0x00 (OFF), 0x01 (ON)
' Parameters:
'	state - Boolean False=Off, True=On
Public Sub Set(state As Boolean)
	Dim deviceid As Byte 	= BLEConstants.DEV_FAN
	Dim commandid As Byte 	= BLEConstants.CMD_SET_STATE
	Dim value As Byte 		= IIf(state, 1, 0)
	Dim command() As Byte = Array As Byte(deviceid, commandid, value)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	mState = state
End Sub

' On
' Fan on
Public Sub On
	Set(True)
End Sub

' Off
' Fan Off
Public Sub Close
	Set(False)
End Sub

' IsOn
' Returns
'	true 
Public Sub IsOn As Boolean
	Return (mState == True)
End Sub
