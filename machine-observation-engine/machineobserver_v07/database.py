import sqlite3
from pathlib import Path
from config import DATA_DIR, DATABASE_PATH


SCHEMA = """
CREATE TABLE IF NOT EXISTS schema_version(version INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS sessions(
    id TEXT PRIMARY KEY, started_at TEXT NOT NULL, ended_at TEXT
);
CREATE TABLE IF NOT EXISTS process_instances(
    id TEXT PRIMARY KEY, session_id TEXT, pid INTEGER NOT NULL,
    name TEXT, executable TEXT, command_line TEXT, created_at TEXT, ended_at TEXT
);
CREATE TABLE IF NOT EXISTS flows(
    id TEXT PRIMARY KEY, session_id TEXT, process_instance_id TEXT,
    protocol TEXT, local_ip TEXT, local_port INTEGER,
    remote_ip TEXT, remote_port INTEGER,
    first_observed TEXT, last_observed TEXT, state TEXT, evidence_class TEXT
);
CREATE TABLE IF NOT EXISTS dns_records(
    id TEXT PRIMARY KEY, session_id TEXT, hostname TEXT, record_type TEXT,
    value TEXT, cname TEXT, ttl INTEGER, first_seen TEXT, last_seen TEXT, expires_at TEXT
);
CREATE TABLE IF NOT EXISTS flow_dns_links(
    id TEXT PRIMARY KEY, flow_id TEXT, dns_record_id TEXT,
    confidence REAL, evidence_class TEXT, created_at TEXT
);
CREATE TABLE IF NOT EXISTS ptr_context(
    id TEXT PRIMARY KEY, ip TEXT, hostname TEXT, observed_at TEXT, evidence_class TEXT
);
CREATE TABLE IF NOT EXISTS probes(
    id TEXT PRIMARY KEY, session_id TEXT, probe_type TEXT, target TEXT,
    status TEXT, details_json TEXT, observed_at TEXT, evidence_class TEXT
);
CREATE TABLE IF NOT EXISTS activities(
    id TEXT PRIMARY KEY, session_id TEXT, process_instance_id TEXT,
    hostname TEXT, started_at TEXT, ended_at TEXT,
    evidence_ids_json TEXT, interpretation TEXT, confidence REAL
);
"""


def connect() -> sqlite3.Connection:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(Path(DATABASE_PATH))
    conn.executescript(SCHEMA)
    row = conn.execute("SELECT COUNT(*) FROM schema_version").fetchone()
    if row[0] == 0:
        conn.execute("INSERT INTO schema_version(version) VALUES (7)")
        conn.commit()
    return conn
