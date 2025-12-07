B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	MenuHandler.bas
' Project:     	make-homekit32
' Brief:       	Handle menus using buttons left & right 
' Date:        	2025-11-12
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx.b4x
' Description:	Butten left to select a menu item.
'				Button right to set the state of the selected menu item.
' Hardware:		https://wiki.keyestudio.com/Ks0029_keyestudio_Digital_Push_Button
' ================================================================
#End Region

Private Sub Process_Globals
	Private DEBOUNCE_MS As UInt = 500

	Private BtnLeft As Pin
	Private BtnRight As Pin
	
	' Firsttime flag to avoid button state change for state true (released)
	Private BtnLeftFirstTime As Boolean = True
	Private BtnRightFirstTime As Boolean = True
	Private BtnLeftLastChange As ULong = 1
	Private BtnRightLastChange As ULong = 1
	
	' Menu Items
	Private MENU_LED=0, MENU_DHT11=1, MENU_EVENTS=2, MENU_Info=3 As Byte
	Private MenuItems() As String = Array As String("Menu: LED", "Menu: DHT11", "Menu: Events", "Menu: Info")
	Private MenuItemSelected As Int = -1
	Private MenuEventsState As Boolean = False
End Sub

' Initialize
' Initializes the buttons.
' Parameters:
'   btnleftpinnr - GPIO pin number
'   btnrightpinnr - GPIO pin number
Public Sub Initialize(btnleftpinnr As Byte, btnrightpinnr As Byte)
	BtnLeft.Initialize(DeviceMgr.BTN_LEFT_PIN, BtnLeft.MODE_INPUT)
	BtnRight.Initialize(DeviceMgr.BTN_RIGHT_PIN, BtnRight.MODE_INPUT)

	' Add buttons state change listen
	BtnLeft.AddListener("BtnLeft_StateChanged")
	BtnRight.AddListener("BtnRight_StateChanged")

	Log("[MenuHandler.Initialize][I] BtnLeft OK, pin=", btnleftpinnr, ", BtnRight OK, pin=", btnrightpinnr)
End Sub

#Region ButtonEvents
' Handle button state changes: Pressed=state 0; Released=state 1
' Use FirstTime flag to avoid handling buttom state 1

' BtnLeft_StateChanged
' Menu item selection.
'	state Boolean - Left button state. False is button pressed.
Private Sub BtnLeft_StateChanged(state As Boolean)
	' Do nothing if first time
	If BtnLeftFirstTime Then
		BtnLeftFirstTime = Not(BtnLeftFirstTime)
		Return
	End If

	' Debounce: ignore changes faster than NNN ms
	If (Millis - BtnLeftLastChange) < DEBOUNCE_MS Then Return
	BtnLeftLastChange = Millis

	' Log("[MenuHandler.BtnLeft_StateChanged] state=",state)

	' Button is pressed
	If Not(state) Then
		' Select the next menu item
		MenuItemSelected = MenuItemSelected + 1
		If MenuItemSelected > MenuItems.Length -1 Then MenuItemSelected = 0
		' Display the menu select on lcd top row
		DevLCD1602.Clear
		DevLCD1602.Lcd.WriteAt(0, 0, MenuItems(MenuItemSelected))
	End If
End Sub

' BtnRight_StateChanged
' Menu item action
'	state Boolean - Right button state. False is button pressed.
Private Sub BtnRight_StateChanged(state As Boolean)
	' Do nothing if first time
	If BtnRightFirstTime Then
		BtnRightFirstTime = Not(BtnRightFirstTime)
		Return
	End If

	' Debounce: ignore changes faster than NNN ms
	If (Millis - BtnRightLastChange) < DEBOUNCE_MS Then Return
	BtnRightLastChange = Millis

	' Log("[MenuHandler.BtnRight_StateChanged] state=",state)

	If Not(state) Then
		Select MenuItemSelected
			Case MENU_LED
				Dim ledstate As Boolean = Not(DevYellowLed.Get)
				DevYellowLed.Set(ledstate)
				DevLCD1602.ClearBottomRow
				DevLCD1602.WriteAt(0, 1, Convert.BoolToOnOff(ledstate))
			Case MENU_DHT11
				DevLCD1602.ClearBottomRow
				DevLCD1602.WriteAt(0, 1, "T:")
				DevLCD1602.WriteAt(3, 1, DevDHT11.Temperature)
				DevLCD1602.WriteAt(8, 1, "H:")
				DevLCD1602.WriteAt(11, 1, DevDHT11.Humidity)
			Case MENU_EVENTS
				MenuEventsState = Not(MenuEventsState)
				DevSystem.EnableEvents(MenuEventsState)
			Case MENU_Info
				DevLCD1602.Clear
				Main.DisplayAppName
		End Select
	End If
End Sub
#End Region
