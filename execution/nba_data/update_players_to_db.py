#!/usr/bin/env python3
"""Run players DB update. See directives/data/update_players_to_db.md."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_players"

def main():
    if not (BACKEND / "src/api/update_db/update_db_players.py").exists():
        print("Error: update_db_players.py not found under backend", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ, "PYTHONPATH": str(BACKEND)},
    ).returncode
    sys.exit(rc)

if __name__ == "__main__":
    main()
