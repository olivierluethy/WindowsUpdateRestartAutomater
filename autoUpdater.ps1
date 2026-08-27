#Requires -Version 5.1
# Windows Update Automater - PowerShell-only, unattended, detailliertes Logging.
# Empfohlen via Task Scheduler als SYSTEM/Admin (z.B. taeglich 02:00 Uhr).

$ErrorActionPreference = 'Stop'

# --- Logging -------------------------------------------------------------
$LogFile = "$env:SystemDrive\UpdateLog.txt"
function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$ts [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

Write-Log INFO "===== Update-Lauf gestartet ====="

# --- Execution policy (nur fuer diesen Prozess) --------------------------
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force } catch {}

# --- Adminrechte pruefen -------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Log ERROR "Skript benoetigt Administratorrechte. Abbruch."
    exit 1
}

# --- Internetverbindung --------------------------------------------------
Write-Log INFO "Pruefe Internetverbindung..."
if (-not (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    Write-Log ERROR "Keine Internetverbindung. Updates abgebrochen."
    exit 1
}
Write-Log INFO "Internetverbindung ok."

# --- PSWindowsUpdate sicherstellen (standardmaessig nicht vorhanden) ------
try {
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {}

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-Log INFO "PSWindowsUpdate nicht gefunden - installiere..."
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
        if (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue) {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        }
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        Write-Log INFO "PSWindowsUpdate installiert."
    } catch {
        Write-Log ERROR "Installation von PSWindowsUpdate fehlgeschlagen: $_"
        exit 1
    }
} else {
    Write-Log INFO "PSWindowsUpdate bereits vorhanden."
}
Import-Module PSWindowsUpdate -ErrorAction Stop

# --- Microsoft Update-Dienst registrieren (Treiber/Office etc.) ----------
try {
    (New-Object -ComObject Microsoft.Update.ServiceManager).AddService2(
        '7971f918-a847-4430-9279-4a52d1efe18d', 7, '') | Out-Null
    Write-Log INFO "Microsoft Update-Dienst registriert."
} catch {
    Write-Log WARN "Microsoft Update-Dienst konnte nicht registriert werden: $_"
}

# --- Updates suchen ------------------------------------------------------
Write-Log INFO "Suche nach Updates..."
$updates = @(Get-WindowsUpdate -MicrosoftUpdate -ErrorAction SilentlyContinue -ErrorVariable searchErr)
if ($searchErr) { Write-Log ERROR "Fehler bei der Suche: $searchErr" }

if ($updates.Count -eq 0) {
    Write-Log INFO "Keine Updates verfuegbar."
} else {
    Write-Log INFO "$($updates.Count) Update(s) gefunden:"
    $updates | ForEach-Object { Write-Log INFO " - $($_.Title) ($($_.Size))" }

    # --- Download + Installation, ohne Benutzerinteraktion --------------
    # -IgnoreReboot: Neustart wird unten kontrolliert geplant.
    Write-Log INFO "Starte Download und Installation..."
    $results = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -Download -Install `
                 -IgnoreReboot -Verbose -ErrorAction Continue -ErrorVariable installErr
    foreach ($r in $results) {
        Write-Log INFO "Installiert: $($r.Title) - Result: $($r.Result)"
    }
    if ($installErr) { $installErr | ForEach-Object { Write-Log ERROR "Installationsfehler: $_" } }
}

# --- Neustart, falls erforderlich ---------------------------------------
# Loest den frueheren 'schtasks /st 04:04'-Fehler (feste Uhrzeit vor
# aktueller Zeit) durch eine relative Frist von 5 Minuten.
if (Get-WURebootStatus -Silent) {
    Write-Log INFO "Neustart erforderlich - plane Neustart in 5 Minuten."
    Start-Process shutdown.exe -ArgumentList '/r','/f','/t','300', `
        '/c','"Windows Update: Neustart in 5 Minuten"' -NoNewWindow
} else {
    Write-Log INFO "Kein Neustart erforderlich."
}

Write-Log INFO "===== Update-Lauf abgeschlossen ====="
