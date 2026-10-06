"""Activity model produced by correlation.

Correlation links evidence. It must not invent observations.
"""

from dataclasses import dataclass, field
from typing import Optional


@dataclass
class Activity:
    activity_id: str
    evidence_ids: list[str] = field(default_factory=list)
    process_identity: Optional[str] = None
    destination: Optional[str] = None
    confidence: float = 0.0
