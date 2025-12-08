B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevDHT11.bas
' Project:      make-homekit32
' Brief:        Reads sensor temperature & humidity values (event or on-demand).
' Date:         2025-11-13
' Author:       Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx, rDHTESP
' Description:	Temperature & humidity values retrieval via callback event or direct read.
' Hardware:		https://https://wiki.keyestudio.com/Ks0034_keyestudio_DHT11_Temperature_and_Humidity_Sensor
' ================================================================
#End Region

Private Sub Process_Globals
	Private Sensor As ESP32DHT
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   pinnr - GPIO pin number (Analog)
Public Sub Initialize(pinnr As Byte)
	Sensor.Initialize(Sensor.DHT11, pinnr, "Sensor_StateChanged")
	Log("[DevDHT11.Initialize][I] OK, pin=", pinnr)
End Sub

#Region Device Control
' State_Changed
' Sensor listener event for state changes.
' Publishes MQTT status as JSON payload:
'	{""t"":#T,""h"":#H}
Private Sub Sensor_StateChanged(temp As Float, hum As Float)
	' Set LCD
	DevLCD1602.Clear
	DevLCD1602.WriteAt(0, 0, "DHT11")
	DevLCD1602.WriteAt(0, 1, "T:")
	DevLCD1602.WriteAt(3, 1, NumberFormat(temp,0,0))
	DevLCD1602.WriteAt(8, 1, "H:")
	DevLCD1602.WriteAt(11, 1, NumberFormat(hum,0,0))
	
	#If MQTT
	PublishToMQTT(temp, hum)
	#End If

	#If BLE
	WriteToBLE(temp, hum)
	#End If
End Sub

' Get
' Reads the current temperature and humidity value as TTHH.
' Parameters:
'   storeindex - Index in the global store buffer
' Returns:
'   Int - TTHH
Public Sub Get(storeindex As Byte) As Int
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevDHT11.Get] storeindex=", storeindex, ", payload=", payload)

	' Read the sensor value
	Dim t As Float = Sensor.Temperature
	Dim h As Float = Sensor.Humidity
	Dim value As Int = Round(t) * 100 + Round(h)
	Log("[DevDHT11.Get] value=", value)
	Return value
End Sub

' Read the sensor temperature value
' Returns:
'   Int - T
Public Sub Temperature As Int
	Dim value As Int = Sensor.Temperature
	Log("[DevDHT11.Temperature] value=", value)
	Return value
End Sub

' Read the sensor humidity value
' Returns:
'   Int - H
Public Sub Humidity As Int
	Dim value As Int = Sensor.Humidity
	Log("[DevDHT11.Humidity] value=", value)
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
	Log("[DevDHT11.Enabled] state=", state)
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Reads the current temperature and humidity value as TTHH and published to MQTT.
' Parameters:
'   storeindex - Index in the global store buffer
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)

	' Read the sensor value
	Dim t As Float = Sensor.Temperature
	Dim h As Float = Sensor.Humidity
	PublishToMQTT(t, h)
	Log("[DevDHT11.ProcessMQTT] storeindex=", storeindex, ", payload=", payload, ", t=", t, ", h=,", h)
End Sub

' PublishToMQTT
' Write, publish, to MQTT the state.
' Parameters:
'	temp - Temperature
'	hum - Humidity
Private Sub PublishToMQTT(temp As Float, hum As Float)
	Dim t As String = temp
	Dim h As String = hum
	Dim payload() As Byte = Convert.ReplaceString(MQTTTopics.PAYLOAD_DHT11_STATUS, "#T", t)
	payload = Convert.ReplaceString(payload, "#H", h)
	
	' Publish
	MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_DHT11_STATUS), _
					   Array As String(Convert.ByteConv.StringFromBytes(payload)))
	Log("[DevDHT11.PublishToMQTT][I] json=", payload)
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x09
' Get the sensor data temperature and humidity.
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x09
' 	Byte 1 Command:	0x04 > Get value
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevDHT11.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	' Get the command and the value
	Dim command As Byte = payload(1)

	' Select command set or get
	Select command
		Case CommBLE.CMD_GET_VALUE
			' Read the sensor value and write to BLE client
			Dim t As Float = Sensor.Temperature
			Dim h As Float = Sensor.Humidity
			WriteToBLE(t, h)
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
'	temp - Temperature
'	hum - Humidity
Public Sub WriteToBLE(temp As Float, hum As Float)
	Dim t As Int = temp
	Dim h As Int = hum
	Dim data(2) As Byte
	data(0) = t
	data(1) = h
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_DHT11, CommBLE.CMD_GET_VALUE, data(0), data(1))
	CommBLE.BLEServer_Write(payload)
	Log("[DevDHT11.WriteToBLE] t=", t, ", h=", h, ", payload=", Convert.BytesToHex(payload))
	' [DevDHT11.WriteToBLE] t=19, h=61, payload=0904133D
End Sub
#End Region
#End If
