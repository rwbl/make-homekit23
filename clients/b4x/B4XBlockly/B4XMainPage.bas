B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Class Header
' File:			HK32Blockly
' Brief:		Client controlling the HomeKit32 via BLE using Blockly.
' Date:			2025-12-07
' Author:		Robert W.B. Linn (c) 2025 MIT
' Description:	This B4J application (app) connects as a client with an ESP32 running as Bluetooth Low Energy (BLE) server.
'				The BLE-Server advertises DHT22 sensor data temperature & humidity and listens to commands send from connected clients.
'				The communication between the B4J-Client and the BLE-Server is managed by the PyBridge with Bleak.
'				The data is passed thru the PyBridge and to be handled by client or BLE server.
' Software: 	B4J 10.30(64 bit), Java JDK 19
' Libraries:	PyBridge 1.00, Bleak 1.02, ByteConverter 1.10
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
	Private Const VERSION As String = "HK32Blockly v20251209"
	
	' UI
	Private Root As B4XView
	Private xui As XUI
	Private TileEventViewer As HMITileEventViewer
	Private PaneBlockly As B4XView
	Private WebViewBlockly As WebView
	Private ButtonTest As B4XView

	' BLE
	#if B4A
	Private BLEMgr As BleManager2
	Private rp As RuntimePermissions
	#end if
	#if B4J
	Public BLEMgr As BLEManager
	#End If
	Private IsConnected As Boolean = False
	
	' BLE Commands
	Private Commands As BLECommands
End Sub

#Region B4XPages
Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	' Load the commands
	Commands.Initialize

	Root = Root1
	' Load layout case sensitive
	Root.LoadLayout("MainPage")

	' UI - CustomView require short sleep
	PaneBlockly.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND
	Sleep(1)
	B4XPages.SetTitle(Me, VERSION)
	TileEventViewer.Title = $"Event Log"$
	
	' WebViewBlockly Initialize
	' Load Blockly HTML. JS will be injected in PageFinished (after load).
	Dim htmlUri As String = File.GetUri(File.DirApp, "blockly_index.html") ' adjust if needed
	TileEventViewer.Insert($"[B4XPage_Created] Loading Blockly HTML from: ${htmlUri}"$, HMITileUtils.EVENT_LEVEL_INFO)
	WebViewBlockly.LoadUrl(htmlUri)

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
	Disconnect
	#End If

	#if B4J
	BLEMgr.PyBridgeKillProcess
	#End If
End Sub

Private Sub B4XPage_Appear
	#if B4A
	If Not(IsConnected) Then
		Connect
	end if
	#End If
End Sub

' These subs are triggered by the BLEMgr pybridge events
#if B4J
Public Sub PyBridgeDisconnected
	TileEventViewer.Insert($"[PyBridgeDisconnected] ${"Disconnected"}"$, HMITileUtils.EVENT_LEVEL_WARNING)
End Sub
#End If

' ================================================================
' B4A BLE MANAGER
' ================================================================
#Region B4A-BLE-Manager
#if B4A
Public Sub Connect
	' Ensure to add permission to manifest
	' AddPermission(android.permission.ACCESS_FINE_LOCATION)
	' AddPermission(android.permission.BLUETOOTH_SCAN)
	' AddPermission(android.permission.BLUETOOTH_CONNECT)
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
	TileEventViewer.Insert($"[BLEMgr_Connected] OK, set flag notify"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[BLEMgr_Connected] OK, set flag notify"$)
End Sub

Sub BLEMgr_Disconnected
	If Not(IsConnected) Then Return
	IsConnected = False
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
' Log the state.
' For B4J disconnect is handled by the sub PyBridgeDisconnected.
' Parameters:
'	state Boolean - True connected else disconnected
Public Sub HandleBLEConnect(state As Boolean)
	If state Then
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Connected"} to ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Disconnected"} from ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
	IsConnected = state
End Sub

' HandleBLENotification
' Process the data received from BLE notify.
' Get the device id as first byte and then parse the data according device byte pattern.
' Parameters:
'	data Byte Array - Response from the BLE device
Public Sub HandleBLENotification(data() As Byte)
	Dim item As String

	item = $"[HandleBLENotification] value=${Convert.ByteConv.HexFromBytes(data)}"$
	TileEventViewer.Insert(item, HMITileUtils.EVENT_LEVEL_INFO)
End Sub
#End Region

