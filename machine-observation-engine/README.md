# Machine Observation & Reasoning Engine

Baseline established: 2026-10-06

## Scope

This project is a general machine/network observation and reasoning system.

Android, ADB, PhoneHub, Chrome, Windows services, Tailscale, DNS, HTTP and other applications are evidence sources, not the project boundary.

## Canonical pipeline

```text
Sensors -> Normalizer -> Correlator -> Evidence Store -> Reasoner -> Human Meaning
```

## Architectural invariant

The Reasoner may interpret evidence, but it must never manufacture evidence.

Unknown or unobservable facts remain UNKNOWN. Encrypted application content must not be presented as observed unless a legitimate sensor actually observed it.

## Categories

1. **01_ARCHITECTURE** — overview, principles, data flow, architecture decisions.
2. **02_SENSORS** — Windows/process/ETW/Sysmon, network, applications and external sources.
3. **03_NORMALIZER** — common event schema, timestamps and identities.
4. **04_CORRELATOR** — temporal, process, network and activity correlation; confidence.
5. **05_EVIDENCE_STORE** — raw events, normalized events, activities, links and retention.
6. **06_REASONER** — WHAT/WHO/WHY reasoning, confidence and UNKNOWN handling.
7. **07_HUMAN_MEANING** — summaries, timelines, explanations, search and dashboard.
8. **08_EXPERIMENTS** — controlled experiments with permanent IDs.
9. **09_TOOLS** — collectors, diagnostics, parsers and test generators.
10. **10_ARCHIVE** — ChatGPT decisions, old designs, deprecated code and research notes.

## First experiment

**EXP001 — Short-lived curl transaction**

Goal: prove that event-oriented Windows telemetry can retain a short-lived `curl.exe` process/network transaction that snapshot polling can miss.

Evidence targets:
- process creation
- stable process identity
- parent process
- DNS activity when available
- outbound TCP connection
- destination IP/port
- process termination
- timestamps precise enough for temporal correlation

Success means the evidence can be normalized and reconstructed into one activity without inventing encrypted application content.

## Event model direction

```text
Raw Sensor Events
       |
       v
NormalizedEvent
       |
       v
Temporal / Identity Correlator
       |
       v
Activity + Evidence Links
       |
       v
Reasoner
       |
       v
Human-readable interpretation
```

## Archive policy

Coding, programming and software-architecture work discussed with ChatGPT should be preserved in this repository as structured source, experiments, decisions or notes when relevant.
