# Retrieve list of MOF files (excluding any that contain "Uninstall", "Remove", or "AutoRecover"), MFL files (excluding any that contain "Uninstall", or "Remove"), & DLL files from the WBEM folder
$WbemContents = Get-ChildItem -Path "$env:WINDIR\System32\Wbem" -Recurse -File -Force
$MofFiles = $WbemContents | Where-Object {$_.Extension -eq ".mof"} | Where-Object {$_.FullName -notmatch "Uninstall|Remove|Autorecover"} | Select-Object -ExpandProperty FullName
$MflFiles = $WbemContents | Where-Object {$_.Extension -eq ".mfl"} | Where-Object {$_.FullName -notmatch "Uninstall|Remove"} | Select-Object -ExpandProperty FullName
$DllFiles = $WbemContents | Where-Object {$_.Extension -eq ".dll"} | Select-Object -ExpandProperty FullName
# Set Services for Volume Shadow Copy (VSS) and Microsoft Storage Spaces (SMPHost) to manual and stopped state prior to repository reset
Set-Service -Name "vss" -Status Stopped -StartupType Manual -ErrorAction SilentlyContinue | Out-Null
Set-Service -Name "smphost" -Status Stopped -StartUpType Manual -ErrorAction SilentlyContinue | Out-Null
# Disable and Stop winmgmt service (Windows Management Instrumentation)
Set-Service -Name "winmgmt" -Status Stopped -StartUpType Disabled -ErrorAction SilentlyContinue | Out-Null
# This line resets the WMI repository, which renames current repository folder %systemroot%\system32\wbem\Repository to Repository.001
& $env:WINDIR\System32\wbem\winmgmt.exe /resetrepository | Out-Null
# These DLL Registers will help fix broken GPUpdate
Start-Process -FilePath "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/s $env:WINDIR\System32\scecli.dll" -Wait
Start-Process -FilePath "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/s $env:WINDIR\System32\userenv.dll" -Wait
# These dll registers help ensure all DLLs for WMI are registered
Foreach ($DllFilePath in $DllFiles) {Start-Process -FilePath "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/s $DllFilePath" -Wait}
# Enable winmgmt service (WMI) and start the service
Set-Service -Name "winmgmt" -Status Running -StartUpType Automatic -ErrorAction SilentlyContinue | Out-Null
# Wait to let WMI Service start
Start-Sleep -Seconds 15
# Parse MOF and MFL files to add classes and class instances to WMI repository
Foreach ($MofFilePath in $MofFiles) {& $env:WINDIR\System32\Wbem\mofcomp.exe $MofFilePath | Out-Null}
Foreach ($MflFilePath in $MflFiles) {& $env:WINDIR\System32\Wbem\mofcomp.exe $MflFilePath | Out-Null}