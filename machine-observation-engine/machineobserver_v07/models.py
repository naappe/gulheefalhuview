from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Optional
from uuid import uuid4


class EvidenceClass(str, Enum):
    OBSERVED = "OBSERVED"
    CORRELATED = "CORRELATED"
    CONTEXT = "CONTEXT"
    PROBED = "PROBED"
    INFERRED = "INFERRED"
    UNKNOWN = "UNKNOWN"


class FlowState(str, Enum):
    BASELINE = "BASELINE"
    OBSERVED_NEW = "OBSERVED_NEW"
    DISAPPEARED = "DISAPPEARED"


@dataclass(frozen=True)
class Evidence:
    evidence_id: str
    timestamp: datetime
    evidence_class: EvidenceClass
    source: str
    kind: str
    payload: dict[str, Any] = field(default_factory=dict)


def new_evidence_id() -> str:
    return str(uuid4())
