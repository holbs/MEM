#Region: Detection
$CAIssuingServer = "CN=PKIServer, DC=contoso, DC=com"
$ClientAuthCerts = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Issuer -eq $CAIssuingServer} | Where-Object {$_.Extensions | Where-Object {$_.Format(0) -match "Client Auth"}}
# Check the certificates to see if they are valid and return $false if any are not valid
$CertsCompliance = $true
Foreach ($Certificate in $ClientAuthCerts) {
    If (Test-Certificate $Certificate -ErrorAction SilentlyContinue) {
        # Certificate is valid
    } Else {
        $CertsCompliance = $false
    }
}
# Return the valid of the certificate after checking
Return $CertsCompliance
#EndRegion
#Region: Remediation
& $env:WINDIR\System32\gpupdate.exe /force /target:computer | Out-Null
#EndRegion
