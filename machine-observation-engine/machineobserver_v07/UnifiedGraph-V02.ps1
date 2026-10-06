# MachineObserver UnifiedGraph V0.2
# Joins ApplicationGraph V0.1 with historical V3.2 socket/correlation evidence.
param(
 [string]$ApplicationGraph="C:\MachineObserver\application-graph-v01.json",
 [string]$ReportV32="C:\MachineObserver\report-v32.json",
 [string]$SocketFile="C:\MachineObserver\sockets-v32.jsonl",
 [string]$OutputFile="C:\MachineObserver\unified-graph-v02.json"
)
$ErrorActionPreference="Stop"
function Read-JsonLines([string]$Path){$a=@();foreach($l in Get-Content $Path){if(-not [string]::IsNullOrWhiteSpace($l)){try{$a+=($l|ConvertFrom-Json)}catch{}}};return $a}
$app=Get-Content $ApplicationGraph -Raw|ConvertFrom-Json
$report=Get-Content $ReportV32 -Raw|ConvertFrom-Json
$sockets=@(Read-JsonLines $SocketFile)
$rows=@()
if($report.chrome_rows){$rows+=@($report.chrome_rows)}
if($report.edge_rows){$rows+=@($report.edge_rows)}
$hosts=@{}
foreach($r in @($app.resources)){try{$h=([Uri][string]$r.name).DnsSafeHost.ToLowerInvariant()}catch{continue};if($h){$hosts[$h]=$true}}
$validSockets=@($sockets|Where-Object{$_.remoteAddr -and $null-ne $_.remotePort})
$endpoints=@($validSockets|ForEach-Object{"$($_.remoteAddr):$($_.remotePort)"}|Sort-Object -Unique)
$hostEvidence=@()
foreach($h in @($hosts.Keys|Sort-Object)){
 $m=@($rows|Where-Object{([string]$_.Host).ToLowerInvariant()-eq $h})
 $hostEvidence+=[PSCustomObject]@{
  host=$h;applicationSeen=1;historicalRows=$m.Count
  single=@($m|Where-Object Verdict-eq "SINGLE").Count
  ambiguous=@($m|Where-Object Verdict-eq "AMBIGUOUS").Count
  noSocket=@($m|Where-Object Verdict-eq "NO_SOCKET").Count
  contradictionV32=@($m|Where-Object Verdict-eq "CONTRADICTION").Count
 }
}
function Sum([string]$p){$x=$hostEvidence|Measure-Object -Property $p -Sum;if($null-eq $x.Sum){0}else{[int]$x.Sum}}
$vector=[ordered]@{
 applicationObserved=1;targetObserved=1;documentObserved=1
 applicationHosts=$hosts.Count;socketIntervals=$validSockets.Count;remoteEndpoints=$endpoints.Count
 historicalSingle=(Sum "single");historicalAmbiguous=(Sum "ambiguous")
 historicalNoSocket=(Sum "noSocket");historicalContradiction=(Sum "contradictionV32")
 exactRequestSocketProof=0
}
$nodes=@()
foreach($s in $validSockets){$nodes+=[PSCustomObject]@{type="TCP_SOCKET_INTERVAL";evidenceClass="OBSERVED_OS";pid=$s.pid;family=$s.family;role=$s.role;localAddr=$s.localAddr;localPort=$s.localPort;remoteAddr=$s.remoteAddr;remotePort=$s.remotePort;firstSeen=$s.firstSeen;lastSeen=$s.lastSeen}}
$claims=@(
 [PSCustomObject]@{state="OBSERVED";claim="DeepSeek application document was observed through CDP."},
 [PSCustomObject]@{state="OBSERVED";claim="Application resource hosts were observed by browser Resource Timing."},
 [PSCustomObject]@{state="OBSERVED";claim="TCP socket intervals were observed by the Windows socket sensor."},
 [PSCustomObject]@{state="CORRELATED";claim="Some browser requests are temporally and endpoint-compatible with controlled-family sockets."},
 [PSCustomObject]@{state="UNKNOWN";claim="A particular HTTP request is proven to have used a particular TCP socket."}
)
$out=[ordered]@{
 schema="machineobserver.unified-evidence-graph.v0.2";generatedAt=(Get-Date).ToUniversalTime().ToString("o")
 sources=[ordered]@{applicationGraph=$ApplicationGraph;v32Report=$ReportV32;socketEvidence=$SocketFile}
 privacy=[ordered]@{credentialValuesRead=$false;cookieValuesRead=$false;storageValuesRead=$false;storageKeyNamesCopiedIntoUnifiedGraph=$false}
 vector=$vector;hostEvidence=$hostEvidence;graph=[ordered]@{socketNodes=$nodes;remoteEndpoints=$endpoints};claims=$claims
}
$out|ConvertTo-Json -Depth 20|Set-Content $OutputFile -Encoding UTF8
Write-Host "=== INPUT EVIDENCE ===" -ForegroundColor Cyan
Write-Host "Application graph : YES";Write-Host "V3.2 report       : YES";Write-Host "Socket records    : $($sockets.Count)";Write-Host "V3.2 correlation rows : $($rows.Count)"
Write-Host "";Write-Host "=== UNIFIED VECTOR ===" -ForegroundColor Cyan;[PSCustomObject]$vector|Format-List
Write-Host "=== APPLICATION HOST EVIDENCE ===" -ForegroundColor Cyan;$hostEvidence|Format-Table -AutoSize
Write-Host "=== EVIDENCE CLAIMS ===" -ForegroundColor Cyan;$claims|Format-Table state,claim -Wrap -AutoSize
Write-Host "UNIFIED EVIDENCE GRAPH V0.2 COMPLETE" -ForegroundColor Green
Write-Host "Evidence: $OutputFile"
