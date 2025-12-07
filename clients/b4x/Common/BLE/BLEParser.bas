B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=10.3
@EndOfDesignText@
#Region Class Header
' Class:        BLEParser
' Brief:        Parse BLE messages.
' Date:         2025-11-30
' Author:       Robert W.B. Linn (c) 2025 MIT
' Description:  Parse received BLE payload and store as a map.
#End Region

Private Sub Process_Globals
'
End Sub

#Region Parse
' Parse
' Parse the BLE message by selecting the device.
' Parameters:
'	data Byte Array - BLE payload
' Returns:
'	n/a
Public Sub Parse(data() As Byte)
	If data.Length < 2 Then
		Log($"[BLEParser.Parse] E: Message too short."$)
		Return
	End If
	Log($"[BLEParser.Parse] data=${Convert.HexFromBytes(data)}"$)

	Dim devid As Byte = data(0)

	Select devid
		Case BLEConstants.DEV_YELLOW_LED
			'Dim parseddata As TDevYellowLED = ParseYellowLED(data)
			'Dim MainPage As B4XMainPage = B4XPages.GetPage("Mainpage")
			'Log($"[BLEParser.Parse][E] ${parseddata}"$)
			'MainPage.TileButtonYellowLEDUpdate(parseddata.State)
			
		Case BLEConstants.DEV_DHT11
			ParseDHT11(data)

		Case BLEConstants.DEV_RFID
			'ParseRFID(data)

		Case BLEConstants.DEV_RGB_LED
			'ParseRGBLED(data)

		Case Else
			Log($"[BLEParser.Parse][E] Unknown device 0x${Bit.ToHexString(devid)}"$)
	End Select
End Sub
#End Region

#Region YellowLED
' ParseYellowLED
' Parse state
' Payload: Example 01 02 01
'	Length: 3 bytes
'	Byte 0:	DeviceID		01
'	Byte 1:	CommandID		02
'	Byte 2:	State			01	'ON
'	Example: 01 02 01 -> DeviceID=0x01, Command=0x02, Value=01 (ON)
' Parameters:
'	data Byte Array - BLE payload
' Returns:
'	Type TDevYellowLED
Public Sub ParseYellowLED(data() As Byte) As TDevYellowLED
	Dim DATA_LENGTH As Byte = 3
	Dim result As TDevYellowLED
	result.Initialize

	Log($"[BLEParser.ParseYellowLED] data=${Convert.ByteConv.HexFromBytes(data)}"$)

	' Init struct
	result.Initialize
	
	' Check data length
	If data.Length < DATA_LENGTH Then
		Log($"[BLEParser.ParseYellowLED][E] Data too short. Expect ${DATA_LENGTH} bytes."$)
		Return result
	End If

	result.DeviceId 	= data(0)
	result.CommandId	= data(1)
	result.State 		= IIf(data(2) == 1, True, False)
	Log($"[BLEParser.ParseYellowLED] ${result}"$)
	Return result
End Sub
#End Region

#Region DHT11
' ParseDHT
' Parse temperature & humidity from DHT11 sensor data.
' Payload: Example 0B04CC02
'	Length: 4 bytes
'	Byte 0:	DeviceID		0B
'	Byte 1:	CommandID		04
'	Byte 2:	Temperature		CC
'	Byte 3: Humidity		02
'	Example: 0B04CC02 -> DeviceID=0x0B, Command=0x04, Value=716
' Parameters:
'	data Byte Array - BLE payload
' Returns:
'	Map - key:value pairs t & h
Public Sub ParseDHT11(data() As Byte) As TDevDHT11
	Dim DATA_LENGTH As Byte = 4
	Dim result As TDevDHT11
	result.Initialize

	Log($"[BLEParser.ParseDHT11] data=${Convert.ByteConv.HexFromBytes(data)}"$)

	' Init struct
	result.Initialize
	
	' Check data length
	If data.Length < DATA_LENGTH Then
		Log($"[BLEParser.ParseDHT11][E] Data too short. Expect ${DATA_LENGTH} bytes."$)
		Return result
	End If

	result.DeviceId = data(0)
	result.CommandId = data(1)
	result.Temperature = data(2)
	result.Humidity= data(3)
	Log($"[BLEParser.ParseDHT11] ${result}"$)	
	Return result
End Sub
#End Region

