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
$helpers = Get-Item -Path "$env:SystemDrive\Users\*\AppData\Local\Mozilla Firefox\uninstall\helper.exe"
# Set up an array to collect exit codes
$ExitCodes = @()
# Loop through the helpers and uninstall each Firefox instance and add the exit code to the array
$helpers.FullName | Foreach-Object {
    Try {
        $helper = $null
        $helper = Start-Process -FilePath $_ -ArgumentList "/s" -PassThru
        Get-Process -Id $helper.Id -ErrorAction SilentlyContinue | Wait-Process -Timeout 300 -ErrorAction Stop
        # Without any error thrown, add the exit code from helper.exe to the array
        $ExitCodes += $helper.ExitCode
    } Catch {
        # If the error was due to a timeout, add a exit code 418. For other errors, add the exit code from helper.exe if it was started, else add exit code 1
        If ($_.FullyQualifiedErrorId -eq "ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand") {
            $ExitCodes += 418
        } Elseif ($helper) {
            $ExitCodes += $helper.ExitCode
        } Else {
            $ExitCodes += 1
        }
        Continue
    }
}
# Determine final exit code
$Failed = $ExitCodes | Where-Object {$_ -ne 0} | Sort-Object -Descending
# If any uninstall failed, exit with the first non-zero exit code, else exit 0
If ($Failed) {
    Exit $Failed[0]
} Else {
    Exit 0
}
#EndRegion