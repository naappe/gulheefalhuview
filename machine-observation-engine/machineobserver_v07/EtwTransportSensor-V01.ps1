param(
 [Parameter(Mandatory=$true)][string]$OutFile,
 [int]$Duration=45,
 [string]$SessionName="MachineObserver-TCPIP"
)
$ErrorActionPreference="Stop"
# MachineObserver V1.4 ETW Transport Sensor - experimental sidecar.
# Captures Windows kernel TCP/IP ETW to ETL using built-in logman, then exports
# a normalized event view. It does not inspect payloads, credentials, cookies,
# response bodies, or TLS plaintext.
$etl=[IO.Path]::ChangeExtension($OutFile,"etl")
$csv=[IO.Path]::ChangeExtension($OutFile,"csv")
$meta=[IO.Path]::ChangeExtension($OutFile,"meta.json")
$dir=Split-Path $OutFile -Parent
if($dir){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
# Kernel logger network flag. logman is built into Windows. Admin rights may be required.
# We intentionally preserve the raw ETL as evidence and do not claim fields that
# the local decoder does not expose.
$started=$false
try {
  & logman stop $SessionName -ets 2>$null | Out-Null
  & logman start $SessionName -p "Windows Kernel Trace" 0x10000 0x5 -o $etl -ets | Out-Null
  if($LASTEXITCODE -ne 0){throw "Unable to start kernel TCP/IP ETW session. Run PowerShell as Administrator."}
  $started=$true
  $start=(Get-Date).ToUniversalTime()
  Start-Sleep -Seconds $Duration
}
finally {
  if($started){& logman stop $SessionName -ets | Out-Null}
}
$end=(Get-Date).ToUniversalTime()
# tracerpt is built into Windows and provides a portable first decoder.
& tracerpt $etl -of CSV -o $csv -y | Out-Null
$decodeOk=(Test-Path $csv)
$eventLines=0
if($decodeOk){$eventLines=[Math]::Max(0,@(Get-Content $csv).Count-2)}
[ordered]@{
 schema="machineobserver.etw-transport.v0.1"
 mode="PASSIVE_KERNEL_ETW"
 sessionName=$SessionName
 startedAt=$start.ToString("o")
 endedAt=$end.ToString("o")
 durationSeconds=$Duration
 rawEtl=$etl
 decodedCsv=$(if($decodeOk){$csv}else{$null})
 decodedApproxRows=$eventLines
 payloadCaptured=$false
 tlsPlaintextCaptured=$false
 credentialValuesCaptured=$false
 cookieValuesCaptured=$false
 exactHttpRequestSocketProof=$false
 evidenceClass="OBSERVED_KERNEL_TRACE"
 note="ETW transport evidence is independent of CDP. Connection/PID/connid fields are provider/version dependent and must be normalized only when actually decoded."
}|ConvertTo-Json -Depth 6|Set-Content $meta -Encoding UTF8
Write-Host "ETW TRANSPORT CAPTURE COMPLETE" -ForegroundColor Green
Write-Host "ETL : $etl"
Write-Host "CSV : $csv"
Write-Host "META: $meta"
