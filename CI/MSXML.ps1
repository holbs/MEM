#Region: Detection
New-PSDrive -Name HKCR -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
$FileNames = @(
    "msxml.dll",
    "msxml4.dll"
)
$CLSIDs = @( 
    # Microsoft have provided the CLSIDs for MSXML 4.0 here: https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ms754671(v=vs.85)
    "{88d969c0-f192-11d4-a65f-0040963251e5}",
    "{88d969c4-f192-11d4-a65f-0040963251e5}",
    "{88d969c1-f192-11d4-a65f-0040963251e5}",
    "{88d969c9-f192-11d4-a65f-0040963251e5}",
    "{88d969d6-f192-11d4-a65f-0040963251e5}",
    "{88d969c8-f192-11d4-a65f-0040963251e5}",
    "{88d969ca-f192-11d4-a65f-0040963251e5}",
    "{7c6e29bc-8b8b-4c3d-859e-af6cd158be0f}",
    "{88d969c6-f192-11d4-a65f-0040963251e5}",
    "{88d969c5-f192-11d4-a65f-0040963251e5}",
    "{88d969c2-f192-11d4-a65f-0040963251e5}",
    "{88d969c3-f192-11d4-a65f-0040963251e5}"
)
# Check the architecture so we can set paths based on x64 or x86 Windows
If ([Environment]::Is64BitOperatingSystem) {
    $FilePath = "$env:WINDIR\SysWOW64"
    $CLSIDPaths = "HKCR:\WOW6432Node\CLSID", "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID"
    $Registry = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
} Else {
    $FilePath = "$env:WINDIR\System32"
    $CLSIDPaths = "HKCR:\CLSID", "HKLM:\SOFTWARE\Classes\CLSID"
    $Registry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
}
# Check if the software is installed and return false if it is
$UninstallKeys = Get-ItemProperty "$Registry\*"
Foreach ($Key in $UninstallKeys) {
    If ($Key.DisplayName -like "MSXML 4.0 * Parser") {
        Return $false
    }
}
# Check if the DLLs are present in %sysnative%\System32 and return false if they are
Foreach ($File in $FileNames) {
    If (Test-Path "$FilePath\$File") {
        Return $false
    }
}
# Check if the Class IDs are present in HKEY_CLASSES_ROOT and return false if they are
Foreach ($Path in $CLSIDPaths) {
    Foreach ($ID in $CLSIDs) {
        If (Test-Path "$Path\$ID") {
            Return $false
        }
    }
}
Return $true
#EndRegion
#Region: Remediation
New-PSDrive -Name HKCR -PSProvider Registry -Root "HKEY_CLASSES_ROOT" | Out-Null
$FileNames = @(
    "msxml.dll",
    "msxml4.dll"
)
$CLSIDs = @(
    # Microsoft have provided the CLSIDs for MSXML 4.0 here: https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ms754671(v=vs.85)
    "{88d969c0-f192-11d4-a65f-0040963251e5}",
    "{88d969c4-f192-11d4-a65f-0040963251e5}",
    "{88d969c1-f192-11d4-a65f-0040963251e5}",
    "{88d969c9-f192-11d4-a65f-0040963251e5}",
    "{88d969d6-f192-11d4-a65f-0040963251e5}",
    "{88d969c8-f192-11d4-a65f-0040963251e5}",
    "{88d969ca-f192-11d4-a65f-0040963251e5}",
    "{7c6e29bc-8b8b-4c3d-859e-af6cd158be0f}",
    "{88d969c6-f192-11d4-a65f-0040963251e5}",
    "{88d969c5-f192-11d4-a65f-0040963251e5}",
    "{88d969c2-f192-11d4-a65f-0040963251e5}",
    "{88d969c3-f192-11d4-a65f-0040963251e5}"
)
# Check the architecture so we can set paths based on x64 or x86 Windows
If ([Environment]::Is64BitOperatingSystem) {
    $FilePath = "$env:WINDIR\SysWOW64"
    $CLSIDPaths = "HKCR:\WOW6432Node\CLSID", "HKLM:\SOFTWARE\WOW6432Node\Classes\CLSID"
    $Registry = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
} Else {
    $FilePath = "$env:WINDIR\System32"
    $CLSIDPaths = "HKCR:\CLSID", "HKLM:\SOFTWARE\Classes\CLSID"
    $Registry = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
}
# Check if the software is installed and uninstall it if it is
$UninstallKeys = Get-ItemProperty "$Registry\*"
Foreach ($Key in $UninstallKeys) {
    If ($Key.DisplayName -like "MSXML 4.0 * Parser") {
        $Uninstall = Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\MsiExec.exe" -ArgumentList "/x $($Key.PSChildName) /qn" -PassThru
        While (Get-Process -Pid $Uninstall.Id -ErrorAction SilentlyContinue) {
            Start-Sleep -Seconds 1
        }
    }
}
# Check if the DLLs are present in %sysnative%\System32 and if they are unregister them, then move them if they're still present
Foreach ($File in $FileNames) {
    If (Test-Path "$FilePath\$File") {
        Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\regsvr32.exe" -ArgumentList "/u /s $File" -Wait
        If (Test-Path "$FilePath\$File") {
            New-Item -Path "$env:ProgramData\Microsoft\MSXML" -ItemType Directory -Force | Out-Null
            Move-Item -Path "$FilePath\$File" -Destination "$env:ProgramData\Microsoft\MSXML\$File.bak" -Force | Out-Null
        }
    }
}
# Check if the Class IDs are present in HKEY_CLASSES_ROOT and if they are back them up and then delete them
Foreach ($Path in $CLSIDPaths) {
    Foreach ($ID in $CLSIDs) {
        If (Test-Path "$Path\$ID") {
            New-Item -Path "$env:ProgramData\Microsoft\MSXML" -ItemType Directory -Force | Out-Null
            $ProgID = Get-ItemProperty -Path "$Path\$ID\ProgID" | Select-Object -ExpandProperty '(default)'
            Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\reg.exe" -ArgumentList "EXPORT $($Path.Replace(':',''))\$ID $env:ProgramData\Microsoft\MSXML\$ProgID.reg /y" -Wait
            Remove-Item -Path "$Path\$ID" -Force -Recurse -Confirm:$false
        }
    }
}
#EndRegion
