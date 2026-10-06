# 02 — Sensors

Collectors observe real machine activity and emit raw facts.

Implementation/category order:

1. Windows process lifecycle
2. Windows network events
3. DNS evidence
4. Browser / application instrumentation
5. Application/external sources
6. Android / ADB / PhoneHub sources

## Browser instrumentation

Browser-side instrumentation is a distinct sensor family because it can directly observe application-layer facts that passive TCP/DNS cannot, including HTTPS URL paths, HTTP status, MIME type, cache/service-worker state, protocol and browser-exposed TLS metadata.

Current Windows implementation:
- `windows/browser/Collector.ps1` — Chrome DevTools Protocol (CDP) network collector.

Evidence emitted by this sensor must identify its provenance as browser/CDP evidence. It must not be relabelled as passive network evidence.

Sensors do not explain WHY. They record WHAT was observed.
