from common import Finding,rows,verdict
def run(report):
    rs=rows(report); gaps=sum(verdict(r) in ("SENSOR_GAP","PROTOCOL_GAP","NO_SOCKET") for r in rs)
    ideas=[]
    if gaps: ideas.append("Improve passive coverage for unresolved protocol/sensor gaps.")
    if report.get("exactRequestSocketProof") is False: ideas.append("Preserve family-level attribution; do not invent request-to-socket identity.")
    p=report.get("pageState") or {}; a=p.get("after") or {}
    if a.get("validationState","UNKNOWN")=="UNKNOWN": ideas.append("Observe a user-driven state transition structurally without collecting entered values.")
    return [Finding("Explorer","Next measurements selected from unresolved evidence.","HYPOTHESIS",["current report"],[],{"measurementPlan":ideas})]
