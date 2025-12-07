B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Class Header
' File:			HK32HMI
' Brief:		Client controlling the HomeKit32 via BLE using HMI ISA101 standard.
' Date:			2025-12-04
' Author:		Robert W.B. Linn (c) 2025 MIT
' Description:	This B4J application (app) connects as a client with an ESP32 running as Bluetooth Low Energy (BLE) server.
'				The BLE-Server advertises DHT22 sensor data temperature & humidity and listens to commands send from connected clients.
'				The communication between the B4J-Client and the BLE-Server is managed by the PyBridge with Bleak.
'				The data is passed thru the PyBridge and to be handled by client or BLE server.
' Source: 		homekit32.b4j, B4J 10.30(64 bit)
' Libraries:	PyBridge 1.00, Bleak 1.02, ByteConverter 1.10
' Bleak:		Install:
'				Set python path under Tools: C:\Prog\B4J\Libraries\Python\python\python.exe
'				Open global Python shell: ide://run?File=%B4J_PYTHON%\..\WinPython+Command+Prompt.exe
'				From folder C:\Prog\B4J\Libraries\Python\Notebooks> run: pip install bleak
'				https://www.b4x.com/android/forum/threads/pybridge-bleak-bluetooth-ble.165982/
#End Region

Sub Class_Globals
	Private VERSION As String	= "HomeKit32HMI v20251204"
	Private COPYRIGHT As String = "Keyestudio Smart Home Kit ESP32 Control by Robert W.B. Linn (c) 2025 MIT"

	' XUI Base	
	Private xui As XUI
	Private fx As JFX
	Private Root As B4XView
	
	' Tiles for device control
	Private TileButtonConnect As HMITileButton
	Private TileButtonAlarm As HMITileButton
	Private TileButtonYellowLED As HMITileButton
	Private TileSensorTemperature As HMITileSensor
	Private TileSensorHumidity As HMITileSensor
	Private TileSensorMoisture As HMITileSensor
	Private TileSensorGasSensor As HMITileSensor
	Private TileRGBLED As HMITileRGB
	Private TileButtonRGBLED As HMITileButton
	Private TileButtonDoor As HMITileButton
	Private TileButtonWindow As HMITileButton
	Private TileSensorPIRSensor As HMITileSensor
	Private TileButtonPlayAlarm As HMITileButton
	Private TileButtonFan As HMITileButton
	Private LabelAbout As Label

	' Logging
	Private TileEventViewer As HMITileEventViewer

	' BLE
	Public BLEMgr As BLEManager		' Global as used by the DevNAME modules
	
	' PyBridge
	Public Py As PyBridge
	
	' Devices
	Private YellowLED As DevYellowLED
	Private Buzzer As DevBuzzer
	Private Door As DevDoor
	Private Window As DevWindow
	Private Fan As DevFan
	Private GasSensor As DevGasSensor
	Private MoistureSensor As DevMoistureSensor
	Private PIRSensor As DevPIRSensor
	Private RFID As DevRFID
	Private RGBLED As DevRGBLED
	Private DHT11 As DevDHT11
	
End Sub

Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

