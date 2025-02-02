<#
.DESCRIPTION
    This script is deployed to uninstall any version of Teams Machine Wide Installer from a workstation and write a log to %ProgramData%\Microsoft\IntuneManagementExtension\Logs\Software
#>

#Requires -RunAsAdministrator

#Region: Detection
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Teams Machine-Wide Installer'} | Foreach-Object {Write-Output "Installed"}
#EndRegion
#Region: Uninstall
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall' | Get-ItemProperty | Where-Object {$_.DisplayName -eq 'Teams Machine-Wide Installer'} | Foreach-Object {
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
    $TeamsMachineWideInstaller = Start-Process @Uninstall
    Wait-Process -Id $TeamsMachineWideInstaller.Id
    # Wait a bit longer
    Start-Sleep -Seconds 5
    # If the uninstall was successful, remove the registry key if it's not been automatically removed
    If ($TeamsMachineWideInstaller.ExitCode -eq 0) {
        Get-Item -Path $_.PSPath | Remove-Item -Force
    }
}
#EndRegion