# WindowsUpdateRestartAutomater

A PowerShell automation that installs pending Windows updates unattended, logs the
whole process, and schedules an automatic restart when one is required — intended to
run overnight via the Windows Task Scheduler.

## Features

- Checks for an internet connection before starting.
- Installs the `PSWindowsUpdate` module automatically if it is missing.
- Enables the Microsoft Update service and triggers an update scan (`usoclient`).
- Downloads and installs available updates, writing a timestamped log to
  `%SystemDrive%\UpdateLog.txt`.
- If a reboot is needed, schedules a restart via `schtasks` (e.g. during the night).
- A `.bat` launcher runs the script with `-ExecutionPolicy Bypass`.

## Files

- `autoUpdater.ps1` — the main update-and-restart script.
- `updateRestartAutomater.bat` — launcher that runs the script from
  `%USERPROFILE%\Documents\`.

## Tech

- Windows PowerShell, the `PSWindowsUpdate` module, and `schtasks` / `usoclient`.

## Usage

Place `autoUpdater.ps1` in your `Documents` folder and run the launcher as an
administrator, or run the script directly:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
powershell -NoProfile -ExecutionPolicy Bypass -File autoUpdater.ps1
```

For unattended operation, register it as a scheduled task (for example at 02:00).
Requires administrator rights.
