from common import *
def run(d):
 p=d.get("pageState") or {}
 if not p:return [Finding("State","Page-state evidence is unavailable in this session.","UNKNOWN",["pageStateAvailable=false"],[],{"validationState":"UNKNOWN"})]
 b=p.get("before") or {}; a=p.get("after") or {}; keys=("url","formCount","inputCount","passwordFieldPresent","submitControlPresent")
 delta={k:[b.get(k),a.get(k)] for k in keys if b.get(k)!=a.get(k)}
 return [Finding("State","Page structure changed." if delta else "No structural page change was observed.","OBSERVED",["pageState.before","pageState.after"],[],{"changes":delta,"validationState":"UNKNOWN"})]
