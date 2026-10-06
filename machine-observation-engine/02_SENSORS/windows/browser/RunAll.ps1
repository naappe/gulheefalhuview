Write-Host "=== MachineObserver Browser One-Shot ==="
$snapJob=Start-Job -ScriptBlock{& "C:\MachineObserver\SocketSnapshot.ps1" -Seconds 60 -OutFile "C:\MachineObserver\sockets.jsonl"}
Write-Host "Socket snapshot started."
& "C:\MachineObserver\Collector.ps1"
Write-Host "Waiting for socket snapshot..."
Wait-Job $snapJob|Out-Null
Receive-Job $snapJob|Write-Host
Remove-Job $snapJob
& "C:\MachineObserver\Analyzer.ps1"
Get-ChildItem C:\MachineObserver\*.jsonl|Select-Object Name,Length
