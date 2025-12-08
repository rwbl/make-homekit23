@echo off
REM Stop Mosquitto manually for dev (no admin required)
setlocal

echo Checking for running Mosquitto...
tasklist /FI "IMAGENAME eq mosquitto.exe" | find /I "mosquitto.exe" >nul

if %ERRORLEVEL%==0 (
    echo Mosquitto is running. Stopping it...
    taskkill /F /IM mosquitto.exe >nul
    timeout /t 2 >nul
    echo Mosquitto stopped.
) else (
    echo Mosquitto is not running.
)
endlocal
pause
