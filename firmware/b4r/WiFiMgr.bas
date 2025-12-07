B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:			WiFiMgr.bas
' Project:		make-homekit32
' Brief:		WiFi methods.
' 				Credentials defines as process_globals (change accordingly).
' 				There is a 15 seconds timeout in the synchronous Connect methods.
'				- This is implemented in the library code (rESP8266WiFi.cpp - line 33 - 41).
' 				- There is no similar timeout in the async method. It simply polls the connection state.
' Date:			2025-11-08
' Author:		Robert W.B. Linn (c) 2025 MIT
' MQTT:			n/a
' Dependencies:	rESP8266WiFi
' ================================================================
#End Region

Private Sub Process_Globals
	' WiFi
	Private SSID As String		= "***"
	Private Password As String	= "***"
	Private WiFi As ESP8266WiFi
	
	' Public vars
	Public Connected As Boolean	= False
	Public Client As WiFiSocket
End Sub

' Connect to the WiFi network
' Return Boolean
' Retval True connected
' Retval False connection failed
Public Sub Connect As Boolean
	' Disable WiFi sleep to ensure stable timing (important for servos)
	RunNative("DisableWifiSleep", Null)
	
	
	If WiFi.Connect2(SSID, Password) Then
		Log("[WiFiMgr.Connect][I] OK, ip=", WiFi.LocalIp)
		Return True
	Else
		Log("[WiFiMgr.Connect][E] Can not connect to the network.")
		Return False
	End If
End Sub

#If C
// Disable WiFi sleep (if small servo delay still happens).
// Sometimes WiFi background tasks cause timing jitter.
void DisableWifiSleep(B4R::Object* o) {
    WiFi.setSleep(false);
}
#End If
