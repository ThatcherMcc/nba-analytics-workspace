#!/usr/bin/env python3
"""Fetch current NBA prop lines from SportsGameOdds API.

Wrapper around nba-data-backend/src/data_collection/scrapers/props.py.
Runs from workspace root.

Usage:
    python execution/nba_data/fetch_props.py --usage       # Check quota only
    python execution/nba_data/fetch_props.py --upcoming    # Fetch today's games
    python execution/nba_data/fetch_props.py --test        # Single request test
"""
import subprocess
import sys
import os

WORKSPACE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BACKEND = os.path.join(WORKSPACE, "nba-data-backend")

args = sys.argv[1:] if len(sys.argv) > 1 else ["--upcoming"]
cmd = [
    sys.executable, "-m", "src.data_collection.scrapers.props",
    *args,
]

result = subprocess.run(cmd, cwd=BACKEND)
sys.exit(result.returncode)
