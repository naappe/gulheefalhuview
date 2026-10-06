# Data Model
ProcessInstance:
process_instance_id, pid, name, executable, command_line, create_time, backend, observer_owned.

Flow:
protocol, local_ip, local_port, remote_ip, remote_port, first_seen, last_seen, state, process_instance_id if established.

DNSRecord:
hostname, type, value, ttl, first_seen, last_seen, expiry.

BrowserResponse:
timestamp, sensor, method, class, url, host, path, status, mimeType, remoteIP, remotePort, protocol, cache flags, TLS.

Every durable fact needs provenance and an evidence ID.
