Install-PackageProvider -Name NuGet -Confirm:$False -Force -Scope AllUsers
Install-Module -Name PSWindowsUpdate -Confirm:$False -Force -Scope AllUsers
Import-Module -Name PSWindowsUpdate -Force -Scope Global
Get-WindowsUpdate -MicrosoftUpdate -UpdateType Software -RootCategories 'Critical Updates','Security Updates' -Install -IgnoreReboot -Confirm:$false