B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Class Header
' File:			HK32HMI
' Brief:		B4X, B4J Client controlling the HomeKit32 via BLE using HMI tiles.
' Date:			2025-12-31
' Author:		Robert W.B. Linn (c) 2025 MIT
' Description:	This B4X Application (B4A, B4J) connects As a BLE Central (GATT Client)
'				To an ESP32 running B4R firmware acting As a BLE Peripheral (GATT Server).
'    			The ESP32 BLE Peripheral advertises DHT22 temperature And humidity data
'    			and listens For commands written by connected BLE Centrals.
'
'    			In the B4J VERSION, BLE communication Is performed through a PyBridge
'    			process that uses the Bleak library. The PyBridge handles BLE operations
'    			and forwards data between the B4J client And the ESP32 BLE Peripheral.
'
'				ESP32 = BLE Peripheral + GATT Server
'				B4A/B4J = BLE Central + GATT Client
'
' Hardware:		B4A:
'				- Acer A11, 11-inch (27.9 cm) display, 1920 x 1200 px, Android 14
'				- Galaxy A13, 6.5-inch display, 1080 x 2408 px, Android 14, One UI 6.1
'				B4J:
'				- Acer NITRO 5, 15,6-inch (39.6 cm), 1920 x 1080 px, Windows 11
'				- Acer V3-771G, 17.6-inch (44.7 cm), 1600 x 900 px, Ubuntu
' Software: 	B4A 13.40 (64 bit), B4J 10.30 (64 bit), Java JDK 19
' Libraries:	B4A: BLE2 1.41, B4XPages 1.12
'				B4J: PyBridge 1.00, Bleak 1.02, ByteConverter 1.10, HMITiles 1.40
'				Min versions to include.
' Bleak:		Install:
'				Set python path under Tools: C:\Prog\B4J\Libraries\Python\python\python.exe
'				Open global Python shell: ide://run?File=%B4J_PYTHON%\..\WinPython+Command+Prompt.exe
'				From folder C:\Prog\B4J\Libraries\Python\Notebooks> run: pip install bleak
'				https://www.b4x.com/android/forum/threads/pybridge-bleak-bluetooth-ble.165982/
' Notes:		Export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip
'				Create a local Python runtime:   ide://run?File=%WINDIR%\System32\Robocopy.exe&args=%B4X%\libraries\Python&args=Python&args=/E
'				Open local Python shell: ide://run?File=%PROJECT%\Objects\Python\WinPython+Command+Prompt.exe
'				Open global Python shell - make sure to set the path under Tools - Configure Paths. Do not update the internal package.
'				ide://run?File=%B4J_PYTHON%\..\WinPython+Command+Prompt.exe
#End Region

#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=BLEExample.zip
#End Region

Private Sub Class_Globals
	Private Const VERSION As String = "HK32HMI v20251231"
	Private Const WELCOME As String	= "Welcome to HomeKit32 (c) 2025 Robert W.B. Linn - MIT"
	
	' UI
	Private Root As B4XView
	Private xui As XUI
	
	' Tiles
	Private TileButtonConnect As HMITileButton
	Private TileButtonAlarm As HMITileButton
	Private TileButtonYellowLED As HMITileButton
	Private TileSensorTemperature As HMITileSensor
	Private TileSensorHumidity As HMITileSensor
	Private TileSensorMoisture As HMITileSensor
	Private TileSensorGas As HMITileSensor
	#if B4J
	Private TileRGBLED As HMITileRGB	
	#End If
	Private TileButtonRGBLED As HMITileButton
	Private TileButtonDoor As HMITileButton
	Private TileButtonWindow As HMITileButton
	Private TileSensorPIR As HMITileSensor
	Private TileButtonPlayAlarm As HMITileButton
	Private TileButtonFan As HMITileButton
	Private TileClock As HMITileClock
	Private TileButtonEvents As HMITileButton
	Private TileEventViewer As HMITileEventViewer
	Private LabelAbout As Label

	' BLE
	#if B4A
	Public BLEMgr As BleManager2
	' Scan Timer
	Private BLEScanTimer As Timer
	Private BLE_SCAN_TIMER_INTERVAL As Long = 1000
	Private BLE_SCAN_TIMER_TIMEOUT As Long = 10000	' Stop scanning after NN seconds
	Private BLEScanTimerCounter As Long = 0
	Private IsDeviceFound As Boolean = False
	Private rp As RuntimePermissions
	#end if
	#if B4J
	Public BLEMgr As BLEManager
	#End If
	Private IsConnected As Boolean = False

	' Devices
	Private YellowLED As DevYellowLed
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
	Private LCD As DevLCD1602
	Private System As DevSystem
