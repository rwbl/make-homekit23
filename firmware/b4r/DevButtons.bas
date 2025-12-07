B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	DevButtons.bas
' Project:     	make-homekit32
' Brief:       	Handle all buttons press & released.
' Date:        	2025-11-12
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx.b4x
' Description:	Handles various button state changes.
' Hardware:		https://wiki.keyestudio.com/Ks0029_keyestudio_Digital_Push_Button
' ================================================================
#End Region

Private Sub Process_Globals
	Private DEBOUNCE_MS As UInt = 800

	Private BtnLeft As Pin
	Private BtnRight As Pin
	
	' Firsttime flag to avoid button state change for state true (released)
	Private BtnLeftFirstTime As Boolean = True
	Private BtnRightFirstTime As Boolean = True
	Private BtnLeftLastChange As ULong = 0
	Private BtnRightLastChange As ULong = 0
End Sub

' Initialize
' Initializes the buttons.
' Parameters:
'   btnleftpinnr - GPIO pin number
'   btnrightpinnr - GPIO pin number
Public Sub Initialize(btnleftpinnr As Byte, btnrightpinnr As Byte)
	BtnLeft.Initialize(DeviceMgr.BTN_LEFT_PIN, BtnLeft.MODE_INPUT)
	Log("[DevButtons.Initialize][I] BtnLeft OK, pin=", btnleftpinnr)
	BtnRight.Initialize(DeviceMgr.BTN_RIGHT_PIN, BtnRight.MODE_INPUT)
	Log("[DevButtons.Initialize][I] BtnRight OK, pin=", btnrightpinnr)

	' Add buttons state change listen
	BtnLeft.AddListener("BtnLeft_StateChanged")
	BtnRight.AddListener("BtnRight_StateChanged")
End Sub

#Region BUTTONEVENTS
' Handle button state changes: Pressed=state 0; Released=state 1
' Use FirstTime flag to avoid handling buttom state 1

' Log the btn left state change.
Private Sub BtnLeft_StateChanged(state As Boolean)
	Dim payload As String

	If BtnLeftFirstTime Then
		BtnLeftFirstTime = Not(BtnLeftFirstTime)
		Return
	End If

	' Debounce: ignore changes faster than NNN ms
	If (Millis - BtnLeftLastChange) < DEBOUNCE_MS Then Return
	BtnLeftLastChange = Millis

	Log("[DevButtons.BtnLeft_StateChanged] state=",state)

	If state Then
		payload = MQTTTopics.PAYLOAD_BUTTON_RELEASED
	Else
		payload = MQTTTopics.PAYLOAD_BUTTON_PRESSED
	End If
	MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_BUTTON_LEFT_ACTION), Array As String (payload))
	Log("[DevButtons.BtnLeft_StateChanged] json=", payload)
End Sub

' Turn the yellow led on or off when btn right is pressed.
Private Sub BtnRight_StateChanged(state As Boolean)
	Dim payload As String

	If BtnRightFirstTime Then
		BtnRightFirstTime = Not(BtnRightFirstTime)
		Return
	End If

	' Debounce: ignore changes faster than NNN ms
	If (Millis - BtnRightLastChange) < DEBOUNCE_MS Then Return
	BtnRightLastChange = Millis

	Log("[DevButtons.BtnRight_StateChanged] state=", state)

	If state == False Then
		If DevYellowLed.Get Then
			DevYellowLed.Set(False)
			payload = MQTTTopics.PAYLOAD_YELLOW_LED_OFF
		Else
			DevYellowLed.Set(True)
			payload = MQTTTopics.PAYLOAD_YELLOW_LED_ON
		End If
		MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_BUTTON_RIGHT_ACTION), Array As String (payload))
		Log("[DevButtons.BtnRight_StateChanged] json=", payload)
	End If
End Sub
#End Region

#Region BUTTONACTIONS
Public Sub BtnLeftAction(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevButtons.BtnLeftAction] storeindex=", storeindex, ", payload=", payload)
End Sub

Public Sub BtnRightAction(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevButtons.BtnRightAction] storeindex=", storeindex, ", payload=", payload)
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT

#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE

#End If
