. ".\archiveFiles.ps1"

$fileArchiveTable = ConvertFrom-Csv @'
file_pattern,date_format,regex_pattern
filename_*,MMddyyyy,filename_(\d{8})_
anotherfilename_*,yyMMdd,anotherfilename_(\d{6})\.csv
anotherway*,yyyy-MM-dd,anotherway.+(\d{4}-\d{2}-\d{2})\s+
'@

$folder = "\\Path\To\Where\All\The\File\To\Be\Archived"

archiveFiles -Folder $folder -fileToArchive $fileArchiveTable
