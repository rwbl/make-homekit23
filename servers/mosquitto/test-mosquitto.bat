REM Test Commands

REM Remove retained messages
c:\Prog\mosquitto\mosquitto_sub.exe --remove-retained -t "#" -W 1

REM Yellow LED
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/yellow_led/set -m {\"s\":\"on\"}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/yellow_led/set -m {\"s\":\"off\"}

REM RGBLED pixel 0 to blue with all pixels cleared
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/rgb_led/set -m {\"i\":0,\"r\":0,\"g\":0,\"b\":50,\"c\":1}

REM Servo
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/servo_door/set -m {\"a\":\"open\"}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/servo_door/set -m {\"a\":\"close\"}

REM Buzzer
REM Single tone
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"t\":440,\"d\":500}
REM Buzzer off
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"t\":0,"\d":0}
REM Alarm melody 1 (police siren)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/buzzer/set -m {\"a\":1}

REM DHT11
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/dht11/get -m ''

REM Moisture
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/moisture/get -m ''

REM FAN
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/fan/set -m {\"s\":10}
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/fan/set -m {\"s\":0}

REM LCD
REM write Hello first row with clear display (x=1)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/lcd/set -m {\"c\":0,\"r\":0,\"t\":\"Hello\",\"x\":1}
REM write World with NO clear display (x=0)
c:\Prog\mosquitto\mosquitto_pub.exe -t homekit32/home1/lcd/set -m {\"c\":0,\"r\":1,\"t\":\"World\",\"x\":0}