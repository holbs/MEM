<#
.SYNOPSIS
    Backs up the BitLocker recovery key for the C:\ drive to Entra if it has not already been backed up.
.DESCRIPTION
    This script checks if the BitLocker recovery key for the system drive (C:) has been backed up to Entra by looking for a specific event log entry. If the recovery key has not been backed up, it initiates the backup process to Entra.
#>

#Region: Detection
Try {
    # Get the BitLocker Volume for the System Drive (C:) and its Recovery Password Protector and GUID
    $BitLockerSystemDriveVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    $BitLockerRecoveryPasswordProtector = $BitLockerSystemDriveVolume.KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} -ErrorAction Stop
    $BitLockerRecoveryPasswordProtectorGuid = $BitLockerRecoveryPasswordProtector.KeyProtectorId
    # Query the Event Log for BitLocker Recovery Key Backup Event (Event ID 845) for the System Drive's Recovery Password Protector GUID
    $BitLockerBackupEvent = Get-WinEvent -ProviderName Microsoft-Windows-BitLocker-API -FilterXPath "*[System[(EventID=845)] and EventData[Data[@Name='ProtectorGUID'] and (Data='$BitLockerRecoveryPasswordProtectorGuid')]]" -MaxEvents 1 -ErrorAction Stop
    # If the Backup Event is found, output the event message and exit with success
    If ($BitLockerBackupEvent) {
        Write-Output $BitLockerBackupEvent.Message
        Exit 0
    } Else {
        # If no Backup Event is found, output a message and exit with failure
        Write-Output "No BitLocker Recovery Key Backup Event found for System Drive."
        Exit 1
    }
} Catch {
    Write-Output $_.Exception.Message
    Exit 1
}
#EndRegion
#Region: Remediation
Try {
    # Get the BitLocker Volume for the System Drive (C:) and its Recovery Password Protector and GUID
    $BitLockerSystemDriveVolume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    $BitLockerRecoveryPasswordProtector = $BitLockerSystemDriveVolume.KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} -ErrorAction Stop
    $BitLockerRecoveryPasswordProtectorGuid = $BitLockerRecoveryPasswordProtector.KeyProtectorId
    # Backup the Recovery Password Protector to Entra
    BackuptoAAD-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $BitLockerRecoveryPasswordProtectorGuid -ErrorAction Stop
} Catch {
    Write-Output $_.Exception.Message
    Exit 1
}
#EndRegion