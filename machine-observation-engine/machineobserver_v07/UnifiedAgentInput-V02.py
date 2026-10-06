#!/usr/bin/env python3
"""MachineObserver Unified Agent Input V0.2
Combines DomainInspector report.json and passive server-evidence.json from ONE session.
No network activity. No secret extraction.
"""
from __future__ import annotations
import argparse,json
from pathlib import Path

def read(p):
    return json.loads(Path(p).read_text(encoding="utf-8-sig"))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("session",help="MachineObserver session directory")
    ap.add_argument("-o","--output",default=None)
    a=ap.parse_args()
    d=Path(a.session)
    rp=d/"report.json"; sp=d/"server-evidence.json"
    if not rp.exists(): raise SystemExit(f"Missing {rp}")
    if not sp.exists(): raise SystemExit(f"Missing {sp}")
    report=read(rp); server=read(sp)

    target=(report.get("target") or {})
    page=report.get("pageState") or {}
    summary=report.get("summary") or []
    if isinstance(summary,dict): summary=[summary]

    server_summary=server.get("summary") or {}
    hosts=server.get("hosts") or []

    observations={
      "browserRequestCount":sum(int(x.get("Requests",0) or 0) for x in summary),
      "serverEventsRead":int(server_summary.get("eventsRead",0) or 0),
      "serverHostCount":int(server_summary.get("hosts",0) or 0),
      "httpStatusCounts":server_summary.get("statusCounts",{}),
      "protocolCounts":server_summary.get("protocolCounts",{}),
      "pageStateAvailable":bool(page),
      "exactRequestSocketProof":bool(report.get("exactRequestSocketProof",False))
    }

    unresolved=[]
    if not observations["exactRequestSocketProof"]:
        unresolved.append("Exact HTTP request to TCP socket causality is not proven.")
    unresolved += [
      "Private server code is not observed.",
      "Private database activity is not observed.",
      "Origin-server architecture is not proven by CDN/edge addresses.",
      "The reason for an HTTP policy decision is unknown unless directly evidenced."
    ]

    out={
      "schema":"machineobserver.unified-agent-input.v0.2",
      "session":str(d),
      "target":{"url":target.get("url"),"host":target.get("host")},
      "sources":{
        "domainInspector":{"file":str(rp),"schema":report.get("schema")},
        "serverEvidence":{"file":str(sp),"schema":server.get("schema"),"mode":server.get("mode")}
      },
      "observations":observations,
      "pageState":page,
      "correlationSummary":summary,
      "serverHosts":hosts,
      "unresolved":unresolved,
      "privacy":{
        "credentialsIncluded":False,
        "passwordValuesIncluded":False,
        "otpValuesIncluded":False,
        "cookieValuesIncluded":False,
        "tokenValuesIncluded":False,
        "responseBodiesIncluded":False
      },
      "evidenceRule":"OBSERVED > CORRELATED > INFERRED > HYPOTHESIS > UNKNOWN"
    }
    dest=Path(a.output) if a.output else d/"agent-input.json"
    dest.write_text(json.dumps(out,indent=2),encoding="utf-8")
    print(json.dumps(observations,indent=2))
    print("Unified agent input:",dest)

if __name__=="__main__":main()
