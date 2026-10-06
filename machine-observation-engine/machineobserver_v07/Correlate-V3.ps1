# MachineObserver V3.3 temporal correlator.
# Attribution is family-level evidence. SINGLE is consistent, never causal proof.
function Read-JsonLines {
    param([string]$Path)
    if(-not(Test-Path $Path)){return @()}
    @(Get-Content $Path|ForEach-Object{try{$_|ConvertFrom-Json}catch{}}|Where-Object{$_})
}
function Invoke-Correlate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CdpFile,
        [Parameter(Mandatory)][string]$SocketFile,
        [Parameter(Mandatory)][object]$Graph,
        [Parameter(Mandatory)][string]$BrowserName,
        [string]$OutFile,
        [int]$TimeToleranceMilliseconds=500
    )
    $cdp=@(Read-JsonLines $CdpFile|Where-Object{$_.remoteIP -and $_.remoteIP -ne '-'})
    $sock=@(Read-JsonLines $SocketFile)
    $tol=[TimeSpan]::FromMilliseconds($TimeToleranceMilliseconds)

    $rows=@(foreach($r in $cdp){
        $proto=([string]$r.protocol).ToLowerInvariant()
        $protocolGap=($proto -eq "h3" -or $proto -like "quic*")
        $t=[datetime]::Parse([string]$r.timestamp).ToUniversalTime()
        $ep=@($sock|Where-Object{$_.remoteAddr -eq $r.remoteIP -and [int]$_.remotePort -eq [int]$r.remotePort})
        $tc=@($ep|Where-Object{
            $a=[datetime]::Parse([string]$_.firstSeen).ToUniversalTime()
            $b=[datetime]::Parse([string]$_.lastSeen).ToUniversalTime()
            $t -ge $a.Subtract($tol) -and $t -le $b.Add($tol)
        })
        $fc=@($tc|Where-Object{
            $_.family -eq $Graph.Family -and
            [int]$_.rootPID -eq [int]$Graph.RootPID -and
            [int]$_.debugPort -eq [int]$Graph.DebugPort
        })
        $foreign=@($tc|Where-Object{-not(
            $_.family -eq $Graph.Family -and
            [int]$_.rootPID -eq [int]$Graph.RootPID -and
            [int]$_.debugPort -eq [int]$Graph.DebugPort
        )})

        if($protocolGap){$v="PROTOCOL_GAP"}
        elseif($fc.Count -eq 1){$v="SINGLE"}
        elseif($fc.Count -gt 1){$v="AMBIGUOUS"}
        elseif($foreign.Count -gt 0){$v="FOREIGN_ONLY"}
        elseif($ep.Count -eq 0){$v="NO_SOCKET"}
        else{$v="SENSOR_GAP"}

        $status=[int]$r.status
        $httpResponded=($status -gt 0)
        $applicationReached=($status -ge 200 -and $status -lt 400)
        $edgePolicyDenied=($status -eq 403)

        [pscustomobject]@{
            Browser=$BrowserName
            Timestamp=$r.timestamp
            Host=$r.host
            Url=$r.url
            Status=$r.status
            Protocol=$r.protocol
            RemoteIP=$r.remoteIP
            RemotePort=$r.remotePort
            Verdict=$v
            CandidateCount=$fc.Count
            CandidatePIDs=@($fc|Select-Object -ExpandProperty pid -Unique)
            CandidateLocalPorts=@($fc|Select-Object -ExpandProperty localPort -Unique)
            CandidateRoles=@($fc|Select-Object -ExpandProperty role -Unique)
            ForeignCandidateCount=$foreign.Count
            EndpointCandidateCount=$ep.Count
            Reachability=[ordered]@{
                NetworkEndpointObserved=$true
                HttpResponded=$httpResponded
                ApplicationReached=$applicationReached
                EdgePolicyDenied=$edgePolicyDenied
            }
            EvidenceVector=[ordered]@{
                EndpointMatch=($ep.Count -gt 0)
                TimeOverlap=($tc.Count -gt 0)
                ProcessTreeMatch=($fc.Count -gt 0)
                ProtocolCompatible=(-not $protocolGap)
                CandidateCount=$fc.Count
                ExactSocket=$false
            }
            EvidenceClass=$r.evidenceClass
        }
    })
    if($OutFile){$rows|ConvertTo-Json -Depth 10|Set-Content $OutFile -Encoding UTF8}
    $rows
}
