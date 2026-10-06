# Sensor Map
Windows sensors:
- process/: process lifecycle and identity
- network/: TCP/UDP flow evidence
- dns/: hostname resolution evidence
- browser/: Chrome/CDP application-layer evidence

Chrome location:
02_SENSORS/windows/browser/Collector.ps1

Chrome output is normalized under the same evidence rules as every other sensor.
Do not merge its provenance with TCP/DNS.
