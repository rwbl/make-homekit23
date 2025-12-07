B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 		DevYellowLed.bas
' Brief:		Getter / setter / parser for the yellow led device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### YellowLED (0x01)
'| Command    | Name      | Payload              | Example    | Description           |
'| ---------- | --------- | -------------------- | ---------- | --------------------- |
'| 0x01       | SET_STATE | 1 byte (0=Off, 1=On) | `01 01 01` | Turns LED On          |
'| 0x02       | GET_STATE | none                 | `01 02`    | Requests LED state    |
'| → Response |           | 1 byte (0 Or 1)      | `01 02 01` | Reports current state |
' ================================================================
#End Region

Sub Class_Globals
	Type TDevYellowLED ( DeviceId As Byte, CommandId As Byte, State As Boolean )

	Private SET_STATE_PAYLOAD_LENGTH As Byte = 3	'ignore
	Private GET_STATE_PAYLOAD_LENGTH As Byte = 3

	' Locals
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
' Set the state of the YellowLED to on or off.
' BLE Payload:
' 	deviceid:	0x01
' 	command:	0x01
' 	state:		0x00 (OFF), 0x01 (ON)
' Parameters:
'	state - Boolean False=OFF, True=ON
Public Sub Set(State As Boolean)
	Dim deviceid As Byte 		= BLEConstants.DEV_YELLOW_LED
	Dim commandid As Byte 		= BLEConstants.CMD_SET_STATE
	Dim value As Byte 			= IIf(State, BLEConstants.STATE_ON, BLEConstants.STATE_OFF)
	Dim command() As Byte 		= Array As Byte(deviceid, commandid, value)
	
	mState 						= State
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
End Sub

' Get
' Get the state of the YellowLED True (on) or False (Off).
Public Sub Get As Boolean
	Return mState
End Sub

' On
' Set LED state ON.
Public Sub On
	Set(True)
End Sub

' Off
' Set LED state OFF.
Public Sub Off
	Set(False)
End Sub

' IsOn
' Returns:
'	Boolean - True LED is ON else False
Public Sub IsOn As Boolean
	Return (mState == True)
End Sub

' Parse
' Parses the BLE payload into type.
' Parameters:
'	data Byte Array
' Returns:
'	Type TYellowLED - Parsed data or null.
Public Sub Parse(data() As Byte) As TDevYellowLED
	Log($"[DevYellowLed.Parse][I] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As TDevYellowLED

	If data.Length < GET_STATE_PAYLOAD_LENGTH Then
		Log($"[DevYellowLed.Parse][E] Data too short, expect ${GET_STATE_PAYLOAD_LENGTH} bytes."$)
		Return result
	End If

	result.Initialize
	result.DeviceId		= data(0)
	result.CommandId	= data(1)
	result.State		= Convert.ByteToBool(data(2).As(Byte))
	Return result
End Sub
