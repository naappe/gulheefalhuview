# Correlation
Graph:
ProcessInstance -> OWNS_FLOW -> Flow -> remote IP
DNS hostname -> DNS_RESOLVED_TO -> remote IP
BrowserResponse -> host/IP/time -> related flow when supported.

Use process instance + time + IP/host + evidence IDs.

Do not convert CORRELATED into OBSERVED.
If Windows socket snapshot misses PID, PID remains UNKNOWN even when Chrome/CDP observed the URL.
