# DeepSeek main.js — Local Integrity Verification

**Date:** 2026-10-06
**Status:** Commands defined; local results pending
**Evidence class:** PROBED

## Purpose

After downloading the tested DeepSeek JavaScript resource as `main.js`, record the local filesystem size and SHA-256 digest.

## Commands

```powershell
Get-Item main.js | Select-Object Name, Length
Get-FileHash main.js -Algorithm SHA256
```

## Evidence boundary

Until the PowerShell output is captured, MachineObserver must not claim a local SHA-256 digest.

The HTTP response previously reported a Content-Length of 1,510,389 bytes, but that response header is remote HTTP evidence. It must not be silently substituted for the locally measured `Get-Item` file length.

Likewise, the HTTP ETag is not assumed to be SHA-256.

## Intended V0.7 representation

```text
HTTP_RESOURCE_PROBE
  hostname       = fe-static.deepseek.com
  path           = /chat/static/main.6fca03582d.js
  status         = 200
  content_length = 1510389
  evidence_class = PROBED

LOCAL_ARTIFACT
  filename       = main.js
  local_length   = UNKNOWN until Get-Item output
  sha256         = UNKNOWN until Get-FileHash output
  evidence_class = OBSERVED
```

When the command output is supplied, the local artifact record can be completed and linked to the probe evidence.
