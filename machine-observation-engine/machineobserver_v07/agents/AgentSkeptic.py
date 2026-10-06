from common import *
def run(d):
 o=obs(d); issues=[]
 if not o.get("exactRequestSocketProof",False):issues.append("exact request/socket causality absent")
 if total(d,"AMBIGUOUS")+total(d,"SENSOR_GAP")+total(d,"PROTOCOL_GAP")+total(d,"FOREIGN_ONLY")+total(d,"NO_SOCKET"):issues.append("unresolved correlation evidence exists")
 if not o.get("pageStateAvailable",False):issues.append("page-state evidence unavailable")
 issues+=list(d.get("unresolved",[]))
 return [Finding("Skeptic","Authentication and private server internals are not established by these observations.","INFERRED",issues,["AUTHENTICATED","PRIVATE_SERVER_INTERNALS"],{"issues":len(issues)})]
