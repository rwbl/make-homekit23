B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	DevRGBLed.bas
' Project:     	make-homekit32
' Brief:       	Set/Get the state of the RGB LED.
' Date:        	2025-11-13
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx.b4x
' Description:  The RGB LED has 4 pixel.
' Hardware:		https://www.keyestudio.com/products/keyestudio-6812-rgb-module-for-arduino-diy-programming-projects-compatible-lego-blocks
' ================================================================
#End Region

Private Sub Process_Globals
	Private RGBLed As AdafruitNeoPixelEx
	Private RGB_LED_PIXEL_COUNT As UInt = 4
	Private RGB_LED_TYPE As UInt = RGBLed.NEO_GRB
End Sub

' Initialize
' Initialize the device.
' Parameters:
'   pinnr - GPIO pin number
Public Sub Initialize(pinnr As Byte)
	RGBLed.Initialize(RGB_LED_PIXEL_COUNT, pinnr, RGB_LED_TYPE)
	' Clear the pixels
	RGBLed.Clear
	' Show cleared pixels
	RGBLed.Show
	Log("[DevRGBLed.Initialize][I] OK, pin=", pinnr, ", pixels=", RGB_LED_PIXEL_COUNT, ", type=", RGB_LED_TYPE, ", pixels cleared")
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' Clear
' Clear all pixels.
Public Sub Clear
	RGBLed.Clear
	RGBLed.Show
	Log("[DevRGBLed.Clear] OK")
End Sub

' Get
' Get the color of a pixel as ULong.
' Parameters:
'   index - Pixel index 0-3
' Returns:
'	color - ULong
Public Sub Get(index As Byte) As ULong
	Return RGBLed.GetPixelColor(index)
End Sub

' GetAll
' Get all pixel colors as ULong array.
Public Sub GetAll As ULong()
	Dim pixels(4) As ULong
	For i = 0 To RGB_LED_PIXEL_COUNT - 1
		pixels(i) = Get(i)		
	Next
	Return pixels
End Sub

' GetRGB
' Get the color of a pixel as RGB 0-255.
' Parameters:
'   index - Pixel index 0-3
' Returns:
'	ByteArray(3) - 0=R, 1=G, 2=B
Public Sub GetRGB(index As Byte) As Byte()
	Return Convert.ColorToRGB(RGBLed.GetPixelColor(index))
End Sub

' GetRGBAll
' Get the color of all pixels as RGB 0-255.
' Returns:
'	ByteArray(16) - Per pixel: index(0-3),r(0-FF),g(0-FF),b(0-FF)
Public Sub GetRGBAll As Byte()
	Dim result(16) As Byte
	Dim index As Byte
	Dim pixel As Byte
	Dim rgb() As Byte
	
	For pixel = 0 To RGB_LED_PIXEL_COUNT - 1
		index = pixel * 4
		result(index) = pixel			'0,1,2,3
		rgb = GetRGB(pixel)
		result(index + 1) = rgb(0)		'1
		result(index + 2) = rgb(1)		'2
		result(index + 3) = rgb(2)		'3
		' Log("[DevRGBLed.GetRGBAll] pixel=", pixel, ", index=", index, ", result=", result(index))
	Next
	Return result
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Set the state of the pixels.
' MQTT Payload: {""i"":$i$,""r"":$r$,""g"":$g$,""b"":$b$, ""x"":$x$}
' storeindex=Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevRGBLed.ProcessMQTT] storeindex=", storeindex, ", payload=", payload)

	' If no index given, set 0 as default
	Dim index As Byte = IIf(MQTTClient.GetNumberFromKey(payload, "i") == -1, 0, MQTTClient.GetNumberFromKey(payload, "i"))

	' If not color given, set 0 as default
	Dim red As Byte = IIf(MQTTClient.GetNumberFromKey(payload, "r") == -1, 0, MQTTClient.GetNumberFromKey(payload, "r"))
	Dim green As Byte = IIf(MQTTClient.GetNumberFromKey(payload, "g") == -1, 0, MQTTClient.GetNumberFromKey(payload, "g"))
	Dim blue As Byte = IIf(MQTTClient.GetNumberFromKey(payload, "b") == -1, 0, MQTTClient.GetNumberFromKey(payload, "b"))

	' Clear as default (1)
	Dim clearpixels As Byte = IIf(MQTTClient.GetNumberFromKey(payload, "x") == -1, 1, MQTTClient.GetNumberFromKey(payload, "x"))

	' Clear the pixels
	If clearpixels == 1 Then Clear

	' Set pixel color
	RGBLed.SetPixelColor(index, red, green, blue)
	RGBLed.Show

	' Publish the state as always true
	MQTTClient.PublishDeviceState(MQTTTopics.TOPIC_RGB_LED_STATUS, True)

	Log("[DevRGBLed.ProcessMQTT] index=", index, ", red=",red, ", green=", green, ", blue=", blue, ", clear=", clearpixels)
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x02
' Sets the state of the pixels (Command 0x01).
'	Length: 6 Bytes
'	Byte 0 Device:		0x02
'	Byte 1 Command:		0x01 > Set
'	Byte 2 Index:		0x00 - 0x03
'	Byte 3 R:			0x00 - 0xFF
'	Byte 4 G:			0x00 - 0xFF
'	Byte 5 B:			0x00 - 0xFF
'	Byte 6 Clear:		0x00 - 0x01 
'	Example: Set pixel 1 to blue = 0201010000FF01
'
' Get the state of all pixels (Command=0x02).
'	Length: 2 Bytes
'	Byte 0 Device:		0x02 
'	Byte 1 Command:		0x02 > Get
'	Example: Get state = 0202
'	Returns Byte array 14: deviceid (1 byte), command (1 byte), rgball (12 bytes)
'	Result: With pixel 1 blue = 020200000000010000FF0200000003000000
'
' Sets the value of all pixels (Command 0x03).
'	Length: 5 Bytes
'	Byte 0 Device:		0x02
'	Byte 1 Command:		0x03 > Set value
'	Byte 2 R:			0x00 - 0xFF
'	Byte 3 G:			0x00 - 0xFF
'	Byte 4 B:			0x00 - 0xFF
'	Example: Set all pixels to blue = 02030000FF
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevRGBLed.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	' [DevRGBLed.ProcessBLE] storeindex=0, payload=0201010000FF01
	
	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_SET_STATE
			Dim index As Byte = payload(2)
			Dim red As Byte = payload(3)
			Dim green As Byte = payload(4)
			Dim blue As Byte = payload(5)
			Dim clearpixels As Byte = payload(6)
			' Set the state of a single pixel
			' Clear the pixels
			If clearpixels == 1 Then Clear
			' Set pixel color
			RGBLed.SetPixelColor(index, red, green, blue)
			RGBLed.Show
		Case CommBLE.CMD_GET_STATE
			' Get the state of all pixels
			Dim state(18) As Byte
			Dim rgb() As Byte = GetRGBAll
			' Populate the result array		
			state(0) = CommBLE.DEV_RGB_LED
			state(1) = command
			For i=0 To rgb.Length - 1
				state(i + 2) = rgb(i)
			Next
			CommBLE.BLEServer_Write(state)
		Case CommBLE.CMD_SET_VALUE
			Dim red As Byte = payload(2)
			Dim green As Byte = payload(3)
			Dim blue As Byte = payload(4)
			' Set all pixels color
			RGBLed.SetColor(red, green, blue)
			RGBLed.Show
	End Select
End Sub
#End Region
#End If
