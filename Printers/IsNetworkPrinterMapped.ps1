<#
.DESCRIPTION
    This script checks if specific print queues are mapped for the currently logged-on user. It runs in the SYSTEM context, and inspects the HKEY_USERS registry hive for the logged on user to find printer connections. It outputs "Detected" to stdout only if all specified print queues are found.
#>

#Requires -RunAsAdministrator
#Requires -Version 5.1

##*=============================================
##* Define the print queues to check for. You can modify this list to include the print queues you want to verify.
##*=============================================

$PrintQueues = @(
    "\\PrintServer.domain.com\Queue1",
    "\\PrintServer.domain.com\Queue2"
)

##*=============================================
##* Main script logic
##*=============================================

Try {
    # Get the currently logged on user using CIM
    $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $LoggedOnUser = $ComputerSystem.UserName
    # Ensure that the application is only set to run when a user is logged on to avoid this, but if the script detects no user is logged on return "No user logged on" to stdout. This is considered compliant so the installation won't run in this scenario but it avoids errors.
    If (-not $LoggedOnUser) {
        Write-Output "No user logged on"
        Exit 0
    }
    # Get the user's SID
    $UserSID = (New-Object System.Security.Principal.NTAccount($LoggedOnUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    # Registry path for user's printer connections
    $PrinterRegPath = "Registry::HKEY_USERS\$UserSID\Printers\Connections"
    # Check if the registry path exists. If it does not exist, it means no printers are mapped for the user. Exit silently without outputting anything to fail detection and kick off the installation.
    If (-not (Test-Path -Path $PrinterRegPath)) {
        Exit 0
    }
    # Get all printer connections for the user
    $PrinterConnections = Get-ChildItem -Path $PrinterRegPath -ErrorAction SilentlyContinue
    # If no printer connections are found, exit silently without outputting anything to fail detection and kick off the installation.
    If (-not $PrinterConnections) {
        Exit 0
    }
    # Convert registry key names back to UNC paths
    $MappedPrinters = @()
    Foreach ($Connection in $PrinterConnections) {
        $PrinterName = $Connection.Name.Split('\')[-1]
        # Convert registry format back to UNC path
        $UncPath = $PrinterName -Replace ',','\'
        $MappedPrinters += "\\$UncPath"
    }
    # Check if ALL required print queues are mapped
    $AllQueuesFound = $true
    Foreach ($Queue in $PrintQueues) {
        If ($MappedPrinters -notcontains $Queue) {
            $AllQueuesFound = $false
            Break
        }
    }
    # If all required print queues are found, output "Detected" to stdout and exit with code 0. If not all queues are found, exit silently without outputting anything to fail detection and kick off the installation.
    If ($AllQueuesFound) {
        Write-Output "Detected"
        Exit 0
    } Else {
        # Silent exit when non-compliant - no stdout output
        Exit 0
    }
} Catch {
    # If there are any errors during execution, exit silently without outputting anything to fail detection and kick off the installation.
    Exit 0
}