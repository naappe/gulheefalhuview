param([int]$ObserverProcessId=0)
$ErrorActionPreference="Stop"
Register-WmiEvent -Class Win32_ProcessStartTrace -SourceIdentifier MOE.ProcessStart | Out-Null
Register-WmiEvent -Class Win32_ProcessStopTrace -SourceIdentifier MOE.ProcessStop | Out-Null
try {
 while($true){
  $evt=Wait-Event -Timeout 1
  if(-not $evt){continue}
  if($evt.SourceIdentifier -notlike "MOE.Process*"){Remove-Event -EventIdentifier $evt.EventIdentifier;continue}
  $e=$evt.SourceEventArgs.NewEvent
  $kind=if($evt.SourceIdentifier -eq "MOE.ProcessStart"){"PROCESS_CREATE"}else{"PROCESS_TERMINATE"}
  $processId=[int]$e.ProcessID
  $ts=(Get-Date).ToUniversalTime().ToString("o")
  $rec=[ordered]@{
   timestamp_utc=$ts
   source="windows-wmi-process"
   event_type=$kind
   pid=$processId
   parent_pid=if($kind -eq "PROCESS_CREATE"){[int]$e.ParentProcessID}else{$null}
   image=[string]$e.ProcessName
   process_instance_id=("wmi:{0}:{1}" -f $processId,$ts)
   observer_owned=($ObserverProcessId -gt 0 -and $processId -eq $ObserverProcessId)
   evidence_class="OBSERVED"
  }
  $rec|ConvertTo-Json -Compress
  Remove-Event -EventIdentifier $evt.EventIdentifier
 }
} finally {
 Unregister-Event -SourceIdentifier MOE.ProcessStart -ErrorAction SilentlyContinue
 Unregister-Event -SourceIdentifier MOE.ProcessStop -ErrorAction SilentlyContinue
 Get-Event|Where-Object{$_.SourceIdentifier -like "MOE.Process*"}|Remove-Event -ErrorAction SilentlyContinue
}
