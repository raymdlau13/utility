Function New-TemporaryFolder {
    # Create Temporary File and store object in $T
    $File = New-TemporaryFile

    # Remove the temporary file .... Muah ha ha ha haaaaa!
    Remove-Item $File -Force

    # Make a new folder based upon the old name
    $tmpFolder = New-Item -Itemtype Directory -Path "$($ENV:Temp)\$($File.Name)"

    return $tmpFolder.FullName
}
function getNewDBServerName
{
    Param (
		[Parameter(Mandatory=$true)] $currentDBServerName
	)
    $newDBServerName = $currentDBServerName
    $dbServerNameHash = @{
        "oldservername" = "newservername"
    }
    if ( $dbServerNameHash[$currentDBServerName] ) {
        $newDBServerName = $dbServerNameHash[$currentDBServerName]
    }
    return $newDBServerName
}
function GetCredential
{
    Param (
		[Parameter(Mandatory=$true)] $key
	)
    $result = '1Welcome2'
    $credentialHash = @{
        "username:dbservername" = "password"
    }
    if ( $credentialHash[$key] ) {
        $result = $credentialHash[$key]
    }
    return $result
}
function SetSharedDataSource
{
	Param (
		[Parameter(Mandatory=$true)] $srcProxy
	   ,[Parameter(Mandatory=$true)] $dstProxy
	   ,[Parameter(Mandatory=$true)][string] $itemWithFullPath
    #    ,[Parameter(Mandatory=$true)][string] $itemTypeName
	)

    $srcDSDef = Get-RsDataSource -Proxy $srcProxy -Path $itemWithFullPath
    $tgtDSDef = Get-RsDataSource -Proxy $dstProxy -Path $itemWithFullPath

    $tgtDSDef.ConnectString = $srcDSDef.ConnectString
    $tgtDSDef.UseOriginalConnectString = $srcDSDef.UseOriginalConnectString
    $tgtDSDef.OriginalConnectStringExpressionBased = $srcDSDef.OriginalConnectStringExpressionBased
    $tgtDSDef.CredentialRetrieval = $srcDSDef.CredentialRetrieval
    $tgtDSDef.WindowsCredentials = $srcDSDef.WindowsCredentials
    $tgtDSDef.ImpersonateUser = $srcDSDef.ImpersonateUser
    $tgtDSDef.ImpersonateUserSpecified = $srcDSDef.ImpersonateUserSpecified
    $tgtDSDef.Prompt = $srcDSDef.Prompt
    $tgtDSDef.Enabled = $srcDSDef.Enabled
    $tgtDSDef.EnabledSpecified = $srcDSDef.EnabledSpecified

    if ( $srcDSDef.CredentialRetrieval -ne 'Store' ) {
        $tgtDSDef.UserName = [NullString]::Value
        $tgtDSDef.Password = [NullString]::Value
    }

    # Write-Host "  overriding connectString, UserName and Password ..."
    $connectString = $srcDSDef.ConnectString -replace "`n", ""
    Write-Host "  connectString=$connectString ..."
    $regexPattern = "Data Source=(?<datasource>.+);"
    if ( $connectString -match $regexPattern) {
        $currentDBServerName = $Matches.datasource
        $newDBServerName = GetNewDBServerName -currentDBServerName $currentDBServerName.ToLower()
        $newConnectString = $connectString -replace [regex]::escape($currentDBServerName),$newDBServerName
        Write-Host "  new connectString = $newConnectString ..."
        $tgtDSDef.ConnectString = $newConnectString
        # if ( $srcDSDef.CredentialRetrieval -eq 'Store' -and $srcDSDef.UserName -ne '' -and $srcDSDef.UserName.IndexOf('\') -lt 0 ) {
        if ( $srcDSDef.CredentialRetrieval -eq 'Store' -and $srcDSDef.UserName -ne '' ) {

            $UserName = $srcDSDef.UserName
            $Password = ""
            if ($UserName -and $currentDBServerName) {
                $key = $UserName.ToLower()+":"+$currentDBServerName.ToLower()
                $Password = GetCredential -key $key
            }
            $srcDSDef.CredentialRetrieval = 'Store'
            $tgtDSDef.UserName = $srcDSDef.UserName
            $tgtDSDef.Password = $Password
        }
    }
    Write-Host "  setting target datasource attributes ..."
    Set-RsDataSource -Proxy $dstProxy -RsItem $itemWithFullPath -DataSourceDefinition $tgtDSDef
}
function SetEmbeddedDataSource {
	Param (
		[Parameter(Mandatory=$true)] $srcProxy
	   ,[Parameter(Mandatory=$true)] $dstProxy
	   ,[Parameter(Mandatory=$true)][string] $itemWithFullPath
	)

    $currentItem  = $itemWithFullPath
    $sourceDataSources = Get-RsItemDataSource -Proxy $srcProxy -RsItem $currentItem
    $targetDataSources = Get-RsItemDataSource -Proxy $dstProxy -RsItem $currentItem

    if ( ($sourceDataSources.Count -ne $targetDataSources.Count) -or $sourceDataSources.Count -eq 0 -or $targetDataSources -eq 0 ) {
        return
    }
    $doNotSetDataSource = $false
    for ($i = 0; $i -lt $sourceDataSources.Count; $i++) {
        if ($sourceDataSources[$i].Item.GetType().Name -eq 'InvalidDataSourceReference' ) {
            write-host "  Source Report has invalid DataSource, skipping." -ForegroundColor Red
            $doNotSetDataSource = $true
            break
        }
        # if ("$($sourceDataSources[$i].Item.Reference)" -ne "") {
        if ( $sourceDataSources[$i].Item.GetType().Name -eq "DataSourceReference" ) {
            # skip for shared data source
            #write-host "it is a shared datasource, skipping."
            $doNotSetDataSource = $true
            break
        }
        if ( $sourceDataSources[$i].Item.GetType().Name -ne "DataSourceDefinition" -or $targetDataSources[$i].Item.GetType().Name -ne "DataSourceDefinition" ) {
            # something wrong
            write-host "  either sourceDataSource or targetDataSource is not in type DataSourceDefinition !"
            $doNotSetDataSource = $true
            break
        }
        if ($sourceDataSources[$i].Name -ne $targetDataSources[$i].Name) {
            # something wrong
            write-host "  source and target dataSourceNames not match !"
            $doNotSetDataSource = $true
            break
        }
        $targetDataSources[$i].Item.ConnectString = $sourceDataSources[$i].Item.ConnectString
        $targetDataSources[$i].Item.UseOriginalConnectString = $sourceDataSources[$i].Item.UseOriginalConnectString
        $targetDataSources[$i].Item.OriginalConnectStringExpressionBased = $sourceDataSources[$i].Item.OriginalConnectStringExpressionBased
        $targetDataSources[$i].Item.CredentialRetrieval = $sourceDataSources[$i].Item.CredentialRetrieval
        $targetDataSources[$i].Item.WindowsCredentials = $sourceDataSources[$i].Item.WindowsCredentials
        $targetDataSources[$i].Item.ImpersonateUser = $sourceDataSources[$i].Item.ImpersonateUser
        $targetDataSources[$i].Item.ImpersonateUserSpecified = $sourceDataSources[$i].Item.ImpersonateUserSpecified
        $targetDataSources[$i].Item.Prompt = $sourceDataSources[$i].Item.Prompt
        $targetDataSources[$i].Item.Enabled = $sourceDataSources[$i].Item.Enabled
        $targetDataSources[$i].Item.EnabledSpecified = $sourceDataSources[$i].Item.EnabledSpecified

        if ( $targetDataSources[$i].Item.CredentialRetrieval -ne 'Store' ) {
            $targetDataSources[$i].Item.UserName = [NullString]::Value
            $targetDataSources[$i].Item.Password = [NullString]::Value
        } else { # CredentialRetrieval = 'Store'
            $currentDBServerName = ""
            if ( -not [string]::IsNullOrEmpty($sourceDataSources[$i].Item.ConnectString) ) {
                $connectString = $sourceDataSources[$i].Item.ConnectString -replace "`n", ""
                $regexPattern = "Data Source=(?<datasource>.+);"
                if ( $connectString -match $regexPattern) {
                    $currentDBServerName = $Matches.datasource
                    $newDBServerName = GetNewDBServerName -currentDBServerName $currentDBServerName.ToLower()
                    $newConnectString = $connectString -replace [regex]::escape($currentDBServerName),$newDBServerName
                    $targetDataSources[$i].Item.ConnectString = $newConnectString
                }

            }
            if ( $sourceDataSources[$i].Item.CredentialRetrieval -eq 'Store' `
                -and $sourceDataSources[$i].Item.UserName -ne '' `
                -and $sourceDataSources[$i].Item.UserName.IndexOf('\') -lt 0 ) {
                $UserName = $sourceDataSources[$i].Item.UserName
                $Password = ""
                if ($UserName -and $currentDBServerName) {
                    $key = $UserName.ToLower()+":"+$currentDBServerName.ToLower()
                    $Password = GetCredential -key $key
                }
                $targetDataSources[$i].Item.UserName = $sourceDataSources[$i].Item.UserName
                $targetDataSources[$i].Item.Password = $Password
            }
        }

    }
    if ( -not $doNotSetDataSource) {
        write-host "  updating targetDataSources ..."
        Set-RsItemDataSource -Proxy $dstProxy -RsItem $currentItem -DataSource $targetDataSources
    }
}
function copySsrsItem
{
	Param (
		[Parameter(Mandatory=$true)] $srcProxy
	   ,[Parameter(Mandatory=$true)] $dstProxy
	   ,[Parameter(Mandatory=$true)][string] $itemWithFullPath
       ,[Parameter(Mandatory=$true)][string] $itemTypeName
       ,[Parameter(Mandatory=$true)][string] $tempFolder
	)
	$strPath = $itemWithFullPath.SubString(0,$itemWithFullPath.LastIndexOf("/"))
    $strName = $itemWithFullPath.SubString($itemWithFullPath.LastIndexOf("/")+1)

	if ( $itemTypeName -eq 'Report' ) {
		$ext = '.rdl'
	} elseif ( $itemTypeName -eq 'DataSource' ) {
		$ext = '.rsds'
	} elseif ( $itemTypeName -eq 'DataSet' ) {
		$ext = '.rsd'
	} elseif ( $itemWithFullPath -match ".*?\.(jpg|jpeg|png)" ) {
	    $ext = ''
	} else {
        write-host "Unsupported item ! $($itemWithFullPath) skipped." -ForegroundColor Red
        return
    }
	Write-host "Copying $strPath , $strName, $itemTypeName, $ext ... " -NoNewline
    Out-RsCatalogItem -Proxy $sourceProxy -Path $itemWithFullPath -Destination $tempFolder
    $result =$true
    try {
	    Write-RsCatalogItem -proxy $targetProxy -Path "$tempFolder/$strName$ext" -RsFolder "$strPath"  -Overwrite:$true -ErrorAction Continue
        Write-Host "[Ok]" -ForegroundColor Green
        if ( $itemTypeName -eq 'DataSource' ) {
            SetSharedDataSource -srcProxy $srcProxy -dstProxy $dstProxy -itemWithFullPath $itemWithFullPath
        } elseif ( $itemTypeName -eq 'Report' ) {
            SetEmbeddedDataSource -srcProxy $srcProxy -dstProxy $dstProxy -itemWithFullPath $itemWithFullPath
        }
    } catch {
        Write-Host "[Failed]" -ForegroundColor Red
        $_.Exception.Message
        $result = $false
    }
    Remove-Item "$tempFolder/$strName$ext" -Force
    return $result

}
function copyItem {
	Param (
		[Parameter(Mandatory=$true)][string] $srcSSRS
	   ,[Parameter(Mandatory=$true)][string] $dstSSRS
	   ,[Parameter(Mandatory=$true)][Object[]] $srcItems
	)

    $ssrsTempFolder = New-TemporaryFolder
    Write-Host "Temp Folder = $ssrsTempFolder"

    Write-Host "connecting to sourceSSRS: $srcSSRS ..." -ForegroundColor Cyan
    $sourceSSRS = $srcSSRS
    $sourceRsUri = "http://$($sourceSSRS)/ReportServer/ReportService2010.asmx?wsdl"
    $sourceProxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri

    Write-Host "connecting to targetSSRS: $dstSSRS ..." -ForegroundColor Cyan
    $targetSSRS = $dstSSRS
    $targetRsUri = "http://$($targetSSRS)/ReportServer/ReportService2010.asmx?wsdl"
    $targetProxy = New-RsWebServiceProxy -ReportServerUri $targetRsUri

    $itemsInSourceSSRS = @{}
    Get-RsFolderContent -Proxy $sourceProxy -RsFolder "/" -Recurse | ForEach-Object { $itemsInSourceSSRS.Add("$($_.Path)",$_.TypeName)}

    $failedItems = @()
    foreach ($sourceItem in $srcItems) {
        #write-host "working on $($sourceItem.Item), $($sourceItem.Type) ..."
        if ( $itemsInSourceSSRS[$sourceItem.Item] -ne $sourceItem.Type ) {
            write-host "Specified $($sourceItem.Item) doesn't exist in sourceSSRS !" -ForegroundColor Yellow
            continue
        }
        if ( $sourceItem.Type -eq 'Folder' ) {
            $sourceFolder = $sourceItem.Item
            Get-RsFolderContent -Proxy $sourceProxy -RsFolder $sourceFolder -Recurse |
            Where-Object { ($_.TypeName -eq 'DataSource') } |
            Foreach-Object {
                $result = copySsrsItem -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $_.Path -itemTypeName $_.TypeName -tempFolder $ssrsTempFolder
                if ( -not $result ) {
                    $failedItems += "$($_.Path)"
                }
            }
            Get-RsFolderContent -Proxy $sourceProxy -RsFolder $sourceFolder -Recurse |
            Where-Object { ($_.TypeName -eq 'DataSet') } |
            Foreach-Object {
                $result = copySsrsItem -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $_.Path -itemTypeName $_.TypeName -tempFolder $ssrsTempFolder
                if ( -not $result ) {
                    $failedItems += "$($_.Path)"
                }
            }
            Get-RsFolderContent -Proxy $sourceProxy -RsFolder $sourceFolder -Recurse |
            Where-Object { (($_.TypeName -ne 'DataSet') -and ($_.TypeName -ne 'DataSource') -and ($_.TypeName -ne 'Folder')) } |
            Foreach-Object {
                $result = copySsrsItem -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $_.Path -itemTypeName $_.TypeName -tempFolder $ssrsTempFolder
                if ( -not $result ) {
                    $failedItems += "$($_.Path)"
                }
            }
        } else {
            $result = copySsrsItem -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $sourceItem.Item -itemTypeName $sourceItem.Type -tempFolder $ssrsTempFolder
            if ( -not $result ) {
                $failedItems += "$($_.Path)"
            }
        }
    }

    if ($failedItems.Count -gt 0) {
        Write-Host "`n`n"
        Write-Host "Please review following failed item(s):" -ForegroundColor Yellow
        $failedItems | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }
    }
}


