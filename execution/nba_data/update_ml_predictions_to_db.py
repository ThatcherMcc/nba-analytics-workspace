#!/usr/bin/env python3
"""Generate ML predictions and upsert to ml_predictions table. See directives/data/."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_ml_predictions"


def main():
    if not (BACKEND / "src/api/update_db/update_db_ml_predictions.py").exists():
        print("Error: update_db_ml_predictions.py not found", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
