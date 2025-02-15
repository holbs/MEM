<#
.DESCRIPTION
    This script to be deployed as a configuration item to check if Microsoft Teams Classic is in any of the users %LOCALAPPDATA%\Microsoft folders. This reports compliant if Microsoft Teams is not found. The non-complaint devices then make up the membership of a device collection.
#>

#Requires -RunAsAdministrator

#Region: Detection
$Compliance = $true
# Find all copies of the Teams update.exe file in the users %LOCALAPPDATA%\Microsoft folder, then check the signature of the file to confirm it's signed by Microsoft. If a file is found that is signed by Microsoft, the device is non-compliant.
$Files = Get-Item -Path "$env:SystemDrive\Users\*\AppData\Local\Microsoft\Teams\update.exe"
If ($Files) {
    Foreach ($Update in $Files) {
        $Signature = Get-AuthenticodeSignature -FilePath $Update.FullName
        If ($Signature.Status -eq "Valid" -and $Signature.SignerCertificate.Subject -eq "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") {
            $Compliance = $false
        }
    }
}
Write-Output $Compliance
#EndRegion
#Region: Remediation

#EndRegion