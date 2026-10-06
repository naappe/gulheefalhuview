"""Windows process lifecycle sensor.

Launches the PowerShell WMI event watcher and converts its JSONL output into
small Python records. WMI instance IDs are local fallback identities; a future
Sysmon backend may replace them with ProcessGuid.
"""
from __future__ import annotations
import json, subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator, Optional

SCRIPT = Path(__file__).resolve().parents[2] / "02_SENSORS" / "windows" / "process" / "process_sensor.ps1"

@dataclass(frozen=True)
class ProcessEvent:
    timestamp_utc: str
    source: str
    event_type: str
    pid: int
    parent_pid: Optional[int]
    image: str
    process_instance_id: str
    observer_owned: bool
    evidence_class: str = "OBSERVED"

def iter_process_events(observer_pid: int = 0) -> Iterator[ProcessEvent]:
    cmd=["powershell.exe","-NoProfile","-ExecutionPolicy","Bypass","-File",str(SCRIPT),"-ObserverProcessId",str(observer_pid)]
    proc=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,encoding="utf-8",errors="replace")
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            line=line.strip()
            if not line.startswith("{"): continue
            try: raw=json.loads(line)
            except json.JSONDecodeError: continue
            yield ProcessEvent(**raw)
    finally:
        if proc.poll() is None: proc.terminate()
