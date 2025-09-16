@echo off
REM ============================================
REM Windows Update Script mit geplantem Reboot
REM Startzeit: 02:00 Uhr (über Task Scheduler)
REM ============================================

REM Prüfe, ob eine Internetverbindung besteht
ping -n 1 8.8.8.8 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Keine Internetverbindung. Updates können nicht durchgeführt werden.
    exit /b
)

REM Sucht online nach verfügbaren Windows Updates (Microsoft Update)
echo [INFO] Starte Suche nach Windows Updates...
powershell -ExecutionPolicy Bypass -Command "
$updateSession = New-Object -ComObject Microsoft.Update.Session;
$updateSearcher = $updateSession.CreateUpdateSearcher();
$searchResult = $updateSearcher.Search('IsInstalled=0');
if ($searchResult.Updates.Count -gt 0) {
    echo 'Es wurden Updates gefunden:'
    $searchResult.Updates | ForEach-Object { $_.Title }
} else {
    echo 'Keine Updates gefunden.'
}"

REM Stelle sicher, dass PowerShell Updates verarbeitet ohne Reboot
powershell -ExecutionPolicy Bypass -Command "Import-Module PSWindowsUpdate; Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot"

REM Prüfe, ob ein Neustart erforderlich ist
powershell -Command "if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { exit 1 } else { exit 0 }"

IF %ERRORLEVEL% EQU 1 (
    echo [INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr

    REM Lösche ggf. alte geplante Aufgabe für Neustart
    schtasks /delete /tn "Geplanter Neustart" /f >nul 2>&1

    REM Erstelle geplante Aufgabe zum Neustart um 04:04 Uhr
    schtasks /create ^
        /tn "Geplanter Neustart" ^
        /tr "shutdown /r /f /t 0" ^
        /sc once ^
        /st 04:04 ^
        /ru SYSTEM ^
        /f

    REM Stelle sicher, dass die Cleanup-Aufgabe nach jedem Neustart existiert
    schtasks /query /tn "Automatischer System-Cleanup" >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        echo [INFO] Erstelle geplante Aufgabe für automatischen Cleanup bei jedem Systemstart

        schtasks /create ^
            /tn "Automatischer System-Cleanup" ^
            /tr "cleanmgr /sagerun:0" ^
            /sc onstart ^
            /ru SYSTEM ^
            /RL HIGHEST ^
            /f
    ) ELSE (
        echo [INFO] Geplante Cleanup-Aufgabe existiert bereits
    )

) ELSE (
    echo [INFO] Kein Neustart erforderlich
)

exit /b
