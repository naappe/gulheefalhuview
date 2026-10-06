from common import *
def run(d):
 n=total(d,"Requests"); s=total(d,"SINGLE"); a=total(d,"AMBIGUOUS"); gaps=total(d,"SENSOR_GAP")+total(d,"PROTOCOL_GAP")
 return [Finding("Math","Correlation cardinalities computed from the session evidence.","CORRELATED",["correlationSummary"],[],{"requests":n,"single":s,"ambiguous":a,"gaps":gaps,"singleRatio":s/n if n else None})]
