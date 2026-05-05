#!/usr/bin/env bash
# Strict NBA gamelog pipeline:
# 1. Full rescrape using configured proxies
# 2. Validate the output JSON is fresh and non-empty
# 3. Update games
# 4. Update player_game_stats
# 5. Revalidate frontend
#
# Unlike the daily wrapper, this script fails fast and writes a timestamped log.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND="${WORKSPACE}/nba-data-backend"
VENV="${BACKEND}/.venv/bin/activate"
LOG_DIR="${BACKEND}/data/logs"
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/full_rescrape_$(date '+%Y%m%d_%H%M%S').log"

if [[ ! -f "${VENV}" ]]; then
  echo "Error: Backend venv not found at ${VENV}"
  exit 1
fi

if [[ -f "${BACKEND}/.env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "${BACKEND}/.env.local"
  set +a
fi

if [[ -z "${POSTGRES_URL:-}" ]]; then
  echo "Error: POSTGRES_URL is required."
  exit 1
fi

exec > >(tee -a "${LOG_FILE}") 2>&1

echo "$(date '+%Y-%m-%dT%H:%M:%S') Starting strict full rescrape"
echo "Log file: ${LOG_FILE}"

run_backend_module() {
  local module="$1"
  echo "Running ${module}"
  (
    cd "${BACKEND}"
    . "${VENV}"
    python3 -m "${module}"
  )
}

run_backend_python() {
  (
    cd "${BACKEND}"
    . "${VENV}"
    python3 "$@"
  )
}

echo "Validating players table before scrape"
run_backend_python - <<'PY'
import os
import sys

try:
    import psycopg2
    from src.data_collection.scrapers.gamelogs import _load_players_from_db
    from src.utils.paths import Utils
except ImportError as exc:
    print(f"Error: backend preflight imports failed: {exc}", file=sys.stderr)
    raise SystemExit(1)

db_url = os.getenv("POSTGRES_URL")
if not db_url:
    print("Error: POSTGRES_URL is required for players table validation.", file=sys.stderr)
    raise SystemExit(1)

conn = psycopg2.connect(db_url)
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM players WHERE url IS NOT NULL AND url != ''")
total = cur.fetchone()[0]
cur.close()
conn.close()

players = _load_players_from_db(Utils()) or []
bad = [
    entry for entry in players
    if "basketball-reference.com/players/" not in (entry.get("url") or "")
    or "/gamelog/2026" not in (entry.get("url") or "")
]

print(f"Players table preflight: total_urls={total}, scraper_loaded={len(players)}, invalid_loaded={len(bad)}")
if total == 0:
    print("Error: players table has no URLs to scrape.", file=sys.stderr)
    raise SystemExit(1)
if not players:
    print("Error: scraper loader returned no NBA Basketball Reference gamelog URLs.", file=sys.stderr)
    raise SystemExit(1)
if bad:
    print("Error: checked-out scraper code still loads non-NBA or non-gamelog URLs. Refusing to run mixed scrape.", file=sys.stderr)
    for entry in bad[:10]:
        print(f"  sample invalid loaded row: {entry.get('name', '')} -> {entry.get('url', '')}", file=sys.stderr)
    raise SystemExit(1)
PY

RAW_PROXIES="$(
run_backend_python - <<'PY'
from src.utils.proxies import load_proxy_list

print(",".join(load_proxy_list()))
PY
)"
RAW_PROXIES="$(printf '%s\n' "${RAW_PROXIES}" | tail -n 1)"
MIN_WORKING_PROXIES="${MIN_WORKING_SCRAPE_PROXIES:-10}"
if [[ -n "${RAW_PROXIES}" ]]; then
  export SCRAPE_PROXIES="${RAW_PROXIES}"
  echo "Validating configured proxies before scrape"
  WORKING_PROXIES="$(
  run_backend_python - <<'PY'
import os
import sys
import cloudscraper

raw = os.getenv("SCRAPE_PROXIES") or os.getenv("PROXY_URLS") or ""
proxies = [p.strip() for p in raw.split(",") if p.strip()]
test_url = "https://www.basketball-reference.com/players/c/curryst01/gamelog/2026"
working = []
status_counts = {}
scraper = cloudscraper.create_scraper(
    browser={
        "browser": "chrome",
        "platform": "windows",
        "mobile": False,
    }
)

for idx, proxy in enumerate(proxies, start=1):
    proxy_dict = {"http": proxy, "https": proxy}
    try:
        resp = scraper.get(test_url, proxies=proxy_dict, timeout=12)
        status_counts[resp.status_code] = status_counts.get(resp.status_code, 0) + 1
        if resp.status_code == 200 and "player_game_log_reg" in resp.text:
            print(f"proxy {idx}: ok")
            working.append(proxy)
        else:
            print(f"proxy {idx}: rejected status={resp.status_code}", file=sys.stderr)
    except Exception as exc:
        key = type(exc).__name__
        status_counts[key] = status_counts.get(key, 0) + 1
        print(f"proxy {idx}: failed {exc}", file=sys.stderr)

summary = ", ".join(f"{k}={v}" for k, v in sorted(status_counts.items(), key=lambda kv: str(kv[0])))
if summary:
    print(f"proxy preflight summary: {summary}", file=sys.stderr)
print(",".join(working))
PY
  )"
  WORKING_PROXIES="$(printf '%s\n' "${WORKING_PROXIES}" | tail -n 1)"
  WORKING_PROXY_COUNT="$(printf '%s' "${WORKING_PROXIES}" | awk -F',' '{print NF}')"

  if [[ -n "${WORKING_PROXIES}" ]]; then
    export SCRAPE_PROXIES="${WORKING_PROXIES}"
    echo "Working proxies passed preflight: ${WORKING_PROXY_COUNT}"
    if [[ "${WORKING_PROXY_COUNT}" -lt "${MIN_WORKING_PROXIES}" ]]; then
      echo "Error: only ${WORKING_PROXY_COUNT} proxies passed preflight; require at least ${MIN_WORKING_PROXIES}."
      exit 1
    fi
    echo "Using ${WORKING_PROXY_COUNT} working proxies for scrape"
  else
    echo "Error: no working proxies passed preflight; require at least ${MIN_WORKING_PROXIES}."
    exit 1
  fi
