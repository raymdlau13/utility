function archiveFiles
{
	param (
		[Parameter(Mandatory=$true)][string] $folder
	   ,[Parameter(Mandatory=$true)][Object[]] $fileToArchive
	   ,[Parameter(Mandatory=$false)][Int32] $DaysToKeep = 14
	   ,[Parameter(Mandatory=$false)][string] $destDateFormat = "yyyy/MM/dd"
   
	)
	$dateToKeep=(Get-Date).Date.AddDays([Math]::Abs($DaysToKeep)*-1)	
	foreach ($fileToArchive in $fileArchiveTable) {
		$filePattern  = $fileToArchive.file_pattern
		$dateFormat   = $fileToArchive.date_format
		$regexPattern = $fileToArchive.regex_pattern
		write-host "checking filePattern : $($filePattern), dateFormat:$($dateFormat), regexPattern:$($regexPattern) ..."
		foreach ($file in (get-childitem $folder -Filter $filePattern -File)) { 
			#if ($file.Name -match "_(\d{8})(\.|_)" ) { 
			if ($file.Name -match $regexPattern ) { 
				try {
					$destDate = [DateTime]::ParseExact($matches[1].ToString(),$dateFormat,$null)
					$destDatedDir = $destDate.ToString($destDateFormat)
					write-host "File: $($file), Destination: $($destDatedDir)" 
					if ( $destDate -lt $dateToKeep ) {
						if ( -not (Test-Path -Path $folder\$destDatedDir) ) { 
							[void](New-Item -Path $folder -Name $destDatedDir -ItemType "Directory")
						}
						write-host "      moving to $($folder)/$($destDatedDir)"
						move-item -Path $file.FullName -Destination $folder\$destDatedDir -Force
					} else {
						write-host "      current date file, not moving."
					}
				} catch {
					write-host "[Error] file:$($file.Name), filePattern: $($filePattern), dateFormat:$($dateFormat), regexPattern:$($regexPattern), destDate:$($matches[1].ToString())"
					write-host $_
				}
			}
		}
	}
}