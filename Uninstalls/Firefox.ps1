<#
.SYNOPSIS
    Uninstalls Mozilla Firefox installed as user.
.DESCRIPTION
    The detection script is used to detect if Mozilla Firefox has been installed by the user by checking per-user installation locations. The uninstall program uses Mozilla Firefox's helper.exe to silently remove it from the system.
.NOTES
    Set up an application using the detection script to detect Mozilla Firefox installations. Set the uninstall script as the uninstall program. Deploy the uninstall program to remove Mozilla Firefox silently.
#>

#Region: Detection
$Firefox = Get-Item -Path "$env:SystemDrive\Users\*\AppData\Local\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
If ($Firefox) {
    Exit 0
} Else {
    Exit 1
}
#EndRegion
#Region: Uninstall
Try {
    $helper = Start-Process -FilePath "$env:SystemDrive\Users\*\AppData\Local\Mozilla Firefox\uninstall\helper.exe" -ArgumentList "/s" -PassThru
    Wait-Process -Id $helper.Id -Timeout 300 -ErrorAction Stop
    # Exit with the same code as helper.exe
    Exit $helper.ExitCode
} Catch {
    Write-Output "Failed to run helper.exe: $_"
    # Exit with the same code as helper.exe if it was started
    If ($helper) {
        Exit $helper.ExitCode
    } Else {
        Exit 1
    }
}
#EndRegion