# Chrome / CDP Sensor
Code:
02_SENSORS/windows/browser/Collector.ps1

Purpose:
observe browser-owned application-layer request/response facts.

Fields include:
timestamp, sensor=browser-cdp, method, class, URL, host, path, status, MIME, remote IP/port, protocol, cache flags, TLS metadata.

Role classes:
api-main
api-main-dev
static-cdn
hif-poller
hif-poller-test
deepseek-other
volc-apm
volc-cdn
cloudfront
other

Classifier rule:
specific hostname cases return immediately before broad wildcard cases.

Current observed count:
volc-apm 17
static-cdn 13
api-main 7
other 4
volc-cdn 2
total 43.
