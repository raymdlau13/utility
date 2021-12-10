$esc = [char]27
$gotoFirstColumn = "$esc[0G"
$Progress = @( "-","\", "|", "/" )
for ( $i = 0; $i -lt 10000; $i++ ) {
	$displayIdx = $i%4
	$Elapsed = (measure-command { Copy-Item \\networkpath\filename.ext . -force }).totalmilliseconds
	if ( $Elapsed -gt 10000 ) {
		write-host "Overrun for $Elapsed" -foregroundcolor Red
	} else {
		write-host "${gotoFirstColumn}working $($Progress[$displayIdx])" -nonewline
	}
	Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 10)
}
