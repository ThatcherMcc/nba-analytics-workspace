#!/usr/bin/env python3
"""Scrape team defensive ratings from Basketball Reference. See directives/data/."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.data_collection.scrapers.team_defensive_ratings"


def main():
    if not (BACKEND / "src/data_collection/scrapers/team_defensive_ratings.py").exists():
        print("Error: team_defensive_ratings.py not found", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
