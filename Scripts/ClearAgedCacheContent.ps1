<#
.SYNOPSIS
    Clears cached content that has not been referenced in the last 7 days.
.DESCRIPTION
    This script utilizes the UIResourceMgr COM object to identify and delete cached content that has not been accessed in the past 7 days, helping to free up disk space.
.NOTES
    This is only applicable for workstations with the Configuration Manager client installed. Remove the Where-Object filter to clear all cached content regardless of last reference time.
#>

$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheContents = $Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).AddDays(-7)}
Foreach ($Obj in $CacheContents) {
    $Cache.DeleteCacheElement($Obj.CacheElementID)
}