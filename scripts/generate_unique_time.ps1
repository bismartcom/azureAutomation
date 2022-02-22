$UTCNow = (Get-Date).ToUniversalTime()
$UTCTimeTick = $UTCNow.Ticks.tostring()
Write-Output $UTCTimeTick