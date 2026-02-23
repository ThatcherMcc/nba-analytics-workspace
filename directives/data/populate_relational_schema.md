# Populate Neon Relational Schema

## Goal
Fill all Neon Postgres tables in dependency order so the relational schema is ready for the app and future ETL.

## Schema reference
- **Full schema**: `directives/infrastructure/neon_schema.md` (refresh via `nba-data-backend/scripts/export_neon_schema.py`).

## Tables and dependency order

Populate in this order (later tables reference earlier ones via FKs):

| Order | Table | FK dependencies | Current status / data source |
|-------|--------|------------------|------------------------------|
| 1 | **teams** | none | Needs `teams_db_data.json`; script: `update_db_teams.py` |
| 2 | **players** | none | **Populated** from `player_urls.json` via `update_db_players.py` |
| 3 | **games** | teams (home_team_id, away_team_id) | Derived from **player_gamelog_2026.json**: unique (DATE, HOME_TEAM, AWAY_TEAM) after rescrape. Season e.g. `2025-2026` or `2026`. |
| 4 | **player_game_stats** | players, games, teams | From same **player_gamelog_2026.json** (after rescrape): join to players, games, teams; one row per player-game. |
| 5 | **prop_markets** | none | Needs seed data: market codes/names (e.g. PTS, REB, AST) |
| 6 | **player_props** | players, games, prop_markets | Needs props pipeline: odds/source → prop_markets + games + players → insert |

Legacy/flat tables (can stay in parallel or migrate later):
- **player_data_2025** / **player_data_2026**: flat gamelogs (player_name, game_date, opponent, stats). Filled via Next.js API `update-players` from `update_db_gamelogs.py` (sends `player_gamelog_2026.json`).

## Gamelog as source of truth (games + player_game_stats)

- **Rescrape** all player gamelogs so `player_gamelog_2026.json` is replaced and becomes the single source for both **games** and **player_game_stats**.
- **processing.py** (after scrape) now keeps the player’s team and derives:
  - **PLAYER_TEAM**: from raw `Team`/`Tm` (no longer dropped).
  - **HOME_TEAM** / **AWAY_TEAM**: from LOCATION + OPPONENT + PLAYER_TEAM (so each row has date + home/away team codes).
- **Season**: Use `2025-2026` (or the single year e.g. `2026` to match the URL) when inserting into `games`.

## Runbook: Rescrape → Games → Player game stats

**Do not** use the existing `player_gamelog_2026.json` for games / player_game_stats. Run in this order:

1. **Rescrape gamelogs** (overwrites `player_gamelog_2026.json` with PLAYER_TEAM, HOME_TEAM, AWAY_TEAM):
   - From workspace: MCP `mcp_nba-engine_scrape_player_gamelogs` (all players) or run backend: `cd nba-data-backend && source .venv/bin/activate && python3 -m src.data_collection.scrapers.gamelogs` (reads `player_urls.json`, writes `data/player_gamelog_2026.json`).
2. **Update games table**:  
   `cd nba-data-backend && source .venv/bin/activate && python3 -m src.api.update_db.update_db_games`  
   or from workspace: `python execution/nba_data/update_games_to_db.py`.
3. **Update player_game_stats table**:  
   `cd nba-data-backend && source .venv/bin/activate && python3 -m src.api.update_db.update_db_player_game_stats`  
   or from workspace: `python execution/nba_data/update_player_game_stats_to_db.py`.

## Data sources and scripts

| Table | Data source | Script / notes |
|-------|--------------|----------------|
| teams | `nba-data-backend/data/teams_db_data.json` | `src/api/update_db/update_db_teams.py` |
| players | `nba-data-backend/data/player_urls.json` | `src/api/update_db/update_db_players.py` (done) |
| games | **player_gamelog_2026.json** (after rescrape) | **Done**: `src/api/update_db/update_db_games.py`; execution: `python execution/nba_data/update_games_to_db.py`. Unique (DATE, HOME_TEAM, AWAY_TEAM) → team_id lookup → INSERT ON CONFLICT. |
| player_game_stats | **player_gamelog_2026.json** (same file) | **Done**: `src/api/update_db/update_db_player_game_stats.py`; execution: `python execution/nba_data/update_player_game_stats_to_db.py`. Run after rescrape and update_db_games. |
| prop_markets | Fixed list in script | **Done**: `src/api/update_db/update_db_prop_markets.py`; execution: `python execution/nba_data/update_prop_markets_to_db.py`. Seed once; idempotent. |
| player_props | Props API/CSV + players + games + prop_markets | For ML later; separate task. Current flow: backend `update_db_props.py` sends CSV to Next.js API update-props (not Neon direct). |

## Recommended next steps (for plan with user)
1. **Run the runbook above**: Rescrape → update games → update player_game_stats (in that order).
2. **prop_markets**: Seed once with `python execution/nba_data/update_prop_markets_to_db.py` or `cd nba-data-backend && python3 -m src.api.update_db.update_db_prop_markets`. See **update_prop_markets_to_db.md**.
3. **player_props**: For ML later; separate task (Neon schema ready; current props flow goes to Next.js API).

## Full pipeline runbook (one-time or refresh)

**Env**: Set `POSTGRES_URL` in `nba-data-backend/.env.local`. See **ENV_SETUP.md** at workspace root.

**Order** (from workspace root unless noted):

1. **Teams** (once; requires `nba-data-backend/data/teams_db_data.json`):  
   `cd nba-data-backend && source .venv/bin/activate && python3 -m src.api.update_db.update_db_teams`  
   (Fails with duplicate key if teams already populated; safe to ignore.)

2. **Player pipeline**:  
   - `python execution/nba_data/scrape_player_names.py` → writes `nba-data-backend/data/player_names.csv`.  
   - (Optional) `python execution/nba_data/scrape_player_urls.py` → writes `player_urls.json`; skip if you already have a good `player_urls.json`.)  
   - `python execution/nba_data/update_players_to_db.py` → fills **players** table.

3. **Gamelogs → games → player_game_stats** (run in order):  
   - Rescrape: `cd nba-data-backend && source .venv/bin/activate && python3 -m src.data_collection.scrapers.gamelogs`  
   - `python execution/nba_data/update_games_to_db.py`  
   - `python execution/nba_data/update_player_game_stats_to_db.py`

4. **prop_markets** (once):  
   `python execution/nba_data/update_prop_markets_to_db.py`

Execution scripts run the backend as Python modules (`-m`); they use `cwd=nba-data-backend` and `PYTHONPATH=nba-data-backend` so `.env.local` and `data/` paths resolve correctly.

## Edge cases
- **teams**: Must exist before games (FK). team_code in script must match whatever source provides for games (e.g. "LAL", "BOS").
- **games**: unique_game (game_date, home_team_id, away_team_id) – upsert to avoid duplicates.
- **player_game_stats**: unq_player_game (player_id, game_id) – one row per player per game; need game_id from games and player_id from players (match by name or abbreviation).
- **player_props**: Requires game_id and market_id; current Next.js route may use different shape – check `nba-prop-website` API and schema.
