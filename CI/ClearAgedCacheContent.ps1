#Region: Detection
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheContents = $Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).AddDays(-7)}
If ($CacheContents) {
    Return $false
} Else {
    Return $true
}
#EndRegion
#Region: Remediation
$UIResourceMgr = New-Object -ComObject UIResource.UIResourceMgr
$Cache = $UIResourceMgr.GetCacheInfo()
$CacheContents = $Cache.GetCacheElements() | Where-Object {[datetime]$_.LastReferenceTime -lt (Get-Date).AddDays(-7)}
Foreach ($Obj in $CacheContents) {
    $Cache.DeleteCacheElement($Obj.CacheElementID)
}
#EndRegion