End Sub

#Region B4XPages
Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	' Load layout case sensitive
	Root.LoadLayout("mainpage")

	' UI
	B4XPages.SetTitle(Me, VERSION)
	Root.Color = HMITileUtils.COLOR_BACKGROUND_SCREEN
	' CustomView require short sleep
	Sleep(1)
	' Add customviews
	SetTilesInitialState
	
	' Add info to the event log
	TileEventViewer.Insert($"[B4XPage_Created] ${VERSION}"$, HMITileUtils.EVENT_LEVEL_INFO)
	TileEventViewer.Insert($"[B4XPage_Created] BLE disconnected"$, HMITileUtils.EVENT_LEVEL_WARNING)
	LabelAbout.Text = WELCOME
	
	' Initialize devices (each device has its own class module)
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
	LCD.Initialize(BLEMgr)
	System.Initialize(BLEMgr)

	' Init scan timer
	#if B4A
	BLEScanTimer.Initialize("BleScanTimer", BLE_SCAN_TIMER_INTERVAL)
	BLEScanTimer.Enabled = False
	#end if

	' BLE B4A & B4J
	' BLE Manager Initialize	
	#if B4A
	' BLE init object with event statechanged
	BLEMgr.Initialize("BLEMgr")
	#End If

	#if B4J
	' BLE init object
	BLEMgr.Initialize(B4XPages.GetPage("MainPage"))
	Wait For (BLEMgr.Start) complete (result As Boolean)
	If result Then
		TileEventViewer.Insert($"[B4XPage_Created] PyBridge started, BLE initialized ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[B4XPage_Created] Failed to start the PyBridge initialize BLE"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
	#End If
End Sub

Private Sub B4XPage_Background
	#if B4A
	BLEMgr.Disconnect
	#End If
	#if B4J
	BLEMgr.PyBridgeKillProcess
	#End If
End Sub

' These subs are triggered by the BLEMgr pybridge events
#if B4J
Public Sub PyBridgeDisconnected
	IsConnected = False
	TileEventViewer.Insert($"[PyBridgeDisconnected] ${"Disconnected"}"$, HMITileUtils.EVENT_LEVEL_WARNING)
	TileButtonConnectUpdate(IsConnected)
	SetTilesInitialState
End Sub
#End If

' ================================================================
' B4A BLE MANAGER
' ================================================================
#Region B4A-BLE-Manager
#if B4A
' BLEScanTimer_Tick
' Runs every second when scan is started.
' If no device found, timer stops and event is logged.
Private Sub BLEScanTimer_Tick
	BLEScanTimerCounter = BLEScanTimerCounter + 1
	If BLEScanTimerCounter > Round(BLE_SCAN_TIMER_TIMEOUT / BLE_SCAN_TIMER_INTERVAL) And Not(IsDeviceFound) Then
		BLEMgr.StopScan
		BLEScanTimer.Enabled = False
		TileEventViewer.Insert($"[BLEScanTimer_Tick] Device ${BLEConstants.BLE_DEVICE_NAME } not found. Timeout reached."$, HMITileUtils.EVENT_LEVEL_ALARM)
		Log($"[BLEScanTimer_Tick][E] Device ${BLEConstants.BLE_DEVICE_NAME } not found. Timeout reached."$)
		TileButtonConnectUpdate(IsConnected)
	End If
End Sub

Public Sub Connect
	' Ensure to add permission to manifest ACCESS_FINE_LOCATION, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
	Dim Permissions As List
	Dim phone As Phone

	If phone.SdkVersion >= 31 Then
		Permissions = Array("android.permission.BLUETOOTH_SCAN", "android.permission.BLUETOOTH_CONNECT", rp.PERMISSION_ACCESS_FINE_LOCATION)
	Else
		Permissions = Array(rp.PERMISSION_ACCESS_FINE_LOCATION)
	End If
	For Each per As String In Permissions
		rp.CheckAndRequest(per)
		Wait For B4XPage_PermissionResult (Permission As String, Result As Boolean)
		If Result = False Then
			ToastMessageShow("No permission: " & Permission, True)
			Return
		End If
	Next

	' Check if BLE is powered on
	If BLEMgr.State <> BLEMgr.STATE_POWERED_ON Then
		TileEventViewer.Insert("[Connect] Scan failed, BLE not powered on.", HMITileUtils.EVENT_LEVEL_ALARM)
		Log($"[Connect][E] BLE not powered on."$)
	Else
		TileEventViewer.Insert("[Connect] Scan started...", HMITileUtils.EVENT_LEVEL_INFO)
		' Start scanning for devices > raised event Manager_DeviceFound
		BLEMgr.Scan2(Array As String(BLEConstants.SERVICE_UUID), False)
	End If
End Sub

Public Sub Disconnect
	If IsConnected Then
		BLEMgr.Disconnect
		BLEScanTimer.Enabled = False
	End If
End Sub

' BLEMgr_DeviceFound
' Event triggered by manager.scan/scan2.
Sub BLEMgr_DeviceFound (Name As String, Id As String, AdvertisingData As Map, RSSI As Double)
'	TileEventViewer.Insert($"[Manager_DeviceFound] Name ${Name}, ID ${Id}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[BLEMgr_DeviceFound][I] name=${Name}, id=${Id}, rssi=${RSSI}, advertisingdata=${AdvertisingData}"$)
	
	If Name == BLEConstants.BLE_DEVICE_NAME Then
'	If Id = "6D:D4:F2:0C:A4:74" Then
		BLEMgr.StopScan
		TileEventViewer.Insert($"[Manager_DeviceFound] Connecting to ${Name}, ID ${Id}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Log($"[Manager_DeviceFound][I] connecting to ${Name}"$)
		IsDeviceFound = True
		BLEScanTimer.Enabled = False
		' Disabling auto connect can make the connection quicker
		BLEMgr.Connect2(Id, False)
	End If
End Sub

' BLEMgr_Connected
' Event triggered by BLEMgr.connect/connect2.
Sub BLEMgr_Connected (services As List)
	Log($"[BLEMgr_Connected] services=${services}"$)
	IsConnected = True
	' Set notify flag. Note UUIDs must be lowercase
	BLEMgr.SetNotify(BLEConstants.SERVICE_UUID.ToLowerCase, BLEConstants.CHAR_UUID_RX.ToLowerCase, True)
	TileButtonConnectUpdate(IsConnected)
	TileEventViewer.Insert($"[BLEMgr_Connected] OK"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[BLEMgr_Connected] OK"$)
	LCD.Clear
	LCD.SetText(0, 0, "Client")
	LCD.SetText(1, 0, "Connected")
End Sub

Sub BLEMgr_Disconnected
	If Not(IsConnected) Then Return
	IsConnected = False
	SetTilesInitialState
	TileEventViewer.Insert($"[BLEMgr_Disconnected] OK"$, HMITileUtils.EVENT_LEVEL_WARNING)
	Log($"[BLEMgr_Disconnected] OK"$)
End Sub

' BLEMgr_DataAvailable
' Received data from the service.
Sub BLEMgr_DataAvailable (ServiceId As String, Characteristics As Map)
	Log($"[BLEMgr_DataAvailable] serviceid=${ServiceId}, characteristics=${Characteristics}"$)
	For Each id As String In Characteristics.Keys
		' The CHAR_UUID_RX is used to read the data (byte array)
		' [BLEMgr_DataAvailable] serviceid=6e400001-b5a3-f393-e0a9-e50e24dcca9e, characteristics={6e400003-b5a3-f393-e0a9-e50e24dcca9e=[B@54eaf38}
		If id == BLEConstants.CHAR_UUID_RX.tolowercase Then
			Dim data() As Byte = Characteristics.Get(id)
			TileEventViewer.Insert($"[Manager_DataAvailable] data=${Convert.HexFromBytes(data)}"$, HMITileUtils.EVENT_LEVEL_INFO)

			Log($"[BLEMgr_DataAvailable] data=${Convert.HexFromBytes(data)}"$)
			' [BLEMgr_DataAvailable] data=0904123F
			' Example data for device id=09 (DHT11), command 04 (GET_VALUE), data=123F=temperature HEX 12 (DEC 18), humidity HEX 3F (DEC 63)
			' [BLEMgr_DataAvailable] data=0D0201
			' Example data for device id=0D (PIR SENSOR), command 02 (GET_STATE), data=01 (detected)

			' Process BLE data
			ProcessBLE(data)
		End If		
	Next
End Sub

Sub BLEMgr_StateChanged (State As Int)
	Dim statetext As String
	Select State
		Case BLEMgr.STATE_POWERED_OFF
			statetext = "POWERED OFF"
		Case BLEMgr.STATE_POWERED_ON
			statetext = "POWERED ON"
		Case BLEMgr.STATE_UNSUPPORTED
			statetext = "UNSUPPORTED"
	End Select
	TileEventViewer.Insert($"[Manager_StateChanged] ${statetext}"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub
#End If
#End Region

' ================================================================
' B4J BLE MANAGER
' ================================================================
#Region B4J-BLE-MANAGER
' HandleBLEConnect
' Set the connect button state.
' Parameters:
'	state Boolean - True connected else disconnected
Public Sub HandleBLEConnect(state As Boolean)
	If state Then
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Connected"} to ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
		LCD.Clear
		LCD.SetText(0, 0, "Client")
		LCD.SetText(1, 0, "Connected")
	Else
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Disconnected"} from ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
	IsConnected = state
	TileButtonConnectUpdate(IsConnected)
End Sub

' HandleBLENotification
' Process the data received from BLE notify.
' Get the device id as first byte and then parse the data according device byte pattern.
' Parameters:
'	data Byte Array - Response from the BLE device
Public Sub HandleBLENotification(payload() As Byte)
	Dim item As String = $"[HandleBLENotification] value=${Convert.ByteConv.HexFromBytes(payload)}"$

	TileEventViewer.Insert(item, HMITileUtils.EVENT_LEVEL_INFO)

	ProcessBLE(payload)
End Sub
#End Region

' ================================================================
' BLE PROCESS DATA
' ================================================================
#Region BLE Process Data
Private Sub ProcessBLE(payload() As Byte)
	Dim m As Map
	' Get the device id
	Dim deviceid As Byte = payload(0)
	
	' Select the device and parse the payload (see device code modules)
	Select deviceid
		Case BLEConstants.DEV_YELLOW_LED
			Dim datayellowled As TDevYellowLED = YellowLED.Parse(payload)
			TileEventViewer.Insert($"[ProcessBLE] YellowLED state=${datayellowled.State}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_BUZZER
			Dim databuzzer As TDevBuzzer= Buzzer.Parse(payload)
			TileEventViewer.Insert($"[ProcessBLE] Buzzer state=${databuzzer.State}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_MOISTURE
			m = MoistureSensor.Parse(payload)
			Dim v As Int = m.Get("value")
			TileSensorMoisture.Value = Convert.ValueToPercent(v, 4095)
			If v > 0 Then
				TileButtonAlarm.SetWarning("Raining")
			End If

		Case BLEConstants.DEV_DHT11
			Dim datadht11 As TDevDHT11 = DHT11.Parse(payload)
			TileSensorTemperature.SetValue(datadht11.Temperature)
			TileSensorHumidity.SetValue(datadht11.Humidity)
			TileEventViewer.Insert($"[ProcessBLE] DHT11 t=${datadht11.Temperature},h=${datadht11.Humidity}"$, HMITileUtils.EVENT_LEVEL_INFO)

		Case BLEConstants.DEV_PIR_SENSOR
			m = PIRSensor.Parse(payload)
			Dim value As Byte = m.get("value")
			If value == 1 Then
				TileSensorPIR.Value = "Detected"
				TileSensorPIR.SetStyleWarning
			Else
				TileSensorPIR.Value = "Cleared"
				TileSensorPIR.SetStyleNormal
			End If

		Case BLEConstants.DEV_GAS_SENSOR
			m = GasSensor.Parse(payload)
			Dim value As Byte = m.get("value")
			TileSensorGas.Value = value
			If value == 0 Then
				TileSensorGas.Value = "Detected"
				TileSensorGas.SetStyleAlarm
			Else
				TileSensorGas.Value = "Cleared"
				TileSensorGas.SetStyleNormal
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
End Sub
#End Region

' ================================================================
' UI
' ================================================================

' SetTilesInitialState
' Set all tiles to its initial state.
' The string "--" indicates, no value received.
Private Sub SetTilesInitialState
	TileButtonConnect.SetStateFontFontAwesome
	TileButtonConnectUpdate(IsConnected)
	TileButtonYellowLEDUpdate(False)
	#If B4J
	TileButtonRGBLEDUpdate(False)	
	#End If
	TileButtonDoorUpdate(False)
	TileButtonWindowUpdate(False)
	TileButtonFanUpdate(False)
	TileButtonEventsUpdate(False)
	TileButtonAlarm.SetInfo("--")
	TileSensorPIR.Value = "--"
	TileSensorPIR.SetStyleNormal
	TileSensorGas.Value = "--"
	TileSensorMoisture.Value = "--"
	TileSensorTemperature.Value = "--"
	TileSensorHumidity.Value = "--"
End Sub

#Region TileButtonConnect_Click
' TileButtonConnect_Click
' Connect or disconnect from the BLE device.
Private Sub TileButtonConnect_Click
	' Connect
	If Not(IsConnected) Then
		TileButtonConnect.StateText = Chr(0xF252)
		TileEventViewer.Insert($"[TileButtonConnect_Click] Connecting to ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
		#if B4A
		BLEScanTimer.Enabled = True
		Connect
		TileButtonConnectUpdate(True)
		#End If

		#if B4J
		' Scan and connect > see event handlebleconnect
		Wait For (BLEMgr.Scan) Complete (Success As Boolean)
		If Not(Success) Then
			TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
		End If
		#End If
		Return		
	End If

	' Disconnect
	If IsConnected Then
		TileButtonConnect.StateText = Chr(0xF252)
		TileEventViewer.Insert($"[TileButtonConnect_Click] Disconnecting from ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_WARNING)
		#if B4A
		Disconnect
		TileButtonConnectUpdate(False)
		#End If
		
		#if B4J
		' Disconnect > see event PyBridgeDisconnected
		Wait For(BLEMgr.Disconnect) Complete (Success As Boolean)
		If Not(Success) Then
			TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
		End If
		#End If
		Return	
	End If
End Sub

' Update the button UI color & text.
Private Sub TileButtonConnectUpdate(state As Boolean)
	If Not(TileButtonConnect.IsInitialized) Then Return
	TileButtonConnect.State = state
	TileButtonConnect.StateText = IIf(state, Chr(0xF0C1), Chr(0xF127))
End Sub
#End Region

#Region TileButtonYellowLED
' Set the yellow led state ON or OFF
Private Sub TileButtonYellowLED_Click
	If Not(IsConnected) Then
		TileEventViewer.Insert($"[TileButtonYellowLED_Click] BEL not connected."$, HMITileUtils.EVENT_LEVEL_WARNING)
		Return
	End If
	Dim state As Boolean = Not(YellowLED.Get)
	' Set the device
	YellowLED.Set(state)
	' Update the tile
	TileButtonYellowLEDUpdate(state)
End Sub

' Update the button UI color & text.
Public Sub TileButtonYellowLEDUpdate(state As Boolean)
	If Not(TileButtonYellowLED.IsInitialized) Then Return
	TileButtonYellowLED.State = state
	TileButtonYellowLED.StateText = Convert.BoolToOnOff(state)
	Log($"[TileButtonYellowLEDUpdate] state=${state}"$)
End Sub
#End Region

Private Sub TileSensorTemperature_Click
	If Not(IsConnected) Then Return
	BLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 Array As Byte(BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE))
	Log($"[TileSensorTemperature_Click] done"$)
End Sub

Private Sub TileSensorHumidity_Click
	If Not(IsConnected) Then Return
	BLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 Array As Byte(BLEConstants.DEV_DHT11, BLEConstants.CMD_GET_VALUE))
	Log($"[TileSensorHumidity_Click] done"$)
End Sub

Private Sub TileSensorMoisture_Click
	If Not(IsConnected) Then Return
	BLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
					 BLEConstants.CHAR_UUID_TX.ToLowerCase, _ 
					 Array As Byte(BLEConstants.DEV_MOISTURE, BLEConstants.CMD_GET_VALUE))
	Log($"[TileSensorMoisture_Click] done"$)
End Sub
#End Region

#Region Buzzer
Private Sub TileButtonPlayAlarm_Click
	If Not(IsConnected) Then Return
	Buzzer.PlayAlarm(0x01, 0x01)
	Log($"[TileButtonAlarm_Click] mode=1, repeats=1, done"$)
End Sub

Private Sub TileButtonPlayTone_Click
	If Not(IsConnected) Then Return
	Buzzer.PlayTone(440, 500)
	Log($"[TileButtonPlayTone_Click] f=440, d=500, done"$)
End Sub
#End Region

#Region Alarm
Private Sub TileButtonAlarm_Click
	If Not(IsConnected) Then Return
	TileButtonAlarm.SetInfo("Cleared")
	TileEventViewer.Insert($"[TileButtonAlarm_Click] Cleared"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub
#End Region

#Region RGBLED
Private Sub TileButtonRGBLED_Click
	If Not(IsConnected) Then
		TileEventViewer.Insert($"[TileButtonRGBLED_Click] BLE not connected."$, HMITileUtils.EVENT_LEVEL_WARNING)
		Return
	End If
	' Set the device
	If Not(RGBLED.IsOn) Then
		RGBLED.SetColor(10,10,10)
	Else
		RGBLED.SetOff		
	End If
	' Update the tile
	TileButtonRGBLEDUpdate(RGBLED.IsOn)
End Sub

' Update the button UI color & text.
Public Sub TileButtonRGBLEDUpdate(state As Boolean)
	If Not(TileButtonRGBLED.IsInitialized) Then Return
	TileButtonRGBLED.State = state
	TileButtonRGBLED.StateText = Convert.BoolToOnOff(state)
	Log($"[TileButtonRGBLEDUpdate] state=${state}"$)
End Sub

#If B4J
Private Sub TileRGBLED_ValueChanged(m As Map)
	If Not(IsConnected) Then
		TileEventViewer.Insert($"[TileButtonRGBLED_ValueChanged] BLE not connected."$, HMITileUtils.EVENT_LEVEL_WARNING)
		Return
	End If
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
#End Region
#End If

#Region Door
Private Sub TileButtonDoor_Click
	If Not(IsConnected) Then Return
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
	If Not(IsConnected) Then Return
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
Private Sub TileSensorPIR_Click
	PIRSensor.SetEnabled(Not (PIRSensor.GetEnabled))
	TileEventViewer.Insert($"[TileSensorPIR] enabled=${PIRSensor.GetEnabled}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[TileSensorPIR] enabled=${PIRSensor.GetEnabled}"$)
End Sub
#End Region

#Region Gas Sensor
Private Sub TileSensorGas_Click
	
End Sub
#End Region

#Region Fan
Private Sub TileButtonFan_Click
	If Not(IsConnected) Then Return
	Dim state As Boolean = Not(Fan.IsOn)
	Fan.Set(state)
	TileButtonFanUpdate(state)
	Log($"[TileButtonFan_Click] state=${state}"$)
End Sub

Private Sub TileButtonFanUpdate(state As Boolean)
	If Not(TileButtonFan.IsInitialized) Then Return
	TileButtonFan.StateText = Convert.BoolToOnOff(state)
	TileButtonFan.SetStateColor(state)
'	Log($"[TileButtonFanUpdate] state=${state}"$)
End Sub
#End Region

#Region Fan
Private Sub TileButtonEvents_Click
	If Not(IsConnected) Then Return
	Dim state As Boolean = Not(System.GetEventsEnabled)
	System.SetEventsEnabled(state)
	TileButtonEventsUpdate(state)

	' Option to immediate get the state
	TileSensorTemperature_Click
	TileSensorMoisture_Click
	TileSensorPIR_Click

	Log($"[TileButtonEvents_Click] state=${state}"$)
End Sub

Private Sub TileButtonEventsUpdate(state As Boolean)
	If Not(TileButtonEvents.IsInitialized) Then Return
	TileButtonEvents.StateText = Convert.BoolToOnOff(state)
	TileButtonEvents.SetStateColor(state)
'	Log($"[TileButtonEventsUpdate] state=${state}"$)
End Sub
#End Region

#Region TileEventViewer/Info
#if B4J
Private Sub TileEventViewer_Click(EventData As MouseEvent)
	Log(BLEMgr.LastMsg)
End Sub
#end if

Private Sub TileEventViewer_ItemClick (Index As Int, Value As Object)
	
End Sub

'Private Sub TileLabelInfo_Click(EventData As MouseEvent)
'	If Root.Tag.As(String).Length == 0 Then Root.Tag = 0
'	If Root.Tag.As(Byte) == 0 Then
'		HMITileUtils.EnableHMITileGrid(Root)
'		Root.Tag = 1
'	Else
'		HMITileUtils.DisableHMITileGrid
'		Root.Tag = 0
'	End If
'End Sub
#End Region
