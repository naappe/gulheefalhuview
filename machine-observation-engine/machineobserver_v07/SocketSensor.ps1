# V3.2 TCP interval sampler. Bounds are observed, not exact kernel open/close times.
function Start-SocketSensor { [CmdletBinding()] param([Parameter(Mandatory)][object[]]$Graphs,[Parameter(Mandatory)][string]$OutFile,[int]$Seconds=60,[int]$PollMilliseconds=200)
 if(Test-Path $OutFile){Remove-Item $OutFile -Force};$idx=@{};foreach($g in $Graphs){foreach($kv in $g.Members.GetEnumerator()){$idx[[int]$kv.Key]=$kv.Value}}
 $iv=@{};$sample=0;$end=(Get-Date).AddSeconds($Seconds)
 while((Get-Date)-lt $end){$sample++;$now=(Get-Date).ToUniversalTime();$present=[Collections.Generic.HashSet[string]]::new()
  foreach($s in @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue)){$pid_=[int]$s.OwningProcess;if(-not $idx.ContainsKey($pid_)){continue};$m=$idx[$pid_];$key="TCP|$($m.ProcessInstanceId)|$($s.LocalAddress)|$($s.LocalPort)|$($s.RemoteAddress)|$($s.RemotePort)";[void]$present.Add($key)
   if(-not $iv.ContainsKey($key)){$iv[$key]=[ordered]@{protocol="TCP";processInstanceId=$m.ProcessInstanceId;pid=$pid_;procName=$m.Name;role=$m.Role;family=$m.Family;rootPID=$m.RootPID;rootProcessInstanceId=$m.RootProcessInstanceId;debugPort=$m.DebugPort;treeClass=$m.TreeClass;localAddr=[string]$s.LocalAddress;localPort=[int]$s.LocalPort;remoteAddr=[string]$s.RemoteAddress;remotePort=[int]$s.RemotePort;firstSeen=$now.ToString("o");lastSeen=$now.ToString("o");observationCount=1;baseline=($sample -eq 1);activeAtEnd=$true;sensor="WINDOWS_TCP_SNAPSHOT";exactOpen=$false;exactClose=$false}}
   else{$iv[$key].lastSeen=$now.ToString("o");$iv[$key].observationCount++;$iv[$key].activeAtEnd=$true}}
  foreach($k in @($iv.Keys)){if(-not $present.Contains($k)){$iv[$k].activeAtEnd=$false}};Start-Sleep -Milliseconds $PollMilliseconds}
 foreach($r in $iv.Values){($r|ConvertTo-Json -Compress -Depth 6)|Add-Content $OutFile -Encoding UTF8};@($iv.Values)
}
