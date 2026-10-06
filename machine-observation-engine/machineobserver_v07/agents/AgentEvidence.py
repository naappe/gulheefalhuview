from common import Finding,rows,verdict
def run(report):
    rs=rows(report); counts={}
    for r in rs: counts[verdict(r)]=counts.get(verdict(r),0)+1
    f=[Finding("Evidence","Browser/network correlation rows were observed.","OBSERVED",["report.rows"],[],{"rows":len(rs),"verdicts":counts})]
    ps=report.get("pageState")
    if ps: f.append(Finding("Evidence","Page structure snapshots exist.","OBSERVED",["pageState.before","pageState.after"],[],{}))
    if report.get("exactRequestSocketProof") is False:
        f.append(Finding("Evidence","Exact HTTP request to TCP socket causality is not proven.","OBSERVED",["exactRequestSocketProof=false"],[],{}))
    return f
