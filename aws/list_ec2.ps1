param ( 
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$profile
)
$v = aws ec2 describe-instances --profile "$profile" | ConvertFrom-Json
Write-Output "Name|InstaceId|Platform|AMI|Type|State|Function|Env"
$amiRepo = @{}
foreach ( $res in $v[0].Reservations ) { 
    $instance = $res.Instances[0]
    $instName = ($instance.Tags | Where-Object { $_.Key -eq 'Name' }).value
    $func = ($instance.Tags | Where-Object { $_.Key -eq 'Function' }).value
    $env = ($instance.Tags | Where-Object { $_.Key -eq 'Env' }).value
    #$ami = aws ec2 describe-images --image-ids $instance.ImageId  --profile "$profile" | ConvertFrom-Json
    $PlatformDetails = ""
    if ( "$($instance.Platform)" -eq "" ) {
        if ( -not $amiRepo.containsKey($instance.ImageId) ) {
            $ami = aws ec2 describe-images --image-ids $instance.ImageId  --profile "$profile" | ConvertFrom-Json
            $PlatformDetails =  $ami.Images[0].PlatformDetails
            $amiRepo.Add($instance.ImageId, $PlatformDetails)
        } else {
            $PlatformDetails = $amiRepo[$instance.ImageId]
        }
    } else {
        $PlatformDetails = $instance.Platform
    }
    Write-Output "$($instName)|$($instance.InstanceId)|$PlatformDetails|$($instance.ImageId)|$($instance.InstanceType)|$($instance.State.name)|$func|$env" 
}

