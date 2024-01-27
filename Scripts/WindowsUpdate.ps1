Install-PackageProvider -Name NuGet -Confirm:$false -Force -Scope AllUsers
Install-Module -Name PSWindowsUpdate -Confirm:$false -Force -Scope AllUsers
Import-Module -Name PSWindowsUpdate -Force -Scope Global
Get-WindowsUpdate -MicrosoftUpdate -UpdateType Software -RootCategories 'Critical Updates','Security Updates' -Install -IgnoreReboot -Confirm:$false