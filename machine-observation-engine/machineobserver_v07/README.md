# MachineObserver V0.7

V0.7 is the modular consolidated implementation. V0.6.1 remains proof-of-concept/history and should not be overwritten.

## Pipeline

Sensors -> Normalizer -> Correlator -> Evidence Store -> Reasoner -> Human Meaning

## Current verified work

- Windows TCP snapshots preserve PID plus local/remote endpoints.
- Browser-side DevTools telemetry observes post-TLS URL/path, method, status, protocol, remote endpoint and TLS metadata when the browser exposes them.
- Browser and OS observations are joined with hard endpoint/time/process gates.
- Ambiguous socket candidates remain ambiguous; no fabricated confidence value is used.
- Synthetic DevTools-compatible events can regression-test the collector without representing them as real network observations.

## Key files

- observer.py — V0.7 controller
- config.py — configuration/database boundary
- database.py — SQLite schema/bootstrap
- models.py — evidence classes/shared models
- sensors/ — process, TCP, DNS, PTR and browser collectors
- correlation/ — DNS, temporal, browser/socket and activity correlation
- probes/ — optional active tests; OFF by default
- reasoning/ — evidence-aware reasoner
- tools/ — reports
- Join-Test.ps1 — hard-gated Browser <-> OS candidate correlation test
- FakeDevTools.ps1 — localhost synthetic protocol test server
- PROTOCOL_INDEPENDENCE.md — browser protocol/evidence contract
- data/observer-v07.db — fresh V0.7 database boundary

## Invariants

1. Observed evidence is never rewritten as inference.
2. PTR is CONTEXT, not hostname identity proof.
3. Active probes are OFF by default.
4. Probe traffic is PROBED and isolated from passive evidence.
5. HTTP status and transport reachability are separate facts.
6. UNKNOWN remains UNKNOWN.
7. Browser process attribution is not browser-tab attribution.
8. TCP/DNS observation does not reveal encrypted HTTPS URL/path/content.
9. Browser telemetry can expose post-TLS application metadata because the browser itself has processed TLS.
10. IP/port/time/PID correlation can produce a candidate set; it must not claim an exact socket when multiple candidates survive.
11. Numeric rank is not confidence/probability.
12. Synthetic protocol events are test evidence, never real service evidence.