' ================================================================
' WEBVIEW
' ================================================================
#Region WebViewBlockly
' ------------------------------
' Page finished: inject bridge and console log redirection
' ------------------------------
Private Sub WebViewBlockly_PageFinished (Url As String)
	TileEventViewer.Insert($"[WebViewBlockly_PageFinished] url=${Url}"$, HMITileUtils.EVENT_LEVEL_INFO)
	' Create the webview engine object
	Dim engine As JavaObject = GetEngine(WebViewBlockly)

	' Set javascript enabled for the webengine
	engine.RunMethod("setJavaScriptEnabled", Array(True))

	' Create an EventHandler so JS alert() calls come to WebViewBlockly_Event.
	' (This makes JS alert messages appear in your B4J logs via WebViewBlockly_Event.)
	Dim ev As Object = engine.CreateEvent("javafx.event.EventHandler", "WebViewBlockly", False)
	engine.RunMethod("setOnAlert", Array(ev))
	TileEventViewer.Insert($"[WebViewBlockly_PageFinished] alert redirection for receiving generated code"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub

' This receives JS alert() messages (via setOnAlert event handler) from the webview
Sub WebViewBlockly_Event(MethodName As String, Args() As Object)
	If Args.Length > 0 Then
		Dim joWebEvent As JavaObject = Args(0)
		Dim msg As String = joWebEvent.RunMethod("getData", Null)
		AppLog(msg)
		TileEventViewer.Insert($"[WebViewBlockly_Event] msg=${msg}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Try
			Dim parser As JSONParser
			parser.Initialize(msg)
			Dim jRoot As Map = parser.NextObject
			Dim command As String = jRoot.Get("command")
			If command == "start" Then TileEventViewer.Clear
			TileEventViewer.Insert($"[WebViewBlockly_Event] command=${command}"$, HMITileUtils.EVENT_LEVEL_INFO)
			AppLog($"[WebViewBlockly_Event] ${command}"$)
			RunCommand(Commands.Find(command.Replace("_", " ")))
		Catch
			AppLog($"[WebViewBlockly_Event][E] ${LastException}"$)
		End Try
	End If
End Sub

Private Sub RunCommand(command As TCommand)
	AppLog($"[RunCommand] ${command}"$)

	' Check if there is a command
	If command.IsInitialized Then

		' Handle system commands first
		If command.DeviceId == BLEConstants.DEV_SYSTEM Then
			' BLE Connect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_ON Then
				If Not(IsConnected) Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Connecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
					#if B4A
					Connect
					#End If
					
					#if B4J
					' Scan and connect > see event handlebleconnect
					Wait For (BLEMgr.Scan) Complete (Success As Boolean)
					If Not(Success) Then
						TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
					End If
					#End If
				End If
			End If
			
			' BLE Disconnect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_OFF Then
				If IsConnected Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Disconnecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_WARNING)
					#if B4A
					Disconnect
					#End If
					
					#if B4J
					' Disconnect > see event PyBridgeDisconnected
					Wait For(BLEMgr.Disconnect) Complete (Success As Boolean)
					If Not(Success) Then
						TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
					End If
					#End If
				End If
			End If
			Return
		End If
		
		' Handle device commands
		#if B4A
		If IsConnected Then
			BLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
							 BLEConstants.CHAR_UUID_TX.ToLowerCase, _
							 Commands.BuildPayload(command))
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command succesful ${command.Name}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Else
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command failed, BLE not connected."$, HMITileUtils.EVENT_LEVEL_ALARM)
			Return
		End If
		#End If

		#if B4J
		' Handle device commands
		If BLEMgr.IsConnected Then
			BLEMgr.Write(Commands.BuildPayload(command))
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command succesful ${command.Name}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Else
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command failed, BLE not connected."$, HMITileUtils.EVENT_LEVEL_ALARM)
			Return
		End If
		#End If
	End If
End Sub

' ------------------------------
' Execute button - user triggers sending command to hardware
' ------------------------------
Private Sub ButtonTest_Click
	' Create the webview engine object
	Dim engine As JavaObject = GetEngine(WebViewBlockly)
	Dim obj As Object = engine.RunMethod("executeScript", Array("updateDeviceState('yellow_led', 'ON')"))
	Dim tempValue As Float = 22.3
	Dim humValue As Float = 54
	obj = engine.RunMethod("executeScript", Array($"updateDeviceDHT11(${tempValue},${humValue})"$))
	Log(obj)
End Sub

' ------------------------------
' Logging Helper
' ------------------------------
Public Sub AppLog(sEntry As String)
	Log(DateTime.Date(DateTime.Now) & " " & DateTime.Time(DateTime.Now) & ": " & sEntry)
End Sub

' ------------------------------
' Helper to access the WebEngine via JavaObject
' ------------------------------
Sub GetEngine(wv As WebView) As JavaObject
	Dim jo As JavaObject = wv
	Return jo.RunMethod("getEngine", Null)
End Sub
#end region
