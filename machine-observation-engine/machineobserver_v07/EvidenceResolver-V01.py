#!/usr/bin/env python3
"""MachineObserver Evidence Resolver V0.1
Explains unresolved correlation rows without manufacturing certainty.
Offline only: reads report.json from one completed session and creates no network traffic.
"""
from __future__ import annotations
import argparse, json
from pathlib import Path

UNRESOLVED={"AMBIGUOUS","SENSOR_GAP","PROTOCOL_GAP","FOREIGN_ONLY","NO_SOCKET"}

def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))

def rows(report):
    out=[]
    for k,v in report.items():
        if k.endswith("_rows") and isinstance(v,list):
            out.extend(v)
    return out

def explanation(r):
    v=str(r.get("Verdict",""))
    cc=int(r.get("CandidateCount",0) or 0)
    ec=int(r.get("EndpointCandidateCount",0) or 0)
    fc=int(r.get("ForeignCandidateCount",0) or 0)
    proto=str(r.get("Protocol") or "")
    if v=="AMBIGUOUS":
        return f"{cc} expected-family sockets matched endpoint and time; CDP has no local-port proof to choose one."
    if v=="SENSOR_GAP":
        return f"Endpoint evidence exists ({ec} candidate(s)) but no compatible expected-family socket overlapped the observation window."
    if v=="PROTOCOL_GAP":
        return f"Browser protocol '{proto}' is not measurable by the TCP snapshot sensor."
    if v=="FOREIGN_ONLY":
        return f"{fc} time-compatible endpoint socket(s) were observed only outside the expected controlled process family."
    if v=="NO_SOCKET":
        return "No socket with the observed remote endpoint was captured by the polling sensor."
    return "Resolved by current correlation rules."

def next_measurement(r):
    v=str(r.get("Verdict",""))
    if v=="AMBIGUOUS": return "Preserve ambiguity; add transport/request identity only if a future authorized sensor exposes a direct join key."
    if v=="SENSOR_GAP": return "Increase passive socket/process temporal coverage and refresh process-tree membership during capture."
    if v=="PROTOCOL_GAP": return "Add passive QUIC/UDP coverage while preserving browser target and process-family provenance."
    if v=="FOREIGN_ONLY": return "Re-check dynamic process-tree membership and capture timing; do not reassign ownership."
    if v=="NO_SOCKET": return "Use event-oriented passive socket telemetry or tighter sampling to reduce short-flow misses."
    return "No additional measurement required."

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("session",help="Completed MachineObserver session directory")
    ap.add_argument("-o","--output")
    a=ap.parse_args()
    d=Path(a.session); rp=d/"report.json"
    if not rp.exists(): raise SystemExit(f"Missing {rp}")
    report=load(rp)
    rr=rows(report)
    unresolved=[]
    for i,r in enumerate(rr):
        v=str(r.get("Verdict",""))
        if v not in UNRESOLVED: continue
        unresolved.append({
          "rowIndex":i,
          "browser":r.get("Browser"),
          "timestamp":r.get("Timestamp"),
          "host":r.get("Host"),
          "url":r.get("Url"),
          "status":r.get("Status"),
          "protocol":r.get("Protocol"),
          "remoteEndpoint":f"{r.get('RemoteIP')}:{r.get('RemotePort')}",
          "verdict":v,
          "candidateCount":int(r.get("CandidateCount",0) or 0),
          "candidatePIDs":r.get("CandidatePIDs") or [],
          "candidateLocalPorts":r.get("CandidateLocalPorts") or [],
          "candidateRoles":r.get("CandidateRoles") or [],
          "foreignCandidateCount":int(r.get("ForeignCandidateCount",0) or 0),
          "endpointCandidateCount":int(r.get("EndpointCandidateCount",0) or 0),
          "evidenceVector":r.get("EvidenceVector") or {},
          "whyUnresolved":explanation(r),
          "nextMeasurement":next_measurement(r),
          "exactRequestSocketProof":False
        })
    counts={}
    for x in unresolved: counts[x["verdict"]]=counts.get(x["verdict"],0)+1
    out={
      "schema":"machineobserver.evidence-resolver.v0.1",
      "mode":"OFFLINE_PASSIVE_ANALYSIS",
      "session":str(d),
      "source":str(rp),
      "rule":"Explain missing evidence; never convert ambiguity into certainty.",
      "summary":{"totalRows":len(rr),"unresolvedRows":len(unresolved),"byVerdict":counts},
      "unresolved":unresolved,
      "limits":{
        "exactRequestSocketProof":False,
        "privateServerCodeObserved":False,
        "databaseSchemaObserved":False,
        "internalBusinessLogicObserved":False
      }
    }
    dest=Path(a.output) if a.output else d/"evidence-resolution.json"
    dest.write_text(json.dumps(out,indent=2),encoding="utf-8")
    print(json.dumps(out["summary"],indent=2))
    print("Evidence resolution:",dest)

if __name__=="__main__": main()
