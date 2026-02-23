# Update player_game_stats Table (DB)

## Goal
Populate the **player_game_stats** table from `player_gamelog_2026.json` (one row per player-game with stats). Run **after** a fresh gamelog rescrape and **after** **update_db_games**.

## Inputs
- **player_gamelog_2026.json**: Rescraped file with PLAYER_TEAM, HOME_TEAM, AWAY_TEAM (or LOCATION, OPPONENT, PLAYER_TEAM for derivation).
- **players**, **games**, **teams** tables must already be populated.

## Tools / Scripts
1. **Execution**: `python execution/nba_data/update_player_game_stats_to_db.py` (from workspace root).
2. **Backend**: `nba-data-backend/src/api/update_db/update_db_player_game_stats.py`.

## Outputs
- **player_game_stats** rows upserted (ON CONFLICT player_id, game_id). Stats mapped from JSON (FG, FGA, PTS, etc.). personal_fouls set to 0 if not in JSON.

## Order
Run only after: (1) Rescrape gamelogs, (2) update_db_games. See **populate_relational_schema.md** runbook.

## DNP (did not play)
- **Insert**: The update script **inserts** all gamelog rows, including DNP. `minutes_played` is stored as the raw value from the log (e.g. `"32:15"`, `"Inact"`, `"0:00"`), truncated to 5 chars. The frontend excludes DNP from averages (filter on `minutes_played` in `''`, `inactive`, `inact`, `did n`, `0`, `0:00`) and uses the most recent row to show "Last game: DNP" when applicable.
- **Legacy cleanup**: If you previously ran a version that skipped DNP and want to backfill, rescrape gamelogs and re-run this script; it will upsert DNP rows. The old `scripts/cleanup_dnp_player_game_stats.py` was for removing DNP rows when the script skipped them; it is no longer needed for the current pipeline.
