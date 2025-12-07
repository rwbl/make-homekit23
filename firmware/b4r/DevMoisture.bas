B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevMoisture.bas
' Project:      make-homekit32
' Brief:        Reads moisture sensor value (event or on-demand).
' Date:         2025-11-14
' Author:       Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx
' Description:	Moisture value retrieval via callback event or direct read.
'				Raw reading: on a microcontroller ADC, typically 0–1023 (Arduino) or 0–4095 (ESP32 ADC 12-bit).
' Hardware: 	https://wiki.keyestudio.com/Ks0203_keyestudio_Steam_Sensor
' ================================================================
#End Region

Private Sub Process_Globals
	Private Sensor As MoistureSensor
End Sub

' Initialize
' Initializes the moisture sensor pin and attaches a listener.
' Parameters:
'   pinnr - GPIO pin number (analog input)
Public Sub Initialize(pinnr As Byte)
	Sensor.Initialize(pinnr, "Moisture_Detected")
	Log("[DevMoisture.Initialize][I] OK, pin=", pinnr)
End Sub

#Region Device Control
' Moisture_Detected
' Callback event triggered by the moisture sensor.
' See PublishToMQTT or WriteToBLE on the payload send.
' Parameters:
'   value - Analog reading of soil moisture
Sub Moisture_Detected(value As Int)
	' Safety check
	If value < 0 Or value > Sensor.MAX_VALUE Then Return

	Log("[DevMoisture.Moisture_Detected] value=", value)

	' Cast value to string
	Dim s As String = value

	' Set LCD	
	DevLCD1602.Clear
	DevLCD1602.WriteAt(0, 0, "Moisture")
	DevLCD1602.WriteAt(0, 1, s)

	#If MQTT
	PublishToMQTT(value)
	#End If

	#If BLE
	WriteToBLE(value)
	#End If
End Sub

' Get
' Reads the current moisture value on-demand.
' Parameters:
'   storeindex - Index of the global store buffer
' Returns:
'   Integer - Analog moisture reading (0–1023)
Public Sub Get(storeindex As Byte) As Int
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Dim value As UInt = Sensor.Read
	Log("[DevMoisture.Get] storeindex=", storeindex, ", payload=", payload, ", value=", value)
	Return value
End Sub

' Moisture
' Reads the current moisture value on-demand.
' Returns:
'   Integer - Analog moisture reading (0–4096)
Public Sub Moisture As Int
	Dim value As UInt = Sensor.Read
	Log("[DevMoisture.Moisture] value=", value)
	Return value
End Sub

' Enabled
' Set the sensor event enabled/disabled.
' Parameters:
'   state Boolean - True (enabled), False (Disabled)
' Returns:
'   Int - TTHH
Public Sub Enabled(state As Boolean)
	Sensor.EventEnabled = state
	Log("[DevMoisture.Enabled] state=", state)
End Sub
#End Region

#If MQTT
#Region MQTT Control
' ProcessMQTT
' Reads the current temperature and humidity value as TTHH and published to MQTT.
' Parameters:
'   storeindex - Index in the global store buffer
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)

	' Read the sensor value
	Dim value As UInt = Sensor.Read
	PublishToMQTT(value)
	Log("[DevMoisture.ProcessMQTT] storeindex=", storeindex, ", payload=", payload, ", moisture=", value)
End Sub

' PublishToMQTT
' Publish the state.
' Parameters
'	value - Moisture value.
Private Sub PublishToMQTT(value As Int)
	Dim s As String = value
	Dim payload() As Byte = Convert.ReplaceString(MQTTTopics.PAYLOAD_MOISTURE_STATUS, "#S", s)
	MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_MOISTURE_STATUS), _
					   Array As String(Convert.ByteConv.StringFromBytes(payload)))
	Log("[DevMoisture.PublishToMQTT][I] json=", Convert.ByteConv.StringFromBytes(payload))
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' Get sensor data.
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x0B > Moisture Sensor
' 	Byte 1 Command:	0x04 > Get value
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevMoisture.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_GET_VALUE
			WriteToBLE(Sensor.Read)
		Case CommBLE.CMD_CUSTOM_ACTION
			' Get the value to set the state changed event to enabled/disabled
			Dim value As Byte = payload(2)
			If value == 0 Then
				Sensor.EventEnabled = False
			Else
				Sensor.EventEnabled = True
			End If
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	value - Int Moisture 0-4096
Public Sub WriteToBLE(value As UInt)
	Dim data() As Byte = Convert.UIntToBytes(value)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_MOISTURE, CommBLE.CMD_GET_VALUE, data(0), data(1))
	CommBLE.BLEServer_Write(payload)
	Log("[DevMoisture.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