else
  echo "Error: SCRAPE_PROXIES not set. This strict run requires at least ${MIN_WORKING_PROXIES} working proxies."
  exit 1
fi

echo "Rescraping full NBA gamelog set"
run_backend_module "src.data_collection.scrapers.gamelogs"

echo "Validating rescrape output"
run_backend_python - <<'PY'
import json
import os
from datetime import date, timedelta
from pathlib import Path
import sys

path = Path("data/player_gamelog_2026.json")
retry_path = Path("data/gamelog_retry_names.txt")

if not path.exists():
    print(f"Error: missing {path}", file=sys.stderr)
    sys.exit(1)

data = json.loads(path.read_text())
player_count = len(data)
row_count = 0
max_date = ""
team_max_dates = {}
for player in data:
    for row in player.get("gamelogs") or []:
        row_count += 1
        d = str(row.get("DATE") or "")
        if d > max_date:
            max_date = d
        team_code = str(row.get("PLAYER_TEAM") or "").strip().upper()
        if team_code and d and d > team_max_dates.get(team_code, ""):
            team_max_dates[team_code] = d

if player_count == 0 or row_count == 0 or not max_date:
    print(f"Error: invalid scrape output players={player_count} rows={row_count} max_date={max_date!r}", file=sys.stderr)
    sys.exit(1)

today = date.today()

