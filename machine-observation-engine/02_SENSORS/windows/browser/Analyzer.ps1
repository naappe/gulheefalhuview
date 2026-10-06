param([string]$LogFile="C:\MachineObserver\capture.jsonl")
if(-not(Test-Path $LogFile)){Write-Host "Log not found: $LogFile";return}
$records=Get-Content $LogFile|Where-Object{$_ -match '\S'}|ForEach-Object{try{$_|ConvertFrom-Json}catch{}}|Where-Object{$_}
if(-not $records){Write-Host "No records.";return}

$unique=$records|Group-Object {
 if($_.resourceKey){$_.resourceKey}
 else{"$($_.method)|$($_.url)|$($_.status)|$($_.remoteIP)|$($_.remotePort)"}
}|ForEach-Object{$_.Group|Select-Object -First 1}

Write-Host "============================================================"
Write-Host " Raw observations : $($records.Count)"
Write-Host " Unique resources : $($unique.Count)"
Write-Host " Duplicates       : $($records.Count-$unique.Count)"
Write-Host "============================================================"

Write-Host "--- Raw observations by class ---"
$records|Group-Object class|Sort-Object Count -Descending|Format-Table Name,Count -AutoSize

Write-Host "--- Unique resources by class ---"
$unique|Group-Object class|Sort-Object Count -Descending|Format-Table Name,Count -AutoSize

Write-Host "--- Host + PID evidence ---"
$records|Group-Object host|Sort-Object Name|ForEach-Object{
 $g=$_.Group
 $pids=@($g|Where-Object{$_.chromePID}|Select-Object -ExpandProperty chromePID -Unique)
 $ips=@($g|Where-Object{$_.remoteIP -and $_.remoteIP -ne "-"}|Select-Object -ExpandProperty remoteIP -Unique)
 [pscustomobject]@{
  Host=$_.Name;Observations=$_.Count;UniqueResources=@($unique|Where-Object{$_.host -eq $_.Name}).Count
  RemoteIP=($ips -join ",");ChromePID=if($pids){$pids -join ","}else{"UNKNOWN"}
 }
}|Format-Table -AutoSize

Write-Host "--- Unique URLs by class ---"
$unique|Group-Object class|Sort-Object Name|ForEach-Object{
 Write-Host "[$($_.Name)]"
 $_.Group|Select-Object -ExpandProperty url|Sort-Object -Unique|ForEach-Object{Write-Host "  $_"}
}

Write-Host "--- TLS summary ---"
$records|Where-Object{$_.tls}|Group-Object host|ForEach-Object{
 $r=$_.Group|Select-Object -First 1
 [pscustomobject]@{Host=$_.Name;TLS=$r.tls.protocol;Cipher=$r.tls.cipher;Cert=$r.tls.subject;Issuer=$r.tls.issuer}
}|Format-Table -AutoSize
