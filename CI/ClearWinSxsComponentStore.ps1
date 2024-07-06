#Region: Detection
$CheckComponentStore = & "$env:WINDIR\System32\dism.exe" /Online /Cleanup-Image /AnalyzeComponentStore
If ($CheckComponentStore | Select-String "Component Store Cleanup Recommended : Yes") {
    Return $false
} Else {
    Return $true
}
#EndRegion
#Region: Remediation
Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\dism.exe" -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup"
#EndRegion
