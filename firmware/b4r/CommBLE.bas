B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         CommBLE.bas
' Project:      make-homekit32
' Brief:        Handle BLE communication. BLE sevice name HomeKit32.
'				UART service & characteristics.
' Date:         2025-12-06
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rWiFiManager, rBLEServer, rGlobalStoreEx
' Description:	Communication layer for message routing via MQTT.
' ================================================================
#End Region

Private Sub Process_Globals
	
	' Devices
	Public DEV_YELLOW_LED As Byte 		= 0x01
	Public DEV_RGB_LED As Byte 			= 0x02
	Public DEV_BUTTON_LEFT As Byte 		= 0x03
	Public DEV_BUTTON_RIGHT As Byte		= 0x04
	Public DEV_SERVO_DOOR As Byte		= 0x05
	Public DEV_SERVO_WINDOW As Byte		= 0x06
	Public DEV_BUZZER As Byte			= 0x07
	Public DEV_FAN As Byte				= 0x08
	Public DEV_DHT11 As Byte			= 0x09
	Public DEV_GAS_SENSOR As Byte		= 0x0A
	Public DEV_MOISTURE As Byte			= 0x0B
	Public DEV_LCD1602 As Byte			= 0x0C
	Public DEV_PIR_SENSOR As Byte		= 0x0D
	Public DEV_RFID As Byte				= 0x0E
	Public DEV_SYSTEM As Byte			= 0xFF
	
	' Commands
	Public CMD_SET_STATE As Byte 		= 0x01
	Public CMD_GET_STATE As Byte 		= 0x02
	Public CMD_SET_COLOR As Byte 		= 0x01
	Public CMD_GET_COLOR As Byte 		= 0x02
	Public CMD_SET_VALUE As Byte 		= 0x03
	Public CMD_GET_VALUE As Byte 		= 0x04
	Public CMD_CUSTOM_ACTION As Byte	= 0x05
	
	' BLE ESP32 Plus BLE Peripheral + GATT Server
	Private BLE_SERVER_NAME As String 	= "HomeKit32"	'ignore
	Private BLEServer As BLEServer						'ignore
	Private MTUSize As UInt = BLEServer.MTU_SIZE_MIN	'ignore
End Sub

#if BLE
' Initialize
' Initializes BLE
Public Sub Initialize
	Log("[CommBLE.Initialize]")
	BLEServer.Initialize(BLE_SERVER_NAME, "BLEServer_NewData", "BLEServer_Error", MTUSize)
	Log("[CommBLE.Initialize] Done, mtusize=", MTUSize)
End Sub

' Handle new data received from connected client.
' Data format: [DeviceID][Command][Payload...]
' Parameters:
' 	buffer - Byte array holding the data send by the client
Private Sub BLEServer_NewData(buffer() As Byte)
	Log("[CommBLE.BLEServer_NewData] buffer HEX=", Convert.BytesToHex(buffer))

	' Check buffer lenght. Expect at least 2.
	If buffer.Length < 2 Then Return

	' Get the device id	
	Dim idx As Byte = buffer(0)
		
	' Store the payload in the global store buffer
	GlobalStoreHandler.Put(buffer)
	
	' Dispatch to handler (slightly delayed to avoid blocking)
	CallSubPlus("BLEDispatch", 50, idx)
End Sub

 'Handle BLE server error.
' Log the error to the B4R IDE, but could also use an LED
' Parameters:
'	code - BLE server error code
Private Sub BLEServer_Error(code As Byte)
	Log("[CommBLE.BLEServer_Error] code=",code)
	Select code
		Case BLEServer.WARNING_INVALID_MTU
			Log("[CommBLE.BLEServer_Error][WARNING] Initialize MTU out of range 23-512, default is set (23).")
		Case BLEServer.ERROR_INVALID_CHARACTERISTIC
			Log("[CommBLE.BLEServer_Error][ERROR] Write failed: No valid characteristic.")
		Case BLEServer.ERROR_EMPTY_DATA
			Log("[CommBLE.BLEServer_Error][ERROR] Write failed: No data.")
	End Select
End Sub

' Write data to the connected client.
' Parameters:
' 	data - Byte array containing data fo the connected client
Public Sub BLEServer_Write(data() As Byte)
	If data == Null Then
		Log("[ERROR][CommBLE.BLEServer_Write] No data.")
		Return
	End If
	Log("[CommBLE.BLEServer_Write] data=", Convert.ByteConv.HexFromBytes(data))
	BLEServer.Write(data)
End Sub

' Dispatch BLE message to the relevant device handler.
' [DeviceID][CommandID][Data...]
' Notes:
'	Buttons not used - see MenuHandler
' Parameters:
'	deviceid - Byte Device ID as defined in the constants.
Private Sub BLEDispatch(deviceid As Byte)
	Log("[CommBLE.BLEDispatch] deviceid=",deviceid)
	Select deviceid
		Case 0
			' Reserved
		Case DEV_YELLOW_LED
			DevYellowLed.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_RGB_LED
			DevRGBLed.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_BUTTON_LEFT
			' DevButtons.BtnLeftAction(GlobalStoreHandler.Index)
		Case DEV_BUTTON_RIGHT
			' DevButtons.BtnRightAction(GlobalStoreHandler.Index)
		Case DEV_SERVO_DOOR
			DevServoDoor.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_SERVO_WINDOW
			DevServoWindow.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_BUZZER
			DevBuzzer.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_FAN
			DevFan.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_DHT11
			DevDHT11.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_GAS_SENSOR
			DevGasSensor.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_MOISTURE
			DevMoisture.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_LCD1602
			DevLCD1602.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_PIR_SENSOR
			DevPIRSensor.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_RFID
			DevRFID.ProcessBLE(GlobalStoreHandler.Index)
		Case DEV_SYSTEM
			DevSystem.ProcessBLE(GlobalStoreHandler.Index)
		Case Else
			'
	End Select
End Sub
#End Region

#End If
