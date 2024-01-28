#Region: Detection
Try {
    $StartMenu = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -ErrorAction Stop
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
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Force
#EndRegion
