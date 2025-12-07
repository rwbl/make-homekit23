B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	DevSystem.bas
' Project:     	make-homekit32
' Brief:       	System specific commands.
' Date:        	2025-12-06
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies:	rGlobalStoreEx, rMQTT
' Description:	System specific commands:
' Hardware:		https://wiki.keyestudio.com/KS5009_Keyestudio_Smart_Home
' ================================================================
#End Region

Sub Process_Globals

	Private mEventsEnabled As Boolean
End Sub

' Initialize
' Initializes system device.
' Parameters:
'   n/a
Public Sub Initialize
	mEventsEnabled = False
	Log("[DevSystem.Initialize][I] OK")
End Sub

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Process system commands
' Parameters:
'   storeindex - Index in the global store buffer
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Dim action As Int 

	' Handle the various system commands

	' Command to enable events using key "e".
	' Get the keys from {"e":0 | 1}. If -1 then key not found.
	action = MQTTClient.GetNumberFromKey(payload, "e")
	If action > -1 Then
		Log("[DevSystem.ProcessMQTT] command=enableevents, action=",action)
		Select action
			Case 0x00
				EnableEvents(False)
			Case 0x01
				EnableEvents(True)
		End Select	
	End If	
End Sub

' PublishToMQTT
' Write, publish, to MQTT the state.
' Parameters:
'Private Sub PublishToMQTT()
'	' Publish
'	MQTTClient.Publish()
'	Log("[DevSystem.PublishToMQTT][I] json=", payload)
'End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0xFF
' Get the custom action. 
' Note: Only the command custom action is supported.
' 	Length: 3 Bytes
' 	Byte 0 Device:	0xFF
' 	Byte 1 Command:	0x05 > Custom Action
'	Byte 2 Action:	0x01 > Enable events
'					0x02 > Disable events
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevSystem.ProcessBLE][I] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))

	' Check if 3 bytes
	If payload.Length < 3 Then
		Log("[DevSystem.ProcessBLE][E] Payload invalid length. Expect 3 bytes.")
		Return
	End If

	' Get the command and the action
	Dim command As Byte = payload(1)
	
	' Check if command is custom action
	If command <> CommBLE.CMD_CUSTOM_ACTION Then
		Log("[DevSystem.ProcessBLE][E] Command invalid. Expect Custom Action 0x05.")		
		Return
	End If

	' Get the action
	Dim action As Byte = payload(2)
	Select action
		Case 0x01
			' Enable events
			EnableEvents(True)
		Case 0x02
			EnableEvents(False)
		' add more
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'Public Sub WriteToBLE()
'	Dim payload() As Byte = Array As Byte()
'	CommBLE.BLEServer_Write(payload)
'	Log("[DevSystem.WriteToBLE] ")
'End Sub
#End Region
#End If

#Region Commands
' Enable Events
' Eanable/disable events from selected sensors:
' PIR, DHT11, Moisture
' Parameters:
'	state Boolean - True (enabled), False (disabled)
Public Sub EnableEvents(state As Boolean)
	mEventsEnabled = state
	DevPIRSensor.Enabled(state)
	DevDHT11.Enabled(state)
	DevMoisture.Enabled(state)

	' Show state on LCD
	DevLCD1602.Clear
	DevLCD1602.WriteAt(0, 0, "Events Enabled")
	DevLCD1602.WriteAt(0, 1, Convert.BoolToOnOff(state))
	Log("[DevSystem.ProcessBLE][I] Events enabled=",state)
End Sub
#End Region

#Region Getter/Setter
Public Sub EventsEnabled As Boolean
	Return mEventsEnabled
End Sub
#End Region
