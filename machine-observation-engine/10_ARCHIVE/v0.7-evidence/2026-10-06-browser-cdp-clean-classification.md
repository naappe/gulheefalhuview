# Browser/CDP Runtime Classification — Clean Result

Date: 2026-10-06
Evidence source: instrumented Chrome via Chrome DevTools Protocol (CDP)

## Observed role counts

| Class | Count | Role |
|---|---:|---|
| volc-apm | 17 | Volcano/ByteDance telemetry endpoints |
| static-cdn | 13 | DeepSeek static assets such as JS/CSS/WASM |
| api-main | 7 | chat.deepseek.com application/API traffic |
| other | 4 | endpoints not yet assigned a specific role |
| volc-cdn | 2 | Volcano/ByteDance CDN |

Total classified responses: 43.

## Interpretation

The corrected classifier is producing scalar role labels and the runtime capture now yields a usable application-layer role breakdown.

These counts are browser/CDP observations from the tested capture, not general claims about all DeepSeek sessions.

## Category placement

This evidence belongs under:

    Sensors
      -> Windows
        -> Browser
          -> Chrome CDP
            -> HTTP request/response evidence
            -> host-role classification

It must remain distinct from passive TCP/DNS evidence.

## Classifier correction retained

Specific host rules return immediately before broad wildcard rules. This prevents a hostname such as fe-static.deepseek.com from emitting both static-cdn and deepseek-other and becoming a System.Object[].

The collector also records sensor=browser-cdp in each JSONL response record so downstream normalization can preserve provenance.
