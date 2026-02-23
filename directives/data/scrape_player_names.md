# Scrape Player Names

## Goal
Refresh the list of active NBA players from Basketball Reference and save to `nba-data-backend/data/player_names.csv`.

## Inputs
- None (scraper fetches from Basketball Reference active players page).

## Tools / Scripts
1. **MCP** (preferred): `mcp_nba-engine_scrape_player_names` (no args).
2. **Execution**: `python execution/nba_data/scrape_player_names.py` (from workspace root; runs backend as module).
3. **Backend**: From `nba-data-backend/`: `python3 -m src.data_collection.scrapers.player_names` (requires `PYTHONPATH` set to backend root if not using execution script).

## Outputs
- `nba-data-backend/data/player_names.csv` – one column: player names (or as defined by scraper).

## Edge Cases (update as you learn)
- Rate limiting/ blocks: use proxies if configured (`SCRAPE_PROXIES` in backend `.env`); MCP `test_proxies` to verify.
- Empty or partial CSV: re-run; if persistent, check Basketball Reference page structure changes.

## Success Criteria
- `player_names.csv` exists and contains current season active players.
- No unhandled exceptions; if proxies used, they are working (test with `mcp_nba-engine_test_proxies`).
