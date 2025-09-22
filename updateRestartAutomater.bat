@echo off
REM ================================
REM Führt autoUpdater.ps1 aus
REM ================================

REM Setze Pfad zur PowerShell-Datei
set "SCRIPT=%USERPROFILE%\Documents\autoUpdater.ps1"

REM Starte PowerShell mit Admin-Rechten und bypassed Policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"





REM ================================================================
REM Nur wenn AdminRechte zwingend nötig sind
@echo off
REM ========================================
REM Führt autoUpdater.ps1 mit Bypass aus
REM ========================================

REM Setze Pfad zur PowerShell-Datei
set "SCRIPT=%USERPROFILE%\Documents\autoUpdater.ps1"

REM Prüfen, ob Datei existiert
if not exist "%SCRIPT%" (
    echo [ERROR] Skript nicht gefunden: %SCRIPT%
    pause
    exit /b 1
)

REM Starte PowerShell mit ExecutionPolicy Bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