function updateDataSource {
	Param (
		[Parameter(Mandatory=$true)][string] $srcSSRS
	   ,[Parameter(Mandatory=$true)][string] $dstSSRS
	   ,[Parameter(Mandatory=$true)][Object[]] $srcFolders
	)

    $sourceSSRS = $srcSSRS
    Write-Host "connecting to sourceSSRS: $sourceSSRS ..." -ForegroundColor Cyan
    $sourceRsUri = "http://$($sourceSSRS)/ReportServer/ReportService2010.asmx?wsdl"
    $sourceProxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri


    $targetSSRS = $dstSSRS
    Write-Host "connecting to targetSSRS: $targetSSRS ..." -ForegroundColor Cyan
    $targetRsUri = "http://$($targetSSRS)/ReportServer/ReportService2010.asmx?wsdl"
    $targetProxy = New-RsWebServiceProxy -ReportServerUri $targetRsUri

    foreach ( $folder in $srcFolders ) {
        write-host $folder
        Get-RsFolderContent -Proxy $sourceProxy -RsFolder $folder -Recurse |
        Where-Object { ($_.TypeName -eq 'DataSource' -or $_.TypeName -eq 'Report' ) } |
        Foreach-Object {
            write-host $_.Path
            if ( $_.TypeName -eq 'DataSource' ) {
                write-host "  going to update datasource $($_.Path) ..."
                SetSharedDataSource -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $_.Path
            } elseif ( $_.TypeName -eq 'Report' ) {
                write-host "  going to update report  $($_.Path) ..."
                SetEmbeddedDataSource -srcProxy $sourceProxy -dstProxy $targetProxy -itemWithFullPath $_.Path
            }
        }        
    }
}
