from __future__ import annotations
import argparse,json
from pathlib import Path
import AgentEvidence,AgentMath,AgentState,AgentSkeptic,AgentExplorer,ConsensusEngine

def main():
    ap=argparse.ArgumentParser(description="MachineObserver five-agent reasoning layer")
    ap.add_argument("report",help="DomainInspector report.json")
    ap.add_argument("-o","--output",default=None)
    a=ap.parse_args()
    report=json.loads(Path(a.report).read_text(encoding="utf-8-sig"))
    findings=[]
    for agent in (AgentEvidence,AgentMath,AgentState,AgentSkeptic,AgentExplorer):
        findings.extend(agent.run(report))
    out={"schema":"machineobserver.reasoning.v0.1","sourceReport":str(Path(a.report)),"consensus":ConsensusEngine.run(findings),"findings":[f.dict() for f in findings]}
    dest=Path(a.output) if a.output else Path(a.report).with_name("reasoning.json")
    dest.write_text(json.dumps(out,indent=2),encoding="utf-8")
    print(json.dumps(out["consensus"],indent=2))
    print("Reasoning:",dest)
if __name__=="__main__":main()
