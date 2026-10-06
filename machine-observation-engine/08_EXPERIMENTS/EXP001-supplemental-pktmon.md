# EXP001 — Supplemental PktMon Capture

**Date:** 2026-10-06  
**Source archive:** DeepSeek-Test(1).txt  
**Classification:** Network sensor evidence  
**Status:** EXP001 supplemental evidence; not process attribution

## What this capture adds

A larger PktMon trace shows multiple concurrent network flows from the observed Windows host.

Examples include:

- 192.168.8.23:59197 <-> 104.18.32.47:443
- 192.168.8.23:65246 <-> 172.237.66.30:443
- 192.168.8.23:62283 -> 1.0.0.1:443
- 192.168.8.23:62284 -> 1.0.0.1:443
- 192.168.8.23:62286 -> 1.1.1.1:443
- IP traffic involving port 5555 is also present.

The trace retains direction, protocol-level endpoint data, packet sizes, TCP flags and high-resolution timestamps.

## Important interpretation boundary

The prefix values rendered around PktMon events must not be treated as proven application PID/process identity without an independent process-event source establishing that relationship.

Therefore this capture strengthens the network sensor evidence but does not complete process-to-network correlation.

## Architecture impact

EXP001 now demonstrates that the network sensor must handle:

1. multiple concurrent flows
2. repeated observations of the same packet across capture components
3. endpoint-based flow identity
4. direction normalization
5. timestamp normalization
6. duplicate/appearance handling before correlation

This directly creates requirements for Stage 03 — Normalizer.

## Current milestone status

### Network observation

- event-oriented capture: PASS
- concurrent flows retained: PASS
- local/remote endpoint evidence: PASS
- direction evidence: PASS
- high-resolution timing: PASS

### Process attribution

- originating process: UNKNOWN
- stable process identity: UNKNOWN
- parent process: UNKNOWN
- process lifecycle: UNKNOWN
- process/network join: NOT YET PROVEN

## Next

Continue with Stage 02 Windows process-lifecycle sensor. Once process create/terminate evidence is available, EXP002 can test joining process identity to a network flow.

The Reasoner must not convert a packet/thread-looking identifier into process evidence unless the sensor semantics prove that interpretation.
