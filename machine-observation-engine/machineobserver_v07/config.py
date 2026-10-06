from pathlib import Path

VERSION = "0.7"
ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"
DATABASE_PATH = DATA_DIR / "observer-v07.db"

ACTIVE_PROBES_ENABLED = False
EXCLUDE_OBSERVER_OWNED_FLOWS = True
