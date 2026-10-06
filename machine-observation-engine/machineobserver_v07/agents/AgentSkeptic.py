from common import Finding,rows,verdict
def run(report):
    rs=rows(report); problems=[]
    if report.get("exactRequestSocketProof") is False: problems.append("exact request/socket causality absent")
    if any(verdict(r) in ("AMBIGUOUS","SENSOR_GAP","PROTOCOL_GAP","FOREIGN_ONLY","NO_SOCKET") for r in rs): problems.append("non-SINGLE evidence exists")
    p=report.get("pageState") or {}; a=p.get("after") or {}
    if a.get("validationState","UNKNOWN")=="UNKNOWN": problems.append("validation state unknown")
    return [Finding("Skeptic","Do not promote the observation to authentication proof.","INFERRED",problems,["AUTHENTICATED is not established"],{"issues":len(problems)})]
