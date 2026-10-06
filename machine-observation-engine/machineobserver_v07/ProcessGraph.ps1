# MachineObserver V3.2.2 - controlled Chromium process-tree discovery with preferred session root.
function Get-ProcessRole { param($Process,[int]$RootPID)
 if([int]$Process.ProcessId -eq $RootPID){return "root"};$c=[string]$Process.CommandLine
 if($c -match '--type=utility' -and $c -match 'network\.mojom\.NetworkService'){return "network-service"}
 if($c -match '--type=renderer'){return "renderer"};if($c -match '--type=gpu-process'){return "gpu"};if($c -match '--type=utility'){return "utility"};if($c -match 'crashpad'){return "crashpad"};return "other"
}
function Get-ControlledProcessGraph { [CmdletBinding()]param([Parameter(Mandatory)][string]$BrowserName,[Parameter(Mandatory)][int]$DebugPort,[string]$BrowserExePath,[int]$PreferredRootPID=0)
 $expected=[IO.Path]::GetFileNameWithoutExtension($BrowserName).ToLowerInvariant();$allRows=@(Get-CimInstance Win32_Process -ErrorAction Stop);$byPid=@{};foreach($p in $allRows){$byPid[[int]$p.ProcessId]=$p}
 $roots=@($allRows|Where-Object{$n=[IO.Path]::GetFileNameWithoutExtension([string]$_.Name).ToLowerInvariant();$c=[string]$_.CommandLine;$n -eq $expected -and $c -match "(?i)--remote-debugging-port(?:=|\s+)$DebugPort(?:\s|$)" -and $c -notmatch '(?i)(?:^|\s)--type='})
 if($BrowserExePath){$want=[IO.Path]::GetFullPath($BrowserExePath).TrimEnd('\').ToLowerInvariant();$pm=@($roots|Where-Object{$_.ExecutablePath -and ([IO.Path]::GetFullPath([string]$_.ExecutablePath).TrimEnd('\').ToLowerInvariant() -eq $want)});if($pm.Count){$roots=$pm}}
 if($roots.Count -eq 0){throw "No controlled $expected root found on debug port $DebugPort."}
 if($PreferredRootPID){$preferred=@($roots|Where-Object{[int]$_.ProcessId -eq $PreferredRootPID});if($preferred.Count -eq 1){$roots=$preferred}}
 if($roots.Count -gt 1){$roots=@($roots|Sort-Object @{Expression={if($_.CreationDate){[datetime]$_.CreationDate}else{[datetime]::MinValue}}} -Descending);Write-Warning "Multiple controlled $expected roots on port ${DebugPort}: $($roots.ProcessId -join ', '). Using newest root PID $($roots[0].ProcessId)."}
 $root=$roots[0];$rootPid=[int]$root.ProcessId;$rc=if($root.CreationDate){([datetime]$root.CreationDate).ToUniversalTime().ToString("o")}else{$null};$ri="$rootPid|$rc"
 $set=[Collections.Generic.HashSet[int]]::new();[void]$set.Add($rootPid);$q=[Collections.Queue]::new();$q.Enqueue($rootPid)
 while($q.Count){$par=[int]$q.Dequeue();foreach($ch in $allRows){if([int]$ch.ParentProcessId -eq $par -and -not $set.Contains([int]$ch.ProcessId)){[void]$set.Add([int]$ch.ProcessId);$q.Enqueue([int]$ch.ProcessId)}}}
 $members=@{};foreach($id in $set){$x=$byPid[$id];if(-not $x){continue};$cr=if($x.CreationDate){([datetime]$x.CreationDate).ToUniversalTime().ToString("o")}else{$null};$members[$id]=[pscustomobject]@{PID=$id;ParentPID=[int]$x.ParentProcessId;ProcessInstanceId="$id|$cr";Name=[string]$x.Name;Role=Get-ProcessRole $x $rootPid;RootPID=$rootPid;RootProcessInstanceId=$ri;Family=$expected;DebugPort=$DebugPort;TreeClass="CONTROLLED"}}
 [pscustomobject]@{Family=$expected;DebugPort=$DebugPort;RootPID=$rootPid;RootProcessInstanceId=$ri;Members=$members}
}
function Get-ProcessGraph { param([string]$BrowserName,[string]$BrowserExePath,[int]$DebugPort);if(-not $DebugPort){throw "V3.2 requires -DebugPort."};(Get-ControlledProcessGraph $BrowserName $DebugPort $BrowserExePath).Members }
