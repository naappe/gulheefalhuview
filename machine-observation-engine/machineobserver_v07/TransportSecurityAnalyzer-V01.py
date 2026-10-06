#!/usr/bin/env python3
import argparse,json,re,ssl,socket
from pathlib import Path
from urllib.parse import urlsplit
def f(level,rule,evidence,detail): return {"level":level,"rule":rule,"evidenceClass":evidence,"detail":detail}
def passive(path):
 findings=[];states={};conns=set();pids=set()
 if not path or not Path(path).exists(): return findings,states,conns,pids
 txt=Path(path).read_text(encoding="utf-8",errors="replace")
 rx=re.compile(r"TCP: connection (0x[0-9A-Fa-f]+).*?State = (\\w+).*?PID = (\\d+), ProcessSeqNum = (\\d+)")
 for m in rx.finditer(txt):
  conns.add(m.group(1));states[m.group(2)]=states.get(m.group(2),0)+1;pids.add((m.group(3),m.group(4)))
 if states.get("EstablishedState",0): findings.append(f("OBSERVED","TCP_ESTABLISHED","OBSERVED_KERNEL_TRACE","EstablishedState records="+str(states["EstablishedState"])))
 return findings,states,conns,pids
def tls(host,port,timeout):
 ctx=ssl.create_default_context()
 with socket.create_connection((host,port),timeout=timeout) as raw:
  with ctx.wrap_socket(raw,server_hostname=host) as s:
   cert=s.getpeercert();c=s.cipher()
   return {"version":s.version(),"cipher":c[0] if c else None,"alpn":s.selected_alpn_protocol(),"certificateSubject":cert.get("subject"),"certificateIssuer":cert.get("issuer"),"notBefore":cert.get("notBefore"),"notAfter":cert.get("notAfter")}
def main():
 ap=argparse.ArgumentParser();ap.add_argument("--transport");ap.add_argument("--domain",required=True);ap.add_argument("--active-tls",action="store_true");ap.add_argument("--timeout",type=float,default=5);ap.add_argument("-o","--output");a=ap.parse_args()
 u=urlsplit(a.domain if "://" in a.domain else "https://"+a.domain);host=u.hostname;port=u.port or (443 if u.scheme=="https" else 80)
 findings,states,conns,pids=passive(a.transport);t=None
 if u.scheme=="http": findings.append(f("OBSERVED_WEAKNESS","PLAINTEXT_HTTP_TARGET","OBSERVED_CONFIGURATION","Target URL uses plaintext HTTP."))
 if a.active_tls and u.scheme=="https":
  try:
   t=tls(host,port,a.timeout);findings.append(f("OBSERVED","TLS_NEGOTIATED","ACTIVE_OBSERVATION",str(t["version"])+" / "+str(t["cipher"])+" / ALPN="+str(t["alpn"])))
   if t["version"] in ("TLSv1","TLSv1.1"): findings.append(f("OBSERVED_WEAKNESS","LEGACY_TLS_NEGOTIATED","ACTIVE_OBSERVATION",t["version"]))
  except Exception as e: findings.append(f("UNKNOWN","TLS_OBSERVATION_FAILED","ACTIVE_OBSERVATION",str(e)))
 report={"schema":"machineobserver.transport-security.v0.1","target":a.domain,"mode":"PASSIVE_PLUS_ACTIVE_TLS" if a.active_tls else "PASSIVE_ONLY","transport":{"states":states,"kernelConnectionCount":len(conns),"processInstanceCount":len(pids)},"tls":t,"findings":findings,"limits":{"tcpThreeWayHandshakeProven":False,"tlsHandshakeMessagesCaptured":False,"exactHttpRequestSocketProof":False,"privateServerInternalsObserved":False,"exploitationPerformed":False},"privacy":{"credentialsCaptured":False,"cookieValuesCaptured":False,"responseBodiesCaptured":False}}
 out=json.dumps(report,indent=2)
 if a.output: Path(a.output).write_text(out,encoding="utf-8")
 print(out)
if __name__=="__main__": main()
