B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	DevGasSensor.bas
' Project:     	make-homekit32
' Brief:       	Handles the Keyestudio analog gas sensor (digital read mode).
' Date:        	2025-11-13
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies:	rGlobalStoreEx, rMQTT
' Description:	Reads the gas detection state (digital 0/1) and publishes it via MQTT.
'				The analog gas sensor is used as a digital detector:
'     			- LOW (0)  > gas detected
'     			- HIGH (1) > clear / no gas
' Hardware:		https://wiki.keyestudio.com/KS0040_keyestudio_Analog_Gas_Sensor
' ================================================================
#End Region

Private Sub Process_Globals
	Private Sensor As Pin
	Private PrevState As Boolean = False
	Private FirstTime As Boolean = True
End Sub

' Initialize
' Initializes the gas sensor pin and attaches a listener.
' Parameters:
'   pinnr - GPIO pin number (digital input)
Public Sub Initialize(pinnr As Byte)
	Sensor.Initialize(pinnr, Sensor.MODE_INPUT)
	Sensor.AddListener("Sensor_StateChanged")
	Log("[DevGasSensor.Initialize][I] OK, pin=", pinnr)
End Sub

#Region Device Control
' Sensor_StateChanged
' Sensor listener event for state changes.
' Publishes MQTT/BLE status:
'   {"s":"detected"} when gas is detected
'   {"s":"clear"} when air is clear
'   0A 02 00 when gas is detected
'   0A 02 01 when air is clear
Sub Sensor_StateChanged(state As Boolean)
	If FirstTime Then
		FirstTime = False
		Return
	End If
	
	Log("[DevGasSensor.State_Changed] state=", state, ", prev=", PrevState)

	If state <> PrevState Then
		#If MQTT
		PublishToMQTT(state)
		#End If
		
		#If BLE
		WriteToBLE(state)
		#End If
		
		PrevState = state
	End If
End Sub

' Get
' Reads the current digital gas sensor value.
' Parameters:
'   storeindex - Index in the global store buffer
' Returns:
'   Boolean - True if gas detected, False otherwise
Public Sub Get(storeindex As Byte) As Boolean
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevGasSensor.Get] storeindex=", storeindex, ", payload=", payload)
	Dim State As Boolean = Sensor.DigitalRead
	Log("[DevGasSensor.Get] state=", State)
	Return State
End Sub

' Detected
' Reads the current digital gas sensor value.
' Returns:
'   Boolean - True if gas detected, False otherwise
Public Sub Detected As Boolean
	Dim state As Boolean = Sensor.DigitalRead
	Log("[DevGasSensor.Detected] state=", state)
	Return state
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' PublishToMQTT
' Publish the state.
' Parameters:
'	state - Sensor state 
Private Sub PublishToMQTT(state As Boolean)
	Dim topic() As String = Array As String(MQTTTopics.TOPIC_GAS_SENSOR_STATUS)
	Dim payload() As String
		
	If Not(state) Then
		payload = Array As String(MQTTTopics.PAYLOAD_GAS_DETECTED)
	Else
		payload = Array As String(MQTTTopics.PAYLOAD_GAS_CLEAR)
	End If
	MQTTClient.Publish(topic, payload)
	Log("[DevGasSensor.PublishToMQTT][I] json=", payload(0))
End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x0A
' Get sensor data.
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x0A
' 	Byte 1 Command:	0x02 > Get state
'	Returns Byte 0=Clear, 1=Detected
'	Example Get State = 0A01
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevMoisture.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_GET_STATE
			WriteToBLE(Sensor.DigitalRead)
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	value - Boolean Gas detected
Public Sub WriteToBLE(state As Boolean)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_GAS_SENSOR, CommBLE.CMD_GET_VALUE, Convert.BoolToByte(state))
	CommBLE.BLEServer_Write(payload)
	Log("[DevGasSensor.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
