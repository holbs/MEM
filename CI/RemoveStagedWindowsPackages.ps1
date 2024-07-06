#Region: Detection
$Packages = Get-WindowsPackage -Online
If ("Staged" -in $Packages.PackageState) {
    Return $false
} Else {
    Return $true
}
#EndRegion
#Region: Remediation
Get-WindowsPackage -Online | Where-Object {$_.PackageState -eq "Staged"} | Remove-WindowsPackage -Online
#EndRegion
