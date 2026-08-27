@echo off
REM ================================================================
REM Fuehrt autoUpdater.ps1 aus. Das PS-Skript benoetigt Adminrechte,
REM daher hier eine Selbst-Elevation (UAC) falls noetig.
REM ================================================================
set "SCRIPT=%USERPROFILE%\Documents\autoUpdater.ps1"

if not exist "%SCRIPT%" (
    echo [ERROR] Skript nicht gefunden: %SCRIPT%
    pause
    exit /b 1
)

REM Pruefen, ob wir bereits Adminrechte haben.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Fordere Administratorrechte an...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
