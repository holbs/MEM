#Region: Detection
$ProgramData = Get-Item $env:ProgramData -Force
If ($ProgramData.Attributes -like "*Hidden*") {
    Return $false
} Else {
    Return $true
}
#EndRegion
#Region: Remediation
$Folder = Get-Item $env:ProgramData -Force 
$Folder.Attributes = $Folder.Attributes -band -bnot [System.IO.FileAttributes]::Hidden
#EndRegion
