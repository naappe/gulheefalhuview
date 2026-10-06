# EXP002 — Process Lifecycle Retention

## Goal

Prove that the Stage 02 Windows process sensor retains a deliberately short-lived process that snapshot polling could miss.

## Sensor

`02_SENSORS/windows/process/process_sensor.ps1`

## Test

Open PowerShell window A:

```powershell
cd <repo>\machine-observation-engine\02_SENSORS\windows\process
.\process_sensor.ps1 | Tee-Object -FilePath "$env:TEMP\moe-process-events.jsonl"
```

Open PowerShell window B and generate a brief process:

```powershell
curl.exe -I https://example.com
```

Stop the sensor with Ctrl+C after the test.

Then inspect:

```powershell
Get-Content "$env:TEMP\moe-process-events.jsonl" | Select-String "curl"
```

## Pass criteria

The evidence file contains both:

- PROCESS_CREATE for curl.exe
- PROCESS_TERMINATE for the same PID

## Important limitation

PID alone is not a permanent process identity because Windows can reuse PIDs.

This experiment establishes lifecycle retention first. A later sensor revision should add a stronger process identity using ETW/Sysmon or a composite identity derived from PID plus creation evidence.

## Next correlation step

Once EXP002 passes, capture network telemetry during the same controlled transaction and test whether timing plus endpoint/process evidence can be joined without inventing missing facts.

## Evidence rule

A process lifecycle event proves that the process existed. It does not by itself prove that a particular network flow belonged to that process.
