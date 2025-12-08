B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevLCD1602.bas
' Project:      make-homekit32
' Brief:        Display text and messages on 16×2 LCD.
' Date:         2025-12-08
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rLiquidCrystal_I2C, rGlobalStoreEx
' Description:	Handles text display and message routing via MQTT.
' Hardware: 	https://wiki.keyestudio.com/Ks0061_keyestudio_1602_I2C_Module
' ================================================================
#End Region

Private Sub Process_Globals
	Public Lcd As LiquidCrystalI2CEX				' Lib LiquidCrystalI2CEX
	Private LCD_COLS As Byte		= 16
	Private LCD_ROWS As Byte 		= 2
	Public LCD_ROW_TOP As Byte 		= 0
	Public LCD_ROW_BOTTOM As Byte	= 1
	
	' LCD Custom Characters
	' Definitions
	Private CUSTOM_CHAR_DEF_WIFI() As Byte 	= Array As Byte (0x0E,0x11,0x0E,0x11,0x0E,0x0E,0x04,0x00)
	Private CUSTOM_CHAR_DEF_MQTT() As Byte 	= Array As Byte (0x0E,0x11,0x11,0x1F,0x08,0x08,0x00,0x00)
	Private CUSTOM_CHAR_DEF_BLE() As Byte	= Array As Byte (0x08,0x0C,0x06,0x0C,0x06,0x0C,0x08,0x00)
	' IDs
	Public CUSTOM_CHAR_WIFI As Byte	= 0
	Public CUSTOM_CHAR_MQTT As Byte	= 1
	Public CUSTOM_CHAR_BLE As Byte 	= 2
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   address - I2C address
Public Sub Initialize(address As Byte)
	Lcd.Initialize(address, LCD_COLS, LCD_ROWS)
	' Custom Chracters
	Lcd.CreateChar(CUSTOM_CHAR_WIFI, CUSTOM_CHAR_DEF_WIFI)
	Lcd.CreateChar(CUSTOM_CHAR_MQTT, CUSTOM_CHAR_DEF_MQTT)
	Lcd.CreateChar(CUSTOM_CHAR_BLE, CUSTOM_CHAR_DEF_BLE)
	' Backlight on
	Lcd.Backlight = True
	' Clear display
	Lcd.Clear
	Log("[DevLCD1602.Initialize][I] OK, address=", Convert.OneByteToHex(address), ", cols=", LCD_COLS, ", rows=", LCD_ROWS)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' Clear
' Clear the lc top and bottom rows.
Public Sub Clear
	Lcd.Clear
End Sub

' ClearTopRow
' Clear the top row
Public Sub ClearTopRow
	Lcd.ClearRow(LCD_ROW_TOP)
End Sub

' ClearBottomRow
' Clear the bottom row.
Public Sub ClearBottomRow
	Lcd.ClearRow(LCD_ROW_BOTTOM)
End Sub

' WriteAt
' Write text at position
' Parameters:
'   col - Column 0-15.
'	row - Row 0-1.
'	message - String or Number to display.
Public Sub WriteAt(col As Byte, row As Byte, message As String)
	Lcd.WriteAt(col, row, message)
End Sub

' WriteCharAt
' Write Custom Character at position
' Parameters:
'   col - Column 0-15.
'	row - Row 0-1.
'	id - Custom character id 0-7
Public Sub WriteCharAt(col As Byte, row As Byte, id As Byte)
	if id < 0 or id > 7 then return
	Lcd.WriteCharAt(col, row, id)
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
#End Region
' ProcessMQTT
' Sets the display based on MQTT action payload.
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevLCD1602.ProcessMQTT] storeindex=", storeindex, ", payload=", payload)

	' Get the keys from {"c":0-15,"r":0-1,"t":"string","x":0-1}
	' If no col or row given, set 0 as default
	Dim col As Int = IIf(MQTTClient.GetNumberFromKey(payload, "c") == -1, 0, MQTTClient.GetNumberFromKey(payload, "c"))
	Dim row As Int = IIf(MQTTClient.GetNumberFromKey(payload, "r") == -1, 0, MQTTClient.GetNumberFromKey(payload, "r"))
	Dim text() As Byte = MQTTClient.GetTextFromKey(payload, "t")
	Dim clr As Int = MQTTClient.GetNumberFromKey(payload, "x")
	Log("[DevLCD1602.ProcessMQTT] col=",col, ", row=", row, ", text=", text, ", clear=",clr)

	' Clear the display
	If clr == 1 Then Lcd.Clear
		
	' Display text
	If text.Length > 0 Then
		Lcd.WriteAt(col, row, text)
	End If

	' Publish the state as always true
	MQTTClient.PublishDeviceState(MQTTTopics.TOPIC_LCD_STATUS, True)
