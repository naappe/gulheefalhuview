from common import *
def run(d):
 o=obs(d); f=[Finding("Evidence",f"Observed {o.get('browserRequestCount',0)} browser events and {o.get('serverEventsRead',0)} passive server-facing events.","OBSERVED",["observations"],[],o)]
 if not o.get("exactRequestSocketProof",False): f.append(Finding("Evidence","Exact HTTP request-to-socket causality is not proven.","OBSERVED",["exactRequestSocketProof=false"],[],{}))
 return f
