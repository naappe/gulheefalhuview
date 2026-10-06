# Implementation Next

## Immediate milestone: V3.3 correlator
V3.2 is frozen as the first complete multi-browser evidence baseline. Do not modify or reinterpret its evidence files in place.

Implement in this order:
1. dynamic process-family refresh during capture
2. process-instance continuity across NetworkService restarts
3. TCP flow generations with first_seen / last_seen / generation identity
4. capture browser protocol in CDP evidence
5. protocol compatibility gate (TCP vs h3/QUIC)
6. endpoint equality gate
7. temporal-overlap gate
8. verified process-family gate
9. candidate-set verdicts: NO_SOCKET/SENSOR_GAP, SINGLE, AMBIGUOUS
10. foreign-family evidence as FOREIGN_FAMILY_CONTEXT, not automatic CONTRADICTION
11. persist browser, process, flow and correlation evidence in V0.7 SQLite
12. reasoner/report layer

Correlation must never select an exact local port when multiple compatible flow candidates remain.
Keep raw evidence immutable and preserve UNKNOWN.
