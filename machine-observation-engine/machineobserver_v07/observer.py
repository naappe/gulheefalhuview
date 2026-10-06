"""MachineObserver V0.7 controller.

Sensors produce evidence. Correlators link evidence. Reasoning never manufactures evidence.
Active probes are disabled by default and remain separate from passive observations.
"""

import os
from config import ACTIVE_PROBES_ENABLED
from database import connect


def main() -> None:
    observer_pid = os.getpid()
    db = connect()
    print(f"MachineObserver V0.7 | observer_pid={observer_pid}")
    print(f"Active probes: {'ON' if ACTIVE_PROBES_ENABLED else 'OFF'}")
    print("Evidence store ready.")
    # Sensor orchestration is implemented incrementally under sensors/.
    db.close()


if __name__ == "__main__":
    main()
