. .\copyItem.ps1

$ssrsServers = ConvertFrom-Csv @'
ssrsName,serverName,dbName,targetSsrsName
'@
# $finalSet = $null

foreach ( $ssrsServer in $ssrsServers ) {
    Write-Output "checking changes in $($ssrsServer.ssrsName) ..."
    $sqlStmt = @"
CREATE TABLE #ItemType (
    Type INT
,   TypeName VARCHAR(25)
)
INSERT INTO #ItemType VALUES
( 1, 'Folder' ),
( 2, 'Report' ),
( 3, 'Resource' ),
( 4, 'LinkedReport' ),
( 5, 'DataSource' )

SELECT a.Path Item
     , ISNULL(b.TypeName,'Unkonw') Type
  FROM dbo.Catalog a
  LEFT JOIN #ItemType b on b.Type = a.Type
 WHERE DATEDIFF(dd,a.ModifiedDate,GETDATE()) <= 20 and a.Type in ( 2, 5 )
"@
    Write-Output "querying in db $($ssrsServer.serverName) ..."
    $resultSet = Invoke-Sqlcmd -ServerInstance $ssrsServer.serverName `
                 -Database $ssrsServer.dbName `
                 -Query $sqlStmt `
                 -queryTimeout 600

    if ($resultSet) {
        Write-Output "Syncing from $($ssrsServer.ssrsName) to $($ssrsServer.targetSsrsName) with following changes ..."
        $resultSet | ForEach-Object { Write-Output "  $($_.Item) of type $($_.Type)"}
        copyItem -srcSSRS $ssrsServer.ssrsName -dstSSRS $ssrsServer.targetSsrsName -srcItems $resultSet
    } else {
        Write-Output "  no changes in $($ssrsServer.ssrsName)."
    }

}



