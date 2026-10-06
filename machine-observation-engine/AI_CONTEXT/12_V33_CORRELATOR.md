# MachineObserver V3.3 — Correlator Contract

Status: NEXT IMPLEMENTATION
Baseline: V3.2 is frozen and must not be modified or deleted.

## Why V3.3 starts here
V3.2 proved the browser/CDP and Windows socket sensors can operate end-to-end. Its overloaded CONTRADICTION state is too strong because TCP polling gaps, short-lived flows, protocol incompatibility such as HTTP/3/QUIC, or foreign-family endpoint activity can produce that label without a logical contradiction.

V3.3 upgrades the correlator first. Dynamic process-tree refresh and socket generations follow as separate structural upgrades.

## Evidence states

### SINGLE
Exactly 1 compatible socket in the expected process family.

### AMBIGUOUS
2 or more compatible sockets in the expected process family.

### NO_SOCKET
No compatible socket observed anywhere.

### FOREIGN_ONLY
Matching endpoint/time socket observed, but only outside the expected process family.

### PROTOCOL_GAP
The browser protocol is not measurable by the current TCP socket sensor, for example HTTP/3 / QUIC.

### SENSOR_GAP
A browser observation exists, but available socket evidence is insufficient to classify safely.

## Formal model

Let R be a browser request.

Cexpected(R) = sockets where:
- endpoint_match = 1
- time_overlap = 1
- process_family_match = 1
- protocol_compatible = 1

Cforeign(R) = sockets where:
- endpoint_match = 1
- time_overlap = 1
- process_family_match = 0

Classification:

- protocol incompatible -> PROTOCOL_GAP
- insufficient sensor evidence -> SENSOR_GAP
- |Cexpected| = 1 -> SINGLE
- |Cexpected| > 1 -> AMBIGUOUS
- |Cexpected| = 0 and |Cforeign| > 0 -> FOREIGN_ONLY
- |Cexpected| = 0 and |Cforeign| = 0 -> NO_SOCKET

The correlator MUST NOT manufacture an exact request-to-socket mapping when more than one compatible expected-family socket exists.

## Correlation pipeline

BrowserRequest
    |
    +-- host
    +-- remote IP
    +-- remote port
    +-- protocol
    +-- timestamp
    |
    v
Protocol compatibility gate
    |
    v
Endpoint equality gate
    |
    v
Temporal-overlap gate
    |
    v
Verified process-family gate
    |
    +-- expected family -> candidate set
    |      0 -> NO_SOCKET / SENSOR_GAP as evidence permits
    |      1 -> SINGLE
    |     >1 -> AMBIGUOUS
    |
    +-- foreign family -> FOREIGN_ONLY when no expected candidate exists

## Structural upgrades after correlator

### Dynamic process-tree refresh
Refresh controlled browser process families during observation so Chromium NetworkService restarts or newly-created helper processes remain associated with the correct controlled browser instance. Same executable alone is not PROCESS_TREE proof; ancestry or equivalent observed process-instance evidence is required.

### Socket generations
A TCP tuple that disappears and later reappears must create a new flow generation. Do not represent tuple reuse as one continuous connection.

Each flow generation should retain at minimum:
- flow_generation_id
- protocol
- local address
- local port
- remote address
- remote port
- owning process instance
- first_seen
- last_seen
- observation count

## V3.2 regression baseline
The successful V3.2 evidence set consists of:
- cdp-chrome-v32.jsonl
- cdp-edge-v32.jsonl
- sockets-v32.jsonl
- report-v32.json

The local baseline must be archived before destructive local changes. V3.3 must be implemented as new code, including Correlate-V3.3.ps1, without modifying the proven V3.2 correlator.

V3.2 final browser verdicts were MIXED. This is a valid baseline containing multiple evidence states, not an experiment failure.

## Invariants
- Raw evidence is immutable.
- OBSERVED and CORRELATED remain distinct.
- Absence of observed TCP evidence is not proof of absence.
- FOREIGN_ONLY is contextual evidence, not proof that the browser used the foreign socket.
- SINGLE means one compatible observed candidate, not causal proof.
- AMBIGUOUS preserves uncertainty.
- PROTOCOL_GAP prevents TCP-only sensors from judging incompatible transport evidence.
- SENSOR_GAP preserves UNKNOWN when evidence quality is insufficient.
