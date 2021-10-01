$sourceSSRS = "sourceSSRSServerName"
$targetSSRS = "targetSSRSServerName"
 
$sourceRsUri = "http://$($sourceSSRS)/ReportServer/ReportService2010.asmx?wsdl"
$sourceProxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri
$sourceFolder = '/SourceFolderName'
## download files like BXC* or GSO* from $sourceProxy under $sourceFolder
Get-RsFolderContent -Proxy $sourceProxy -RsFolder $sourceFolder | 
Where-Object { (($_.Name -Like 'BXC*') -or ($_.Name -Like 'GSO*')) -and $_.TypeName -eq 'Report' } |
Foreach-Object { 
  Write-host "Downloading from $($_.Path) ..."
  Out-RsCatalogItem -Proxy $sourceProxy -Path $_.Path -Destination . 
}

$targetRsUri = "http://$($targetSSRS)/ReportServer/ReportService2010.asmx?wsdl"
$targetProxy = New-RsWebServiceProxy -ReportServerUri $targetRsUri
## upload files like GSO* to targetProxy under path specified in $targetFolder
$targetFolder = '/targetFolderName'
Get-ChildItem . -Filter *.rdl | 
Foreach-Object {
  Write-Host "Uploading to $($targetFolder)/$($_.Name) ..."
  Write-RsCatalogItem -proxy $targetProxy -Path $_ -RsFolder $targetFolder  -Overwrite:$true -ErrorAction Stop
}  
