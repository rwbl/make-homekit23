B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DeviceMgr.bas
' Project:      make-homekit32
' Brief:        ESP32 Hardware Configuration and Device Mapping
' Date:         2025-11-11
' Author:       Robert W.B. Linn (c) 2025 MIT
' Servo Timers: Dedicated timer allocation per servo.
' Notes:        Constants use UPPER_SNAKE_CASE.
' ================================================================
#End Region

Private Sub Process_Globals

	' ===== LEDs =====
	Public ONBOARDLED_PIN As Byte = 2
	Public YELLOW_LED_PIN As Int = 12
	Public RGB_LED_PIN As Int = 26

	' ===== Buttons =====
	Public BTN_LEFT_PIN As Int = 16
	Public BTN_RIGHT_PIN As Int = 27

	' ===== PIR Sensor (Motion) =====
	Public PIR_SENSOR_PIN As Int = 14

	' ===== DHT11 Temp + Hum =====
	Public DHT11_PIN As Int = 17

	' ===== Moisture Sensor (Analog) =====
	Public MOISTURE_SENSOR_PIN As Int = 34

	' ===== Gas Sensor (Analog) =====
	Public GAS_SENSOR_PIN As Int = 23

	' ===== Audio =====
	Public BUZZER_PIN As Int = 25

	' ===== Fan =====
	Public FAN_DIRECTION_PIN As Int = 19
	Public FAN_SPEED_PIN As Int = 18

	' ===== Servos =====
	Public SERVO_WINDOW_PIN As Int = 5
	Public SERVO_DOOR_PIN As Int = 13
	
	' ===== I2C Devices =====
	Public RFID_I2C_ADDRESS As Byte = 0x28	' RFID Mifare
	Public LCD_I2C_ADDRESS As Byte  = 0x27	' LCD1602

	' ===== ESP32 Board =====
	Public BOARD_REV As String = "1.0"

End Sub

Public Sub Initialize
	Log("[DeviceMgr.Initialize][I] Start")

	' LEDs
	' DevOnboardLed.Initialize(ONBOARDLED_PIN)  ' if used
	DevYellowLed.Initialize(YELLOW_LED_PIN)
	DevRGBLed.Initialize(RGB_LED_PIN)

	' Servos
	DevServoDoor.Initialize(SERVO_DOOR_PIN)
	DevServoWindow.Initialize(SERVO_WINDOW_PIN)

	' Sensors
	DevMoisture.Initialize(MOISTURE_SENSOR_PIN)
	DevDHT11.Initialize(DHT11_PIN)
	DevPIRSensor.Initialize(PIR_SENSOR_PIN)
	DevRFID.Initialize(RFID_I2C_ADDRESS)
	DevGasSensor.Initialize(GAS_SENSOR_PIN)

	' Fan
	DevFan.Initialize(FAN_DIRECTION_PIN, FAN_SPEED_PIN)

	' Display
	DevLCD1602.Initialize(LCD_I2C_ADDRESS)

	' Audio
	DevBuzzer.Initialize(BUZZER_PIN)

	' System
	DevSystem.Initialize

	' Buttons NOT USED > See MenuHandler
	' DevButtons.Initialize(BTN_LEFT_PIN, BTN_RIGHT_PIN)
	
	' MenuHandler using buttons
	MenuHandler.Initialize(BTN_LEFT_PIN, BTN_RIGHT_PIN)

	Log("[DeviceMgr.Initialize][I] Done")
End Sub
