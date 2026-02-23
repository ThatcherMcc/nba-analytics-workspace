#!/usr/bin/env python3
"""Run player URLs scraper (players_table_data). See directives/data/scrape_player_urls.md."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.data_collection.scrapers.players_table_data"

def main():
    if not (BACKEND / "src/data_collection/scrapers/players_table_data.py").exists():
        print("Error: players_table_data.py not found under backend", file=sys.stderr)
        sys.exit(1)
    rc = subprocess.run(
        [sys.executable, "-m", MODULE],
        cwd=str(BACKEND),
        env={**__import__("os").environ, "PYTHONPATH": str(BACKEND)},
    ).returncode
    sys.exit(rc)

if __name__ == "__main__":
    main()
