$targetSSRS = "rereports"
$targetRsUri = "http://$($targetSSRS)/ReportServer/ReportService2010.asmx?wsdl"
$targetProxy = New-RsWebServiceProxy -ReportServerUri $targetRsUri
## upload files like GSO* to targetProxy under path specified in $targetFolder
$targetFolder = '/targetFolderName'
Get-ChildItem . -Filter *.rdl | 
Foreach-Object {
  Write-Host "backing up $($targetFolder)/$($_.NameBase) to backup folder ..."
  Out-RsCatalogItem -Proxy $targetProxy  -Destination ./backup -Path "$($targetFolder)/$($_.BaseName)"
  Write-Host "Uploading to $($targetFolder)/$($_.Name) ..."  
  Write-RsCatalogItem -proxy $targetProxy -Path $_ -RsFolder $targetFolder  -Overwrite:$true -ErrorAction Stop
}


