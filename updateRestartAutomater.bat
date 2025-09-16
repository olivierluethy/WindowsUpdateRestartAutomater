@echo off
REM ============================================
REM Windows Update Script mit geplantem Reboot und Protokollierung
REM Startzeit: 02:00 Uhr (über Task Scheduler)
REM Protokolliert Updates und Neustart-Status in UpdateLog.txt
REM Sucht online nach Updates über Microsoft Update
REM ============================================

REM Setze Log-Datei und Zeitstempel
set LOGFILE=%SystemDrive%\UpdateLog.txt
set TIMESTAMP=%DATE% %TIME%

REM Prüfe, ob eine Internetverbindung besteht
echo [INFO] Pruefe Internetverbindung... >> %LOGFILE%
ping -n 1 8.8.8.8 >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo %TIMESTAMP% [ERROR] Keine Internetverbindung. Updates können nicht durchgeführt werden. >> %LOGFILE%
    echo [ERROR] Keine Internetverbindung. Updates können nicht durchgeführt werden.
    exit /b
)
echo %TIMESTAMP% [INFO] Internetverbindung erfolgreich geprüft. >> %LOGFILE%

REM Aktiviere Microsoft Update-Dienst, falls nicht bereits aktiviert
echo [INFO] Aktiviere Microsoft Update-Dienst...
echo %TIMESTAMP% [INFO] Aktiviere Microsoft Update-Dienst... >> %LOGFILE%
powershell -ExecutionPolicy Bypass -Command "
$ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager;
$ServiceManager.AddService2('7971f918-a847-4430-9279-4a52d1efe18d',7,'') | Out-Null;
echo %TIMESTAMP% [INFO] Microsoft Update-Dienst aktiviert. >> %LOGFILE%
"

REM Starte zusätzlichen Update-Scan mit usoclient
echo [INFO] Starte zusätzlichen Update-Scan mit usoclient...
echo %TIMESTAMP% [INFO] Starte zusätzlichen Update-Scan mit usoclient... >> %LOGFILE%
usoclient StartScan

REM Sucht online nach verfügbaren Windows Updates (Microsoft Update)
echo [INFO] Starte Suche nach Windows Updates...
echo %TIMESTAMP% [INFO] Starte Suche nach Windows Updates... >> %LOGFILE%
powershell -ExecutionPolicy Bypass -Command "
$updateSession = New-Object -ComObject Microsoft.Update.Session;
$updateSearcher = $updateSession.CreateUpdateSearcher();
$searchResult = $updateSearcher.Search('IsInstalled=0');
if ($searchResult.Updates.Count -gt 0) {
    echo 'Es wurden Updates gefunden:' >> %LOGFILE%
    $searchResult.Updates | ForEach-Object { echo $_.Title >> %LOGFILE% }
    $searchResult.Updates | ForEach-Object { $_.Title }
} else {
    echo 'Keine Updates gefunden.' >> %LOGFILE%
    echo 'Keine Updates gefunden.'
}"

REM Installiere Updates ohne Neustart
echo [INFO] Installiere verfügbare Updates...
echo %TIMESTAMP% [INFO] Installiere verfügbare Updates... >> %LOGFILE%
powershell -ExecutionPolicy Bypass -Command "
Import-Module PSWindowsUpdate;
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot | ForEach-Object { echo %TIMESTAMP% [INFO] Update installiert: $_.Title >> %LOGFILE% }
"

REM Prüfe, ob ein Neustart erforderlich ist
powershell -Command "if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') { exit 1 } else { exit 0 }"

IF %ERRORLEVEL% EQU 1 (
    echo [INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr
    echo %TIMESTAMP% [INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr >> %LOGFILE%

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
    echo %TIMESTAMP% [INFO] Geplanter Neustart um 04:04 Uhr erstellt. >> %LOGFILE%

    REM Stelle sicher, dass die Cleanup-Aufgabe nach jedem Neustart existiert
    schtasks /query /tn "Automatischer System-Cleanup" >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        echo [INFO] Erstelle geplante Aufgabe für automatischen Cleanup bei jedem Systemstart
        echo %TIMESTAMP% [INFO] Erstelle geplante Aufgabe für automatischen Cleanup bei jedem Systemstart >> %LOGFILE%
        schtasks /create ^
            /tn "Automatischer System-Cleanup" ^
            /tr "cleanmgr /sagerun:0" ^
            /sc onstart ^
            /ru SYSTEM ^
            /RL HIGHEST ^
            /f
    ) ELSE (
        echo [INFO] Geplante Cleanup-Aufgabe existiert bereits
        echo %TIMESTAMP% [INFO] Geplante Cleanup-Aufgabe existiert bereits >> %LOGFILE%
    )
) ELSE (
    echo [INFO] Kein Neustart erforderlich
    echo %TIMESTAMP% [INFO] Kein Neustart erforderlich >> %LOGFILE%
)

REM Füge Trennlinie für bessere Lesbarkeit im Log hinzu
echo %TIMESTAMP% [INFO] Update-Prozess abgeschlossen. ----------------------------- >> %LOGFILE%
exit /b
