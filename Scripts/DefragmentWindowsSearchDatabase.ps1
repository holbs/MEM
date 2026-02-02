<#
.SYNOPSIS
    Defragments the Windows Search Database.
.DESCRIPTION
    This script stops the Windows Search service, defragments the Windows Search database using EsentUtl.exe, and then restarts the Windows Search service to improve search performance and free up drive space.
.NOTES
    Windows 10 uses the Windows Search database Windows.edb. In Windows 11 this is replaced by Windows.db
#>

Try {
    # Determine the path to the Windows Search database
    $Database = Resolve-Path -Path "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.*db" -ErrorAction Stop
    # Stop the Windows Search service
    Set-Service -Name "wsearch" -StartupType "Disabled" -Status "Stopped" -ErrorAction Stop
    # Defragment the Windows Search database
    $EsentUtl = Start-Process -WindowStyle hidden -FilePath "$env:WINDIR\System32\EsentUtl.exe" -ArgumentList "/d $Database" -PassThru
    # Wait for the defragmentation process to complete. Timeout of 15 minutes (900 seconds)
    Get-Process -Id $EsentUtl.Id -ErrorAction SilentlyContinue | Wait-Process -Timeout 900 -ErrorAction Stop
    # Restart the Windows Search service
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction Stop
} Catch {
    # In case of any errors, ensure the Windows Search service is running again
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction SilentlyContinue
    Set-Service -Name "wsearch" -StartupType "Automatic" -Status "Running" -ErrorAction SilentlyContinue
}