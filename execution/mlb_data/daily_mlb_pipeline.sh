#!/usr/bin/env bash
# Daily MLB pipeline: starters → gamelogs → games → player gamelogs → park factors → predictions → revalidate.
# Schedule with cron or run manually.
#
# Required env (set in cron or source before running):
#   POSTGRES_URL      - Neon connection string (also loaded from nba-data-backend/.env.local if present)
#   APP_URL           - Frontend base URL, e.g. https://your-app.vercel.app (no trailing slash)
#   REVALIDATE_SECRET - Same as frontend REVALIDATE_SECRET; used to auth POST /api/revalidate
# Optional:
#   SCRAPE_PROXIES    - Comma-separated proxy URLs for scrapers
#   MORNING_RUN       - Set to "1" to include full gamelog rescrape (slower; skip for quick afternoon refresh)
#
# Example cron (7:30am ET daily, load env from backend):
#   30 11 * * * cd /path/to/nba-analytics-workspace && . nba-data-backend/.env.local 2>/dev/null; export APP_URL=https://... REVALIDATE_SECRET=...; execution/mlb_data/daily_mlb_pipeline.sh >> /tmp/daily-mlb.log 2>&1

set -e
WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND="${WORKSPACE}/nba-data-backend"
VENV="${BACKEND}/.venv/bin/activate"

if [[ ! -f "${VENV}" ]]; then
  echo "Error: Backend venv not found at ${VENV}"
  exit 1
fi

# Load backend env (POSTGRES_URL, SCRAPE_PROXIES, etc.) if present
if [[ -f "${BACKEND}/.env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "${BACKEND}/.env.local"
  set +a
fi

if [[ -z "${APP_URL:-}" || -z "${REVALIDATE_SECRET:-}" ]]; then
  echo "Error: Set APP_URL and REVALIDATE_SECRET (frontend URL and revalidate secret)."
  exit 1
fi

echo "$(date '+%Y-%m-%dT%H:%M:%S') Starting daily MLB pipeline"

# ---- Phase 1: Confirmed starters ----
echo "  Scraping confirmed MLB starters..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.data_collection.scrapers.mlb_confirmed_starters) || true

# ---- Phase 2: Gamelogs (morning run only; skip for quick afternoon refresh) ----
if [[ "${MORNING_RUN:-0}" == "1" ]]; then
  echo "  Rescraping MLB gamelogs (morning run)..."
  (cd "${BACKEND}" && . "${VENV}" && python3 -m src.data_collection.scrapers.mlb_gamelogs) || true
else
  echo "  Skipping gamelog rescrape (set MORNING_RUN=1 to enable)."
fi

# ---- Phase 3: DB updates ----
echo "  Updating mlb_games table..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_mlb_games)

echo "  Updating mlb_player_gamelogs table..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_mlb_gamelogs)

echo "  Updating mlb_park_factors table..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_mlb_park_factors) || true

# ---- Phase 4: ML predictions ----
echo "  Generating MLB predictions..."
(cd "${BACKEND}" && . "${VENV}" && python3 -m src.api.update_db.update_db_mlb_predictions) || true

# ---- Phase 5: Revalidate frontend ----
echo "  Revalidating frontend cache..."
curl -sf -X POST "${APP_URL}/api/revalidate" \
  -H "Authorization: Bearer ${REVALIDATE_SECRET}"

echo "$(date '+%Y-%m-%dT%H:%M:%S') Done."
