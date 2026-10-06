# Verified State — 2026-10-06

## V3.2 complete baseline
V3.2 completed end-to-end with both browser CDP collectors and the OS socket collector.
Observed browser-response counts: Chrome 55; Edge 43.
The generated local report was C:\MachineObserver\report-v32.json.

Verified architectural result:
- Browser-family attribution works.
- CDP browser observations work.
- OS socket ownership observations work.
- Temporal correlation works.
- Exact causal BrowserRequest -> TCP flow is NOT proven by endpoint equality alone.

DeepSeek 3.173.21.63:443 demonstrated multiple simultaneous TCP candidates inside each controlled browser family.
Chrome candidate local ports included 61140, 59904, 61814 and later 58005.
Edge candidate local ports included 53997, 50826, 64050 and 55478.
Therefore remote IP + remote port cannot identify the exact request socket.

SINGLE means exactly one compatible observed family socket in the correlation window; it remains correlation, not causality.
Observed examples included Chrome portal101 local port 51714 and Edge gator 54534, apmplus 58514, portal101 49219.

V3.2 CONTRADICTION is not a logical contradiction. With polling TCP evidence it may represent a missed short-lived expected-family socket, protocol incompatibility such as HTTP/3/QUIC, or foreign-family contextual evidence.
V3.3 must replace this overloaded state with protocol-aware and sensor-aware states.

V3.2 final Chrome/Edge verdicts were MIXED because multiple evidence states were present; this is not an experiment failure.

## V3.3 target
1. Dynamic process-family refresh, including NetworkService restarts.
2. TCP flow generations: disappearance/reappearance creates distinct flow instances.
3. Protocol compatibility gate: do not judge h3/QUIC against a TCP-only sensor.
4. Separate NO_SOCKET / SENSOR_GAP from FOREIGN_FAMILY_CONTEXT.
5. Preserve UNKNOWN; never manufacture an exact local-port mapping.

Target pipeline:
BrowserRequest -> protocol gate -> endpoint gate -> temporal-overlap gate -> verified process-family gate -> candidate set.
Expected-family candidate count: 0 = NO_SOCKET/SENSOR_GAP; 1 = SINGLE; >1 = AMBIGUOUS.
Foreign-family matches are contextual evidence, not automatically CONTRADICTION.

## Earlier artifact integrity
main.6fca03582d.js size 1510389 bytes.
SHA256 C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE.
Two independent downloads matched.

Evidence invariant: OBSERVED remains distinct from CORRELATED; missing or unobservable facts remain UNKNOWN.
