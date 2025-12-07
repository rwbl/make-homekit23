B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevRGBLED.bas
' Brief:	Getter / setter for the rgb led (neopixel) device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### RGB LED (0x02)
'| Command    | Name      | Payload                                | Example                                | Description                                                         |
'| ---------- | --------- | ------------------------------- ------ | -------------------------------------- | ------------------------------------------------------------------- |
'| 0x01       | SET_COLOR | 5 bytes (I,R,G,B,C)                    | `02 01 01 00 00 FF 01`                 | Set color Blue (FF) for pixel index 1 (01) and clear all pixels (01)|
'| 0x02       | GET_COLOR | none                                   | `02 02`                                | Request current color for all 4 pixels                              |
'| -> Response|           | 14 bytes (I,C,I,R,G,B,I,R,G,B,I,R,G,B) | `020200000000010000FF0200000003000000` | Reports current RGB color for all pixels. Pixel Blue all other off  |
'| 0x03       | SET_VALUE | 3 byte (R,G,B)      | `02 03 00 00 FF` | Set color blue for all pixels          |                                                                     |
'| -> Response|           | 14 bytes (I,C,I,R,G,B,I,R,G,B,I,R,G,B) | `020200000000010000FF0200000003000000` | Reports current RGB color for all pixels. Pixel Blue all other off  |
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
	Private mR As Byte = 0
	Private mG As Byte = 0
	Private mB As Byte = 0
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

' SetColor
' Set the color for all pixels
' deviceid:	0x02
' command:	0x03
' state:	0x00-0xFF
' Parameters:
'	r - Byte 00-FF
'	g - Byte 00-FF
'	b - Byte 00-FF
Public Sub SetColor(r As Byte, g As Byte, b As Byte)
	Dim deviceid As Byte 	= BLEConstants.DEV_RGB_LED
	Dim commandid As Byte 	= BLEConstants.CMD_SET_VALUE
	Dim command() As Byte	= Array As Byte(deviceid, commandid, r, g, b)

	' Save the color setting to the class globals
	mR = r
	mG = g
	mB = b

	' Set the state
	If mR==0 And mG==0 And mB==0 Then
		mState = False
	Else
		mState = True
	End If

	Log($"[DevRGBLed.SetColor] state=${mState}, rgb=${mR},${mG},${mB}"$)

	' Write the BLE command
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
End Sub

' GetColor
' Returns the color as map.
Public Sub GetColor As Map
	Return CreateMap("r":mR, "g":mG, "b":mB)
End Sub

' On
' Turn on with latest color state
Public Sub SetOn
	Dim deviceid As Byte 	= BLEConstants.DEV_RGB_LED
	Dim commandid As Byte 	= BLEConstants.CMD_SET_VALUE
	Dim command() As Byte	= Array As Byte(deviceid, commandid, mR, mG, mB)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	mState = True
End Sub

' Off
' Turn off by setting rgb to 0.
Public Sub SetOff
	Dim deviceid As Byte 	= BLEConstants.DEV_RGB_LED
	Dim commandid As Byte 	= BLEConstants.CMD_SET_VALUE
	Dim command() As Byte	= Array As Byte(deviceid, commandid, 0x0, 0x0, 0x0)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	mState = False
End Sub

' Set
' Set the state to on or off
Public Sub SetOnOff(state As Boolean)
	If state Then
		SetOn
	Else
		SetOff
	End If
End Sub

' IsOn
' Returns True if ON else false.
Public Sub IsOn As Boolean
	Return (mState == True)
End Sub

' SetWarning
' Set the color to light yellow to indicate a warning.
Public Sub SetWarning
	SetColor(255, 255, 224)
End Sub
