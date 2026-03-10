#!/usr/bin/env python3
"""
Execution wrapper: Scrape MLB confirmed starting pitchers for a given date.
Run from workspace root: python execution/mlb_data/scrape_mlb_starters.py [--date YYYY-MM-DD]

Optional args:
  --date YYYY-MM-DD   Date to scrape starters for (default: today)
"""
import os
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.data_collection.scrapers.mlb_confirmed_starters"


def main():
    if not (BACKEND / "src/data_collection/scrapers/mlb_confirmed_starters.py").exists():
        print("Error: mlb_confirmed_starters.py not found under backend", file=sys.stderr)
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
