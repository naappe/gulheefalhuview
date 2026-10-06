# DeepSeek Static Resource Probe Evidence — 2026-10-06

## Classification

Controlled active probe evidence for the MachineObserver V0.7 reachability model.

Evidence class: **PROBED**

This evidence must remain separate from passive TCP/DNS observations.

## Target

Host: fe-static.deepseek.com
Resolved IPv4: 3.173.21.63
Transport: TCP/443 + TLS
Client: curl.exe on Windows

## Successful resource probes

### JavaScript bundle

Request:
GET /chat/static/main.6fca03582d.js

Observed:
- HTTP/1.1 200 OK
- Content-Type: text/javascript
- Content-Length: 1,510,389 bytes
- Server: AmazonS3
- Last-Modified: Tue, 29 Sep 2026 06:51:02 GMT
- ETag: 13cf9c4050b724f8ba5b1c25a6f95685
- X-Cache: Hit from cloudfront
- CloudFront POP: BOM78
- TLS connection established through Windows Schannel

A HEAD request to the same resource also returned HTTP 200.

### CSS bundle

Request:
HEAD /chat/static/main.6c351450f6.css

Observed:
- HTTP/1.1 200 OK
- Content-Type: text/css
- Content-Length: 288,638 bytes
- Server: AmazonS3
- Last-Modified: Tue, 29 Sep 2026 06:51:02 GMT
- ETag: 427a95e16c2f29081bc36d7460be290e
- X-Cache: Hit from cloudfront
- CloudFront POP: BOM78

### Web manifest

Request:
GET /chat/manifest.json

Observed:
- HTTP/1.1 200 OK
- Content-Type: application/json
- Content-Length: 491 bytes
- Server: AmazonS3
- Last-Modified: Thu, 01 Oct 2026 16:16:22 GMT
- ETag: e3debf20257adc1c68c475182924e6b9
- X-Cache: Hit from cloudfront

Manifest content identifies:
- name: DeepSeek
- short_name: DeepSeek
- start_url: https://chat.deepseek.com/
- scope: https://chat.deepseek.com/
- display: standalone
- icon resources under fe-static.deepseek.com/chat/

## Reachability interpretation

fe-static.deepseek.com
    |
    +-- DNS_RESOLVED       PROBED/OBSERVED BY TEST
    |       3.173.21.63
    |
    +-- TCP_CONNECTED      PROBED
    |
    +-- TLS_ESTABLISHED    PROBED
    |
    +-- HTTP_RESPONDED     PROBED
            |
            +-- JS resource       200 OK
            +-- CSS resource      200 OK
            +-- manifest.json     200 OK

Conclusion: the tested static-resource network path and HTTP service were working at test time.

A previous HTTP 403 for the root resource must not be interpreted as network failure. The resource path was denied while named static resources were successfully served.

## Attribution boundary

The resource paths are known because curl explicitly issued those HTTP requests at the endpoint.

Passive TCP/DNS telemetry alone does NOT reveal:
- the HTTPS path
- browser tab identity
- encrypted request/response content

MachineObserver V0.7 must record this evidence as PROBED rather than silently upgrading it to passive OBSERVED evidence.

## V0.7 design consequence

The probe model should retain:
- target hostname
- resolved address
- TCP outcome
- TLS outcome
- HTTP method
- requested path
- HTTP status
- content type
- content length
- selected response headers
- timestamp
- probe process instance/PID

Observer-generated probe flows must remain excluded from ordinary passive activity interpretation.
