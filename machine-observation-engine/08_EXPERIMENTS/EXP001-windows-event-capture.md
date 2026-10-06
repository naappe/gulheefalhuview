# EXP001 — Windows Event Capture

**Date:** 2026-10-06  
**Status:** Partial pass

## Purpose

Determine whether event-oriented Windows telemetry can retain brief network activity that snapshot polling can miss.

## Recorded evidence

- Windows Packet Monitor capture completed with no reported event loss.
- 10,521 events were formatted from the ETL capture.
- Local host observed: 192.168.8.23.
- ICMP request/reply activity with 1.1.1.1 was retained.
- A brief TCP session between local port 65022 and remote port 443 was retained.
- The trace preserved connection establishment, direction, endpoint information, timestamps, and bidirectional traffic.

## Proven

Event-oriented network telemetry can preserve brief activity after it has occurred.

This supports the architecture:

Sensors -> Normalizer -> Correlator -> Evidence Store -> Reasoner

and demonstrates why periodic snapshot polling cannot be the only sensor mechanism.

## Still unknown

The packet trace alone does not establish:

- originating process identity
- stable process identifier
- parent process
- process start/end lifecycle
- DNS/process/network relationship
- encrypted application content
- application intent

These remain UNKNOWN until supported by additional sensors.

## Next experiment

Add Windows process-lifecycle telemetry and determine whether process evidence and network evidence can be joined into one correlated activity.

## Evidence policy

Observation and interpretation remain separate. The reasoning layer may interpret recorded evidence but must not manufacture missing evidence.
