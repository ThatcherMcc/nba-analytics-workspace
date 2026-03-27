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

RAW_PROXIES="${SCRAPE_PROXIES:-${PROXY_URLS:-}}"
if [[ -n "${RAW_PROXIES}" ]]; then
  echo "Validating configured proxies before scrape"
  WORKING_PROXIES="$(
  run_backend_python - <<'PY'
import os
import sys
import requests

raw = os.getenv("SCRAPE_PROXIES") or os.getenv("PROXY_URLS") or ""
proxies = [p.strip() for p in raw.split(",") if p.strip()]
test_url = "https://www.basketball-reference.com/players/c/curryst01/gamelog/2026"
working = []

for idx, proxy in enumerate(proxies, start=1):
    proxy_dict = {"http": proxy, "https": proxy}
    try:
        resp = requests.get(test_url, proxies=proxy_dict, timeout=12)
        if resp.status_code == 200 and "player_game_log_reg" in resp.text:
            print(f"proxy {idx}: ok")
            working.append(proxy)
        else:
            print(f"proxy {idx}: rejected status={resp.status_code}", file=sys.stderr)
    except requests.RequestException as exc:
        print(f"proxy {idx}: failed {exc}", file=sys.stderr)

print(",".join(working))
PY
  )"
  WORKING_PROXIES="$(printf '%s\n' "${WORKING_PROXIES}" | tail -n 1)"

  if [[ -n "${WORKING_PROXIES}" ]]; then
    export SCRAPE_PROXIES="${WORKING_PROXIES}"
    echo "Using $(run_backend_python - <<'PY'
import os
print(len([p for p in (os.getenv('SCRAPE_PROXIES') or '').split(',') if p.strip()]))
PY
    ) working proxies for scrape"
  else
    echo "No working proxies passed preflight. Falling back to direct no-proxy scrape."
    unset SCRAPE_PROXIES
    unset PROXY_URLS
  fi
else
  echo "SCRAPE_PROXIES not set. Running direct no-proxy scrape."
fi

echo "Rescraping full NBA gamelog set"
run_backend_module "src.data_collection.scrapers.gamelogs"

echo "Validating rescrape output"
run_backend_python - <<'PY'
import json
from datetime import date, timedelta
from pathlib import Path
import sys

path = Path("nba-data-backend/data/player_gamelog_2026.json")
retry_path = Path("nba-data-backend/data/gamelog_retry_names.txt")

if not path.exists():
    print(f"Error: missing {path}", file=sys.stderr)
    sys.exit(1)

data = json.loads(path.read_text())
player_count = len(data)
row_count = 0
max_date = ""
for player in data:
    for row in player.get("gamelogs") or []:
        row_count += 1
        d = str(row.get("DATE") or "")
        if d > max_date:
            max_date = d

if player_count == 0 or row_count == 0 or not max_date:
    print(f"Error: invalid scrape output players={player_count} rows={row_count} max_date={max_date!r}", file=sys.stderr)
    sys.exit(1)

fresh_cutoff = (date.today() - timedelta(days=3)).isoformat()
if max_date < fresh_cutoff:
    print(f"Error: scrape output is stale. max_date={max_date}, expected >= {fresh_cutoff}", file=sys.stderr)
    sys.exit(1)

failed_count = 0
if retry_path.exists():
    failed_count = sum(
        1 for line in retry_path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )

print(f"Validated scrape output: players={player_count} rows={row_count} max_date={max_date} failed_players={failed_count}")
PY

echo "Updating games table"
run_backend_module "src.api.update_db.update_db_games"

echo "Updating player_game_stats table"
run_backend_module "src.api.update_db.update_db_player_game_stats"

echo "Strict full rescrape completed successfully"
