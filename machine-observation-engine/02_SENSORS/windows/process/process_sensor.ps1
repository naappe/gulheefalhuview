# Machine Observation Engine — Windows Process Sensor
# Emits process lifecycle evidence as JSON Lines.
# Run in PowerShell. Stop with Ctrl+C.

$ErrorActionPreference = "Stop"

function Emit-ProcessEvent {
    param(
        [string]$EventType,
        [System.Management.ManagementBaseObject]$Target
    )

    $obj = [ordered]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        source        = "windows-wmi-process"
        event_type    = $EventType
        pid           = [int]$Target.ProcessId
        parent_pid    = if ($Target.ParentProcessId -ne $null) { [int]$Target.ParentProcessId } else { $null }
        image         = [string]$Target.Name
        executable    = [string]$Target.ExecutablePath
        command_line  = [string]$Target.CommandLine
        evidence_only = $true
    }

    $obj | ConvertTo-Json -Compress
}

Write-Host "Machine Observation Engine - Process Sensor"
Write-Host "Listening for process create/terminate events. Ctrl+C to stop."
Write-Host ""

Register-WmiEvent -Class Win32_ProcessStartTrace -SourceIdentifier MOE.ProcessStart -Action {
    $e = $Event.SourceEventArgs.NewEvent
    [ordered]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        source        = "windows-wmi-process"
        event_type    = "PROCESS_CREATE"
        pid           = [int]$e.ProcessID
        parent_pid    = [int]$e.ParentProcessID
        image         = [string]$e.ProcessName
        evidence_only = $true
    } | ConvertTo-Json -Compress
} | Out-Null

Register-WmiEvent -Class Win32_ProcessStopTrace -SourceIdentifier MOE.ProcessStop -Action {
    $e = $Event.SourceEventArgs.NewEvent
    [ordered]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        source        = "windows-wmi-process"
        event_type    = "PROCESS_TERMINATE"
        pid           = [int]$e.ProcessID
        image         = [string]$e.ProcessName
        evidence_only = $true
    } | ConvertTo-Json -Compress
} | Out-Null

try {
    while ($true) { Start-Sleep -Milliseconds 250 }
}
finally {
    Unregister-Event -SourceIdentifier MOE.ProcessStart -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier MOE.ProcessStop -ErrorAction SilentlyContinue
    Get-Job | Where-Object { $_.Name -like "MOE.Process*" } | Remove-Job -Force -ErrorAction SilentlyContinue
}
