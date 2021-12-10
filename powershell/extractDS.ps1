$dataSources = Import-Csv -Path DataSourceDetails.csv
$uniqueCreds = @{}
foreach ( $dataSource in $dataSources ) {
    #if ( $dataSource.CredentialRetrieval -eq 'Store' -and $dataSource.UserName -ne '' -and $dataSource.UserName.IndexOf('\') -lt 0 ) {
        $regexPattern = "Data Source=(?<datasource>.+);"
        if ( $dataSource.ConnectString -match $regexPattern ) {
            #$key = $dataSource.UserName.ToLower() + ":" + $Matches.datasource.ToLower()
            $key = $Matches.datasource.ToLower()
            if ( -not $uniqueCreds[$key] ) {
                $uniqueCreds.Add($key,$Matches.datasource)
            }
        }
    #}
}
$uniqueCreds
