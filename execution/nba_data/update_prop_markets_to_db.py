#!/usr/bin/env python3
"""Seed prop_markets table. See directives/data/update_prop_markets_to_db.md."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_prop_markets"


def main():
    if not (BACKEND / "src/api/update_db/update_db_prop_markets.py").exists():
        print(f"Error: update_db_prop_markets.py not found under {BACKEND}", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
