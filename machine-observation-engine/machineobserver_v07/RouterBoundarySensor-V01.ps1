param(
 [string]$Gateway = "",
 [string]$BaseDir = "C:\MachineObserver"
)
$ErrorActionPreference="Stop"
function Get-DefaultRoute {
 Get-NetRoute -DestinationPrefix "0.0.0.0/0" -AddressFamily IPv4 -ErrorAction Stop |
  Where-Object {$_.NextHop -ne "0.0.0.0"} |
  Sort-Object @{Expression={$_.RouteMetric + $_.InterfaceMetric}} |
  Select-Object -First 1
}
$route=Get-DefaultRoute
if(-not $Gateway){$Gateway=$route.NextHop}
$ifIndex=$route.InterfaceIndex
$adapter=Get-NetAdapter -InterfaceIndex $ifIndex -ErrorAction Stop
$local=(Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction Stop |
 Where-Object {$_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress
# Populate neighbor cache with one ordinary ICMP echo.
$ping=Test-Connection -ComputerName $Gateway -Count 2 -ErrorAction SilentlyContinue
$neighbor=Get-NetNeighbor -InterfaceIndex $ifIndex -IPAddress $Gateway -ErrorAction SilentlyContinue | Select-Object -First 1
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss"
$session=Join-Path $BaseDir ("sessions\ROUTER_"+$stamp)
New-Item -ItemType Directory -Path $session -Force|Out-Null
$report=[ordered]@{
 schema="machineobserver.router-boundary.v0.1"
 capturedAt=(Get-Date).ToUniversalTime().ToString("o")
 evidenceClass="OBSERVED_LOCAL_NETWORK_STATE"
 pc=[ordered]@{ipv4=$local;interfaceIndex=$ifIndex;interfaceName=$adapter.Name;interfaceDescription=$adapter.InterfaceDescription}
 gateway=[ordered]@{ipv4=$Gateway;mac=if($neighbor){$neighbor.LinkLayerAddress}else{$null};neighborState=if($neighbor){[string]$neighbor.State}else{"UNKNOWN"};pingReplies=@($ping).Count}
 defaultRoute=[ordered]@{destination="0.0.0.0/0";nextHop=$route.NextHop;routeMetric=$route.RouteMetric;interfaceMetric=$route.InterfaceMetric}
 nat=[ordered]@{mappingObserved=$false;wanAddressObserved=$false;translatedSourcePortObserved=$false;state="UNKNOWN";reason="PC-side observation cannot directly expose the router NAT table or WAN translation."}
 routerManagement=[ordered]@{probed=$false;authenticated=$false;configurationChanged=$false}
 limits=[ordered]@{routerWanStateObserved=$false;routerNatTableObserved=$false;publicEgressObserved=$false}
}
$out=Join-Path $session "router-boundary.json"
$report|ConvertTo-Json -Depth 8|Set-Content $out -Encoding UTF8
Write-Host ""
Write-Host "=== MACHINEOBSERVER ROUTER BOUNDARY ===" -ForegroundColor Cyan
Write-Host "PC       : $local"
Write-Host "Interface: $($adapter.Name) [$ifIndex]"
Write-Host "Gateway  : $Gateway"
Write-Host "MAC      : $($report.gateway.mac)"
Write-Host "Neighbor : $($report.gateway.neighborState)"
Write-Host "NAT state: UNKNOWN (router-side evidence not yet observed)" -ForegroundColor Yellow
Write-Host "REPORT   : $out" -ForegroundColor Green
