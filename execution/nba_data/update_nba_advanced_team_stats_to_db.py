#!/usr/bin/env python3
"""Update nba_advanced_team_stats table from JSON. See directives/data/."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_nba_advanced_team_stats"


def main():
    updater = BACKEND / "src/api/update_db/update_db_nba_advanced_team_stats.py"
    if not updater.exists():
        print("Error: update_db_nba_advanced_team_stats.py not found", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
