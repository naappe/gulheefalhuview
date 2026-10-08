# Male City Council HTTPS response — 2026-10-08

## User-provided PowerShell evidence

```powershell
PS C:\Users\User> try {
>>     $r = Invoke-WebRequest -Uri "https://malecity.gov.mv/en" -UseBasicParsing
>>     Write-Host "HTTP STATUS: $($r.StatusCode)"
>> } catch {
>>     Write-Host "ERROR: $($_.Exception.Message)"
>> }
HTTP STATUS: 200
PS C:\Users\User>
```

## Evidence classification

- REQUEST_TARGET = https://malecity.gov.mv/en — OBSERVED (command text)
- HTTP_STATUS = 200 — OBSERVED (PowerShell output)
- HTTP_RESPONSE_RECEIVED = OBSERVED
- DNS resolution and transport were sufficient for this request to complete — INFERRED
- TLS version / cipher / certificate details = UNKNOWN
- Final redirected URL = UNKNOWN
- Response headers / content length / title = UNKNOWN
- Browser page rendering = NOT_TESTED
- Authentication = NOT_TESTED
- Backend/database health = NOT_TESTED

## Next read-only test

```powershell
$r = Invoke-WebRequest -Uri "https://malecity.gov.mv/en" -UseBasicParsing
[PSCustomObject]@{
    StatusCode    = $r.StatusCode
    FinalURL      = $r.BaseResponse.ResponseUri.AbsoluteUri
    ContentType   = $r.Headers["Content-Type"]
    Server        = $r.Headers["Server"]
    ContentLength = $r.RawContentLength
    PageTitle     = if ($r.Content -match '(?is)<title[^>]*>(.*?)</title>') {
        $Matches[1].Trim()
    } else { "NOT FOUND" }
} | Format-List
```

## Machine Observation Engine invariant

An HTTP 200 response proves an HTTP success response was received for this request; it does not prove successful browser rendering, authentication, or application/backend health.
