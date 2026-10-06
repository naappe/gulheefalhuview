# DeepSeek main.js — Local Integrity Verification

**Date:** 2026-10-06
**Status:** VERIFIED
**Evidence class:** OBSERVED + PROBED

## Resource

URL:
`https://fe-static.deepseek.com/chat/static/main.6fca03582d.js`

Local working directory:
`C:\MachineObserver`

## First download

```powershell
curl.exe "https://fe-static.deepseek.com/chat/static/main.6fca03582d.js" -o main.js
Get-Item main.js | Select-Object Name, Length
Get-FileHash main.js -Algorithm SHA256
```

Observed local artifact:

```text
Name:   main.js
Length: 1510389 bytes
SHA256: C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
Path:   C:\MachineObserver\main.js
```

## Independent second download

```powershell
curl.exe "https://fe-static.deepseek.com/chat/static/main.6fca03582d.js" -o main2.js
Get-FileHash main2.js -Algorithm SHA256
```

Observed:

```text
SHA256: C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
Path:   C:\MachineObserver\main2.js
```

## Verification result

Both independently downloaded files produced the same SHA-256 digest:

`C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE`

The locally measured first-download size was 1,510,389 bytes.

The earlier HTTP response for this resource reported Content-Length 1,510,389 bytes, so the observed local size matches the reported HTTP entity length.

## Evidence interpretation

```text
REMOTE RESOURCE PROBE
  hostname       = fe-static.deepseek.com
  path           = /chat/static/main.6fca03582d.js
  http_status    = 200
  content_length = 1510389
  evidence_class = PROBED

LOCAL ARTIFACT #1
  filename       = main.js
  local_length   = 1510389
  sha256         = C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
  evidence_class = OBSERVED

LOCAL ARTIFACT #2
  filename       = main2.js
  sha256         = C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
  evidence_class = OBSERVED

CORRELATED RESULT
  artifact hashes equal = TRUE
  first local size equals HTTP Content-Length = TRUE
```

## What this proves

At the times of these controlled downloads, two retrieved copies were byte-identical according to SHA-256.

It also establishes a reproducible artifact identity for this tested JavaScript bundle.

## What this does not prove

The digest does not establish authorship, source-code provenance, safety, or that the resource will remain unchanged in the future.

The URL/path remains known from the explicit endpoint-side curl request. Passive TCP/DNS observation alone does not expose an HTTPS path.

## V0.7 consequence

MachineObserver's artifact/probe model should support:

- HTTP resource identity
- local artifact size
- SHA-256
- repeated-download comparison
- linkage from PROBED HTTP resource to OBSERVED local artifact
- explicit distinction between byte-integrity evidence and provenance/meaning
