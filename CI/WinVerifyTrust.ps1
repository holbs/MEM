#Region: Detection
Try {
    # Check both keys exist on the workstation first
    $1 = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -ErrorAction Stop
    $2 = Get-ItemProperty -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -ErrorAction Stop
    # Check that the string 'EnableCertPaddingCheck' is present and set to 1
    If ($1.EnableCertPaddingCheck -and $2.EnableCertPaddingCheck) {
        If ($1.EnableCertPaddingCheck -ne 1 -or $2.EnableCertPaddingCheck -ne 1) {
            Return $false
        }
    } Else {
        Return $false
    }
} Catch {
    Return $false
}
Return $true
#EndRegion
#Region: Remediation
New-Item -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust'
New-Item -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust\Config'
New-ItemProperty -Path 'HKLM:\Software\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value '1' -Type String -Force
New-Item -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust'
New-Item -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config'
New-ItemProperty -Path 'HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value '1' -Type String -Force
#EndRegion
