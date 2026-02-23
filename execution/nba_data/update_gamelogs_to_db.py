#!/usr/bin/env python3
"""Run gamelogs DB update (calls backend script; backend may call Next.js API). See directives/data/update_gamelogs_to_db.md."""
import argparse
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
SCRIPT = "src/api/update_db/update_db_gamelogs.py"

def main():
    if not (BACKEND / SCRIPT).exists():
        print(f"Error: {SCRIPT} not found under {BACKEND}", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, SCRIPT],
        cwd=str(BACKEND),
        env={**__import__("os").environ, "PYTHONPATH": str(BACKEND / "src")},
    ).returncode
    sys.exit(rc)

if __name__ == "__main__":
    main()
