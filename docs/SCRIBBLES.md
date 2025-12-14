# SCRIBBLES - make-homekit32

This document keeps some scribbles which might be of any use.  

---

## Links
Overview Components:
https://wiki.keyestudio.com/Main_Page

https://docs.keyestudio.com/projects/KS5009/en/latest/docs/index.html#
https://www.keyestudio.com/products/keyestudio-esp32-plus-development-board-woroom-32-module-wifibluetooth-compatible-with-arduino
https://www.keyestudio.com/blog/how-to-use-sk6812-rgb-module-with-esp32-304

https://inductiveautomation.com/resources/casestudy/clovis-community-college
https://github.com/CCC-Industry4/IIOT-4.0-Project/tree/main

https://draeger-it.blog/programmieren-des-keyestudio-smart-home-kit-in-der-arduino-ide/

## Command Topic
Idea using command topic with payload.
```
homekit32/home1/command
```

```
{"device":"door","action":"open"}
{"device":"lcd","c":0,"r":1,"t":"Welcome","x":0}
{"device":"dht11","action":"read"}
```
OR
```
{"d":"door","a":"open"}
{"d":"lcd","c":0,"r":1,"t":"Welcome","x":0}
{"d":"dht11","a":"read"}
```

## AllocateAllTimers
'
'#if C
'void AllocateAllTimers(B4R::Object* o)
'{
'	// Allow allocation of all timers
'	ESP32PWM::allocateTimer(0);
'	ESP32PWM::allocateTimer(1);
'	ESP32PWM::allocateTimer(2);
'	ESP32PWM::allocateTimer(3);
'}
'#End If
'
'#If C
'void AttachServoWindowToTimer(B4R::Object* o) 
'{
'	// use timer 3 only for this servo
'  	ESP32PWM::allocateTimer(3);
'  	b4r_devicemgr::_servowindow->Attach(b4r_devicemgr::_servo_window_pinnr);
'  	// b4r_devicemgr::_servowindow->Attach2(b4r_devicemgr::_servo_window_pinnr, 1000, 2000);
'}
'
'void AttachServoDoorToTimer(B4R::Object* o) 
'{
'	// use timer 2 only for this servo
'  	ESP32PWM::allocateTimer(2);
'  	b4r_devicemgr::_servodoor->Attach2(b4r_devicemgr::_servo_door_pinnr, 1000, 2000);
'}
'#End If

## Color Conversion
```
'#Region Helper
' ColorToRGB
' Convert color value (ULong) to R,G,B values 0-255.
' Parameters:
'	color - ULong
' Returns:
'	ByteArray - 3 colors R,G,B 0-255
'Public Sub ColorToRGB(color As ULong) As Byte()
'	Dim result(3) As Byte
'	Dim r As Byte = Bit.And(Bit.ShiftRight(color, 16), 0xFF)
'	Dim g As Byte = Bit.And(Bit.ShiftRight(color, 8), 0xFF)
'	Dim b As Byte = Bit.And(color, 0xFF)
'	result(0) = r
'	result(1) = g
'	result(2) = b
'	Log("[ColorToRGB] color=", color, ", > r=", r, " g=", g, " b=", b)
'	Return result
'End Sub
'
' RGBToColor
' Convert R,G,B bytes (0–255) into a single ULong color value 0xRRGGBB
' Parameters:
'   r, g, b - Byte values 0..255
' Returns:
'   ULong - packed 24-bit color value
'Public Sub RGBToColor(r As Byte, g As Byte, b As Byte) As ULong
'	Dim color As ULong = 0
'	color = Bit.Or(color, Bit.ShiftLeft(r, 16))
'	color = Bit.Or(color, Bit.ShiftLeft(g, 8))
'	color = Bit.Or(color, b)
'
'	Log("[RGBToColor] r=", r, " g=", g, " b=", b, " > color=", color)
'	Return color
'End Sub
'#End Region
```

## RFID Parser
```
' ================================================================
' Sub: ParseRFIDPayload
' Description:
'   Parses a BLE payload in the format:
'       [UL][UID bytes...][DL][DATA bytes...]
'   Returns UID() and Data() byte arrays.
' Parameters:
'   payload() As Byte - input byte array from BLE
' Returns:
'   uid() As Byte
'   data() As Byte
' ================================================================
Public Sub ParseRFIDPayload(payload() As Byte) As Map
    Dim result As Map
    result.Initialize

    If payload.Length < 2 Then
        Log("⚠ Payload too short!")
        Return result
    End If

    Dim idx As Int = 0

    ' --- UID ---
    Dim uidLen As Byte = payload(idx)
    idx = idx + 1
    Dim uid(uidLen) As Byte
    For i = 0 To uidLen - 1
        uid(i) = payload(idx)
        idx = idx + 1
    Next
    result.Put("UID", uid)

    ' --- Data ---
    If idx >= payload.Length Then
        Log("⚠ No data length byte found!")
        Return result
    End If
    Dim dataLen As Byte = payload(idx)
    idx = idx + 1
    Dim data(dataLen) As Byte
    For i = 0 To dataLen - 1
        data(i) = payload(idx)
        idx = idx + 1
    Next
    result.Put("DATA", data)

    ' Optional: extra bytes
    If idx <> payload.Length Then
        Log("⚠ Extra bytes at end of payload: " & (payload.Length - idx))
    End If

    Return result
End Sub
```

## CommBLE Dispatch IfElse
```
Private Sub BLEDispatch(deviceid As Byte)
	Log("[CommBLE.BLEDispatch] deviceid=",deviceid, ", hex=", Convert.OneByteToHex(deviceid))
	
	If deviceid == 0 Then
		' Reserved
	else if deviceid == DEV_YELLOW_LED Then
		DevYellowLed.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_RGB_LED Then
		DevRGBLed.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_BUTTON_LEFT Then
		' DevButtons.BtnLeftAction(GlobalStoreHandler.Index)
	else if deviceid == DEV_BUTTON_RIGHT Then
		' DevButtons.BtnRightAction(GlobalStoreHandler.Index)
	else if deviceid == DEV_SERVO_DOOR Then
		DevServoDoor.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_SERVO_WINDOW Then
		DevServoWindow.ProcessBLE(GlobalStoreHandler.Index)
	Else if deviceid == DEV_BUZZER Then
		DevBuzzer.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_FAN Then
		DevFan.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_DHT11 Then
		DevDHT11.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_GAS_SENSOR Then
		DevGasSensor.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_MOISTURE Then
		DevMoisture.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_LCD1602 Then
		DevLCD1602.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_PIR_SENSOR Then
		DevPIRSensor.ProcessBLE(GlobalStoreHandler.Index)
	else if deviceid == DEV_RFID Then
		DevRFID.ProcessBLE(GlobalStoreHandler.Index)
	End If
End Sub
```
