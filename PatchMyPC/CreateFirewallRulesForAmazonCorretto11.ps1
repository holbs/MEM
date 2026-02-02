<#
.SYNOPSIS
    Script to create firewall rules for Amazon Corretto 11 installations.
.DESCRIPTION
    Used as a post install script in Patch My PC to create inbound firewall rules for Amazon Corretto 11 installations. The script first removes any existing rules for Amazon Corretto where the installation path no longer exists, then creates new rules for any current installations found.
#>

Try {
    # Clean up any existing firewall rules for Amazon Corretto if the paths no longer exist
    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "OpenJDK Platform Binary*"} | Foreach-Object {
        $Filter = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_ -ErrorAction Stop
        If ($Filter -and $Filter.Program -and -not (Test-Path -Path $Filter.Program)) {
            Remove-NetFirewallRule -Name $_.Name -ErrorAction Stop
        }
    }
    # Get Amazon Corretto 11 paths from Program Files for 64-bit installations and Program Files (x86) for 32-bit installations
    $ProgramFilesAmazonCorretto = Get-ChildItem -Path "$env:ProgramW6432\Amazon Corretto","${env:ProgramFiles(x86)}\Amazon Corretto" -Directory -ErrorAction Stop | Where-Object {$_.Name -like "jdk11.*"}
    $ProgramFilesAmazonCorrettoResolvedPaths = $ProgramFilesAmazonCorretto | Foreach-Object {Get-ChildItem -Path $_.FullName -Recurse -Filter "java.exe" -ErrorAction Stop | Where-Object {$_.FullName -like "*bin\java.exe"}}
    # Create new firewall rules for each current Amazon Corretto 11 installation
    $ProgramFilesAmazonCorrettoResolvedPaths | Foreach-Object {
        # Dynamically set the rule name to use the version of java.exe
        $Arch = If ($_.Directory -like "${env:ProgramFiles(x86)}*") {"x86"} Else {"x64"}
        $Version = $_.VersionInfo.FileVersion
        $RuleName = "OpenJDK Platform Binary for Amazon Corretto $Arch $Version"
        # Check if the rule already exists
        If (-not (Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue)) {
            # Create the firewall rule for the Amazon Corretto 11
            New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Protocol TCP -Action Allow -Program $_.FullName -Profile Domain,Private,Public -ErrorAction Stop
        }
    }
} Catch {
    Write-Verbose -Message "Error occurred while creating firewall rules for Amazon Corretto 11: $_"
    Exit 1
}