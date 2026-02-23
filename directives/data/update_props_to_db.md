# Update Props to Database

## Goal
Upload prop betting lines from a CSV file into the Postgres database.

## Inputs
- **Data file**: Default `nba-data-backend/data/prop_line_df.csv` (or path provided). CSV format must match what `update_db_props` expects (columns documented in backend).

## Tools / Scripts
1. **MCP**: `mcp_nba-engine_update_props_to_db` with optional `data_file`.
2. **Execution**: `python execution/nba_data/update_props_to_db.py [--data-file path]`.
3. **Backend**: `nba-data-backend/src/api/update_db/update_db_props.py` (run from backend dir).

## Outputs
- Prop lines inserted/upserted in DB. MCP or script returns stdout/stderr and return code.

## Edge Cases (update as you learn)
- MCP script path: MCP may look for `src/api/update_props.py`; actual path is `src/api/update_db/update_db_props.py`. Use execution script if MCP path is wrong.
- Missing CSV: fail with clear message; ensure props have been fetched/generated (see **fetch_player_props.md** if applicable).
- Odds API rate limits: document if props are fetched first; add to fetch directive.

## Success Criteria
- Props table updated; no connection or query errors.
- Data matches source CSV (spot-check or count).
