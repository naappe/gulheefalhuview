from common import LEVELS
def run(fs):
 high=[f for f in fs if LEVELS.get(f.level,0)>=3]; unk=[f for f in fs if f.level=="UNKNOWN"]; sk=[f for f in fs if f.agent=="Skeptic" and f.metrics.get("issues",0)]
 disagreements=[{"challenger":"Skeptic","targets":f.contradicts,"basis":f.evidence} for f in sk]
 return {"state":"BOUNDED_EVIDENCE" if sk else ("EVIDENCE_AVAILABLE" if high else "INSUFFICIENT_EVIDENCE"),"rule":"OBSERVED > CORRELATED > INFERRED > HYPOTHESIS > UNKNOWN","authenticationProven":False,"findingCount":len(fs),"highEvidenceCount":len(high),"unknownCount":len(unk),"disagreements":disagreements}
