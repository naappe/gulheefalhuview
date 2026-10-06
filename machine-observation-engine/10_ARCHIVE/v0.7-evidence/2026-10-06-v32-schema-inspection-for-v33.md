# V3.2 Schema Inspection for V3.3 — 2026-10-06

## Purpose
Preserve the observed V3.2 socket/report schema and the constraints it imposes on the V3.3 correlator. V3.2 raw evidence remains immutable.

## Observed V3.2 socket schema
A representative WINDOWS_TCP_SNAPSHOT row contains:
- protocol = TCP
- processInstanceId
- pid / procName
- role = network-service
- family
- rootPID / rootProcessInstanceId
- debugPort
- treeClass = CONTROLLED
- localAddr / localPort
- remoteAddr / remotePort
- firstSeen / lastSeen
- observationCount
- baseline
- activeAtEnd
- sensor = WINDOWS_TCP_SNAPSHOT
- exactOpen = false
- exactClose = false

Key implication: firstSeen and lastSeen are polling observation bounds, not exact TCP open/close timestamps. V3.3 temporal overlap must preserve that uncertainty.

## Observed V3.2 report schema
Top-level fields:
- version
- timestamp
- principle
- chrome_summary
- edge_summary
- chrome_root
- edge_root
- chrome_rows
- edge_rows

V3.2 principle:
"Attributes requests to process families, not causally to specific TCP connections."

Per-request rows include Browser, Timestamp, Host, Url, Status, RemoteIP, RemotePort, Verdict, CandidateCount, CandidatePIDs, CandidateLocalPorts, CandidateRoles, ForeignCandidateCount, EndpointCandidateCount, EvidenceVector and EvidenceClass.

## Empirical examples
DeepSeek endpoint 3.173.21.63:443 produced multiple simultaneous expected-family NetworkService candidates.

Chrome examples:
- candidate count 3 with local ports 61140, 59904, 61814
- later candidate count 4 after local port 58005 also appeared

Edge examples:
- candidate count 4 with local ports 55478, 64050, 53997, 50826

This validates AMBIGUOUS and disproves any rule that maps remote IP + remote port directly to one local socket.

V3.2 also produced SINGLE observations. Edge apmplus.volces.com 163.181.82.193:443 had one expected-family NetworkService candidate on local port 58514 at one observation, and a later observation of the same endpoint had two candidates (58514 and 50441).

Therefore SINGLE is an observation-time candidate-set state, not a permanent endpoint binding.

Another Edge SINGLE observation for fp-it-acc.portal101.cn 138.113.144.16:443 used local port 49219. Its EvidenceVector still recorded ExactSocket=false. This is correct: one compatible candidate does not prove causal request-to-socket identity.

## V3.2 overloaded CONTRADICTION
Early Chrome rows for 3.173.21.63:443 showed:
- CandidateCount = 0
- ForeignCandidateCount = 2
- EndpointCandidateCount = 16
- endpoint/time evidence existed
- ProcessTreeMatch = false

This is evidence for V3.3 FOREIGN_ONLY or SENSOR_GAP depending on protocol/sensor sufficiency. It is not sufficient for a logical CONTRADICTION.

## V3.3 constraints derived from this dataset
1. Preserve V3.2 raw evidence unchanged.
2. Never treat firstSeen/lastSeen as exact open/close when exactOpen/exactClose are false.
3. SINGLE means exactly one compatible observed expected-family candidate; it does not set ExactSocket=true.
4. AMBIGUOUS preserves all compatible candidates.
5. Endpoint equality alone is insufficient for exact flow attribution.
6. FOREIGN_ONLY requires endpoint/time evidence outside the expected family with zero compatible expected-family candidates.
7. NO_SOCKET requires no compatible observed socket evidence anywhere after protocol and sensor-sufficiency gates.
8. PROTOCOL_GAP must precede TCP candidate classification when browser transport is not measurable by the TCP sensor.
9. SENSOR_GAP preserves uncertainty when polling or missing fields make safe classification impossible.
10. Socket generations must distinguish a later reuse of the same tuple from continuity of an earlier observed flow.

## Evidence invariant
Observed browser request != proven exact TCP flow.
Observed compatible socket != causal proof.
Candidate-set cardinality is correlation evidence.
UNKNOWN remains UNKNOWN.
