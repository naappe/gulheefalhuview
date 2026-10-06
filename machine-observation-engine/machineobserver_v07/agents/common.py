from dataclasses import dataclass,asdict
LEVELS={"UNKNOWN":0,"HYPOTHESIS":1,"INFERRED":2,"CORRELATED":3,"OBSERVED":4}
@dataclass
class Finding:
 agent:str; claim:str; level:str; evidence:list; contradicts:list; metrics:dict
 def dict(self): return asdict(self)
def obs(d): return d.get("observations",{})
def summaries(d):
 s=d.get("correlationSummary",[]); return [s] if isinstance(s,dict) else s
def total(d,key): return sum(int(x.get(key,0) or 0) for x in summaries(d))
