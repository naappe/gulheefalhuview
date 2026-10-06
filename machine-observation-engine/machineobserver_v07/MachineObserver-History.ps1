param(
 [int]$Hours = 8,
 [int]$ChunkMinutes = 10,
 [int]$MaxGB = 10,
 [string]$BaseDir = "C:\MachineObserver"
)
$ErrorActionPreference="Stop"
if($Hours -lt 1){throw "Hours must be >= 1"}
if($ChunkMinutes -lt 1){throw "ChunkMinutes must be >= 1"}
if($MaxGB -lt 1){throw "MaxGB must be >= 1"}
$etw=Join-Path $BaseDir "EtwTransportSensor-V01.ps1"
if(-not(Test-Path $etw)){throw "Missing $etw"}
$root=Join-Path $BaseDir "history"
New-Item -ItemType Directory -Path $root -Force|Out-Null
$run=Join-Path $root ("RUN_"+(Get-Date -Format "yyyy-MM-dd_HHmmss"))
New-Item -ItemType Directory -Path $run -Force|Out-Null
$index=Join-Path $run "history-index.jsonl"
$started=Get-Date
$ends=$started.AddHours($Hours)
$seq=0
function Get-DirBytes([string]$Path){
 $n=0L
 Get-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue|ForEach-Object{$n+=$_.Length}
 return $n
}
function Write-Index($obj){
 ($obj|ConvertTo-Json -Compress -Depth 8)|Add-Content $index -Encoding UTF8
}
Write-Index ([ordered]@{type="RUN_START";time=$started.ToUniversalTime().ToString("o");hours=$Hours;chunkMinutes=$ChunkMinutes;maxGB=$MaxGB;privacy="transport metadata only"})
Write-Host "=== MACHINEOBSERVER LONG HISTORY ===" -ForegroundColor Cyan
Write-Host "Run       : $run"
Write-Host "Until     : $ends"
Write-Host "Disk cap  : $MaxGB GB"
Write-Host "Chunk     : $ChunkMinutes minutes"
Write-Host "Stop      : Ctrl+C" -ForegroundColor Yellow
try{
 while((Get-Date) -lt $ends){
  $seq++
  $now=Get-Date
  $remaining=[int][Math]::Ceiling(($ends-$now).TotalSeconds)
  if($remaining -le 0){break}
  $seconds=[Math]::Min($ChunkMinutes*60,$remaining)
  $chunk=Join-Path $run ("chunk_{0:D5}_{1}" -f $seq,(Get-Date -Format "yyyy-MM-dd_HHmmss"))
  New-Item -ItemType Directory -Path $chunk -Force|Out-Null
  $out=Join-Path $chunk "transport.jsonl"
  Write-Host ""
  Write-Host ("[{0}] chunk {1} / {2}s" -f (Get-Date -Format "HH:mm:ss"),$seq,$seconds) -ForegroundColor Green
  $t0=Get-Date
  $ok=$true;$err=$null
  try{& $etw -OutFile $out -Duration $seconds}catch{$ok=$false;$err=$_.Exception.Message}
  $t1=Get-Date
  $bytes=Get-DirBytes $chunk
  Write-Index ([ordered]@{type="CHUNK";sequence=$seq;start=$t0.ToUniversalTime().ToString("o");end=$t1.ToUniversalTime().ToString("o");durationSeconds=[int]($t1-$t0).TotalSeconds;ok=$ok;bytes=$bytes;path=$chunk;error=$err})
  $total=Get-DirBytes $run
  Write-Host ("History size: {0:N2} GB" -f ($total/1GB))
  if($total -ge ($MaxGB*1GB)){
   Write-Index ([ordered]@{type="STOP";reason="DISK_CAP";time=(Get-Date).ToUniversalTime().ToString("o");bytes=$total})
   Write-Host "Disk cap reached. Capture stopped safely." -ForegroundColor Yellow
   break
  }
 }
}finally{
 try{pktmon stop 2>$null|Out-Null}catch{}
 $finished=Get-Date
 $total=Get-DirBytes $run
 Write-Index ([ordered]@{type="RUN_END";time=$finished.ToUniversalTime().ToString("o");chunks=$seq;bytes=$total})
 $summary=[ordered]@{
  schema="machineobserver.long-history.v0.1"
  started=$started.ToUniversalTime().ToString("o")
  finished=$finished.ToUniversalTime().ToString("o")
  requestedHours=$Hours
  chunkMinutes=$ChunkMinutes
  chunks=$seq
  bytes=$total
  gigabytes=[Math]::Round($total/1GB,3)
  directory=$run
  index=$index
  evidenceClass="OBSERVED_KERNEL_TRACE"
  limits=[ordered]@{payloadInspection=$false;tlsPlaintext=$false;credentials=$false;cookies=$false;exactHttpRequestSocketProof=$false}
 }
 $summary|ConvertTo-Json -Depth 6|Set-Content (Join-Path $run "history-summary.json") -Encoding UTF8
 Write-Host ""
 Write-Host "=== HISTORY COMPLETE ===" -ForegroundColor Cyan
 Write-Host "Chunks : $seq"
 Write-Host ("Size   : {0:N2} GB" -f ($total/1GB))
 Write-Host "Index  : $index"
 Write-Host "Folder : $run" -ForegroundColor Green
}
