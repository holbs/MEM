<#
.SYNOPSIS
    Ensures that WinVerifyTrust EnableCertPaddingCheck is set to 1 for both 32-bit and 64-bit registry paths to mitigate CVE-2013-3900.
.DESCRIPTION
    This script checks if the EnableCertPaddingCheck registry value is set to 1 in both the 32-bit and 64-bit paths for WinVerifyTrust. If not, it sets the value to 1 in both locations.
.NOTES
    Microsoft have previously published guidance that these settings should be strings, but that has since been updated to indicate they should be DWORDs: https://msrc.microsoft.com/update-guide/vulnerability/CVE-2013-3900
#>

#Region: Detection
$WinVerifyTrust = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -ErrorAction SilentlyContinue
$WinVerifyTrustWow6432Node = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -ErrorAction SilentlyContinue
If ($WinVerifyTrust -eq 1 -and $WinVerifyTrustWow6432Node -eq 1) {
    Write-Output "WinVerifyTrust EnableCertPaddingCheck is set"
    Exit 0
} else {
    Write-Output "WinVerifyTrust EnableCertPaddingCheck is not set"
    Exit 1
}
#EndRegion
#Region: Remediation
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust' -ErrorAction SilentlyContinue | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config' -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value 1 -Type DWord -Force | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust' -ErrorAction SilentlyContinue | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -ErrorAction SilentlyContinue | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Cryptography\Wintrust\Config' -Name 'EnableCertPaddingCheck' -Value 1 -Type DWord -Force | Out-Null
#EndRegion