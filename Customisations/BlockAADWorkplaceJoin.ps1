#Region: Detection
Try {
    $BlockAADWorkplaceJoin = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin" -ErrorAction Stop
    If ($BlockAADWorkplaceJoin.BlockAADWorkplaceJoin -eq 1) {
        Return $true
    } Else {
        Return $false
    }
} Catch {
    Return $false
}
#EndRegion
#Region: Remediation
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin' -Name 'BlockAADWorkplaceJoin' -Value '1' -Type DWord -Force | Out-Null
#EndRegion
