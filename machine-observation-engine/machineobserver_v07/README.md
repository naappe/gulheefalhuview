# MachineObserver V0.7

V0.7 is the modular consolidated implementation. V0.6.1 remains the proof-of-concept/history.

## Layout

- observer.py — controller
- config.py — configuration and database boundary
- database.py — SQLite schema/bootstrap
- models.py — evidence classes and shared models
- sensors/ — process, TCP, DNS and PTR collectors
- correlation/ — DNS, temporal and activity correlation
- probes/ — optional TLS/HTTP active tests
- reasoning/ — evidence-aware reasoner
- tools/ — reports
- data/observer-v07.db — fresh V0.7 evidence database

## Invariants

1. Observed evidence is never rewritten as inference.
2. PTR is CONTEXT, not hostname identity proof.
3. Active probes are OFF by default.
4. Probe traffic is PROBED and isolated from passive evidence.
5. HTTP 403 means HTTP responded with status 403; it does not mean the network path failed.
6. UNKNOWN remains UNKNOWN.
7. Browser process attribution is not browser-tab attribution.
8. TCP/DNS observation does not reveal encrypted HTTPS URL/path or content.
