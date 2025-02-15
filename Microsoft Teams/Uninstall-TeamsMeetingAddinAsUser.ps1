<#
.DESCRIPTION
    Scripts for detecting and uninstalling the Microsoft Teams Meeting Add-in for Microsoft Office when it's installed in user context (default). This is so we can supersede this user install with another application that installs the add-in in machine context.
#>

#Region: Detection
$TeamsMeetingAddin = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'}
If ($TeamsMeetingAddin) {
    $TeamsMeetingAddinVersion = $TeamsMeetingAddin.DisplayVersion
    If (Test-Path -Path "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAdd-in\$TeamsMeetingAddinVersion") {
        If (Test-Path -Path "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAdd-in\$TeamsMeetingAddinVersion\AddinInstaller.dll") {
            Write-Output "Installed"
        } Else {
            # Not installed
        }
    } Else {
        # Not installed  
    }
}
#EndRegion
#Region: Uninstall
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Microsoft Teams Meeting Add-in for Microsoft Office'} | Foreach-Object {
    $DisplayName = $_.GetValue('DisplayName').Replace(" ","_")
    $ProductCode = $_.PSChildName
    $Version     = $_.GetValue('DisplayVersion')
    # Splatting to pass the product code to msiexec to uninstall the software
    $Uninstall = @{
        FilePath = "$env:WINDIR\System32\msiexec.exe"
        ArgumentList = @(
            "/x",
            "$ProductCode",
            "/qn",
            "/L*vx! $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Software\$($DisplayName)_$($Version)_Uninstall.log"
        )
        PassThru = $true
    }
    $TeamsMeetingAddin = Start-Process @Uninstall
    Wait-Process -Id $TeamsMeetingAddin.Id
    # Wait a bit longer
    Start-Sleep -Seconds 5
    # If the uninstall was successful, remove the folder from %LOCALAPPDATA%
    If ($TeamsMeetingAddin.ExitCode -eq 0) {
        Get-Item -Path "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAdd-in\$Version" | Remove-Item -Recurse -Force -Confirm:$false
    }
}
#EndRegion