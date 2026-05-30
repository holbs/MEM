<#
.SYNOPSIS
    Script updates Microsoft 365 Apps content in a Configuration Manager source folder, then redistributes the content to distribution points.
.DESCRIPTION
    Downloads the latest ODT (setup.exe), uses this in download mode to download the latest Microsoft 365 Apps content, then updates the content of a provided Configuration Manager application on the distribution points it's assigned to.
.NOTES
    Script assumes the ContentLocation contains an XML file called Installation.xml with the necessary configuration for the ODT to download the correct Microsoft 365 Apps content.
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

# Get the latest ODT download link from the Microsoft Download Center to extract setup.exe. Download Center link taken from: https://learn.microsoft.com/en-gb/microsoft-365-apps/deploy/overview-office-deployment-tool#download-the-office-deployment-tool
Try {
    $OfficeDeploymentToolUrl = Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/p/?LinkID=626065" -UseBasicParsing
    $OfficeDeploymentToolUrl = $OfficeDeploymentToolUrl.Links | Where-Object {$_.href -like "https://download.microsoft.com/*/officedeploymenttool*"} | Select-Object -ExpandProperty href -First 1
    If (-not $OfficeDeploymentToolUrl) {
        Throw "Could not find ODT download link on Microsoft Download Center page"
    }
} Catch {
    Write-Verbose -Message "Error finding ODT download link: $_"
    Exit 1
}

# Create C:\Temp directory if it doesn't exist
If (-not (Test-Path -Path "C:\Temp" -PathType Container)) {
    New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
}

# Download ODT to C:\Temp first to confirm the downloads complete successfully
$TempOfficeDeploymentToolPath = Join-Path -Path "C:\Temp" -ChildPath "officedeploymenttool.exe"
Try {
    Invoke-WebRequest -Uri $OfficeDeploymentToolUrl -OutFile $TempOfficeDeploymentToolPath -UseBasicParsing -ErrorAction Stop
} Catch {
    Write-Verbose -Message "Error downloading files: $_"
    Exit 1
}

# Extract setup.exe from the ODT
Try {
    $ExtractODT = Start-Process -FilePath $TempOfficeDeploymentToolPath -ArgumentList "/extract:C:\Temp\ODT /quiet /log:C:\Temp\ODT.log" -Wait -PassThru -ErrorAction Stop
    # Check the exit code of the extraction process to confirm it completed successfully
    If ($ExtractODT.ExitCode -ne 0) {
        Throw "ODT extraction failed with exit code: $($ExtractODT.ExitCode)."
    }
} Catch {
    Write-Verbose -Message "Error extracting ODT: $_"
    Exit 1
}

# Copy the extracted setup.exe to the Configuration Manager source folder
Try {
    Copy-Item -Path "C:\Temp\ODT\setup.exe" -Destination $ContentLocation -Force -ErrorAction Stop
} Catch {
    Write-Verbose -Message "Error copying setup.exe to source folder: $_"
    Exit 1
}

# Download the latest source content using the extracted setup.exe and existing configuration XML file
Try {
    Set-Location -Path $ContentLocation
    $Download = Start-Process -FilePath "$ContentLocation\setup.exe" -ArgumentList "/download $ContentLocation\Installation.xml" -Wait -PassThru -ErrorAction Stop
    # Check the exit code of the download process to confirm it completed successfully
    If ($Download.ExitCode -ne 0) {
        Throw "Download failed with exit code: $($Download.ExitCode)."
    }
} Catch {
    Write-Verbose -Message "Error running setup.exe in download mode: $_"
    Exit 1
}

# Collect the architecture from the existing configuration XML file
Try {
    [xml]$ConfigXml = Get-Content -Path "$ContentLocation\Installation.xml" -ErrorAction Stop
    $Architecture = $ConfigXml.Configuration.Add.OfficeClientEdition
    If (-not $Architecture) {
        Throw "Could not find OfficeClientEdition in configuration XML."
    }
} Catch {
    Write-Verbose -Message "Error retrieving architecture from configuration XML: $_"
    Exit 1
}

# Collect the version number from the downloaded content
Try {
    $Version = Get-ChildItem -Path "$ContentLocation\Office\Data" -Directory -ErrorAction Stop
    $Version = $Version.Name
    # Check the string can be cast as a version number to confirm it's in the expected format
    [version]$Version | Out-Null
} Catch {
    Write-Verbose -Message "Error retrieving version number from downloaded content: $_"
    Exit 1
}

# Clean up temporary files from C:\Temp
Remove-Item -Path $TempOfficeDeploymentToolPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\ODT" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Temp\ODT.log" -Force -ErrorAction SilentlyContinue

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
Set-CMApplication -InputObject $App -SoftwareVersion $Version -NewName "Microsoft 365 Apps $Architecture $Version" -Description "$(Get-Date -Format 'yyyy-MM-dd') - Updated by automation script. Microsoft 365 Apps has been updated to version $Version."
 
# Update the Configuration Manager application content, first getting the app object again to ensure it's up to date and then using this with Update-CMDistributionPoint
Try {
    $App = Get-CMApplication -ModelName $AppModelName
    $DeploymentType = $App | Get-CMDeploymentType
    Update-CMDistributionPoint -ApplicationName $App.LocalizedDisplayName -DeploymentTypeName $DeploymentType.LocalizedDisplayName
} Catch {
    Write-Verbose -Message "Error updating Configuration Manager distribution points: $_"
    Exit 1
}