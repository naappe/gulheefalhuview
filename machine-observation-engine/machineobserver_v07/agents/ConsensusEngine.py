from common import LEVELS
def run(findings):
    facts=[f for f in findings if LEVELS.get(f.level,0)>=LEVELS["CORRELATED"]]
    unknowns=[f for f in findings if f.level=="UNKNOWN"]
    blockers=[f for f in findings if f.agent=="Skeptic" and f.metrics.get("issues",0)>0]
    state="EVIDENCE_AVAILABLE" if facts else "INSUFFICIENT_EVIDENCE"
    if blockers: state="BOUNDED_EVIDENCE"
    return {"state":state,"rule":"OBSERVED > CORRELATED > INFERRED > HYPOTHESIS > UNKNOWN","authenticationProven":False,"findingCount":len(findings),"highEvidenceCount":len(facts),"unknownCount":len(unknowns)}
