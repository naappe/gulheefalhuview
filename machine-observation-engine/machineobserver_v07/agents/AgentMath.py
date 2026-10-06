from common import Finding,rows,verdict
def run(report):
    rs=rows(report); n=len(rs); c={}
    for r in rs:c[verdict(r)]=c.get(verdict(r),0)+1
    single=c.get("SINGLE",0); ambiguous=c.get("AMBIGUOUS",0); gaps=c.get("SENSOR_GAP",0)+c.get("PROTOCOL_GAP",0)
    return [Finding("Math","Candidate-set cardinalities summarized without converting them to causal certainty.","CORRELATED",["row verdict cardinalities"],[],{"N":n,"single":single,"ambiguous":ambiguous,"gaps":gaps,"singleRatio":single/n if n else None})]
