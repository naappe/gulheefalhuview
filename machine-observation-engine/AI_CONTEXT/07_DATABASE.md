# Database
V0.7 DB: data/observer-v07.db
Never reuse old observer.db.

Tables:
schema_version
sessions
process_instances
flows
dns_records
flow_dns_links
ptr_context
probes
activities

Add:
browser_responses
evidence_links
artifacts

Store source/provenance, timestamps, session IDs and evidence IDs.
Never overwrite raw observed facts with inference.
