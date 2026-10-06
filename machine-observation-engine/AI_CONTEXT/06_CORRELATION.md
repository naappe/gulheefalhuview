# Correlation
Graph:
ProcessInstance -> OWNS_FLOW -> Flow -> remote IP
DNS hostname -> DNS_RESOLVED_TO -> remote IP
BrowserResponse -> host/IP/time -> related flow when supported.

Use process instance + time + endpoint + evidence IDs.

Process matching levels:
- EXACT_PID: browser and socket evidence name the same PID.
- PROCESS_TREE: recorded parent/child identity supports ancestry.
- SAME_APPLICATION: executable identity matches, but ancestry/profile is not proven.
- DIFFERENT_APPLICATION: executable identity conflicts.
- UNKNOWN: evidence is insufficient.

Chrome network-service command line:
--type=utility --utility-sub-type=network.mojom.NetworkService
may explain why request-origin PID and socket-owning PID differ.

Do not call same executable/path PROCESS_TREE without ancestry evidence.
Do not convert CORRELATED into OBSERVED.
Missing PID remains UNKNOWN.
