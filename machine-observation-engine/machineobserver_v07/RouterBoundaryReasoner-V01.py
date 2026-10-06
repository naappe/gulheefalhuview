#!/usr/bin/env python3
import argparse,json
from pathlib import Path
def main():
 p=argparse.ArgumentParser();p.add_argument("report");p.add_argument("-o","--output");a=p.parse_args()
 d=json.loads(Path(a.report).read_text(encoding="utf-8-sig"))
 facts=[];unknown=[]
 def fact(k,v): facts.append({"claim":k,"value":v,"evidenceClass":"OBSERVED_LOCAL_NETWORK_STATE"})
 fact("pc.ipv4",d["pc"]["ipv4"]);fact("gateway.ipv4",d["gateway"]["ipv4"])
 if d["gateway"].get("mac"):fact("gateway.mac",d["gateway"]["mac"])
 fact("defaultRoute.nextHop",d["defaultRoute"]["nextHop"])
 for k,v in d["nat"].items():
  if k.endswith("Observed") and not v: unknown.append(k)
 out={"schema":"machineobserver.router-boundary-reasoning.v0.1","facts":facts,"unknown":unknown,
 "conclusion":"LAN gateway boundary observed; router WAN/NAT transformation remains UNKNOWN until router-side or controlled external peer evidence is available.",
 "security":{"configurationChanged":False,"credentialCapture":False,"natInferencePromotedToFact":False}}
 s=json.dumps(out,indent=2)
 if a.output:Path(a.output).write_text(s,encoding="utf-8")
 print(s)
if __name__=="__main__":main()
