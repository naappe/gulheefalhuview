param([string]$History="",[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
$an=Join-Path $BaseDir "DeepHistoryAnalyzer-V01.py"
if(-not(Test-Path $an)){throw "Missing $an"}

function Get-TraceCount([string]$p){
 if(-not $p -or -not(Test-Path $p)){return 0}
 return @(Get-ChildItem $p -Recurse -File -Filter "transport.txt" -ErrorAction SilentlyContinue).Count
}

if(-not $History){
 $roots=@()
 $historyRoot=Join-Path $BaseDir "history"
 $sessionRoot=Join-Path $BaseDir "sessions"
 if(Test-Path $historyRoot){$roots+=Get-ChildItem $historyRoot -Directory -Filter "RUN_*" -ErrorAction SilentlyContinue}
 if(Test-Path $sessionRoot){$roots+=Get-ChildItem $sessionRoot -Directory -ErrorAction SilentlyContinue}
 $candidates=@($roots|ForEach-Object{
  $count=Get-TraceCount $_.FullName
  if($count -gt 0){[pscustomobject]@{Path=$_.FullName;TraceCount=$count;LastWriteTime=$_.LastWriteTime}}
 }|Sort-Object LastWriteTime -Descending)
 if($candidates.Count -eq 0){throw "No completed transport.txt trace found under C:\MachineObserver\history or sessions. Finish a capture first."}
 $History=$candidates[0].Path
 Write-Host ("AUTO-SELECTED EVIDENCE: "+$History) -ForegroundColor Yellow
 Write-Host ("transport.txt files  : "+$candidates[0].TraceCount)
}else{
 if((Get-TraceCount $History) -eq 0){throw "Selected history contains no transport.txt: $History"}
}

$out=Join-Path $History "deep-history.json"
python $an $History -o $out
if($LASTEXITCODE -ne 0){throw "Deep analyzer failed."}
$d=Get-Content $out -Raw|ConvertFrom-Json
if([int]$d.sourceFiles -eq 0){throw "Analyzer returned zero source files; refusing an empty deep-history result."}
Write-Host ""
Write-Host "=== MACHINEOBSERVER DEEP HISTORY ===" -ForegroundColor Cyan
Write-Host "Evidence directory  : $History"
Write-Host "Trace files         : $($d.sourceFiles)"
Write-Host "Connection objects  : $($d.connectionObjects)"
Write-Host "TX events           : $($d.transport.txEvents)"
Write-Host "RX events           : $($d.transport.rxEvents)"
Write-Host "ACK events          : $($d.transport.ackEvents)"
Write-Host "RTT events          : $($d.transport.rttEvents)"
Write-Host "Deep graph          : $out" -ForegroundColor Green
