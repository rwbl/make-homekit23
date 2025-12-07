B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevWindow.bas
' Brief:	Setter/Getter for the window device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### Servo Window (0x06)
'| Command    | Name      | Payload        | Example    | Description           |
'| ---------- | --------- | -------------- | ---------- | --------------------- |
'| 0x01       | SET_STATE | 1 byte (0=Close, 1=Open)    | `06 01 01` | Set window Open         |
'| 0x02       | GET_STATE | none                        | `06 02`    | Request current state |
#End Region

Sub Class_Globals
	#if B4A
	Private mBLEMgr As BleManager2
	#End If
	#if B4J
	Private mBLEMgr As BLEManager
	#End If
	Private mDeviceState As Boolean = False
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
' Set window to open or closed.
' BLE Payload:
' 	deviceid:	0x06
' 	command:	0x01
' 	state:		0x00 (OFF), 0x01 (ON)
' Parameters:
'	state - Boolean False=Closed, True=Open
Public Sub Set(state As Boolean)
	Dim deviceid As Byte 	= BLEConstants.DEV_SERVO_WINDOW
	Dim commandid As Byte 	= BLEConstants.CMD_SET_STATE
	Dim value As Byte 		= IIf(state, 1, 0)
	Dim command() As Byte = Array As Byte(deviceid, commandid, value)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	mDeviceState = state
End Sub

' Open
' Open the window
Public Sub Open
	Set(True)
End Sub

' Close
' Close the window
Public Sub Close
	Set(False)
End Sub

' IsOpen
' Returns
'	true 
Public Sub IsOpen As Boolean
	Return (mDeviceState == True)
End Sub
