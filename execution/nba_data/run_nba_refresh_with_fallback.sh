#!/usr/bin/env bash
# Try the strict full refresh first. If that fails, fall back to a smaller
# active-team refresh so the site still gets current playoff gamelogs.

set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
BACKEND="${WORKSPACE}/nba-data-backend"
VENV="${BACKEND}/.venv/bin/activate"
STRICT_SCRIPT="${WORKSPACE}/execution/nba_data/full_rescrape_and_update.sh"
FALLBACK_SCRIPT="${BACKEND}/scripts/refresh_active_nba_gamelogs.py"

if [[ ! -f "${VENV}" ]]; then
  echo "Error: Backend venv not found at ${VENV}"
  exit 1
fi

if [[ ! -f "${STRICT_SCRIPT}" ]]; then
  echo "Error: Missing strict refresh script at ${STRICT_SCRIPT}"
  exit 1
fi

if [[ -f "${BACKEND}/.env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  . "${BACKEND}/.env.local"
  set +a
fi

echo "$(date '+%Y-%m-%dT%H:%M:%S') Starting NBA refresh with fallback"

set +e
"${STRICT_SCRIPT}"
strict_rc=$?
set -e

if [[ ${strict_rc} -eq 0 ]]; then
  echo "Strict full refresh succeeded."
  exit 0
fi

echo "Strict full refresh failed with exit code ${strict_rc}. Falling back to active-team refresh."
(
  cd "${BACKEND}"
  . "${VENV}"
  python3 scripts/refresh_active_nba_gamelogs.py --no-proxies --lookback-days 0 --lookahead-days 3
)
