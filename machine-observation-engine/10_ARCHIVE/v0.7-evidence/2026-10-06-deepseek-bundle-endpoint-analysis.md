# DeepSeek Verified Bundle — Endpoint and HIF Static-Code Findings

**Date:** 2026-10-06
**Source artifact:** main.pretty.js derived from the verified DeepSeek main.js bundle
**Artifact SHA-256:** C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
**Evidence classification:** OBSERVED_IN_ARTIFACT

## Search patterns

```text
hif-dliq.deepseek.com
hif-leim.deepseek.com
/api/v0/chat/completion
/api/v0/chat/create_pow_challenge
/api/v0/index/query
/api/v0/index/prepare
```

## HIF hosts

The frontend bundle contains poller configuration referencing:

```text
https://hif-leim.deepseek.com/query
https://hif-dliq.deepseek.com/query
```

The code creates LEIM and DLIQ pollers, exposes their current values through getHeaders(), uses a configurable maximum retry interval, and stores cached values under:

```text
hif_leim_cached
hif_dliq_cached
```

A test-environment fallback also references:

```text
https://hif-test.deepseek.com/query
```

## Chat completion

The bundle defines:

```text
/api/v0/chat/completion
```

and separately defines a file-upload route:

```text
/api/v0/file/upload_file
```

The completion route is used as a target path in the challenge-selection logic.

## Proof-of-work challenge

The bundle contains a POST request to:

```text
/api/v0/chat/create_pow_challenge
```

with JSON containing:

```text
target_path
```

The returned data is interpreted as a challenge with expiry information.

## Conversation search

The bundle contains:

```text
POST /api/v0/index/query
GET  /api/v0/index/prepare
```

The query route includes request data containing query and before_seq_id and processes progressive response text.

The prepare route is used before conversation-search behavior.

## Evidence graph

```text
VERIFIED HTTP RESOURCE
  /chat/static/main.6fca03582d.js
          |
          +-- local size = 1510389
          +-- SHA256 = C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE
          |
          v
PRETTY-PRINTED STATIC ARTIFACT
          |
          +-- OBSERVED_IN_ARTIFACT --> hif-leim.deepseek.com/query
          +-- OBSERVED_IN_ARTIFACT --> hif-dliq.deepseek.com/query
          +-- OBSERVED_IN_ARTIFACT --> /api/v0/chat/completion
          +-- OBSERVED_IN_ARTIFACT --> /api/v0/chat/create_pow_challenge
          +-- OBSERVED_IN_ARTIFACT --> /api/v0/index/query
          +-- OBSERVED_IN_ARTIFACT --> /api/v0/index/prepare
```

## Critical attribution boundary

Static occurrence in JavaScript proves that these strings/routes and associated client logic exist in the tested frontend artifact.

It does **not** by itself prove:
- that every route was contacted during the observed session,
- that a particular browser tab issued a request,
- the server-side implementation behind a route,
- the semantics of LEIM/DLIQ beyond what the client code directly demonstrates,
- that the endpoints will remain unchanged in future deployments.

Runtime network evidence must be stored separately and correlated temporally if MachineObserver later observes an actual connection/request.

## V0.7 consequence

Add an artifact-analysis evidence class or source qualifier such as:

```text
OBSERVED
  source_type = STATIC_ARTIFACT
  artifact_sha256 = ...
  observation = endpoint_reference
```

This allows the Reasoner to distinguish:

```text
"the frontend contains a reference to endpoint X"
```

from:

```text
"process Y contacted endpoint X at time T"
```

The latter requires runtime evidence.