End Sub

'' PublishToMQTT
'' Publish data
'' Parameters
'Private Sub PublishToMQTT()
'End Sub
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' Sets the state based on BLE action payload.
' DeviceID: 0x0C
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
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim MIN_PAYLOAD_LEN As Byte = 3
	Dim MIN_PAYLOAD_LEN_SET_VALUE As Byte = 6	' At least 1 character = ID CMD Row Col Len Char
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevLCD1602.ProcessBLE][I] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	
	' Check payload length - must be 3 min, like for clear display: 0x0C 0x05 0x01
	If payload.Length < MIN_PAYLOAD_LEN Then
		Log("[DevLCD1602.ProcessBLE][E] Invalid payload length, expect min ", MIN_PAYLOAD_LEN, " bytes, payload=", Convert.BytesToHex(payload))
		Return
	End If
	
	' Get command SET_VALUE or CUSTOM_COMMAND
	Dim cmd As Byte = payload(1)
	
	' Select command
	If cmd == CommBLE.CMD_SET_VALUE Then
		' Write Text
		' Check payload length
		If payload.Length < MIN_PAYLOAD_LEN_SET_VALUE Then
			Log("[DevLCD1602.ProcessBLE][E] Command SET VALUE Invalid payload length, expect min ", MIN_PAYLOAD_LEN_SET_VALUE, " bytes, payload=", Convert.BytesToHex(payload))
			Return
		End If
		' Get row 0x00 - 0x01
		Dim row As Byte = payload(2)
		If row > 0x01 Then
			Log("[DevLCD1602.ProcessBLE][E] Command SET VALUE Invalid row ", row, ", expect 0x00-0x01")
			Return
		End If
		' Get col 0x00 - 0x0F
		Dim col As Byte = payload(3)
		If col > 0x0F Then
			Log("[DevLCD1602.ProcessBLE][E] Command SET VALUE Invalid col ", col, ", expect 0x00-0x0F")
			Return
		End If
		' Get len 0x01 - 0x0F = expect at least 1 char
		Dim len As Byte = payload(4)
		If len == 0x00 Or len > 0x0F Then
			Log("[DevLCD1602.ProcessBLE][E] Command SET VALUE Invalid text length ", len, ", expect 0x01-0x0F")
			Return
		End If
		' Finally lets write the characters starting at payload index 5
		For i = 5 To payload.Length - 1
			Lcd.WriteCharAt(i - 5, row, payload(i))
		Next
	End If

	If cmd == CommBLE.CMD_CUSTOM_ACTION Then
		' Custom action like clear, clear row, set backlight
		Dim action As Byte = payload(2)
		Select action
			Case 0x01
				Lcd.Clear
				Log("[DevLCD1602.ProcessBLE][I] Command CUSTOM ACTION clear")
			Case 0x02
				Dim row As Byte = payload(3)
				If row == 0x00 Or row == 0x01 Then
					Lcd.ClearRow(row)
					Log("[DevLCD1602.ProcessBLE][I] Command CUSTOM ACTION clearrow")
				End If
			Case 0x03
				Dim state As Byte = payload(3)
				If state == 0 Then
					Lcd.Backlight = False
				Else
					Lcd.Backlight = True
				End If
				Log("[DevLCD1602.ProcessBLE][I] Command CUSTOM ACTION backlight")
		End Select
	End If
End Sub
#End Region
#End If
