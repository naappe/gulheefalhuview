param(
    [string]$BrowserFile = "C:\MachineObserver\capture.jsonl",
    [string]$SocketFile  = "C:\MachineObserver\sockets.jsonl",
    [double]$WindowSec   = 10
)

$browser = Get-Content $BrowserFile | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } |
    Where-Object { $_.remoteIP -and $_.remotePort }
$sockets = Get-Content $SocketFile | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} } |
    Where-Object { $_.remoteIP -and $_.remotePort }

$results = foreach ($b in $browser) {
    $bt = [datetimeoffset]::Parse($b.timestamp)

    $endpoint = @($sockets | Where-Object {
        $_.remoteIP -eq $b.remoteIP -and [int]$_.remotePort -eq [int]$b.remotePort
    })

    $temporal = @($endpoint | Where-Object {
        $st = [datetimeoffset]::Parse($_.timestamp)
        [math]::Abs(($bt-$st).TotalSeconds) -le $WindowSec
    })

    $process = @($temporal | Where-Object {
        $b.chromePID -and $_.pid -and [int]$_.pid -eq [int]$b.chromePID
    })

    $candidateSockets = @($process | Sort-Object pid,localIP,localPort,remoteIP,remotePort -Unique)
    $count = $candidateSockets.Count
    $ports = if ($count) { ($candidateSockets | Select-Object -ExpandProperty localPort | Sort-Object -Unique) -join "," } else { "" }

    [pscustomobject]@{
        Time=$b.timestamp; Host=$b.host; Path=$b.path; Method=$b.method; Status=$b.status
        Protocol=$b.protocol; RemoteIP=$b.remoteIP; RemotePort=$b.remotePort; BrowserPID=$b.chromePID
        EndpointCandidates=$endpoint.Count; TemporalCandidates=$temporal.Count; ProcessCandidates=$count
        CandidateLocalPorts=$ports; ExactSocket=[int]($count -eq 1)
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host " MACHINEOBSERVER CORRELATION V2"
Write-Host "============================================================"
Write-Host ""
$results | Where-Object { $_.ProcessCandidates -gt 0 } |
    Format-Table Host,Status,RemoteIP,BrowserPID,ProcessCandidates,CandidateLocalPorts,ExactSocket -AutoSize
Write-Host ""
Write-Host "ExactSocket=1: exactly one candidate survived"
Write-Host "ExactSocket=0: ambiguous; retain all candidates"
