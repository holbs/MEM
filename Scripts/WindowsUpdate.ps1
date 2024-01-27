Install-PackageProvider -Name NuGet
Install-Module -Name PSWindowsUpdate -Confirm:$False -Force -Scope Allusers
Import-Module -Name PSWindowsUpdate
Get-WindowsUpdate -MicrosoftUpdate -UpdateType Software -RootCategories 'Critical Updates','Security Updates' -Install -IgnoreReboot -Confirm:$false