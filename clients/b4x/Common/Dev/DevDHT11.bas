B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 		DevDHT11.bas
' Brief:		Getter / setter / parser for the DHT11 device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### DHT11 Sensor (0x09)
'| Command    | Name          | Payload                                            | Example      | Description                 |
'| ---------- | ------------- | -------------------------------------------------- | ------------ | --------------------------- |
'| 0x04       | GET_VALUE     | none                                               | `09 04`      | Request temp+humidity       |
'| → Response |               | 2 bytes (Temp, Humidity)                           | `09 04 1E 32`| 30°C / 50% RH               |
'| 0x05       | CUSTOM_ACTION | 1 byte (state changed event=0x00 (on), 0x01 (off)) | `09 05 00`   | Disable state changed event |
' ================================================================
#End Region

Sub Class_Globals
	Type TDevDHT11 ( DeviceId As Byte, CommandId As Byte, Temperature As Int, Humidity As Int )
	Private GET_VALUE_PAYLOAD_LENGTH As Byte = 4
	#if B4A
	Private mBLEMgr As BleManager2	'ignore
	#End If
	#if B4J
	Private mBLEMgr As BLEManager	'ignore
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

' Parse
' Parses the BLE payload into type.
' Parameters:
'	data Byte Array
' Returns:
'	Type TDevDHT11 - Parsed data or null.
Public Sub Parse(data() As Byte) As TDevDHT11
	Log($"[DevDHT11.Parse][I] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As TDevDHT11

	If data.Length < GET_VALUE_PAYLOAD_LENGTH Then
		Log($"[DevDHT11.Parse][E] Data too short, expect ${GET_VALUE_PAYLOAD_LENGTH} bytes."$)
		Return result
	End If

	result.Initialize
	result.DeviceId		= data(0)
	result.CommandId	= data(1)
	Dim t As Int 		= data(2)
	result.Temperature 	= t
	Dim h As Int 		= data(3)
	result.Humidity 	= h
	Log($"[DevDHT11.Parse] t=${t}, h=${h}"$)

	Return result
End Sub
