param([int]$Seconds=30,[string]$OutFile="C:\MachineObserver\sockets.jsonl")
function Get-ProcName { param([int]$ProcessId)
 if($ProcessId -le 4){return '(kernel/unknown)'}
 $p=Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
 if($p){return $p.ProcessName};return '(exited)'
}
if(Test-Path $OutFile){Remove-Item $OutFile -Force}
$end=(Get-Date).AddSeconds($Seconds);$seen=@{}
while((Get-Date)-lt $end){
 try{Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue|ForEach-Object{
  $key="$($_.LocalAddress):$($_.LocalPort)->$($_.RemoteAddress):$($_.RemotePort)"
  if(-not $seen.ContainsKey($key)){$seen[$key]=$true
   $rec=[ordered]@{timestamp=(Get-Date).ToString("o");sensor="windows-tcp-snapshot";localAddr=$_.LocalAddress;localPort=$_.LocalPort;remoteAddr=$_.RemoteAddress;remotePort=$_.RemotePort;pid=$_.OwningProcess;procName=Get-ProcName -ProcessId $_.OwningProcess}
   ($rec|ConvertTo-Json -Compress)|Add-Content $OutFile -Encoding UTF8
  }}}catch{}
 Start-Sleep -Milliseconds 500
}
Write-Host "Done. Rows: $($seen.Count)"
