# Evidence Rules
Classes:
OBSERVED | CORRELATED | CONTEXT | PROBED | INFERRED | UNKNOWN

Rules:
- UNKNOWN stays UNKNOWN.
- Never invent PID, URL, host, path, content or ownership.
- PTR = CONTEXT only.
- HTTP 403 = HTTP responded, not network failure.
- TCP/DNS cannot see encrypted HTTPS paths.
- Chrome/CDP can directly observe browser URL/path metadata.
- Static JS endpoint reference != runtime contact.
- Probe traffic is PROBED and isolated from passive evidence.
