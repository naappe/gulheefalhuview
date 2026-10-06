# DeepSeek Sign-in Browser/CDP Capture — Full Role and PID Correlation

Date: 2026-10-06
Sensor provenance: browser-cdp plus Windows socket/PID correlation

## Role totals

| Class | Responses |
|---|---:|
| volc-apm | 17 |
| static-cdn | 13 |
| api-main | 7 |
| other | 4 |
| volc-cdn | 2 |
| **Total** | **43** |

19/43 responses were classified as volc-apm or volc-cdn (about 44.2% of the observed response count).

## URL inventory

### api-main
- https://chat.deepseek.com/
- /api/v0/client/settings with scopes banner, main, model, provider and web_upgrade
- /static/fp.min.js

The captured settings URLs contained the same did query value during this run. This is observed request data; persistence beyond this capture is not established by this evidence alone.

### static-cdn
Observed public resources included:
- icon-192.png
- manifest.json
- default-vendors.73c732e189.js
- Inter font subsets
- KaTeX JS/CSS
- main.6c351450f6.css
- main.6fca03582d.js
- opus decoder WASM/JS
- web-tts.d93cb232e3.js

### volc-apm
- https://apmplus.volces.com/settings/get/webpro?aid=675113
- https://gator.volces.com/list
- https://gator.volces.com/profile/list

### volc-cdn
- https://apm.volccdn.com/mars-web/apmplus/web/browser.cn.js?aid=0&globalName=apmPlus
- https://lf3-data.volccdn.com/obj/data-static/log-sdk/collect/5.0/collect-rangers-v5.2.11.js

### other
- Apple ID JS API
- Cloudflare Turnstile API JS
- https://fp-it-acc.portal101.cn/deviceprofile/v4

## Host/IP/PID correlation

| Host | Count | Remote IP | Chrome PID |
|---|---:|---|---:|
| apm.volccdn.com | 1 | 111.48.108.100 | UNKNOWN |
| apmplus.volces.com | 1 | 43.109.39.199 | 17116 |
| appleid.cdn-apple.com | 1 | 23.54.81.170 | UNKNOWN |
| challenges.cloudflare.com | 2 | 104.18.94.41 | UNKNOWN |
| chat.deepseek.com | 7 | 3.173.21.63 | 17116 |
| fe-static.deepseek.com | 13 | 3.173.21.63 | 17116 |
| fp-it-acc.portal101.cn | 1 | 138.113.144.16 | 17116 |
| gator.volces.com | 16 | 43.109.38.198 | 17116 |
| lf3-data.volccdn.com | 1 | 43.109.38.198 | 17116 |

## Evidence interpretation

PID 17116 is directly correlated in the captured data for chat.deepseek.com, fe-static.deepseek.com, fp-it-acc.portal101.cn, gator.volces.com, apmplus.volces.com and lf3-data.volccdn.com.

The three rows with blank ChromePID are retained as UNKNOWN. Their appearance in browser/CDP telemetry establishes that the instrumented browser observed those resources, but the later Windows socket snapshot did not preserve direct PID ownership evidence for those short-lived connections. MachineObserver must not fill this gap by inference.

## Layer model

    chrome.exe / process evidence
          |
          +-- PID correlation where observed
          |
          v
    Browser/CDP response evidence
          |
          +-- host
          +-- full URL/path
          +-- HTTP status
          +-- MIME
          +-- remote IP
          +-- TLS/browser metadata
          |
          v
    role classifier
          |
          +-- api-main
          +-- static-cdn
          +-- volc-apm
          +-- volc-cdn
          +-- other

## Integrity linkage

The previously archived main.6fca03582d.js resource was independently downloaded twice and both copies had SHA-256:

C1A25CBB78E344205463CF54D673C1E0F01DB007697B92D84FB8131C6FEAB7DE

This links the browser-observed public static resource name to the separately verified artifact. It does not prove that all browser-loaded assets were independently hashed.

## Claims intentionally NOT promoted to fact

- Blank PID rows are not assigned PID 17116 without evidence.
- The did value is not called persistent across sessions based on a single capture.
- portal101.cn ownership/purpose is not asserted beyond the observed hostname/path unless separately verified.
- Domain ownership labels are role labels used by this experiment; legal/corporate ownership requires separate source verification.
