param(
 [Parameter(Mandatory=$true)][string]$OutFile,
 [int]$Duration=45
)
$ErrorActionPreference="Stop"
# MachineObserver V1.4 Transport Sensor V0.2
# Uses Windows Packet Monitor as the supported ETW controller and enables the
# Microsoft-Windows-TCPIP provider. Metadata/transport observation only.
$etl=[IO.Path]::ChangeExtension($OutFile,"etl")
$txt=[IO.Path]::ChangeExtension($OutFile,"txt")
$meta=[IO.Path]::ChangeExtension($OutFile,"meta.json")
$dir=Split-Path $OutFile -Parent
if($dir){New-Item -ItemType Directory -Path $dir -Force|Out-Null}
if(-not(Get-Command pktmon.exe -ErrorAction SilentlyContinue)){throw "pktmon.exe is unavailable on this Windows installation."}
$admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){throw "Transport ETW capture requires an elevated PowerShell window."}
# Clear a stale Packet Monitor collection only; this does not terminate browsers.
& pktmon stop 2>$null | Out-Null
Remove-Item $etl,$txt -Force -ErrorAction SilentlyContinue
$start=(Get-Date).ToUniversalTime()
$startOutput=@(& pktmon start --trace -p Microsoft-Windows-TCPIP --file-name $etl --log-mode circular 2>&1)
$startCode=$LASTEXITCODE
if($startCode -ne 0){
 throw ("pktmon start failed (exit "+$startCode+"): "+($startOutput -join " | "))
}
try {
 Write-Host "TCP/IP ETW ACTIVE for $Duration seconds..." -ForegroundColor Cyan
 Start-Sleep -Seconds $Duration
}
finally {
 $stopOutput=@(& pktmon stop 2>&1)
 $stopCode=$LASTEXITCODE
}
$end=(Get-Date).ToUniversalTime()
if(-not(Test-Path $etl)){throw "Packet Monitor stopped but ETL was not created: $etl"}
$decodeOutput=@(& pktmon etl2txt $etl --out $txt 2>&1)
$decodeCode=$LASTEXITCODE
$decodeOk=($decodeCode -eq 0 -and (Test-Path $txt))
$lineCount=0
if($decodeOk){$lineCount=@(Get-Content $txt).Count}
[ordered]@{
 schema="machineobserver.etw-transport.v0.2"
 mode="PASSIVE_TCPIP_ETW_VIA_PKTMON"
 elevated=$admin
 startedAt=$start.ToString("o")
 endedAt=$end.ToString("o")
 durationSeconds=$Duration
 provider="Microsoft-Windows-TCPIP"
 rawEtl=$etl
 decodedText=$(if($decodeOk){$txt}else{$null})
 decodedLines=$lineCount
 startExitCode=$startCode
 stopExitCode=$stopCode
 decodeExitCode=$decodeCode
 payloadInspectionPerformed=$false
 tlsPlaintextCaptured=$false
 credentialValuesCaptured=$false
 cookieValuesCaptured=$false
 exactHttpRequestSocketProof=$false
 evidenceClass="OBSERVED_KERNEL_TRACE"
 note="Provider event fields must be normalized from the actual local trace before stronger connection-lifecycle claims are made."
}|ConvertTo-Json -Depth 6|Set-Content $meta -Encoding UTF8
Write-Host "ETW TRANSPORT CAPTURE COMPLETE" -ForegroundColor Green
Write-Host "ETL : $etl"
Write-Host "TXT : $txt"
Write-Host "META: $meta"
if(-not $decodeOk){Write-Warning ("pktmon etl2txt failed: "+($decodeOutput -join " | "))}
