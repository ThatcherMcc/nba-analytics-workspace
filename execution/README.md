# Execution (Layer 3: Doing the Work)

Deterministic scripts run by the agent. Prefer **MCP tools** when available (`mcp_nba-engine_*`); use these scripts when MCP is unavailable or you need to run from the workspace root with explicit args.

## nba_data/

Scripts that delegate to `nba-data-backend/`. All run from **workspace root**; they `cd` to `nba-data-backend` and use `uv run` (or `python -m`) so backend imports resolve.

| Script | Backend module | Directive |
|--------|----------------|-----------|
| `scrape_player_names.py` | `src/data_collection/scrapers/player_names.py` | `directives/data/scrape_player_names.md` |
| `scrape_player_gamelogs.py` | (MCP preferred) acquisition + processing | `directives/data/scrape_player_gamelogs.md` |
| `scrape_player_urls.py` | `src/data_collection/scrapers/players_table_data.py` | `directives/data/scrape_player_urls.md` |
| `update_players_to_db.py` | `src/api/update_db/update_db_players.py` | `directives/data/update_players_to_db.md` |
| `update_gamelogs_to_db.py` | `src/api/update_db/update_db_gamelogs.py` | `directives/data/update_gamelogs_to_db.md` |
| `update_props_to_db.py` | `src/api/update_db/update_db_props.py` | `directives/data/update_props_to_db.md` |

Run from workspace root, e.g.:
```bash
python execution/nba_data/update_players_to_db.py
uv run --directory nba-data-backend src/data_collection/scrapers/player_names.py   # alternative
```
