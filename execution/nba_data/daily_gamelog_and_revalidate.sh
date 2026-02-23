#!/usr/bin/env bash
# Daily pipeline: gamelogs → games → player_game_stats → props → revalidate.
# Schedule with cron (e.g. 0 3 * * * for 3am) or run manually.
#
# Required env (set in cron or source before running):
#   POSTGRES_URL      - Neon connection (backend uses this; often in nba-data-backend/.env.local)
#   APP_URL           - Frontend base URL, e.g. https://your-app.vercel.app (no trailing slash)
#   REVALIDATE_SECRET - Same as frontend REVALIDATE_SECRET; used to auth POST /api/revalidate
# Optional:
#   SCRAPE_PROXIES    - Comma-separated proxy URLs for the gamelog scraper
#   ODDS_API_KEY      - SportsGameOdds API key (enables automatic prop line fetching)
#
# Example cron (3am local, load env from backend):
#   0 3 * * * cd /path/to/nba-analytics-workspace && . nba-data-backend/.env.local 2>/dev/null; export APP_URL=https://... REVALIDATE_SECRET=...; execution/nba_data/daily_gamelog_and_revalidate.sh >> /tmp/daily-gamelog.log 2>&1

set -e
WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND="${WORKSPACE}/nba-data-backend"
VENV="${BACKEND}/.venv/bin/activate"

if [[ ! -f "${VENV}" ]]; then
  echo "Error: Backend venv not found at ${VENV}"
  exit 1
fi

# Load backend env (POSTGRES_URL, optional SCRAPE_PROXIES, ODDS_API_KEY) if present
if [[ -f "${BACKEND}/.env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "${BACKEND}/.env.local"
  set +a
fi

if [[ -z "${APP_URL}" || -z "${REVALIDATE_SECRET}" ]]; then
  echo "Error: Set APP_URL and REVALIDATE_SECRET (frontend URL and revalidate secret)."
  exit 1
fi

echo "$(date '+%Y-%m-%dT%H:%M:%S') Starting daily pipeline"

# ---- Phase 1: Gamelog pipeline ----
echo "  Rescraping gamelogs..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.data_collection.scrapers.gamelogs) || true

echo "  Updating games table..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_games)

echo "  Updating player_game_stats table..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_player_game_stats)

# ---- Phase 2: Props pipeline (optional: requires ODDS_API_KEY) ----
if [[ -n "${ODDS_API_KEY:-}" ]]; then
  echo "  Fetching prop lines from SportsGameOdds API..."
  PROPS_OUTPUT=$(cd "${BACKEND}" && . "${VENV}" && python3 -m src.data_collection.scrapers.props --upcoming --max-objects 100 2>&1) || true
  echo "${PROPS_OUTPUT}"

  # Budget safety check: skip props insert if remaining < 200
  REMAINING=$(echo "${PROPS_OUTPUT}" | grep -oP 'Objects remaining:\s*\K\d+' || echo "")
  if [[ -n "${REMAINING}" && "${REMAINING}" -lt 200 ]]; then
    echo "  WARNING: Only ${REMAINING} API objects remaining (< 200). Skipping props insert to preserve budget."
  else
    echo "  Updating games table from API events (upcoming games)..."
    (cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_games_from_api) || true

    echo "  Inserting player props into DB..."
    (cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_player_props --json-dir="${BACKEND}/data/raw_json/2025-26") || true
  fi
else
  echo "  Skipping props fetch (ODDS_API_KEY not set)."
fi

# ---- Phase 3: Revalidate frontend ----
echo "  Revalidating frontend cache..."
curl -sf -X POST "${APP_URL}/api/revalidate" \
  -H "Authorization: Bearer ${REVALIDATE_SECRET}"

echo "$(date '+%Y-%m-%dT%H:%M:%S') Done."
