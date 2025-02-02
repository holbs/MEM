<#
.DESCRIPTION
    This script is deployed as an application to a collection of workstations where Microsoft Teams has been detected in one of the users %LOCALAPPDATA%\Microsoft folders by a configuration item.
    The deployment itself runs in the user context, so the software is removed from the user of the workstation. If there are other users on the workstation with Teams it still remains non-compliant to the CI and the application will be removed when they are logged in.
#>

#Region: Detection
Try {
    $Signature = Get-AuthenticodeSignature -FilePath "$env:LOCALAPPDATA\Microsoft\Teams\update.exe"
    If ($Signature.Status -eq "Valid" -and $Signature.SignerCertificate.Subject -eq "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") {
        Write-Output "Installed"
    } Else {
        Throw "File not signed by Microsoft"
    }
} Catch {
    # File not found or not signed by Microsoft
}
#EndRegion
#Region: Uninstall
Try {
    $Signature = Get-AuthenticodeSignature -FilePath "$env:LOCALAPPDATA\Microsoft\Teams\update.exe"
    If ($Signature.Status -eq "Valid" -and $Signature.SignerCertificate.Subject -eq "CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US") {
        $Teams = Start-Process -FilePath "$env:LOCALAPPDATA\Microsoft\Teams\update.exe" -ArgumentList "--uninstall -s" -PassThru
        Wait-Process -Id $Teams.Id
    } Else {
        Throw "File not signed by Microsoft"
    }
} Catch {
    # File not found or not signed by Microsoft
}
#EndRegion