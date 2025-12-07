B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         CommMQTT.bas
' Project:      make-homekit32
' Brief:        Handle MQTT communication.
' Date:         2025-11-12
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rWiFiManager, rMQTT, rGlobalStoreEx
' Description:	Communication layer for message routing via MQTT.
' ================================================================
#End Region

Private Sub Process_Globals

End Sub

' Initialize
' Initializes WiFi and MQTT, connects, and subscribes to topics.
Public Sub Initialize
	Log("[CommMQTT.Initialize][I] Starting MQTT communication...")

	' 1. Connect to WiFi
	WiFiMgr.Connected = WiFiMgr.Connect
	If Not(WiFiMgr.Connected) Then
		Log("[CommMQTT.Initialize][E] WiFi connection failed")
		DevLCD1602.ClearBottomRow
		DevLCD1602.WriteAt(0, DevLCD1602.LCD_ROW_BOTTOM, "ERR: WiFi")
		Return
	End If

	' 2. Connect to MQTT broker
	MQTTClient.Initialize(MQTTClient.ID, WiFiMgr.Client.Stream)
	MQTTClient.Connect(0)
	Delay(MQTTClient.DELAY_AFTER_TASK)

	' 3. Subscribe to topics after connecting (see MQTTTopics)
	If MQTTClient.Connected Then
		MQTTClient.Subscribe(Array As String(MQTTTopics.TOPIC_COMMAND, _
											 MQTTTopics.TOPIC_YELLOW_LED_SET, _
											 MQTTTopics.TOPIC_RGB_LED_SET, _ 
											 MQTTTopics.TOPIC_BUTTON_LEFT_ACTION, _ 
											 MQTTTopics.TOPIC_BUTTON_RIGHT_ACTION, _ 
											 MQTTTopics.TOPIC_SERVO_DOOR_SET, _ 
											 MQTTTopics.TOPIC_SERVO_WINDOW_SET, _ 
											 MQTTTopics.TOPIC_BUZZER_SET, _ 
											 MQTTTopics.TOPIC_FAN_SET, _ 
											 MQTTTopics.TOPIC_DHT11_GET, _ 
											 MQTTTopics.TOPIC_GAS_SENSOR_GET, _ 
											 MQTTTopics.TOPIC_MOISTURE_GET, _ 
											 MQTTTopics.TOPIC_LCD_SET))
		Delay(MQTTClient.DELAY_AFTER_TASK)
		Log("[CommMQTT.Initialize][I] MQTT connected and topics subscribed")
	Else
		Log("[CommMQTT.Initialize][E] MQTT broker connection failed")
		DevLCD1602.ClearBottomRow
		DevLCD1602.WriteAt(0, DevLCD1602.LCD_ROW_BOTTOM, "ERR: MQTT")
	End If
	Log("[CommMQTT.Initialize] Done")
End Sub

#Region MQTT Events
' Handle MQTT message arrived and routing
Public Sub MQTT_MessageArrived(topic As String, payload() As Byte)
	' Get the topic index from the topic table
	Dim idx As Byte = MQTTTopics.GetTopicIndex(topic)

	' Check if topic index found
	If idx == MQTTTopics.TOPIC_NOT_FOUND Then
		Log("[CommMQTT.MQTT_MessageArrived][E] Unknown topic: ", topic)
	End If

	' Store the payload in the global store buffer
	GlobalStoreHandler.Put(payload)

	' Dispatch to handler (slightly delayed to avoid blocking)
	CallSubPlus("MQTTDispatch", 50, idx)
	
	Log("[CommMQTT.MQTT_MessageArrived][I] topic=",topic, ", index=", idx, ", payload=",payload, ", storeindex=", GlobalStoreHandler.Index)
End Sub

' Dispatch MQTT message to the relevant device handler.
' Ensure to align with the MQTTTopics TopicTable.
Private Sub MQTTDispatch(topicindex As Byte)
	#If MQTT
	Select topicindex
		Case 0
			ProcessMQTT(GlobalStoreHandler.Index)
		Case 1
			DevYellowLed.ProcessMQTT(GlobalStoreHandler.Index)
		Case 2
			DevRGBLed.ProcessMQTT(GlobalStoreHandler.Index)
		Case 3
			' DevButtons.BtnLeftAction(GlobalStoreHandler.Index)
		Case 4
			' DevButtons.BtnRightAction(GlobalStoreHandler.Index)
		Case 5
			DevServoDoor.ProcessMQTT(GlobalStoreHandler.Index)
		Case 6
			DevServoWindow.ProcessMQTT(GlobalStoreHandler.Index)
		Case 7
			DevBuzzer.ProcessMQTT(GlobalStoreHandler.Index)
		Case 8
			DevFan.ProcessMQTT(GlobalStoreHandler.Index)
		Case 9
			DevDHT11.ProcessMQTT(GlobalStoreHandler.Index)
		Case 10
		Case 11
			DevMoisture.ProcessMQTT(GlobalStoreHandler.Index)
		Case 12
			DevLCD1602.ProcessMQTT(GlobalStoreHandler.Index)
	End Select
	#End If
End Sub
#End Region

#Region ProcessMQTT
' Set command for a device. Payload examples:
' {"d":"door","a":"open"}
' {"d":"lcd","c":0,"r":1,"t":"Welcome","x":0}
' {"d":"dht11","a":"read"}
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DeviceHandlers.SetCommand] storeindex=", storeindex, ", payload=", payload)

	' Det the key device
	Dim device() As Byte = MQTTClient.GetTextFromKey(payload, MQTTTopics.KEY_DEVICE)
	Log("[DeviceHandlers.SetCommand] device=", Convert.ByteConv.StringFromBytes(device))
	
'	' Select the device
'	If device == "door" Then
'		Dim action() As Byte = MQTTClient.GetTextFromKey(payload, MQTTTopics.KEY_ACTION)
'		Log("[DeviceHandlers.SetCommand] action=", Convert.ByteConv.StringFromBytes(action))
'		If action == MQTTTopics.ACTION_OPEN Then
'			CallSubPlus("MoveServoDoor", 0, MQTTTopics.ACTION_OPEN_VAL)
'		Else If action == MQTTTopics.ACTION_CLOSE Then
'			CallSubPlus("MoveServoDoor", 0, MQTTTopics.ACTION_CLOSE_VAL)
'		End If
'	End If
End Sub
#End region
