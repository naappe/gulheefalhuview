# Verified State — 2026-10-06

## Artifact integrity
main.6fca03582d.js
size: 1510389 bytes
SHA256: C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
Two independent downloads matched.

## Browser + socket correlation
Latest browser capture: 10 response observations.

Windows socket snapshot independently observed PID 17116 on the same remote endpoint/time window as:
- fe-static.deepseek.com browser responses
- gator.volces.com browser responses

Evidence rule:
browser URL/path/status = OBSERVED by CDP
PID/IP/port = OBSERVED by Windows socket sensor
cross-sensor join = CORRELATED

A browser response whose socket PID was not observed remains PID UNKNOWN.

Latest DeepSeek static observations included icon, Web-TTS JavaScript, Opus decoder JavaScript and Opus WASM. All returned HTTP 200.

No main.6fca03582d.js response was present in this latest capture.

Cached responses may report encodedLength=0. This means no encoded network transfer for that observation; it does not establish a zero-byte resource.

Static artifact endpoint references remain distinct from runtime contact evidence.
