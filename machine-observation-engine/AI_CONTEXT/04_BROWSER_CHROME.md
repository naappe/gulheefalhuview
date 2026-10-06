# Chrome / CDP Sensor
Code: 02_SENSORS/windows/browser/Collector.ps1
Analyzer: 02_SENSORS/windows/browser/Analyzer.ps1

Purpose: browser application-layer evidence with Windows PID correlation when directly observable.

Raw evidence is never deleted to remove duplicates.

Each response gets resourceKey:
method | URL | HTTP status | remote IP | remote port

Analyzer reports:
- raw observations
- unique resources
- duplicate count
- raw count by class
- unique count by class
- host/IP/PID evidence
- unique URLs
- TLS summary

Missing PID remains UNKNOWN.

Fields:
timestamp, sensor=browser-cdp, method, class, url, host, path, status, mimeType, remoteIP, remotePort, chromePID, procName, resourceKey, protocol, cache flags, TLS.

Roles:
api-main, api-main-dev, static-cdn, hif-poller, hif-poller-test, deepseek-other, volc-apm, volc-cdn, cloudfront, fingerprint, turnstile, apple-auth, other.

Classifier uses immediate return for specific/broad wildcard rules.
