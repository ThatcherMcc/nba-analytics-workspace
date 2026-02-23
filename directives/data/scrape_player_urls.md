# Scrape Player URLs (Player Table Data)

## Goal
Build the player URL list (Basketball Reference slugs + metadata) from `player_names.csv`. Output is used to populate the `players` table (see **update_players_to_db.md**).

## Inputs
- **Source**: `nba-data-backend/data/player_names.csv` (must exist; see **scrape_player_names.md**).

## Tools / Scripts
1. **Execution**: `python execution/nba_data/scrape_player_urls.py` (from workspace root; runs backend as module).
2. **Backend**: From `nba-data-backend/`: `python3 -m src.data_collection.scrapers.players_table_data` (needs `PYTHONPATH` set to backend root; reads `player_names.csv`, writes `player_urls.json`).

## Outputs
- `nba-data-backend/data/player_urls.json` – structure expected by `update_db_players`: e.g. `successful_players` list with `name`, `url`, `web_index` (or as in backend).
- Optional: `nba-data-backend/data/player_urls_failed.json` for failed lookups (if backend produces it).

## Edge Cases (update as you learn)
- Rate limiting: use proxies; consider batching or delays.
- Name mismatches: some names in CSV may not resolve; failures go to failed file or log.
- Empty CSV: fail fast with clear message; ensure **scrape_player_names** has been run.

## Success Criteria
- `player_urls.json` exists and contains `successful_players` (or structure required by update_players_to_db).
- Failed players (if any) recorded for inspection.
