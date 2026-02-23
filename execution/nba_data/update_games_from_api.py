#!/usr/bin/env python3
"""Insert upcoming games from API event data into the games table.

Wrapper around nba-data-backend/src/api/update_db/update_db_games_from_api.py.
Runs from workspace root.

Usage:
    python execution/nba_data/update_games_from_api.py
    python execution/nba_data/update_games_from_api.py --dry-run
    python execution/nba_data/update_games_from_api.py --json-dir=path/to/dir
"""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_games_from_api"


def main():
    if not (BACKEND / "src/api/update_db/update_db_games_from_api.py").exists():
        print("Error: update_db_games_from_api.py not found under backend", file=sys.stderr)
        sys.exit(1)
    args = sys.argv[1:] if len(sys.argv) > 1 else []
    rc = subprocess.run(
        [sys.executable, "-m", MODULE, *args],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
