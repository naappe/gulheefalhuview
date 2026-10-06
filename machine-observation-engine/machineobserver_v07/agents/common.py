from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Any

LEVELS={"UNKNOWN":0,"HYPOTHESIS":1,"INFERRED":2,"CORRELATED":3,"OBSERVED":4}

@dataclass
class Finding:
    agent:str
    claim:str
    level:str
    evidence:list[str]
    contradicts:list[str]
    metrics:dict[str,Any]
    def dict(self): return asdict(self)

def rows(report): 
    r=report.get("rows",[])
    if isinstance(r,dict):
        out=[]
        for v in r.values(): out.extend(v if isinstance(v,list) else [])
        return out
    return r if isinstance(r,list) else []

def verdict(row): return str(row.get("Verdict",row.get("verdict","UNKNOWN"))).upper()
