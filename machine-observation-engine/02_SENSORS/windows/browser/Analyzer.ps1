param([string]$LogFile="C:\MachineObserver\capture.jsonl")
if(-not(Test-Path $LogFile)){Write-Host "Log not found: $LogFile";return}
$records=Get-Content $LogFile|Where-Object{$_ -match '\S'}|ForEach-Object{try{$_|ConvertFrom-Json}catch{}}|Where-Object{$_}
if(-not $records){Write-Host "No records.";return}
Write-Host "Total responses: $($records.Count)"
Write-Host "--- By class ---"
$records|Group-Object class|Sort-Object Count -Descending|Format-Table Name,Count -AutoSize
Write-Host "--- By host + PID ---"
$records|Group-Object host|Sort-Object Name|ForEach-Object{$first=$_.Group|Select-Object -First 1;[pscustomobject]@{Host=$_.Name;Count=$_.Count;IP=$first.remoteIP;PID=$first.chromePID;Process=$first.procName}}|Format-Table -AutoSize
Write-Host "--- Unique URLs by class ---"
$records|Group-Object class|Sort-Object Name|ForEach-Object{Write-Host "[$($_.Name)]";$_.Group|Select-Object -ExpandProperty url|Sort-Object -Unique|ForEach-Object{Write-Host "  $_"}}
