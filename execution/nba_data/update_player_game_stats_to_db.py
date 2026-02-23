#!/usr/bin/env python3
"""Run player_game_stats DB update from player_gamelog_2026.json. See directives/data/populate_relational_schema.md."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.api.update_db.update_db_player_game_stats"


def main():
    if not (BACKEND / "src/api/update_db/update_db_player_game_stats.py").exists():
        print("Error: update_db_player_game_stats.py not found under backend", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
