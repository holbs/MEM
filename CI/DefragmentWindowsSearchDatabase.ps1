#Region: Detection
Return $false
#EndRegion
#Region: Remediation
Try {
    Set-Service -Name "wsearch" -StartupType "Disabled" -Status "Stopped" -ErrorAction Stop
    Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\EsentUtl.exe" -ArgumentList "/d $env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
    Wait-Process -Name "EsentUtl" -ErrorAction SilentlyContinue
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction Stop
} Catch {
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction Stop
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction Stop
}
#EndRegion
