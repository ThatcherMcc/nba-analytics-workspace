# Update Gamelogs to Database

## Goal
Upload scraped player gamelog data from the backend’s JSON file into Postgres (gamelogs table or equivalent).

## Inputs
- **Data file**: Default `nba-data-backend/data/player_gamelog_2026.json` (or path from backend `Utils.get_player_gamelog_data_path()`). Populate via **scrape_player_gamelogs.md**.

## Tools / Scripts
1. **MCP**: `mcp_nba-engine_update_player_gamelogs_to_db` with optional `data_file` (path to JSON).
2. **Execution**: `python execution/nba_data/update_gamelogs_to_db.py [--data-file path]`.
3. **Backend**: `nba-data-backend/src/api/update_db/update_db_gamelogs.py` (run from backend dir; MCP may invoke different path – see MCP implementation).

## Outputs
- Gamelog rows inserted/upserted in database. Script or MCP returns stdout/stderr and return code.

## Edge Cases (update as you learn)
- MCP script path: MCP may look for `src/api/update_gamelogs.py`; actual module is `src/api/update_db/update_db_gamelogs.py`. If MCP fails, use execution script that calls the correct module.
- Schema mismatch: JSON keys must match DB columns; document any mapping here.
- Large file: note runtime and memory; consider chunking if added later.

## Success Criteria
- Gamelog data appears in DB for expected players.
- No unhandled exceptions; document any duplicate-handling behavior.
