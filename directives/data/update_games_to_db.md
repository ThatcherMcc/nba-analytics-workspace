# Update Games Table (DB)

## Goal
Populate the **games** table from `player_gamelog_2026.json` by deriving unique (game_date, home_team, away_team) from each player’s gamelogs.

## Inputs
- **player_gamelog_2026.json**: Must exist (path from `Utils.get_player_gamelog_data_path()`). Should be from a **rescrape** so rows include **HOME_TEAM** / **AWAY_TEAM** (or **LOCATION**, **OPPONENT**, **PLAYER_TEAM** so the script can infer). See **scrape_player_gamelogs.md** and **populate_relational_schema.md**.
- **teams** table must already be populated (script resolves team_code → team_id).

## Tools / Scripts
1. **Execution**: `python execution/nba_data/update_games_to_db.py` (from workspace root).
2. **Backend**: `nba-data-backend/src/api/update_db/update_db_games.py`. Run from backend with `.venv` activated: `python3 -m src.api.update_db.update_db_games` or `python3 src/api/update_db/update_db_games.py` with `PYTHONPATH=src`.

## Outputs
- **games** table: one row per unique (game_date, home_team_id, away_team_id). Season set to `2025-2026`. ON CONFLICT updates season only (idempotent).

## Edge Cases
- Missing HOME_TEAM/AWAY_TEAM: script derives from LOCATION + OPPONENT + PLAYER_TEAM when present.
- Unknown team_code: row skipped; script reports count of skipped games.
- home_team_id = away_team_id: skipped (constraint check_different_teams).

## Success Criteria
- Script runs without connection errors.
- Games table row count increases (or unchanged if already populated). No duplicate key errors.
