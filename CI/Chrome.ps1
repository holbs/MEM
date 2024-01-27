#Region: Detection
If (Test-Path -Path "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\Application") {
    Return $false
} Else {
    Return $true
}
#EndRegion
#Region: Remediation
Get-Item -Path "$env:SystemDrive\Users\*\AppData\Local\Google\Chrome\Application" | Remove-Item -Recurse -Force -Confirm:$false
#EndRegion
