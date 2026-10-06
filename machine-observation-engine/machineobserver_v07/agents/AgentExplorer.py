from common import *
def run(d):
 o=obs(d); plan=[]
 if not o.get("pageStateAvailable",False):plan.append("Run a V1.2+ isolated session to add before/after structural page-state evidence.")
 if total(d,"SENSOR_GAP")+total(d,"PROTOCOL_GAP"):plan.append("Improve passive coverage for unresolved sensor/protocol gaps.")
 if not o.get("exactRequestSocketProof",False):plan.append("Keep family-level attribution; do not manufacture request-to-socket identity.")
 plan.append("Compare only user-driven, non-secret state transitions when additional evidence is needed.")
 return [Finding("Explorer","Proposed next measurements target unresolved evidence without collecting secrets.","HYPOTHESIS",["unresolved","observations"],[],{"measurementPlan":plan})]
