param ( 
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$targetEnv,
        [Parameter(Mandatory=$false)]
        [switch]$Override = $false
)
Function New-TemporaryFolder {
    # Create Temporary File and store object in $T
    $File = New-TemporaryFile

    # Remove the temporary file!
    Remove-Item $File -Force

    # Make a new folder based upon the old name
    $tmpFolder = New-Item -Itemtype Directory -Path "$($ENV:Temp)\$($File.Name)"

    return $tmpFolder.FullName
}

$envJosn = ConvertFrom-Json @'
{
    "dev" : {
        "smtpappdev.xxx.com" : "mail.aws.xxx.com",
        "olddbserver\\\\instance" : "newdbservername",
        "olddbserver\\instance" : "newdbservername",
        "olddbserver" : "bxc-sql-nv-d01"
    },
    "qa" : {
        "smtpappdev.xxx.com" : "mail.aws.xxx.com",
        "olddbserver\\\\instance" : "newdbservername",
        "olddbserver\\instance" : "newdbservername",
        "olddbserver" : "bxc-sql-nv-d01"
    },
    "qb" : {
        "smtpappdev.xxx.com" : "mail.aws.xxx.com",
        "olddbserver\\\\instance" : "newdbservername",
        "olddbserver\\instance" : "newdbservername",
        "olddbserver" : "bxc-sql-nv-d01"
    },
    "prod" : {
        "smtpappdev.xxx.com" : "mail.aws.xxx.com",
        "olddbserver\\\\instance" : "newdbservername",
        "olddbserver\\instance" : "newdbservername",
        "olddbserver" : "bxc-sql-nv-d01"
    }
}
'@

Write-Host "targetEnv = $targetEnv"
Write-Host "Override = $Override"
$patterns = $envJosn.PSObject.Properties.Match($targetEnv).value

$findPattern = ""
$patterns.PSObject.Properties | ForEach-Object { $findPattern += ( "|" + [Regex]::Escape($_.Name) )}
$findPattern = "(" + $findPattern.SubString(1) + ")"
Write-Host "findPattern = $findPattern"

$backupDt = (Get-Date).ToString("yyyyMMdd_HHmm")

$tempFolder = New-TemporaryFolder
write-host "temp folder = $($tempFolder)"


# searching for target files 
$configFiles = @()
foreach ($folder in ( Get-ChildItem -directory -recurse | where-object { $_.PsIsContainer -and $_.FullName -notmatch '(temp|backup|archive|bkup)' } ) ) {
    foreach ($file in ( Get-ChildItem -Path $folder.FullName -File | where-object { $_.FullName -match '\.(dtsx|dtsConfig|config|xml|yaml|ini|cfg|bat|ps1|vbs|py)$' } )) {
        $found = ( Select-String -Path $file.FullName -pattern $findPattern )
        if ( $found.count -gt 0 ) {
            $configFiles += $file.FullName
        }
    }
}

# backing up target files
foreach ($configFile in $configFiles) {
    $backupFile = $tempFolder + $configFile.SubString(2)
    # write-host $backupFile
    New-Item -ItemType File -Path $backupFile -Force | Out-Null
    Copy-Item $configFile $backupFile -Force | Out-Null
}

compress-archive -Path "$tempFolder\*" -DestinationPath "d:\temp\$($backupDt)_ConfigFiles.zip"

$tempOutFolder = ""
if ( $Override -eq $false ) {
    $tempOutFolder = New-TemporaryFolder
}

write-host "Output Folder = $($tempOutFolder)"
# replacing target files
foreach ($configFile in $configFiles ) {
    $replacedContent = (Get-Content -path $configFile -Raw)
    foreach ( $pattern in $patterns.PSObject.Properties ) {
        $replacedContent = $replacedContent -replace [Regex]::Escape($pattern.Name), $pattern.Value
    }
    if ( $Override -eq $true ) {
        $alternativeFile = $configFile
    } else {
        $alternativeFile = $tempOutFolder + $configFile.SubString(2)
    }
    New-Item -ItemType File -Path $alternativeFile -Force | Out-Null
    $replacedContent | Set-Content -Path $alternativeFile -Force
}