#Region B4XPage
' This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("MainPage")

	' UI settings
	B4XPages.GetNativeParent(Me).Resizable = False
	Root.Color = HMITileUtils.COLOR_BACKGROUND_SCREEN
	B4XPages.SetTitle(Me, VERSION)
	LabelAbout.Text = COPYRIGHT

	' CustomViews require short sleep else not initialized error message
	Sleep(1)
	TileButtonYellowLEDUpdate(False)
	TileButtonRGBLEDUpdate(False)
	TileButtonConnect.SetStateFontFontAwesome
	TileButtonConnectUpdate(False)
	TileButtonDoorUpdate(False)
	TileButtonWindowUpdate(False)
	TileButtonFanUpdate(False)
	TileButtonAlarm.SetInfo("--")
	
	' Add info to the event log
	TileEventViewer.Insert($"[B4XPage_Created] ${VERSION}"$, HMITileUtils.EVENT_LEVEL_INFO)
	TileEventViewer.Insert($"[B4XPage_Created] BLE disconnected"$, HMITileUtils.EVENT_LEVEL_WARNING)
	
	' Initialize BLEMgr
	BLEMgr.Initialize(B4XPages.GetPage("MainPage"))
	Wait For (BLEMgr.Start) complete (result As Boolean)
	If result Then
		TileEventViewer.Insert($"[B4XPage_Created] PyBridge started, BLE initialized"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[B4XPage_Created] Failed to start the PyBridge initialize BLE"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If

	' Initialize devices
	YellowLED.Initialize(BLEMgr)
	Buzzer.Initialize(BLEMgr)
	Door.Initialize(BLEMgr)
	Window.Initialize(BLEMgr)
	Fan.Initialize(BLEMgr)
	GasSensor.Initialize(BLEMgr)
	MoistureSensor.Initialize(BLEMgr)
	PIRSensor.Initialize(BLEMgr)
	RFID.Initialize(BLEMgr)
	RGBLED.Initialize(BLEMgr)
	DHT11.Initialize(BLEMgr)
	
	' Start ble connection
	'TileButtonConnect_Click
End Sub

'Close the b4xpages app. Prior closing the PyBridge is stopped.
Private Sub B4XPage_CloseRequest As ResumableSub
	LogColor($"[B4XPage_CloseRequest] starting..."$, xui.Color_Red)
	BLEMgr.PyBridgeKillProcess
	Sleep(100)
	LogColor($"[B4XPage_CloseRequest] done..."$, xui.Color_Red)
	Return True
End Sub

Private Sub B4XPage_Background
	BLEMgr.PyBridgeKillProcess
End Sub
#End Region

#Region PyBridge
' These subs are triggered by the BLEMgr pybridge events

Public Sub PyBridgeDisconnected
	TileButtonConnectUpdate(False)
End Sub
#End Region

#Region BLE
' HandleBLEConnect
' Set the connect button state.
' Parameters:
'	state Boolean - True connected else disconnected
Public Sub HandleBLEConnect(state As Boolean)
	TileButtonConnectUpdate(state)
	If state Then
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Connected"}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Disconnected"}"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
End Sub