def load_active_team_next_dates():
    db_url = os.getenv("POSTGRES_URL")
    if not db_url:
        return {}, "none"

    try:
        import psycopg2
    except ImportError:
        return {}, "none"

    upcoming_end = today + timedelta(days=3)
    team_next_dates = {}

    try:
        conn = psycopg2.connect(db_url)
        cur = conn.cursor()

        # Prefer games that currently have player props, since that is what the
        # app is actually showing. Fall back to upcoming games if no props are present.
        cur.execute(
            """
            SELECT DISTINCT g.game_date::text, ht.team_code, at.team_code
            FROM player_props pp
            JOIN games g ON g.game_id = pp.game_id
            JOIN teams ht ON ht.team_id = g.home_team_id
            JOIN teams at ON at.team_id = g.away_team_id
            WHERE g.game_date BETWEEN %s AND %s
            """,
            (today.isoformat(), upcoming_end.isoformat()),
        )
        rows = cur.fetchall()
        source = "player_props"

        if not rows:
            cur.execute(
                """
                SELECT DISTINCT g.game_date::text, ht.team_code, at.team_code
                FROM games g
                JOIN teams ht ON ht.team_id = g.home_team_id
                JOIN teams at ON at.team_id = g.away_team_id
                WHERE g.game_date BETWEEN %s AND %s
                """,
                (today.isoformat(), upcoming_end.isoformat()),
            )
            rows = cur.fetchall()
            source = "games"

        cur.close()
        conn.close()

        for game_date, home_code, away_code in rows:
            for code in (home_code, away_code):
                code = str(code or "").strip().upper()
                if not code:
                    continue
                prev = team_next_dates.get(code)
                if prev is None or game_date < prev:
                    team_next_dates[code] = game_date
        return team_next_dates, source
    except Exception as exc:
        print(f"Warning: could not load active teams from DB for freshness validation: {exc}", file=sys.stderr)
        return {}, "none"

team_next_dates, freshness_source = load_active_team_next_dates()
if team_next_dates:
    stale_teams = []
    missing_teams = []

    for team_code, next_game_date in sorted(team_next_dates.items()):
        latest_team_date = team_max_dates.get(team_code)
        if not latest_team_date:
            missing_teams.append(team_code)
            continue

        # Around play-in / playoffs, active teams can go several days between games.
        # Validate the scrape against the teams that currently have lined games and
        # allow a wider gap from their next scheduled game.
        fresh_cutoff = (date.fromisoformat(next_game_date) - timedelta(days=7)).isoformat()
        if latest_team_date < fresh_cutoff:
            stale_teams.append((team_code, latest_team_date, fresh_cutoff, next_game_date))

    if missing_teams:
        print(
            f"Error: scrape output is missing gamelog data for active teams from {freshness_source}: {', '.join(missing_teams)}",
            file=sys.stderr,
        )
        sys.exit(1)

    if stale_teams:
        details = "; ".join(
            f"{team}: max_date={team_date}, expected >= {cutoff} for next_game={next_game}"
            for team, team_date, cutoff, next_game in stale_teams[:8]
        )
        print(
            f"Error: scrape output is stale for active teams from {freshness_source}. {details}",
            file=sys.stderr,
        )
        sys.exit(1)
else:
    fresh_cutoff = (today - timedelta(days=7)).isoformat()
    if max_date < fresh_cutoff:
        print(f"Error: scrape output is stale. max_date={max_date}, expected >= {fresh_cutoff}", file=sys.stderr)
        sys.exit(1)

failed_count = 0
if retry_path.exists():
    failed_count = sum(
        1 for line in retry_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )

active_team_count = len(team_next_dates)
print(
    f"Validated scrape output: players={player_count} rows={row_count} "
    f"max_date={max_date} active_teams={active_team_count} "
    f"freshness_source={freshness_source} failed_players={failed_count}"
)
PY

echo "Updating games table"
run_backend_module "src.api.update_db.update_db_games"

echo "Updating player_game_stats table"
run_backend_module "src.api.update_db.update_db_player_game_stats"

echo "Strict full rescrape completed successfully"
