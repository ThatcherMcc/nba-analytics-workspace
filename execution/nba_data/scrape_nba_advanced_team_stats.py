#!/usr/bin/env python3
"""Scrape NBA advanced team stats from NBA.com stats API. See directives/data/."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.data_collection.scrapers.nba_advanced_team_stats"


def main():
    scraper = BACKEND / "src/data_collection/scrapers/nba_advanced_team_stats.py"
    if not scraper.exists():
        print("Error: nba_advanced_team_stats.py not found", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ},
    ).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
