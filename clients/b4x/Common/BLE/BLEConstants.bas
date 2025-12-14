B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=10.3
@EndOfDesignText@
'Static code module
Sub Process_Globals
	
#Region Device Data Types
' See device modules liek DevDHT11
'	Type TDevRFID ( DeviceId As Byte, CommandId As Byte, UID() As Byte, Block As Int, Data() As Byte )

	' Future:
	' Type TDevMotion ( DeviceId As Byte, Active As Boolean )
	' Type TDevButton ( DeviceId As Byte, Pressed As Boolean )
	' Type TDevRelay ( DeviceId As Byte, State As Boolean )

#End Region

#Region BLE
	' BLE device (ESP32 Plus)
	Public BLE_DEVICE_NAME As String 	= "HomeKit32"								' Case sensitive

	' BLE Service & Characteristics
	Public SERVICE_UUID As String 		= "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"	' UART
	Public CHAR_UUID_TX As String 		= "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"	' Transmit
	Public CHAR_UUID_RX As String 		= "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"	' Receive Flags read,notify,write
#End Region

#Region Device IDs
	' Devices (as defined in B4R firmware)
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
	Public DEV_SYSTEM As Int			= 0xFF
#End Region

#Region Command IDs	
	' Commands (as defined in B4R firmware)
	Public CMD_SET_STATE As Byte 		= 0x01
	Public CMD_GET_STATE As Byte 		= 0x02
	Public CMD_SET_COLOR As Byte 		= 0x01
	Public CMD_GET_COLOR As Byte 		= 0x02
	Public CMD_SET_VALUE As Byte 		= 0x03
	Public CMD_GET_VALUE As Byte 		= 0x04
	Public CMD_CUSTOM_ACTION As Byte	= 0x05
#End Region

#Region Device States
	Public STATE_OFF As Byte 			= 0x00
	Public STATE_ON As Byte 			= 0x01
#End Region
	
#Region Device Actions
	Public ACTION_CLOSE As Byte 		= 0x00
	Public ACTION_OPEN As Byte 			= 0x01
#End Region
End Sub
