#Region: Detection
$ClientAuthCert = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object {$_.Extensions | Where-Object {$_.Format(0) -match "Client Authenication"}} | Sort-Object NotAfter -Descending | Select-Object -f 1
If ($ClientAuthCert.NotAfter -ge (Get-Date)) {
    Return $true
} Elseif ($ClientAuthCert.NotAfter -lt (Get-Date)) {
    Return $false
} Else {
    Return $false
}
#EndRegion
#Region: Remediation

#EndRegion
