#!/usr/bin/env python3
"""
Execution wrapper: Post yesterday's PropEdge pick grades to Twitter and Discord.

Run from workspace root:
    python execution/nba_data/post_social_grades.py

Delegates to:
    nba-data-backend/src/social/post_twitter.py
    nba-data-backend/src/social/post_discord.py

Requires in environment (or nba-data-backend/.env.local):
    POSTGRES_URL         -- Neon connection string
    DISCORD_WEBHOOK_URL  -- Discord webhook (optional; skipped if absent)
    TWITTER_API_KEY      -- Twitter v2 API credentials (optional)
    TWITTER_API_SECRET
    TWITTER_ACCESS_TOKEN
    TWITTER_ACCESS_SECRET

Grades are pulled from ml_backtest_results for yesterday's date
(America/New_York timezone). If the backtest table has not been
populated for yesterday yet, both posts are skipped gracefully.

Behaviour:
    - If Twitter fails, Discord still runs (independent steps).
    - Exit code 0 always (non-blocking CI step).
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
    print("PropEdge Social Grades — posting to Twitter + Discord")
    print("=" * 60)

    results: dict[str, bool] = {}

    try:
        conn = psycopg2.connect(db_url)
    except psycopg2.Error as e:
        print(f"Error: DB connection failed: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        # --- Twitter ---
        print("\n[1/2] Twitter")
        try:
            from src.social.post_twitter import post_morning_grades
            results["twitter"] = post_morning_grades(conn)
        except Exception as e:
            print(f"[twitter] Unexpected error: {e}", file=sys.stderr)
            results["twitter"] = False

        # --- Discord ---
        print("\n[2/2] Discord")
        try:
            from src.social.post_discord import post_discord_grades
            results["discord"] = post_discord_grades(conn)
        except Exception as e:
            print(f"[discord] Unexpected error: {e}", file=sys.stderr)
            results["discord"] = False

    finally:
        conn.close()

    print("\n" + "=" * 60)
    for platform, ok in results.items():
        status = "OK" if ok else "SKIPPED/FAILED"
        print(f"  {platform:<12} {status}")
    print("=" * 60)

    # Grades are a non-blocking step — always exit 0
    sys.exit(0)


if __name__ == "__main__":
    main()
