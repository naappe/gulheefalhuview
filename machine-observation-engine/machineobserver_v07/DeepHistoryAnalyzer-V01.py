#!/usr/bin/env python3
import argparse,json,re,collections,ipaddress
from pathlib import Path
CONN=re.compile(r'TCP: connection (?P<kid>0x[0-9A-Fa-f]+) \(local=(?P<local>.+?), remote=(?P<remote>.+?)\) exists\. State = (?P<state>\w+), PID = (?P<pid>\d+), ProcessSeqNum = (?P<seq>\d+)')
UDP=re.compile(r'UDP: endpoint (?P<kid>0x[0-9A-Fa-f]+).*?(?:pid|PID)[ =](?P<pid>\d+).*?(?:processseqnum|ProcessSeqNum)[ =](?P<seq>\d+)',re.I)
def split_ep(s):
 s=s.strip()
 m=re.match(r'^\[(.+)\]:(\d+)$',s)
 if m:return m.group(1),int(m.group(2))
 m=re.match(r'^(.*):(\d+)$',s)
 return (m.group(1),int(m.group(2))) if m else (s,None)
def scope(ip):
 try:
  a=ipaddress.ip_address(ip.replace('::ffff:',''))
  return 'PRIVATE' if a.is_private else ('LOOPBACK' if a.is_loopback else 'PUBLIC')
 except:return 'UNKNOWN'
def main():
 ap=argparse.ArgumentParser();ap.add_argument('history');ap.add_argument('-o','--output');a=ap.parse_args()
 root=Path(a.history); files=list(root.rglob('transport.txt'))
 conns={}; pids=collections.Counter(); remotes=collections.Counter(); states=collections.Counter(); udp=collections.Counter()
 tx=rx=ack=rtt=0
 for f in files:
  for line in f.open(errors='ignore'):
   m=CONN.search(line)
   if m:
    d=m.groupdict(); lip,lp=split_ep(d['local']); rip,rp=split_ep(d['remote'])
    key=(d['kid'],d['seq'],lip,lp,rip,rp)
    conns[key]={'kernelConnectionId':d['kid'],'pid':int(d['pid']),'processSeqNum':int(d['seq']),'localIP':lip,'localPort':lp,'remoteIP':rip,'remotePort':rp,'remoteScope':scope(rip),'state':d['state']}
    pids[int(d['pid'])]+=1;remotes[(rip,rp)]+=1;states[d['state']]+=1
   low=line.lower()
   if 'tcp send event' in low:tx+=1
   if 'received data with number of bytes' in low:rx+=1
   if 'send acked' in low:ack+=1
   if 'rtt sample recorded' in low:rtt+=1
   u=UDP.search(line)
   if u:udp[(int(u['pid']),int(u['seq']))]+=1
 out={'schema':'machineobserver.deep-history.v0.1','sourceFiles':len(files),'connectionObjects':len(conns),
 'transport':{'txEvents':tx,'rxEvents':rx,'ackEvents':ack,'rttEvents':rtt,'states':dict(states)},
 'topProcessIds':[{'pid':k,'observations':v} for k,v in pids.most_common(50)],
 'topRemoteEndpoints':[{'ip':k[0],'port':k[1],'observations':v,'scope':scope(k[0])} for k,v in remotes.most_common(100)],
 'udpProcessInstances':[{'pid':k[0],'processSeqNum':k[1],'events':v} for k,v in udp.most_common(50)],
 'connections':list(conns.values()),
 'evidenceClass':'OBSERVED_KERNEL_TRACE',
 'limits':{'httpRequestSocketJoin':False,'tlsPlaintext':False,'credentials':False,'routerNatInternals':False}}
 dest=Path(a.output) if a.output else root/'deep-history.json';dest.write_text(json.dumps(out,indent=2),encoding='utf-8')
 print('DEEP HISTORY');print('Trace files:',len(files));print('Connection objects:',len(conns));print('TX/RX/ACK/RTT:',tx,rx,ack,rtt);print('Output:',dest)
if __name__=='__main__':main()