' HandleBLENotification
' Process the data received from BLE notify.
' Get the device id as first byte and then parse the data according device byte pattern.
' Parameters:
'	data Byte Array
Public Sub HandleBLENotification(payload() As Byte)
	Dim m As Map
	Dim item As String

	item = $"[HandleBLENotification] payload=${Convert.ByteConv.HexFromBytes(payload)}"$
	TileEventViewer.Insert($"[HandleBLENotification] payload=${Convert.ByteConv.HexFromBytes(payload)}"$, HMITileUtils.EVENT_LEVEL_INFO)
	
	' Get the device id
	Dim deviceid As Byte = payload(0)
	
	' Select the device and parse the payload (see device code modules)
	Select deviceid
		Case BLEConstants.DEV_YELLOW_LED
			Dim datayellowled As TDevYellowLED = YellowLED.Parse(payload)
			TileEventViewer.Insert($"[HandleBLENotification] YellowLED state=${datayellowled.State}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_BUZZER
			Dim databuzzer As TDevBuzzer= Buzzer.Parse(payload)
			TileEventViewer.Insert($"[HandleBLENotification] Buzzer state=${databuzzer.State}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_MOISTURE
			m = MoistureSensor.Parse(payload)
			Dim v As Int = m.Get("value")
			TileSensorMoisture.Value = Convert.ValueToPercent(v, 4095)
			TileButtonAlarm.SetWarning("Raining")

		Case BLEConstants.DEV_DHT11
			Dim datadht11 As TDevDHT11 = DHT11.Parse(payload)
			TileSensorTemperature.SetValue(datadht11.Temperature)
			TileSensorHumidity.SetValue(datadht11.Humidity)
			TileEventViewer.Insert($"[HandleBLENotification] DHT11 t=${datadht11.Temperature},h=${datadht11.Humidity}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_PIR_SENSOR
			m = PIRSensor.Parse(payload)
			Dim value As Byte = m.get("value")
			If value == 1 Then
				TileSensorPIRSensor.Value = "Detected"
				TileSensorPIRSensor.SetStyleWarning
			Else
				TileSensorPIRSensor.Value = "Cleared"
				TileSensorPIRSensor.SetStyleInfo
			End If

		Case BLEConstants.DEV_GAS_SENSOR
			m = GasSensor.Parse(payload)
			Dim value As Byte = m.get("value")
			TileSensorGasSensor.Value = value
			If value == 0 Then
				TileSensorGasSensor.Value = "Detected"
				TileSensorGasSensor.SetStyleAlarm
			Else
				TileSensorGasSensor.Value = "Cleared"
				TileSensorGasSensor.SetStyleInfo
			End If

		Case BLEConstants.DEV_RFID
			m = RFID.Parse(payload)
			If m.IsInitialized Then
				Dim group As Byte = m.Get("group")		'ignore
				Dim command As Byte = m.Get("command")
				If command == 4 Then
					If Door.IsOpen Then
						Door.Close
					Else
						Door.Open
					End If
				End If
				TileButtonAlarm.SetWarning($"RFID touched${CRLF}Group${CRLF}${group}"$)
			End If
		Case Else
			' m = CreateMap("msg":"Device not found or data not parsed")
	End Select
	
	If m.IsInitialized Then
		item = $"[HandleBLENotification] device=${Convert.ByteToHex(deviceid)}, ${m}"$
		TileEventViewer.Insert($"${item}"$, HMITileUtils.EVENT_LEVEL_INFO)
	End If
End Sub

Public Sub BLEDeviceDisconnected
	TileButtonConnectUpdate(False)
End Sub
#End Region

#Region Device Control
'==================================================================
' Device Control
'==================================================================
' Hints: For buttons, the UI follows actual device state

'Connect to the BLE-Server using its service uuid.
Private Sub TileButtonConnect_Click
	TileButtonConnect.StateText = Chr(0xF252)
	If Not(BLEMgr.IsConnected) Then
		TileEventViewer.Insert($"[TileButtonConnect_Click] Connecting..."$, HMITileUtils.EVENT_LEVEL_WARNING)
		'TileButtonConnect.SetWarning($"Connecting${CRLF}..."$)
		
		' Scan for devices using service uuid.
		Wait For (BLEMgr.Scan) Complete (Success As Boolean)
		If Not(Success) Then
			TileEventViewer.Insert($"[TileButtonConnect_Click] ${BLEMgr.LastMsg}"$, HMITileUtils.EVENT_LEVEL_ALARM)
			TileButtonConnectUpdate(False)
		End If
	Else
		TileEventViewer.Insert($"[TileButtonConnect_Click] Disconnecting..."$, HMITileUtils.EVENT_LEVEL_WARNING)
		Wait For(BLEMgr.Disconnect) Complete (Success As Boolean)
		TileEventViewer.Insert($"[TileButtonConnect_Click] Disconnected"$, HMITileUtils.EVENT_LEVEL_INFO)
		TileButtonConnectUpdate(False)
	End If
End Sub

Private Sub TileButtonConnectUpdate(state As Boolean)
	If Not(TileButtonConnect.IsInitialized) Then Return
	TileButtonConnect.State = state
	TileButtonConnect.StateText = IIf(state, Chr(0xF205), Chr(0xF204)) ' FA toggle-on / toggle-off
End Sub

' Set the yellow led state ON or OFF
Private Sub TileButtonYellowLED_Click
	Dim state As Boolean = Not(YellowLED.Get)
	' Set the device
	YellowLED.Set(state)
	' Update the tile
	TileButtonYellowLEDUpdate(state)
End Sub

Private Sub TileButtonYellowLEDUpdate(state As Boolean)
	If Not(TileButtonYellowLED.IsInitialized) Then Return
	TileButtonYellowLED.StateText = Convert.BoolToOnOff(state)
	TileButtonYellowLED.SetStateColor(state)
	Log($"[TileButtonYellowLEDUpdate] state=${state}"$)
End Sub

Private Sub TileReadoutTemperature_Click(EventData As MouseEvent)
	BLEMgr.Write(Array As Byte(BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE))
	Log($"[TileReadoutTemperature_Click] done"$)
End Sub

Private Sub TileSensorTemperature_Click(EventData As MouseEvent)
	BLEMgr.Write(Array As Byte(BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE))
	Log($"[TileSensorTemperature_Click] done"$)
End Sub

Private Sub TileReadoutHumidity_Click(EventData As MouseEvent)
	BLEMgr.Write(Array As Byte(BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE))
	Log($"[TileReadoutHumidity_Click] done"$)
End Sub

Private Sub TileReadoutMoisture_Click(EventData As MouseEvent)
	BLEMgr.Write(Array As Byte(BLEConstants.DEV_MOISTURE, BLEConstants.CMD_GET_VALUE))
	Log($"[TileReadoutMoisture_Click] done"$)
End Sub
#End Region

#Region Buzzer
Private Sub TileButtonPlayAlarm_Click
	Buzzer.PlayAlarm(0x01, 0x01)
	Log($"[TileButtonAlarm_Click] mode=1, repeats=1, done"$)
End Sub

Private Sub TileButtonPlayTone_Click
	Buzzer.PlayTone(440, 500)
	Log($"[TileButtonPlayTone_Click] f=440, d=500, done"$)
End Sub
#End Region

#Region Alarm
Private Sub TileButtonAlarm_Click
	TileButtonAlarm.SetInfo("Cleared")
	TileEventViewer.Insert($"[TileButtonAlarm_Click] Cleared"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub
#End Region

#Region RGBLED
Private Sub TileRGBLED_ValueChanged(m As Map)
	If Not(TileRGBLED.IsInitialized) Then Return
	Log($"[TileRGB_ValueChanged] ${m}"$)
	' Cast the map values to byte
	Dim r As Byte = m.get("r")
	Dim g As Byte = m.get("g")
	Dim b As Byte = m.get("b")
	RGBLED.SetColor(r, g, b)
	' Update the tile
	TileButtonRGBLEDUpdate(RGBLED.IsOn)
End Sub

Private Sub TileButtonRGBLED_Click
	If Not(TileButtonRGBLED.IsInitialized) Then Return
	Dim state As Boolean = Not(RGBLED.IsOn)
	' Set the device
	RGBLED.SetOnOff(state)
	' Update the tile
	TileButtonRGBLEDUpdate(state)
	Log($"[TileButtonRGBLED_Click] state=${state}"$)
End Sub

Private Sub TileButtonRGBLEDUpdate(state As Boolean)
	If Not(TileButtonRGBLED.IsInitialized) Then Return
	TileButtonRGBLED.SetStateColor(state)
	TileButtonRGBLED.StateText = IIf(state, "ON", "OFF")
'	Log($"[TileButtonRGBLEDUpdate] state=${state}"$)
End Sub
#End Region

#Region Door
Private Sub TileButtonDoor_Click
	Dim state As Boolean = Not(Door.IsOpen)
	Door.Set(state)
	TileButtonDoorUpdate(state)
	Log($"[TileButtonDoor_Click] state=${state}"$)
End Sub

Private Sub TileButtonDoorUpdate(state As Boolean)
	If Not(TileButtonDoor.IsInitialized) Then Return
	TileButtonDoor.StateText = IIf(state, "Open", "Closed")
	TileButtonDoor.SetStateColor(state)
'	Log($"[TileButtonDoorUpdate] state=${state}"$)
End Sub
#End Region

#Region Window
Private Sub TileButtonWindow_Click
	Dim state As Boolean = Not(Window.IsOpen)
	Window.Set(state)
	TileButtonWindowUpdate(state)
	Log($"[TileButtonWindow_Click] state=${state}"$)
End Sub

Private Sub TileButtonWindowUpdate(state As Boolean)
	If Not(TileButtonWindow.IsInitialized) Then Return
	TileButtonWindow.StateText = IIf(state, "Open", "Closed")
	TileButtonWindow.SetStateColor(state)
'	Log($"[TileButtonWindowUpdate] state=${state}"$)
End Sub
#End Region

#Region Motion
Private Sub TileSensorPIRSensor_Click(EventData As MouseEvent)
	PIRSensor.SetEnabled(Not (PIRSensor.GetEnabled))
	TileEventViewer.Insert($"[TileSensorPIRSensor] enabled=${PIRSensor.GetEnabled}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[TileSensorPIRSensor] enabled=${PIRSensor.GetEnabled}"$)
End Sub
#End Region

#Region Gas Sensor
Private Sub TileSensorGas_Click(EventData As MouseEvent)
	
End Sub
#End Region

#Region Fan
Private Sub TileButtonFan_Click
	Dim state As Boolean = Not(Fan.IsOn)
	Fan.Set(state)
	TileButtonFanUpdate(state)
	Log($"[TileButtonFan_Click] state=${state}"$)
End Sub

Private Sub TileButtonFanUpdate(state As Boolean)
	If Not(TileButtonFan.IsInitialized) Then Return
	TileButtonFan.StateText = IIf(state, "On", "Off")
	TileButtonFan.SetStateColor(state)
'	Log($"[TileButtonFanUpdate] state=${state}"$)
End Sub
#End Region


#Region TileEventViewer/Info
Private Sub TileEventViewer_Click(EventData As MouseEvent)
	Log(BLEMgr.LastMsg)
End Sub

Private Sub TileLabelInfo_Click(EventData As MouseEvent)
'	If Root.Tag.As(String).Length == 0 Then Root.Tag = 0
'	If Root.Tag.As(Byte) == 0 Then
'		HMITileUtils.EnableHMITileGrid(Root)
'		Root.Tag = 1
'	Else
'		HMITileUtils.DisableHMITileGrid
'		Root.Tag = 0
'	End If
End Sub
#End Region
