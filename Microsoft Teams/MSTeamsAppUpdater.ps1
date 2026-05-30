<#
.SYNOPSIS
    Script to download the latest Microsoft Teams bootstrapper and MSIX, then update a Configuration Manager application source.
.DESCRIPTION
    Downloads the latest Microsoft Teams bootstrapper (teamsbootstrapper.exe) and the latest MSIX and saves to a provided location, then updates the content of a provided Configuration Manager application on the distribution points it's assigned to.
#>
 
#Requires -Version 5.1
#Requires -RunAsAdministrator
 
# Define parameters
Param (
    [Parameter(Mandatory = $true)]
    [string]$ContentLocation,
    [Parameter(Mandatory = $true)]
    [string]$AppModelName # Provide the ModelName for the application that is returned from Get-CMApplication. This is the unique value that remains constant even when the application is updated and the revision count goes up
)
 
# Define download URLs (taken from Microsoft documentation here: https://learn.microsoft.com/en-us/microsoftteams/teams-client-bulk-install#option-1b-download-and-install-teams-using-an-offline-installer)
$TeamsBootstrapperUrl = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
$TeamsMsixUrl = "https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix"
 
# Create C:\Temp directory if it doesn't exist
If (-not (Test-Path -Path "C:\Temp")) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
}
 
# Download the files to C:\Temp first to confirm the downloads complete successfully
$TempBootstrapperPath = Join-Path -Path "C:\Temp" -ChildPath "teamsbootstrapper.exe"
$TempMsixPath = Join-Path -Path "C:\Temp" -ChildPath "MSTeams-x64.msix"
Try {
    Invoke-WebRequest -Uri $TeamsBootstrapperUrl -OutFile $TempBootstrapperPath -UseBasicParsing -ErrorAction Stop
    Invoke-WebRequest -Uri $TeamsMsixUrl -OutFile $TempMsixPath -UseBasicParsing -ErrorAction Stop
} Catch {
    Write-Verbose -Message "Error downloading files: $_"
    Exit 1
}
 
# Create a copy of the MSIX and convert this to a ZIP file by renaming the file extension
$TempZipPath = [System.IO.Path]::ChangeExtension($TempMsixPath, ".zip")
Try {
    Copy-Item -Path $TempMsixPath -Destination $TempZipPath -Force -ErrorAction Stop
} Catch {
    Write-Verbose -Message "Error creating ZIP copy of MSIX: $_"
    Exit 1
}
 
# Import necessary assembly for ZIP file handling
Add-Type -AssemblyName System.IO.Compression.FileSystem
 
# Read the AppxManifest.xml from within the ZIP to get the version number
Try {
    $ZipFile = [System.IO.Compression.ZipFile]::OpenRead($TempZipPath)
    $AppxManifestContent = $ZipFile.Entries | Where-Object {$_.FullName -eq "AppxManifest.xml"} | Foreach-Object {
        $Stream = $_.Open()
        $Reader = New-Object System.IO.StreamReader($Stream)
        $Reader.ReadToEnd()
    }
    $AppxManifestXml = [xml]$AppxManifestContent
    $TeamsVersion = $AppxManifestXml.Package.Identity.Version
} Catch {
    Write-Verbose -Message "Error reading AppxManifest.xml: $_"
    Exit 1
} Finally {
    # Clean up the temporary ZIP file by closing it first, then deleting it
    $ZipFile.Dispose()
    Remove-Item -Path $TempZipPath -Force -ErrorAction SilentlyContinue
}
 
# Copy the downloaded files to the Configuration Manager source folder, overwriting existing files
$DestinationBootstrapperPath = Join-Path -Path $ContentLocation -ChildPath "teamsbootstrapper.exe"
$DestinationMsixPath = Join-Path -Path $ContentLocation -ChildPath "MSTeams-x64.msix"
Try {
    Copy-Item -Path $TempBootstrapperPath -Destination $DestinationBootstrapperPath -Force -ErrorAction Stop
    Copy-Item -Path $TempMsixPath -Destination $DestinationMsixPath -Force -ErrorAction Stop
} Catch {
    Write-Verbose -Message "Error copying files to Configuration Manager source folder: $_"
    Exit 1
}
 
# Clean up temporary files from C:\Temp
Remove-Item -Path $TempBootstrapperPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $TempMsixPath -Force -ErrorAction SilentlyContinue
 
# Connect to the Configuration Manager site
Try {
    Import-Module "$($env:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" -ErrorAction Stop
    $SiteCode = (Get-PSDrive -PSProvider CMSite).Name
    Set-Location "$SiteCode`:"
} Catch {
    Write-Verbose -Message "Error connecting to Configuration Manager site: $_"
    Exit 1
}
 
# Check the provided application ID exists in Configuration Manager
$App = Get-CMApplication -ModelName $AppModelName
If ($null -eq $App) {
    Write-Verbose -Message "Configuration Manager application '$AppModelName' not found."
    Exit 1
}
 
# Update the application with the new version number
Set-CMApplication -InputObject $App -SoftwareVersion $TeamsVersion -NewName "MSTeams_x64_$TeamsVersion" -Description "$(Get-Date -Format 'yyyy-MM-dd') - Updated by automation script. MSTeams has been updated to version $TeamsVersion."
 
# Update the Configuration Manager application content, first getting the app object again to ensure it's up to date and then using this with Update-CMDistributionPoint
Try {
    $App = Get-CMApplication -ModelName $AppModelName
    $DeploymentType = $App | Get-CMDeploymentType
    Update-CMDistributionPoint -ApplicationName $App.LocalizedDisplayName -DeploymentTypeName $DeploymentType.LocalizedDisplayName
} Catch {
    Write-Verbose -Message "Error updating Configuration Manager distribution points: $_"
    Exit 1
}