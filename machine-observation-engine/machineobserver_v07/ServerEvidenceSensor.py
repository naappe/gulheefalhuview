#!/usr/bin/env python3
"""MachineObserver ServerEvidenceSensor V0.1

PASSIVE ONLY: converts browser-observed CDP response metadata into a
server-evidence graph. It creates no network requests and does not read
response bodies, cookies, credentials, tokens, or storage values.
"""
from __future__ import annotations
import argparse, json
from collections import Counter, defaultdict
from pathlib import Path
from urllib.parse import urlsplit

def load_jsonl(path: Path):
    out=[]
    for n,line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(),1):
        if not line.strip(): continue
        try: out.append(json.loads(line))
        except json.JSONDecodeError as e: raise SystemExit(f"{path}:{n}: {e}")
    return out

def clean_url(value):
    try:
        p=urlsplit(str(value))
        if p.scheme not in ("http","https"): return None
        return f"{p.scheme}://{p.netloc}{p.path or '/'}"
    except Exception: return None

def first(d,*keys):
    for k in keys:
        if k in d and d[k] not in (None,""): return d[k]
    return None

def main():
    ap=argparse.ArgumentParser(description="Build passive server evidence from MachineObserver CDP JSONL")
    ap.add_argument("cdp", help="cdp-chrome.jsonl or cdp-edge.jsonl")
    ap.add_argument("-o","--output",default=None)
    a=ap.parse_args()
    src=Path(a.cdp)
    events=load_jsonl(src)
    nodes={}
    edges=[]
    statuses=Counter()
    protocols=Counter()
    hosts=defaultdict(lambda:{"responses":0,"statuses":Counter(),"ips":Counter(),"protocols":Counter()})

    for i,e in enumerate(events):
        url=clean_url(first(e,"url","Url"))
        host=str(first(e,"host","Host") or "").lower()
        if not host and url:
            host=(urlsplit(url).hostname or "").lower()
        status=first(e,"status","Status")
        proto=str(first(e,"protocol","Protocol") or "UNKNOWN").lower()
        ip=str(first(e,"remoteIP","RemoteIP") or "")
        port=first(e,"remotePort","RemotePort")
        ts=first(e,"timestamp","Timestamp")
        mime=first(e,"mime","mimeType","Mime")
        if not host: continue
        try: status_i=int(status) if status is not None else None
        except Exception: status_i=None

        h=hosts[host];h["responses"]+=1
        if status_i is not None: h["statuses"][str(status_i)]+=1;statuses[str(status_i)]+=1
        h["protocols"][proto]+=1;protocols[proto]+=1
        if ip: h["ips"][ip]+=1

        hid="host:"+host
        nodes[hid]={"id":hid,"type":"HOST","value":host,"evidenceClass":"OBSERVED_BROWSER"}
        if ip:
            eid=f"endpoint:{ip}:{port or ''}"
            nodes[eid]={"id":eid,"type":"REMOTE_ENDPOINT","ip":ip,"port":port,"evidenceClass":"OBSERVED_BROWSER"}
            edges.append({"from":hid,"to":eid,"relation":"BROWSER_OBSERVED_RESPONSE_FROM","timestamp":ts})
        rid=f"response:{i}"
        nodes[rid]={"id":rid,"type":"HTTP_RESPONSE","host":host,"url":url,"status":status_i,"protocol":proto,"mime":mime,"timestamp":ts,"evidenceClass":"OBSERVED_BROWSER"}
        edges.append({"from":hid,"to":rid,"relation":"RETURNED","timestamp":ts})

    host_summary=[]
    for host,h in sorted(hosts.items()):
        host_summary.append({"host":host,"responses":h["responses"],"statuses":dict(h["statuses"]),"remoteIPs":dict(h["ips"]),"protocols":dict(h["protocols"])})

    out={
      "schema":"machineobserver.server-evidence.v0.1",
      "source":{"type":"CDP_BROWSER_METADATA","file":str(src)},
      "mode":"PASSIVE",
      "activeProbes":False,
      "privacy":{"responseBodiesCaptured":False,"cookiesCaptured":False,"credentialsCaptured":False,"tokensCaptured":False,"storageValuesCaptured":False},
      "limits":["Externally observable browser evidence only.","No claim about private server code, databases, memory, or internal services.","Remote IP/CDN edge is not proof of origin-server identity.","HTTP response metadata does not prove why a server made its decision."],
      "summary":{"eventsRead":len(events),"hosts":len(hosts),"statusCounts":dict(statuses),"protocolCounts":dict(protocols)},
      "hosts":host_summary,
      "graph":{"nodes":list(nodes.values()),"edges":edges}
    }
    dest=Path(a.output) if a.output else src.with_name("server-evidence.json")
    dest.write_text(json.dumps(out,indent=2),encoding="utf-8")
    print(json.dumps(out["summary"],indent=2))
    print("Server evidence:",dest)

if __name__=="__main__": main()
