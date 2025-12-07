B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Class Header
' File:			HK32Commander
' Brief:		Android client controlling the HomeKit32 via BLE using commands.
'				B4i is not supported.
' Date:			2025-12-01
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
' Tools:
'				Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
'				Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=BLEExample.zip
#End Region

#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
#End Region

Sub Class_Globals
	Private Const VERSION As String = "HK32Commander v20251201"
	
	' UI
	Private Root As B4XView
	Private xui As XUI
	Private TileListCommands As HMITileList
	Private TileEventViewer As HMITileEventViewer
	Private LabelInfo As B4XView

	' BLE
	#if B4A
	Private BLEMgr As BleManager2
	Private rp As RuntimePermissions
	#end if
	Private IsConnected As Boolean = False
	Private Commands As BLECommands
End Sub

#Region B4XPages
Public Sub Initialize
	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	Root.LoadLayout("mainpage")

	' UI
	B4XPages.SetTitle(Me, VERSION)

	' CustomView require short sleep
	Sleep(1)
	' Add the list of commands
	' Initialize Command List
	Commands.Initialize
	TileListCommandsAddAll
	
	' BLE
	BLEMgr.Initialize("BLEMgr")
	StateChanged
End Sub

' B4XPage_Disappear
' If page disappears, disconnect from BLE to ensure it is not blocking other clients.
Private Sub B4XPage_Disappear
	Disconnect
End Sub

#End Region

#Region Scanning
Public Sub Connect
	' Ensure to add permission to manifest: ACCESS_FINE_LOCATION, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
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
		TileEventViewer.Insert("[Connect][I] Scan started...", HMITileUtils.EVENT_LEVEL_INFO)
		' Start scanning for devices > raised event Manager_DeviceFound
		BLEMgr.Scan2(Array As String(BLEConstants.SERVICE_UUID), False)
	End If
End Sub

Public Sub Disconnect
	If IsConnected Then
		BLEMgr.Disconnect
		BLEMgr_Disconnected
		TileEventViewer.Insert("[Disconnect] OK.", HMITileUtils.EVENT_LEVEL_WARNING)
	End If
End Sub
#End Region

#Region BLEManager
' BLEMgr_DeviceFound
' Event triggered by BLEMgr.scan/scan2.
Sub BLEMgr_DeviceFound (Name As String, Id As String, AdvertisingData As Map, RSSI As Double)
'	TileEventViewer.Insert($"[Manager_DeviceFound] Name ${Name}, ID ${Id}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[BLEMgr_DeviceFound][I] name=${Name}, id=${Id}, rssi=${RSSI}, advertisingdata=${AdvertisingData}"$)
	
	If Name == BLEConstants.BLE_DEVICE_NAME Then
'	If Id = "6D:D4:F2:0C:A4:74" Then
		BLEMgr.StopScan
		TileEventViewer.Insert($"[Manager_DeviceFound] Connecting to ${Name}, ID ${Id}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Log($"[BLEMgr_DeviceFound][I] connecting to ${Name}"$)
		' Disabling auto connect can make the connection quicker
		BLEMgr.Connect2(Id, False)
	End If
End Sub

' BLEMgr_Connected
' Event triggered by BLEMgr.connect/connect2.
Sub BLEMgr_Connected (services As List)
	Log($"[BLEMgr_Connected][I] services=${services}"$)
	IsConnected = True
	LabelInfo.Text = "Connected"
	' Set notify flag. Note UUIDs must be lowercase
	BLEMgr.SetNotify(BLEConstants.SERVICE_UUID.ToLowerCase, BLEConstants.CHAR_UUID_RX.ToLowerCase, True)

	TileEventViewer.Insert($"[BLEMgr_Connected] Connected"$, HMITileUtils.EVENT_LEVEL_INFO)
	Log($"[BLEMgr_Connected][I] Connected"$)
End Sub

Sub BLEMgr_Disconnected
	Log($"[BLEMgr_Disconnected][I] OK"$)
	IsConnected = False
	LabelInfo.Text = "Disconnected"
	StateChanged
End Sub

' BLEMgr_DataAvailable
' Received data Byte Array from the connected service.
Sub BLEMgr_DataAvailable (ServiceId As String, Characteristics As Map)
	Log($"[BLEMgr_DataAvailable] serviceid=${ServiceId}, characteristics=${Characteristics}"$)
	
	For Each id As String In Characteristics.Keys

		' The CHAR_UUID_RX is used to read the data (byte array)
		' [Manager_DataAvailable] serviceid=6e400001-b5a3-f393-e0a9-e50e24dcca9e, characteristics={6e400003-b5a3-f393-e0a9-e50e24dcca9e=[B@54eaf38}
		If id == BLEConstants.CHAR_UUID_RX.tolowercase Then
			Dim data() As Byte = Characteristics.Get(id)
			TileEventViewer.Insert($"[BLEMgr_DataAvailable] data=${Convert.HexFromBytes(data)}"$, HMITileUtils.EVENT_LEVEL_INFO)
			Log($"[BLEMgr_DataAvailable][I] data=${Convert.HexFromBytes(data)}"$)

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
	TileEventViewer.Insert($"[BLEMgr_StateChanged] ${statetext}"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub

Public Sub StateChanged
	TileEventViewer.Insert($"[StateChanged] connected=${IsConnected}"$, HMITileUtils.EVENT_LEVEL_INFO)
End Sub
#End Region

#Region TileList
' TileListCommandsAddAll
' Add all commands from the commands list.
Private Sub TileListCommandsAddAll
	For Each command As TCommand In Commands.ListCommands
		TileListCommands.Add(command.Name, command.Description, command)
	Next
End Sub

' TileListCommands_ItemClick
' Execute selected command. 
' The first commands are system commands to connect/disconnect to/from HomeKit32 device.
Private Sub TileListCommands_ItemClick (Index As Int, Value As Object)
	Dim command As TCommand = Value
	' Check if the commands list is initialized
	If command.IsInitialized Then
		' Handle system commands first
		If command.DeviceId == BLEConstants.DEV_SYSTEM Then
			' BLE Connect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_ON Then
				If Not(IsConnected) Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Connecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
					Connect
				End If
			End If
			' BLE Disconnect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_OFF Then
				If IsConnected Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Disconnecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
					Disconnect
					BLEMgr_Disconnected
				End If
			End If
			Return
		End If
		
		' Handle device commands
		If IsConnected Then
			BLEMgr.WriteData(BLEConstants.SERVICE_UUID.ToLowerCase, _
							  BLEConstants.CHAR_UUID_TX.ToLowerCase, _
							  Commands.BuildPayload(command))
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command succesful ${command.Name}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Else
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command failed, BLE not connected."$, HMITileUtils.EVENT_LEVEL_ALARM)
			Return
		End If
	End If
	
End Sub
#End Region

