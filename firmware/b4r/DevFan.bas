B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevFan.bas
' Project:      make-homekit32
' Brief:        Controls fan motor (on/off/speed).
' Date:         2025-11-15
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx
' Description:	Controls the fan motor speed via ESP32.
' Hardware: 	https://wiki.keyestudio.com/KS0347_Keyestudio_130_Motor_DC3-5V_Driving_Module
' Logic:
' INA | INB | Mode
' L   | L   | Standby STOP
' H   | L   | Forward
' L   | H   | Reverse
' H   | H   | Break
' ================================================================
#End Region

Private Sub Process_Globals
	Private SpeedPin As Pin							' IN- minus
	Private DirectionPin As Pin						' IN+ plus
	Public IsRotating As Boolean = False
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   directionpinnr - GPIO pin number
'   speedpinnr - GPIO pin number
Public Sub Initialize(directionpinnr As Byte, speedpinnr As Byte)
	DirectionPin.Initialize(directionpinnr, DirectionPin.MODE_OUTPUT)
	SpeedPin.Initialize(speedpinnr, SpeedPin.MODE_OUTPUT)
	
	Log("[DevFan.Initialize][I] OK, directionpin=", directionpinnr, ", speedpin=", speedpinnr)
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' Set
' Set the speed.
' The direction is fixed.
' Parameters:
'   state - Boolean True=On (full speed), False=Off
Public Sub Set(state As Boolean)
	' Set the fan speed
	If state Then
		DirectionPin.digitalWrite(True)		' HIGH
		SpeedPin.analogWrite(255)
		IsRotating = True
	Else
		DirectionPin.digitalWrite(False)	' LOW
		SpeedPin.analogWrite(0)
		IsRotating = False
	End If
	Log("[DevFan.Set] state=", state)
End Sub

' Get
' Get the state ON or OFF.
' Returns:
'   state - 0=Off, 1=On
Public Sub Get As Boolean
	Return SpeedPin.DigitalRead
End Sub

' On
' Turn motor on
Public Sub On
	Set(True)
End Sub

' Off
' Turn motor off
Public Sub Off
	Set(False)
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' ProcessMQTT
' Sets the speed based on MQTT action payload.
' The direction is fixed.
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessMQTT(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)

	Dim Speed As Double = MQTTClient.GetNumberFromKey(payload, MQTTTopics.KEY_STATE)
	Log("[DevFan.ProcessMQTT] storeindex=", storeindex, ", payload=", payload, ", speed=", Speed)

	If Speed < 0 Or Speed > 1023 Then Return	' Safety check
		
	' Set the fan speed
	If Round(Speed) == 0 Then
		DirectionPin.digitalWrite(False)	' LOW
	Else
		DirectionPin.digitalWrite(True)		' HIGH
	End If
	SpeedPin.analogWrite(Round(Speed))

	Dim speedstr As String = Speed
	Dim payload() As Byte = Convert.ReplaceString(MQTTTopics.PAYLOAD_FAN_STATUS, "#S", speedstr)
	MQTTClient.Publish(Array As String(MQTTTopics.TOPIC_FAN_STATUS), _
					   Array As String(Convert.ByteConv.StringFromBytes(payload)))
	Log("[DevFan.ProcessMQTT][I] json=", Convert.ByteConv.StringFromBytes(payload))
End Sub

#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x08 > Fan
' Sets the state to on or off (Command 0x01).
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x08
' 	Byte 1 Command:	0x01 > Set
' 	Byte 2 State:	0x01 > ON or 0x00 > OFF
'	Example: Set ON = 080101
'
' Get the state (Command 0x02)
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x08
' 	Byte 1 Command:	0x02 > Get
'	Returns Byte 0=ON, 1=ON
'	Example State ON = 080201
'
' NOT SUPPORTED
' Set the value (Command 0x03)
' 	Length: 3 Bytes
' 	Byte 0 Device:	0x08
' 	Byte 1 Command:	0x03 > Set value
' 	Byte 2 Value:	0x00-0xFF
'	Example State speed 255 = 08030FF
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevFan.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	' [DevFan.ProcessBLE] storeindex=1, payload=0803FF
	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_SET_STATE
			Dim state As Byte = payload(2)
			If state == 1 Then
				On
			Else
				Off
			End If
			WriteToBLE(command, state)
		Case CommBLE.CMD_GET_STATE
			WriteToBLE(command, Convert.BoolToByte(Get))
	End Select
End Sub

' WriteToBLE
' Write to BLE the state.
' Parameters:
'	value - Byte 0 or 1 for setting state, 0-255 for getting state
Public Sub WriteToBLE(command As Byte, value As Byte)
	Dim payload() As Byte = Array As Byte(CommBLE.DEV_FAN, command, value)
	CommBLE.BLEServer_Write(payload)
	Log("[DevFan.WriteToBLE] payload=", Convert.BytesToHex(payload))
End Sub
#End Region
#End If
