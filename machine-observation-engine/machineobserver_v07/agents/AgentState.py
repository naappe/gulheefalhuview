from common import Finding
def run(report):
    p=report.get("pageState") or {}; b=p.get("before") or {}; a=p.get("after") or {}
    if not b or not a:return [Finding("State","Insufficient page snapshots for a state transition.","UNKNOWN",[],[],{})]
    keys=("url","formCount","inputCount","passwordFieldPresent","submitControlPresent")
    delta={k:[b.get(k),a.get(k)] for k in keys if b.get(k)!=a.get(k)}
    level="OBSERVED" if delta else "OBSERVED"
    claim="Page structure changed." if delta else "No structural page change was observed."
    return [Finding("State",claim,level,["pageState.before","pageState.after"],[],{"changes":delta,"validationState":"UNKNOWN"})]
