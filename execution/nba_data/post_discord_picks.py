#!/usr/bin/env python3
"""
Execution wrapper: Post today's high-confidence picks to Discord.
Run from workspace root: python execution/nba_data/post_discord_picks.py

Delegates to nba-data-backend/scripts/post_discord_picks.py.
Requires POSTGRES_URL and DISCORD_WEBHOOK_URL in the environment (or
in nba-data-backend/.env.local for local runs).
"""
import subprocess
import sys
import os

WORKSPACE = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BACKEND = os.path.join(WORKSPACE, "nba-data-backend")


def main():
    script = os.path.join(BACKEND, "scripts", "post_discord_picks.py")
    cmd = [sys.executable, script]
    result = subprocess.run(cmd, cwd=BACKEND)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
