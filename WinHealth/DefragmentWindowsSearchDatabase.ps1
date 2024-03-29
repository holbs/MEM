#Region: Detection
Return $false
#EndRegion
#Region: Remediation
Try {
    Set-Service -Name "wsearch" -StartupType "Disabled" -ErrorAction Stop
    Stop-Service -Name "wsearch" -ErrorAction Stop
    Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\EsentUtl.exe" -ArgumentList "/d $env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
    Wait-Process -Name "EsentUtl" -ErrorAction SilentlyContinue
    Set-Service -Name "wsearch" -StartupType "Automatic" -ErrorAction Stop
    Start-Service -Name "wsearch" -ErrorAction Stop
} Catch {
    Set-Service -Name "wsearch" -StartupType "Automatic" -ErrorAction SilentlyContinue
    Start-Service -Name "wsearch"
}
#EndRegion