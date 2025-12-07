B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:			MQTTClient.bas
' Project:		make-homekit32
' Brief:		MQTT (Message Queue Telemetry Transport) methods.
' Date:			2025-11-04
' Author:		Robert W.B. Linn (c) 2025 MIT
' MQTT:			Credentials defines as process_globals (change accordingly).
' Dependencies:	rMQTT, rConvert
' ================================================================
#End Region

Private Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'Public variables can be accessed from all modules.

	' Logging flag
	Private LOGGING As Boolean = False

	' Types
	Type TMQTTMessage(topic As String, payload As String)

	' MQTT
	Private MQTT As MqttClient

	Public ID As String 				= "homekit32"

	Private USERNAME As String			= ""
	Private PASSWORD As String			= ""

	Private BROKER_IP () As Byte 		= Array As Byte(NNN,NNN,NNN,NNN)
	Private BROKER_PORT As UInt 		= 1883

	Private RETRIES As Byte				= 5
	Private RetryCounter As Byte		= 0

	Public DELAY_AFTER_TASK As ULong	= 250
	Public Connected As Boolean			= False

	' JSON Parser
	Private QUOTEARRAY() As Byte 		= """"
	Private LastIndex As Int 			= 0			'ignore
End Sub

' Initialize module.
' TODO: Consider enhancing with parameter username As String, password As String, ip() As Byte, port As UInt.
Public Sub Initialize(CLIENTID As String, stream As Stream)
	MQTT.Initialize(stream, BROKER_IP, BROKER_PORT, CLIENTID, "MQTT_MessageArrived", "MQTT_Disconnected")
End Sub

#Region MQTT
' Check if connected to mqtt. if not, then try again after 1 sec.
' This sub can not return true or false, because used by callsubplus. Therefor global connected.
' unused - Mandatory parameter as used for the callsubplus retry
Public Sub Connect(tag As Byte)
	Dim mqttopt As MqttConnectOptions
	mqttopt.Initialize(USERNAME, PASSWORD)

	Connected = MQTT.Connect2(mqttopt)

	If Connected = False Then
		' Log("[MQTTClient.Connect][ERROR] Trying to connect again...Retry #", MQTTRetryCounter)
		Log("[MQTTClient.Connect][W] Trying to connect again...Retry #", RetryCounter)
		RetryCounter = RetryCounter + 1
		If RetryCounter <= RETRIES Then
			CallSubPlus("Connect", 10000, 0)
			Return 'False
		Else
			Log("[MQTTClient.Connect][E] Can not connect to the broker.")
			Return 'False
		End If
	End If
	
	' MQTT connected. Reset the retrycounter
	RetryCounter = 0
	Log("[MQTTClient.Connect][I] OK")
	Delay(500)

	Return 'True
End Sub

' MQTT disconnected.
' If the server is nor reachable, then MQTT is disconnected.
' After 5 seconds, retry to connect again.
Private Sub MQTT_Disconnected
	Log("[MQTTClient.MQTT_Disconnected][W] Disconnected > start retrying.")
	Connected = False
	MQTT.Close

	' Retry MQTT connection after delay (e.g. 10 seconds)
	CallSubPlus("Connect", 10000, 0)
End Sub

' Handle MQTT Message arrived.
' IMPORTANT: In main the event must be created MQTT_MessageArrived(topic, payload)
Private Sub MQTT_MessageArrived(Topic As String, Payload() As Byte)
	' Log("[MQTT_MessageArrived] Topic=", Topic, ", Payload=", Payload)
	CommMQTT.MQTT_MessageArrived(Topic, Payload)
End Sub

' Subscribe to the topics publsihed. Ensure to set QoS to 1 and NOT 0.
' topics - Array with topics.
Public Sub Subscribe(topics() As String)
	If Not(Connected) Then
		Log("[MQTTClient.Subscribe][E] MQTT is not connected.")
		Return
	End If

	' Loop over the topics and add
	For Each Topic As String In topics
		MQTT.Subscribe(Topic, 1)		
	Next
End Sub

' Publish sensor values to the MQTT broker
' messages - Array with messages.
Public Sub Publish(topics() As String, payloads() As String)
	' Leave if not connected
	If Not(Connected) Then
		Log("[MQTTClient.Publish][E] MQTT is not connected.")
		Return
	End If

	For i = 0 To topics.Length - 1
		If LOGGING Then 
			Log("[MQTTClient.Publish][I] topic=", topics(i), ", payload=", payloads(i))
		End If
		PublishChunked(topics(i), payloads(i).GetBytes, True)
		' HINT
		' Publish2 can be used if payload length < 128		
	Next
	'If LOGGING Then Log("[MQTTMod Publish] Done")
End Sub

' Remove topics permanent.
' topics - Array with topics.
Public Sub Remove(topics() As String)
	' Leave if not connected
	If Not(Connected) Then
		Log("[MQTTClient.Remove][E] MQTT is not connected.")
		Return
	End If
	
	' Empty payload to remove the autodiscovery config topic
	Dim b() As Byte = Array As Byte()

	For i = 0 To topics.Length - 1
		If LOGGING Then
			Log("[MQTTClient.Remove][I] topic=", topics(i))
		End If
		MQTT.Publish2(topics(i), b, True)
	Next
	Log("[MQTTClient.Remove][I]  Done")
End Sub

' Sends a large MQTT message in chunks
' Parameters:
'   topic - the topic string (e.g. "homeassistant/sensor/xyz/config")
'   payload() - the payload as a byte array
'   retain - whether to retain the message on the broker
Private Sub PublishChunked(topic As String, payload() As Byte, retain As Boolean)
	Dim length As Int = payload.Length
	Dim result As Boolean
	Dim CHUNK_SIZE As Int = 32
	Dim buffer(CHUNK_SIZE) As Byte

	If LOGGING Then
		Log("[MQTTClient.PublishChunked][I] topic=", topic)
	End If

	If MQTT.BeginPublish(topic, length, retain) = False Then
		Log("[MQTTClient.PublishChunked][E] BeginPublish failed.")
		Return
	End If

	Dim i As Int
	Do While i < length
		Dim remaining As Int = length - i
		Dim thisChunkSize As Int = Min(CHUNK_SIZE, remaining)

		' Copy this chunk into the buffer
		For j = 0 To thisChunkSize - 1
			buffer(j) = payload(i + j)
		Next

		' Create an exact-size array to pass
		Dim actualChunk(thisChunkSize) As Byte
		For j = 0 To thisChunkSize - 1
			actualChunk(j) = buffer(j)
		Next

		result = MQTT.WriteChunk(actualChunk)
		If result = False Then
			Log("[MQTTClient.PublishChunked][E] WriteChunk failed at offset ", i)
			MQTT.EndPublish
			Return
		End If

		i = i + thisChunkSize
	Loop

	result = MQTT.EndPublish
	If LOGGING Then 
		Log("[MQTTClient.PublishChunked][I] result=", result)
	End If
End Sub

' Publish the state of a device after f.e. an operation.
' state - True or False
' Returns JSON string {"s":0-1}
Public Sub PublishDeviceState(topic As String, state As Boolean)
	Dim statestr As String
	If state Then
		statestr = "1"
	Else
		statestr = "0"
	End If
	Dim payload() As Byte = Convert.ReplaceString(MQTTTopics.PAYLOAD_STATE, "#S", statestr)
	Publish(Array As String(topic), _ 
			Array As String(Convert.ByteConv.StringFromBytes(payload)))
End Sub
#End Region

#Region JSON GETTER

' JSON Get Text Value from Key.
' Note: Can not handle if the text is not enclosed between "".
' Returns array as Byte.
Public Sub GetTextFromKey (json() As Byte, jsonkey() As Byte) As Byte()
	Dim MAXSIZE As Int = 20
	Dim buffer(MAXSIZE) As Byte
	
	GetTextValueFromKey(json, jsonkey, 0, buffer, MAXSIZE)
	' Log("[MQTTClient.GetTextFromKey] jsonkey=",jsonkey,",buffer=", buffer)
	' [MQTTClient.GetTextFromKey] jsonkey=state,buffer=on
	Return buffer
End Sub

' JSON Get Number Value from Key.
' Note: Can not handle if the value in enclosed between "". 
' Return double.
Public Sub GetNumberFromKey (json() As Byte, jsonkey() As Byte) As Double
	Return GetNumberValueFromKey(json, jsonkey, 0)
End Sub

' JSON Get Text Value from Key   
' Dim MaxSize As Int = 20
' Dim buffer(MaxSize) As Byte
' GetTextValueFromKey(jsontext, "get_status", 0, buffer, MaxSize)
Private Sub GetTextValueFromKey (json() As Byte, Key() As Byte, StartIndex As Int, ResultBuffer() As Byte, MaxLength As UInt)	'ignore
	Dim qkey() As Byte = JoinBytes(Array(QUOTEARRAY, Key, QUOTEARRAY))
	Dim i As Int = Convert.ByteConv.IndexOf2(json, qkey, StartIndex)
	If i = -1 Then
		Convert.ByteConv.ArrayCopy(Array As Byte(), ResultBuffer)
		Return
	End If
	Dim i1 As Int = Convert.ByteConv.IndexOf2(json, QUOTEARRAY, i + qkey.Length + 1)
	Dim i2 As Int = Convert.ByteConv.IndexOf2(json, QUOTEARRAY, i1 + 1)
	Convert.ByteConv.ArrayCopy(Convert.ByteConv.SubString2(json, i1 + 1, Min(i2, i1 + 1 + MaxLength)), ResultBuffer)
	LastIndex = i2
End Sub

' JSON Get Number Value from Key. If key not found, -1 is returned.
' Dim MaxSize As Int = 20
' Dim buffer(MaxSize) As Byte
' Log(GetNumberValueFromKey(jsontext, "value", 0))
' Log(GetNumberValueFromKey(jsontext, "value", LastIndex)) 'second value
Private Sub GetNumberValueFromKey (json() As Byte, Key() As Byte, StartIndex As Int) As Double	'ignore
	Dim qkey() As Byte = JoinBytes(Array(QUOTEARRAY, Key, QUOTEARRAY))
	Dim i As Int = Convert.ByteConv.IndexOf2(json, qkey, StartIndex)
	If i = -1 Then Return -1
	Dim colon As Int = Convert.ByteConv.IndexOf2(json, ":", i + qkey.Length)
	Dim i2 As Int = 0
	For Each c As String In Array As String(",", "}", "]")
		i2 = Convert.ByteConv.IndexOf2(json, c, colon + 1)
		If i2 <> -1 Then
			Exit
		End If
	Next
	Dim res() As Byte = Convert.ByteConv.SubString2(json, colon + 1, i2)
	LastIndex = i2 + 1
	res = Convert.ByteConv.Trim(res)
	Dim s As String = Convert.ByteConv.StringFromBytes(res)
	Dim value As Double = s
	Return value
End Sub
#End Region

