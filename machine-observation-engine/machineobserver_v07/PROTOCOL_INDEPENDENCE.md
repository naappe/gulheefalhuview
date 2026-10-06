# Protocol-independent browser sensor

MachineObserver's browser-side sensor is protocol-oriented rather than tied to a single browser brand.

A DevTools-compatible endpoint exposes target discovery over HTTP and a WebSocket transport carrying JSON commands and events. Chromium-derived applications may expose compatible endpoints when explicitly launched/configured for debugging.

## Evidence boundary

Browser telemetry is **OBSERVED_BROWSER** evidence. Windows TCP state is **OBSERVED_OS** evidence. A relationship between them is **CORRELATED_CANDIDATE** until the available tuple/time/process evidence uniquely identifies the underlying flow.

Do not treat a hostname/IP rule as raw fact. Keep the original hostname, address, port, timestamp, target ID, request ID, method, status, protocol and provenance.

## Correlation rule

First apply hard gates:

1. remote IP equality;
2. remote port equality;
3. temporal compatibility;
4. process-instance compatibility when available.

Only rank candidates after the hard gates. A numeric rank is not a probability or certainty value.

If multiple local sockets survive, retain the candidate set and set ExactSocket=0. HTTP/2 multiplexing and connection reuse mean an individual HTTP request cannot always be assigned to one TCP socket from endpoint/time evidence alone.

## Synthetic protocol test

FakeDevTools.ps1 implements a localhost-only synthetic DevTools-like target for collector regression tests. Its events use example.test and the documentation address 203.0.113.10 so synthetic evidence cannot be confused with captured third-party traffic.

This test proves parser/transport compatibility only. It does not prove that a synthetic server implements the complete Chrome DevTools Protocol.

## Security

Bind debugging endpoints to localhost. Use isolated browser profiles. Redact authorization, cookies, Set-Cookie and sensitive query parameters before persistence. Response bodies are not captured by default.
