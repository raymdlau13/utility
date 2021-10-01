$hostname = $env:COMPUTERNAME

$regexPattern = '^\s+(?<Protocol>\w+)\s{2,}(?<LocalIP>.+):(?<LocalPort>.+?)\s{2,}(?<DestIP>.+):(?<DestPort>.+?)\s{2,}(?<State>.+?)\s{2,}(?<PID>\d+)'
#$regexPattern = '^\s+(?<Protocol>\w+)\s{2,}(?<LocalIP>.+):(?<LocalPort>.+?)\s{2,}(?<DestIP>.+):(?<DestPort>.+?)\s{2,}LISTENING\s{2,}(?<PID>\d+)'
#write-output "Hostname,Protocol,LocalIP,LocalPort,DestIP,DestPort,State,PID,ProcessName"
foreach ($line in (netstat -ano)) {
  if ($line -match $regexPattern ) { 
	if ($Matches.State -eq 'LISTENING') {
		$processName = Get-Process -Id ($Matches.PID) |select -ExpandProperty ProcessName
		write-output "$($hostname),$($matches.Protocol),$($matches.LocalIP),$($matches.LocalPort),$($matches.DestIP),$($matches.DestPort),$($matches.State),$($matches.PID),$($processName)"
	}
  }
}