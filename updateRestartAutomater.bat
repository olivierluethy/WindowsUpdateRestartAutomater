@echo off
REM ================================
REM Führt autoUpdater.ps1 aus
REM ================================

REM Setze Pfad zur PowerShell-Datei
set "SCRIPT=%USERPROFILE%\Documents\autoUpdater.ps1"

REM Starte PowerShell mit Admin-Rechten und bypassed Policy
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
