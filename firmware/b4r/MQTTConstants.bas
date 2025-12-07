B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Code Module Info
' File:			MQTTConstants.bas
' Brief:		homekit32 MQTT constants for topics etc.
' Notes:		MQTT project prefix: homekit32
#End Region

'These global variables will be declared once when the application starts.
'Public variables can be accessed from all modules.
Sub Process_Globals

	' Client
	Public CLIENT_ID As String = "homekit32client"

	' State
	Public KEY_STATE As String = "state"
	Public STATE_ON As String = "on"
	Public STATE_OFF As String = "off"

	'================================================
	' YellowLed
	'================================================
	' Topics
	' Client sends set the state of the Yellow Led to on or off
	Public TOPIC_YELLOW_LED_SET As String = "homekit32/home1/yellow_led/set"
	' Clien requests the ESP32 to report current LED state on or off
	Public TOPIC_YELLOW_LED_STATUS As String = "homekit32/home1/yellow_led/status"
	' Payloads
	Public PAYLOAD_YELLOW_LED_ON As String = "{""state"":""on""}"
	Public PAYLOAD_YELLOW_LED_OFF As String = "{""state"":""off""}"

	' MORE
End Sub
