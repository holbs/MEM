<#
.SYNOPSIS
    Uninstalls Teams Classic for all users on the system.
.DESCRIPTION
    The detection script is used to detect if Teams Classic has been installed by the user by checking per-user installation locations. The uninstall program uses the Teams Classic update.exe to silently remove it from the system.
.NOTES
    This script does not remove the Teams Machine-Wide Installer if it is present on the system. This can be removed separately if required.
#>

#Region: Detection
$Teams = Test-Path -Path "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Teams\teams.exe" -PathType Leaf
If ($Teams) {
    Exit 0
} Else {
    Exit 1
}
#EndRegion
#Region: Uninstall
$updates = Get-Item -Path "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Teams\update.exe"
# Set up an array to collect exit codes
$ExitCodes = @()
# Loop through the updates, check their signature, then uninstall each Teams instance and add the exit code to the array
$updates.FullName | Foreach-Object {
    Try {
        $update = $null
        $update = Start-Process -FilePath $_ -ArgumentList "--uninstall --silent" -PassThru
        Get-Process -Id $update.Id -ErrorAction SilentlyContinue | Wait-Process -Timeout 300 -ErrorAction Stop
        # Without any error thrown, add the exit code from update.exe to the array
        $ExitCodes += $update.ExitCode
    } Catch {
        # If the error was due to a timeout, add a exit code 418. For other errors, add the exit code from update.exe if it was started, else add exit code 1
        If ($_.FullyQualifiedErrorId -eq "ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand") {
            $ExitCodes += 418
        } Elseif ($update) {
            $ExitCodes += $update.ExitCode
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