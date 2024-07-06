#Region: Detection
Try {
    $StartMenu = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction Stop
    If ($StartMenu.TaskbarAl -eq 0) {
        Return $true
    } Else {
        Return $false
    }
} Catch {
    Return $false
}
#EndRegion
#Region: Remediation
New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Force | Out-Null
#EndRegion
