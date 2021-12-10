
$ssrsServers = ConvertFrom-Csv @'
ssrsName,serverName,dbName
'@

$finalSet = $null

foreach ( $ssrsServer in $ssrsServers ) {

    $sqlStmt = @"
WITH CTE AS (
    SELECT ItemPath
         , RequestType
         , UserName
         , CONVERT(VARCHAR,TimeStart,111) reportRunDate
         , CASE 
             WHEN CHARINDEX('/',REVERSE(ItemPath)) > 0 THEN 
               LEFT(ItemPath,LEN(ItemPath) - CHARINDEX('/',REVERSE(ItemPath))) 
             ELSE 
               ItemPath 
           END Folder
      FROM dbo.ExecutionLog3 
     WHERE DATEDIFF(dd,TimeStart,GETDATE()) < 90 )
SELECT ReportServerName = '$($ssrsServer.ssrsName)', Folder, ItemPath, RequestType, reportRunDate, UserName, NumOfExecution = COUNT(1)
  FROM CTE
 GROUP BY Folder, ItemPath, RequestType, reportRunDate, UserName
"@

    $resultSet = Invoke-Sqlcmd -ServerInstance $ssrsServer.serverName `
                 -Database $ssrsServer.dbName `
                 -Query $sqlStmt `
                 -queryTimeout 600

    if ($resultSet) {
        $finalSet += $resultSet
    }
    # $resultSet | `
    # ForEach-Object{ Write-Output "{ $($_.ItemPath), $($_.RequestType), $($_.UserName), $($_.reportRunDate), $($_.NumOfExecution) }" }
}

if ($finalSet) {
    $finalSet | Select-Object -Property ReportServerName, Folder, ItemPath, RequestType, reportRunDate, UserName, NumOfExecution | `
    Export-Csv -Path .\ssrsUsage.csv -NoTypeInformation
}


