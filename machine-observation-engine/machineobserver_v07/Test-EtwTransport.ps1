param([int]$Duration=10,[string]$BaseDir="C:\MachineObserver")
$ErrorActionPreference="Stop"
$sensor=Join-Path $BaseDir "EtwTransportSensor-V01.ps1"
if(-not(Test-Path $sensor)){throw "Missing $sensor"}
$stamp=Get-Date -Format "yyyy-MM-dd_HHmmss"
$out=Join-Path $BaseDir ("sessions\ETW_TEST_"+$stamp+"\transport.jsonl")
& $sensor -OutFile $out -Duration $Duration
$meta=[IO.Path]::ChangeExtension($out,"meta.json")
if(-not(Test-Path $meta)){throw "ETW metadata missing"}
Get-Content $meta -Raw
