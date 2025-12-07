B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Class Header
' File:			HK32Commander
' Brief:		Client controlling the HomeKit32 via BLE using commands.
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
#End Region

#CustomBuildAction: after packager, %WINDIR%\System32\robocopy.exe, Python temp\build\bin\python /E /XD __pycache__ Doc pip setuptools tests

Sub Class_Globals
	Private VERSION As String	= "HomeKit32 Commander v20251201"
	Private COPYRIGHT As String = "Keyestudio Smart Home KIT ESP32 control by Robert W.B. Linn (c) 2025 MIT"

	' UI
	Private xui As XUI
	Private Root As B4XView
	Private TileListCommands As HMITileList
	Private TileEventViewer As HMITileEventViewer
	Private LabelInfo As B4XView

	' BLE
	Public BLEMgr As BLEManager				' Global as used by the DevNAME modules
	Private Commands As BLECommands
End Sub

Public Sub Initialize
	
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	' Layout
	Root = Root1
	' Load the layout
	Root.LoadLayout("MainPage")

	' Initialize Command List
	Commands.Initialize

	' UI
	B4XPages.SetTitle(Me, VERSION)
	B4XPages.GetNativeParent(Me).Resizable = False
	Root.Color = HMITileUtils.COLOR_BACKGROUND_SCREEN
	LabelInfo.Text = COPYRIGHT
	LabelInfo.TextColor = HMITileUtils.COLOR_TEXT_SECONDARY
	
	' CV require short sleep else not initialized message
	Sleep(1)
	' Add the list of commands
	TileListCommandsAddAll
	
	' Initialize BLEMgr
	BLEMgr.Initialize(B4XPages.GetPage("MainPage"))
	Wait For (BLEMgr.Start) complete (result As Boolean)
	If result Then
		TileEventViewer.Insert($"[B4XPage_Created] PyBridge started, BLE initialized ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[B4XPage_Created] Failed to start the PyBridge initialize BLE"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
End Sub

Private Sub B4XPage_Background
	BLEMgr.PyBridgeKillProcess
End Sub

#Region PyBridge
' These subs are triggered by the BLEMgr pybridge events

Public Sub PyBridgeDisconnected
	TileEventViewer.Insert($"[PyBridgeDisconnected] ${"Disconnected"}"$, HMITileUtils.EVENT_LEVEL_WARNING)
End Sub
#End Region

#Region BLE
' HandleBLEConnect
' Set the connect button state.
' Parameters:
'	state Boolean - True connected else disconnected
Public Sub HandleBLEConnect(state As Boolean)
	If state Then
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Connected"} to ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
	Else
		TileEventViewer.Insert($"[HandleBLEConnect] ${"Disconnected"} from ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_ALARM)
	End If
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

#Region TileListCommands
' TileListCommandsAddAll
' Add all commands from the commands list
Private Sub TileListCommandsAddAll
	For Each command As TCommand In Commands.ListCommands
		TileListCommands.Add(command.Name, command.Description, command)
	Next
End Sub

Private Sub TileListCommands_ItemClick (Index As Int, Value As Object)
	Dim command As TCommand = Value
	' Check if there is a command
	If command.IsInitialized Then

		' Handle system commands first
		If command.DeviceId == BLEConstants.DEV_SYSTEM Then
			' BLE Connect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_ON Then
				If Not(BLEMgr.IsConnected) Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Connecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
					Wait For (BLEMgr.Scan) Complete (Success As Boolean)
					If Not(Success) Then
						TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
					End If
				End If
			End If
			' BLE Disconnect - see also HandleBLEConnect
			If command.Value(0) = BLEConstants.STATE_OFF Then
				If BLEMgr.IsConnected Then
					TileEventViewer.Insert($"[TileListCommands_ItemClick] Disconnecting... ${BLEConstants.BLE_DEVICE_NAME}"$, HMITileUtils.EVENT_LEVEL_INFO)
					Wait For(BLEMgr.Disconnect) Complete (Success As Boolean)
					If Not(Success) Then
						TileEventViewer.Insert(BLEMgr.LastMsg, HMITileUtils.EVENT_LEVEL_ALARM)
					End If
				End If
			End If
			Return
		End If
		
		' Handle device commands
		If BLEMgr.IsConnected Then
			BLEMgr.Write(Commands.BuildPayload(command))
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command succesful ${command.Name}"$, HMITileUtils.EVENT_LEVEL_INFO)
		Else
			TileEventViewer.Insert($"[TileListCommands_ItemClick] Command failed, BLE not connected."$, HMITileUtils.EVENT_LEVEL_ALARM)
			Return
		End If
	End If
End Sub
#End Region

#Region EventViewer
Private Sub TileEventViewer_ItemClick (Index As Int, Value As Object)
	Log($"$[TileEventViewer_ItemClick] index=${Index}, value=${Value}"$)
End Sub
#End Region

