#!/usr/bin/env python3
"""Insert parsed player prop lines into the Neon player_props table.

Wrapper around nba-data-backend/src/api/update_db/update_db_player_props.py.
Runs from workspace root.

Usage:
    python execution/nba_data/update_player_props_to_db.py                           # all raw JSON
    python execution/nba_data/update_player_props_to_db.py --json-dir=path/to/dir    # specific dir
    python execution/nba_data/update_player_props_to_db.py --dry-run                 # preview only
"""
import subprocess
import sys
import os

WORKSPACE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BACKEND = os.path.join(WORKSPACE, "nba-data-backend")

args = sys.argv[1:] if len(sys.argv) > 1 else []
cmd = [
    sys.executable, "-m", "src.api.update_db.update_db_player_props",
    *args,
]

result = subprocess.run(cmd, cwd=BACKEND)
sys.exit(result.returncode)
