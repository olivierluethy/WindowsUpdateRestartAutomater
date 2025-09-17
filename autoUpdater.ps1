# Windows Update PowerShell-Skript mit detailliertem Logging und automatischer Installation
# Startzeit: 02:00 Uhr (über Task Scheduler empfohlen)
# Protokolliert Updates und Neustart-Status in UpdateLog.txt

# Log-Datei und Zeitstempel initialisieren
$LogFile = "$env:SystemDrive\UpdateLog.txt"
Function Write-Log($Message) {
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$TimeStamp $Message"
}

# Prüfen, ob Internetverbindung besteht
Write-Log "[INFO] Pruefe Internetverbindung..."
if (!(Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    Write-Log "[ERROR] Keine Internetverbindung. Updates abgebrochen."
    Write-Host "[ERROR] Keine Internetverbindung. Updates abgebrochen."
    exit
}
Write-Log "[INFO] Internetverbindung erfolgreich geprueft."

# Prüfen und Installieren des PSWindowsUpdate-Moduls
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Log "[INFO] PSWindowsUpdate-Modul nicht gefunden. Versuche zu installieren..."
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -ErrorAction Stop
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        Write-Log "[INFO] Modul PSWindowsUpdate erfolgreich installiert."
    } catch {
        Write-Log "[ERROR] Fehler bei der Installation von PSWindowsUpdate: $_"
        Write-Host "[ERROR] Fehler bei der Installation von PSWindowsUpdate: $_"
        exit
    }
} else {
    Write-Log "[INFO] PSWindowsUpdate-Modul ist bereits installiert."
}

# Microsoft Update-Dienst aktivieren
Write-Log "[INFO] Aktiviere Microsoft Update-Dienst..."
try {
    $ServiceManager = New-Object -ComObject Microsoft.Update.ServiceManager
    $ServiceManager.AddService2('7971f918-a847-4430-9279-4a52d1efe18d', 7, '') | Out-Null
    Write-Log "[INFO] Microsoft Update-Dienst erfolgreich aktiviert."
} catch {
    Write-Log "[ERROR] Fehler beim Aktivieren des Microsoft Update-Dienstes: $_"
}

# Starte zusätzlichen Update-Scan mit usoclient
Write-Log "[INFO] Starte zusätzlichen Update-Scan mit usoclient..."
Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -NoNewWindow -Wait

# Suche nach verfügbaren Updates
Write-Log "[INFO] Starte Suche nach Windows Updates..."
Import-Module PSWindowsUpdate
$updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction SilentlyContinue -ErrorVariable SearchErrors
if ($SearchErrors) {
    Write-Log "[ERROR] Fehler bei der Update-Suche: $SearchErrors"
}

if ($updates.Count -eq 0) {
    Write-Log "[INFO] Keine Updates verfügbar."
    Write-Host "Keine Updates gefunden."
} else {
    Write-Log "[INFO] Updates gefunden:"
    foreach ($update in $updates) {
        Write-Log " - $($update.Title)"
        Write-Host "Gefundenes Update: $($update.Title)"
    }

    # Updates installieren
    Write-Log "[INFO] Installation der Updates startet..."
    $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose -ErrorAction Continue -ErrorVariable UpdateErrors
    foreach ($result in $results) {
        Write-Log "[INFO] Installiert: $($result.Title) - Result: $($result.ResultCode)"
        Write-Host "Installiert: $($result.Title) - Result: $($result.ResultCode)"
    }
    if ($UpdateErrors) {
        foreach ($err in $UpdateErrors) {
            Write-Log "[ERROR] Fehler bei der Installation: $err"
            Write-Host "[ERROR] Fehler bei der Installation: $err"
        }
    }
}

# Prüfen, ob ein Neustart erforderlich ist
Write-Log "[INFO] Pruefe, ob ein Neustart erforderlich ist..."
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
    Write-Log "[INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr."
    Write-Host "[INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr."

    # Lösche ggf. alte geplante Aufgabe für Neustart
    schtasks /delete /tn "Geplanter Neustart" /f | Out-Null
    Write-Log "[INFO] Alte Neustart-Aufgabe geloescht (falls vorhanden)."

    # Erstelle geplante Aufgabe für Neustart um 04:04 Uhr
    schtasks /create /tn "Geplanter Neustart" /tr "shutdown /r /f /t 0" /sc once /st 04:04 /ru SYSTEM /f | Out-Null
    Write-Log "[INFO] Geplanter Neustart um 04:04 Uhr erstellt."
} else {
    Write-Log "[INFO] Kein Neustart erforderlich."
    Write-Host "[INFO] Kein Neustart erforderlich."
}

# Prüfen und Erstellen der Cleanup-Aufgabe
Write-Log "[INFO] Pruefe geplante Cleanup-Aufgabe..."
$taskExists = schtasks /query /tn "Automatischer System-Cleanup" 2>$null
if (-not $taskExists) {
    Write-Log "[INFO] Erstelle geplante Aufgabe für automatischen Cleanup bei jedem Systemstart."
    schtasks /create /tn "Automatischer System-Cleanup" /tr "cleanmgr /sagerun:0" /sc onstart /ru SYSTEM /RL HIGHEST /f | Out-Null
    Write-Log "[INFO] Geplante Cleanup-Aufgabe erfolgreich erstellt."
} else {
    Write-Log "[INFO] Geplante Cleanup-Aufgabe existiert bereits."
}

# Abschluss des Prozesses
Write-Log "[INFO] Update-Prozess abgeschlossen. -----------------------------"
Write-Host "[INFO] Update-Prozess abgeschlossen."
