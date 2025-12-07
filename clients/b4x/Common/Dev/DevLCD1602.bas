B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 		DevLCD1602.bas
' Brief:		Setter for the LCD1602 device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### LCD1602 (0x0C)
'| Command | Name          | Payload                | Example                         | Description     |
'| ------- | ------------- | ---------------------- | ------------------------------- | --------------- |
'| 0x03    | SET_VALUE     | ASCII text (<=32 bytes)| `0C 03 00 00 05 68 65 6C 6C 6F` | Display "hello" |
'| 0x05    | CUSTOM_ACTION | 1 byte (clear=0x00)    | `0C 05 01`                      | Clear screen    |
'
' Command SET VALUE 0x03:
'	Set text at row 0 (0x00) - 1 (0x01), col 0 (0x00) - 15 (0x0F), text length 0 (0x00) - 15 (0x0F)
'	0x00 - 0x01 - Row 0 - 1
'	0x00 - 0x0F - Col 0 - 15
'	0x00 - 0x0F - Text length
'	0xNN, 0x...	- Text
'	Example: hello (5 bytes) at row 0, col 0
'		Example payload (10 bytes): 0x0C 0x03 0x00 0x00 0x05 0x68 0x65 0x6C 0x6C 0x6F
'						  Byte Pos: 0    1    2    3    4    5    6    7    8    9
'									ID   CMD  Row  Col  Len  h    e    l    l    o
'	
' Command CUSTOM_ACTION 0x05: 
'	0x01 (1 byte) = Clear display
'		Example payload (3 bytes): 0x0C 0x05 0x01
'						 Byte Pos: 0    1    2   
'	0x02 0x00-0x01 (2 bytes) = Clear row (0x00) or on (0x01)
'		Example payload set clear botton row (row 1)(4 bytes): 0x0C 0x05 0x02 0x01
'						                             Byte Pos: 0    1    2    3    	
'	0x03 0x00-0x01 (2 bytes) = Set backlight off (0x00) or on (0x01)
'		Example payload set backlight off (4 bytes): 0x0C 0x05 0x03 0x00
'						                   Byte Pos: 0    1    2    3    	
'	TODO
'	0x04 0x00-0xFF (2 bytes) = Set brightness
'		Example payload set full brightness (4 bytes): 0x0C 0x05 0x04 0xFF
'						                     Byte Pos: 0    1    2    3    	
' ================================================================
#End Region

Sub Class_Globals
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


' Clear
' Clear the display
' BLE Payload:
' 	deviceid:	0x0C
' 	command:	0x05
' 	value:		0x01
Public Sub Clear
	Dim command() As Byte = Array As Byte(BLEConstants.DEV_LCD1602, BLEConstants.CMD_CUSTOM_ACTION, 0x01)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	Sleep(1)
End Sub

' SetText
' Set text at row, col.
' BLE Payload:
' 	deviceid:	0x0C
' 	command:	0x03
' 	value:		row, col, textlen, text as byte array, like 00 00 05 68 65 6C 6C 6F for row 0, col 0, text hello
' Parameters:
'	row Byte - 0-1
'	col Byte - 0-15
'	text String - Text max length 16 characters
Public Sub SetText(row As Byte, col As Byte, text As String)
	' Checks first
	If row > 1  Or col > 15 Or text.Length > 16 Then 
		Log($"[DevLCD1602.SetText] Invalid index row/col or text too long. Expect row 0-1, col 0-15, text length max 16"$)
		Return
	End If

	Dim deviceid As Byte 		= BLEConstants.DEV_LCD1602
	Dim commandid As Byte 		= BLEConstants.CMD_SET_VALUE
	Dim textbytes() As Byte		= text.GetBytes("UTF8")
	Dim textlen	 As Byte		= text.Length
	'							  deviceid + commandid + row + col + textlength + length text
	Dim commandlength As Byte	= 1 + 1 + 1 + 1 + 1 + textlen
	' Define the command array
	Dim command(commandlength) As Byte 

	' Populate the command array byte-by-byte (secure way)
	command(0)	= deviceid
	command(1)	= commandid
	command(2)	= row
	command(3)	= col
	command(4)	= textlen
	For i = 0 To textlen - 1
		command(5 + i) = textbytes(i)
	Next
	Log($"[DevLCD1602.SetText][i] command=${Convert.HexFromBytes(command)}"$)
	mBLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 command)
	Sleep(1)
End Sub
