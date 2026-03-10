#!/usr/bin/env python3
"""
Execution wrapper: Upsert MLB park factors into the DB.
Run from workspace root: python execution/mlb_data/update_mlb_park_factors_to_db.py
"""
import os
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_mlb_park_factors"


def main():
    if not (BACKEND / "src/api/update_db/update_db_mlb_park_factors.py").exists():
        print("Error: update_db_mlb_park_factors.py not found under backend", file=sys.stderr)
        sys.exit(1)
    cmd = [sys.executable, "-m", MODULE] + sys.argv[1:]
    result = subprocess.run(
        cmd,
        cwd=str(BACKEND),
        env={**os.environ, "PYTHONPATH": str(BACKEND)},
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
