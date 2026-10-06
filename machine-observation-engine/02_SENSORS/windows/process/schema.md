# Process Sensor Evidence Contract

Minimum fields:

| Field | Meaning |
|---|---|
| timestamp_utc | Observation timestamp |
| source | Sensor that produced the observation |
| event_type | PROCESS_CREATE or PROCESS_TERMINATE |
| pid | Windows process ID |
| parent_pid | Parent PID when supplied by the source |
| image | Process image/name |
| evidence_only | Marks the record as observation, not interpretation |

## Identity warning

PID is an observed identifier but can be reused. The correlator must not treat PID alone as globally stable process identity.

## Missing values

Unavailable fields remain absent/null. The sensor must not manufacture command lines, executable paths, parents, network destinations or intent.
