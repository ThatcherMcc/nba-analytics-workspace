#!/usr/bin/env python3
"""
Execution wrapper: Post weekly PropEdge track record to r/sportsbook.

Run from workspace root (typically every Monday morning):
    python execution/nba_data/post_reddit_weekly.py

Delegates to:
    nba-data-backend/src/social/post_reddit.py

Requires in environment (or nba-data-backend/.env.local):
    POSTGRES_URL         -- Neon connection string
    REDDIT_CLIENT_ID     -- Reddit OAuth app client ID
    REDDIT_CLIENT_SECRET -- Reddit OAuth app client secret
    REDDIT_USERNAME      -- Reddit account username
    REDDIT_PASSWORD      -- Reddit account password

Optional:
    REDDIT_SUBREDDIT     -- Target subreddit (defaults to 'sportsbook')

If Reddit credentials are missing the script exits 0 cleanly.
This makes it safe to include in CI without blocking other steps.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[2]
BACKEND = WORKSPACE / "nba-data-backend"
sys.path.insert(0, str(BACKEND))


def _load_env() -> None:
    env_file = BACKEND / ".env.local"
    if env_file.exists():
        from dotenv import load_dotenv
        load_dotenv(dotenv_path=str(env_file))


def main() -> None:
    _load_env()

    db_url = os.environ.get("POSTGRES_URL", "").strip()
    if not db_url:
        print("Error: POSTGRES_URL not set.", file=sys.stderr)
        sys.exit(1)

    import psycopg2

    print("=" * 60)
    print("PropEdge Reddit — posting weekly track record")
    print("=" * 60)

    try:
        conn = psycopg2.connect(db_url)
    except psycopg2.Error as e:
        print(f"Error: DB connection failed: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        from src.social.post_reddit import post_reddit_weekly
        ok = post_reddit_weekly(conn)
    except Exception as e:
        print(f"[reddit] Unexpected error: {e}", file=sys.stderr)
        ok = False
    finally:
        conn.close()

    print("\n" + "=" * 60)
    print(f"  Reddit: {'OK' if ok else 'SKIPPED/FAILED'}")
    print("=" * 60)

    # Non-blocking — always exit 0
    sys.exit(0)


if __name__ == "__main__":
    main()
