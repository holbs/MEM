<#
.SYNOPSIS
    Uninstalls Google Chrome installed as user.
.DESCRIPTION
    The detection script is used to detect if Google Chrome has been installed by the user by checking the logged on users %LOCALAPPDATA% folder. The uninstall program uses Google Chrome's setup.exe to silently remove it from that logged on users profile.
.NOTES
    This needs to run as the user. The SYSTEM account wont be able to uninstall Chrome installed in user context. This script assumes exit code 19 is a successful uninstall as documented in the Chromium source files https://github.com/chromium/chromium/blob/main/chrome/installer/util/util_constants.h
#>

#Region: Detection
$Chrome = Test-Path -Path "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe" -PathType Leaf -ErrorAction SilentlyContinue
If ($Chrome) {
    Exit 0
} Else {
    Exit 1
}
#EndRegion
#Region: Uninstall
Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Where-Object {$_.Path -eq "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"} | Stop-Process -Force
# If there was a pending Chrome update, wait for a moment to let Chrome release any locks on files
Start-Sleep -Seconds 5
# Get all installer folders sorted by version descending so the latest version is uninstalled first
$installerFolders = Get-Item -Path "$env:LOCALAPPDATA\Google\Chrome\Application\*\Installer" | Sort-Object {[version]$_.Parent.BaseName} -Descending
# Get the setup.exe paths from the sorted installer folders
$setups = $installerFolders | Foreach-Object {$Path = Join-Path -Path $_.Parent.FullName -ChildPath "Installer\setup.exe";If (Test-Path $Path) {$Path}}
# Set up an array to collect exit codes
$ExitCodes = @()
# Loop through the setups running them to uninstall Chrome and add the exit code to the array
$setups | Foreach-Object {
    If (Test-Path -Path $_) {
        Try {
            $setup = $null
            $setup = Start-Process -FilePath $_ -ArgumentList "--uninstall --force-uninstall --verbose-logging" -PassThru
            Get-Process -Id $setup.Id -ErrorAction SilentlyContinue | Wait-Process -Timeout 300 -ErrorAction Stop
            # Without any error thrown, add the exit code from setup.exe to the array
            $ExitCodes += $setup.ExitCode
        } Catch {
            # If the error was due to a timeout, add a exit code 418. For other errors, add the exit code from setup.exe if it was started, else add exit code 1
            If ($_.FullyQualifiedErrorId -eq "ProcessNotTerminated,Microsoft.PowerShell.Commands.WaitProcessCommand") {
                $ExitCodes += 418
            } Elseif ($setup) {
                $ExitCodes += $setup.ExitCode
            } Else {
                $ExitCodes += 1
            }
            Continue
        }
    }
}
# Determine final exit code
$Failed = $ExitCodes | Where-Object {$_ -ne 0 -and $_ -ne 19} | Sort-Object -Descending
# If any uninstall failed, exit with the first non-zero exit code, else exit 0
If ($Failed) {
    Exit $Failed[0]
} Else {
    Exit 0
}
#EndRegion