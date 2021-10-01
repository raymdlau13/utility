$targetSSRS = "reports"
$targetRsUri = "http://$($targetSSRS)/ReportServer/ReportService2010.asmx?wsdl"
$targetProxy = New-RsWebServiceProxy -ReportServerUri $targetRsUri

Get-RsFolderContent -Proxy $targetProxy -RsFolder / -Recurse | `
Select-Object @{Name='Server';Expression={$targetSSRS}},@{Name='Folder';Expression={$_.Path.SubString(0,$_.Path.LastIndexOf("/")+1)}},Name,TypeName,ModifiedDate,ModifiedBy | `
Export-Csv -Path "c:\temp\$($targetSSRS)_d.csv" -NoTypeInformation
