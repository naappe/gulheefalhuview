"""Process-aware cross-sensor matching.

Exact PID, ancestry, and same-application identity are deliberately distinct.
A shared executable path is evidence of the same application binary, not proof
that two processes share a parent/child relationship or browser profile.
"""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Optional

class ProcessMatch(str, Enum):
    EXACT_PID = "EXACT_PID"
    PROCESS_TREE = "PROCESS_TREE"
    SAME_APPLICATION = "SAME_APPLICATION"
    DIFFERENT_APPLICATION = "DIFFERENT_APPLICATION"
    UNKNOWN = "UNKNOWN"

@dataclass(frozen=True)
class ProcessIdentity:
    pid: Optional[int]
    parent_pid: Optional[int] = None
    executable: Optional[str] = None
    command_line: Optional[str] = None

def _norm_exe(value: Optional[str]) -> Optional[str]:
    if not value: return None
    return str(Path(value)).replace("\\", "/").casefold()

def classify_process_match(browser: ProcessIdentity, socket: ProcessIdentity) -> ProcessMatch:
    if not browser.pid or not socket.pid:
        return ProcessMatch.UNKNOWN
    if browser.pid == socket.pid:
        return ProcessMatch.EXACT_PID
    if socket.parent_pid == browser.pid or browser.parent_pid == socket.pid:
        return ProcessMatch.PROCESS_TREE
    b_exe, s_exe = _norm_exe(browser.executable), _norm_exe(socket.executable)
    if b_exe and s_exe:
        if b_exe == s_exe:
            return ProcessMatch.SAME_APPLICATION
        return ProcessMatch.DIFFERENT_APPLICATION
    return ProcessMatch.UNKNOWN

def chrome_network_service(identity: ProcessIdentity) -> bool:
    cmd=(identity.command_line or "").casefold()
    return "--type=utility" in cmd and "--utility-sub-type=network.mojom.networkservice" in cmd
