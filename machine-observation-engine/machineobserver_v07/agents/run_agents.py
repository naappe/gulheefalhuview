import argparse,json
from pathlib import Path
import AgentEvidence,AgentMath,AgentState,AgentSkeptic,AgentExplorer,ConsensusEngine
def main():
 ap=argparse.ArgumentParser(description="MachineObserver five-agent reasoning V0.2");ap.add_argument("input_file");ap.add_argument("-o","--output");a=ap.parse_args()
 p=Path(a.input_file);d=json.loads(p.read_text(encoding="utf-8-sig"))
 if d.get("schema")!="machineobserver.unified-agent-input.v0.2":raise SystemExit("Expected machineobserver.unified-agent-input.v0.2")
 fs=[]
 for m in (AgentEvidence,AgentMath,AgentState,AgentSkeptic,AgentExplorer):fs+=m.run(d)
 out={"schema":"machineobserver.reasoning.v0.2","source":str(p),"consensus":ConsensusEngine.run(fs),"findings":[f.dict() for f in fs]}
 dest=Path(a.output) if a.output else p.with_name("reasoning-v02.json");dest.write_text(json.dumps(out,indent=2),encoding="utf-8")
 print(json.dumps(out["consensus"],indent=2));print("Reasoning:",dest)
if __name__=="__main__":main()
