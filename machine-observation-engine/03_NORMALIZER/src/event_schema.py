"""Canonical normalized event contract.

This is the boundary between source-specific collectors and correlation.
Missing facts remain None; they are never inferred here.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional


@dataclass(frozen=True)
class NormalizedEvent:
    event_id: str
    timestamp: datetime
    source: str
    event_type: str
    process_id: Optional[int] = None
    process_identity: Optional[str] = None
    parent_identity: Optional[str] = None
    image: Optional[str] = None
    protocol: Optional[str] = None
    local_address: Optional[str] = None
    local_port: Optional[int] = None
    remote_address: Optional[str] = None
    remote_port: Optional[int] = None
    evidence: dict[str, Any] = field(default_factory=dict)
