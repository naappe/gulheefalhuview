# Browser Sensor Files
Production/reference files:
- 02_SENSORS/windows/browser/Collector.ps1
- 02_SENSORS/windows/browser/SocketSnapshot.ps1
- 02_SENSORS/windows/browser/Analyzer.ps1
- 02_SENSORS/windows/browser/RunAll.ps1

Collector: Chrome CDP HTTP/application evidence.
SocketSnapshot: Windows TCP/PID observations.
Analyzer: compact class/host/PID/URL report.
RunAll: starts socket capture, collector, then analyzer.

PowerShell rule:
Never use Pid as a function parameter name. $PID is an automatic read-only variable and PowerShell variable names are case-insensitive. Use ProcessId.

Current browser roles include:
api-main, api-main-dev, static-cdn, hif-poller, hif-poller-test, deepseek-other, cloudfront, volc-apm, volc-cdn, fingerprint, turnstile, apple-auth, other.
