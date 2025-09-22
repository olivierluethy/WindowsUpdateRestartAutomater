# WindowsUpdateRestartAutomater


Security Bypass Methode die genutzt wird:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass


Dauerhaft:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

## Resourcen
https://www.remove.bg/de
https://picsart.com/ai-image-enhancer/
https://imageresizer.com/bulk-resize
https://www.w3schools.com/css/css_tooltip.asp
https://www.craiyon.com/de/image/TjhD8UbhT22suUaSuh58gA
https://www.craiyon.com/de/image/v30EMdjZRKO4OLdJcbt4Sg
https://www.craiyon.com/de?prompt=A%20neon%20dark%20blue%20block%20blast%20app%20logo&model=pro-illustration&negativePrompt=&aspectRatio=auto


Fehlermeldungen:
[INFO] Neustart erforderlich - plane Neustart um 04:04 Uhr.
schtasks : FEHLER: Das System kann die angegebene Datei nicht finden.
In C:\Users\Administrator\Documents\autoUpdater.ps1:91 Zeichen:5
+     schtasks /delete /tn "Geplanter Neustart" /f | Out-Null
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (FEHLER: Das Sys...i nicht finden.:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
schtasks : WARNUNG: Aufgabe wird evtl. nicht ausgefhrt, da /ST vor der aktuellen Zeit
In C:\Users\Administrator\Documents\autoUpdater.ps1:95 Zeichen:5
+     schtasks /create /tn "Geplanter Neustart" /tr "shutdown /r /f /t  ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (WARNUNG: Aufgab... aktuellen Zeit:String) [], RemoteException
    + FullyQualifiedErrorId : NativeCommandError
 
liegt.
[INFO] Update-Prozess abgeschlossen.