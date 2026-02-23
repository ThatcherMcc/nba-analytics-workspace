#!/usr/bin/env python3
"""Run player names scraper. See directives/data/scrape_player_names.md."""
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
MODULE = "src.data_collection.scrapers.player_names"

def main():
    if not (BACKEND / "src/data_collection/scrapers/player_names.py").exists():
        print("Error: player_names.py not found under backend", file=sys.stderr)
        sys.exit(1)
    os = __import__("os")
    uv = __import__("shutil").which("uv")
    if uv:
        cmd = [uv, "run", "--directory", str(BACKEND), "-m", MODULE]
        cwd, env = str(BACKEND), os.environ
    else:
        cmd = [sys.executable, "-m", MODULE]
        cwd, env = str(BACKEND), {**os.environ, "PYTHONPATH": str(BACKEND)}
    rc = subprocess.run(cmd, cwd=cwd, env=env).returncode
    sys.exit(rc)

if __name__ == "__main__":
    main()
