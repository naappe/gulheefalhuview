# Architecture
Layers:
1 Sensors
2 Normalizer
3 Correlator
4 SQLite Evidence Store
5 Reasoner
6 Human Meaning

Sensor families:
Process | Network/TCP | DNS | PTR | Browser/Chrome CDP | Probes | future Android.

Browser/CDP is a first-class sensor, not a bypass and not passive TCP.
V0.7 stays modular. Do not rebuild the V0.6.1 monolith.
