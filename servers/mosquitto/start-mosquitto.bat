@echo off
setlocal

REM Path to mosquitto executable and config
set MOSQUITTO_EXE=C:\prog\mosquitto\mosquitto.exe
set MOSQUITTO_CONF=C:\prog\mosquitto\mosquitto.conf

echo Checking for running mosquitto…

REM Check if mosquitto is running
tasklist /FI "IMAGENAME eq mosquitto.exe" | find /I "mosquitto.exe" >nul

if %ERRORLEVEL%==0 (
    echo Mosquitto is running. Stopping it…
    taskkill /F /IM mosquitto.exe >nul
    timeout /t 2 >nul
) else (
    echo Mosquitto is not running.
)

echo Starting Mosquitto...
"%MOSQUITTO_EXE%" -v -c "%MOSQUITTO_CONF%"

echo Mosquitto exited.
endlocal
exit
