# Frontend data readiness (players, prop_markets, DNP)

## What the frontend can rely on

The frontend (nba-prop-website) and backend share **Neon Postgres**. The following are the source of truth and how they are populated.

### 1. Players table = canonical player list

- **Source of truth**: Neon `players` table, populated by the backend pipeline: scrape_player_names → scrape_player_urls → **update_players_to_db** (see `directives/data/update_players_to_db.md` and `directives/data/populate_relational_schema.md`).
- **How the frontend gets names**: Direct DB query only (no backend API). Use **`getPlayerNames()`** in `src/lib/data.ts`, which `SELECT player_name FROM players ORDER BY player_name`. The home page caches this and passes `playerNames` into `PlayerSearch` for search suggestions and datalist. The player page uses **`getPlayerExists(playerName)`** for 404 when the name is not in `players`.
- **Keeping it updated**: Run the player pipeline (scrape names → scrape URLs → update_players_to_db) when new players need to appear; then revalidate the frontend cache (POST /api/revalidate) so the homepage gets fresh names.

### 2. Prop markets

- **Source of truth**: Neon `prop_markets` table. Seeded once with **`python execution/nba_data/update_prop_markets_to_db.py`** (or `python3 -m src.api.update_db.update_db_prop_markets` from backend). See `directives/data/update_prop_markets_to_db.md`.
- **Frontend**: Table is available for future prop features (e.g. odds by market). No frontend change required for “readiness”; seeding is a one-time (or idempotent) step.

### 3. DNP in gamelogs (minutes_played)

- **Source of truth**: `player_game_stats.minutes_played` (varchar). Populated by the gamelog scrape and **update_player_game_stats_to_db** (see `directives/data/update_player_game_stats_to_db.md`).
- **Behavior**: The backend **inserts all gamelog rows**, including DNP. `minutes_played` is stored as the raw value from Basketball Reference (e.g. `"32:15"`, `"Inact"`, `"0:00"`), truncated to 5 chars.
- **Frontend**:
  - **Averages / “last N games”**: Exclude DNP by filtering where `minutes_played` (trimmed, lowercased) is **not** in `''`, `'inactive'`, `'inact'`, `'did n'`, `'0'`, `'0:00'` (see `PLAYED_ONLY` and `DNP_MINUTES_VALUES` in `src/lib/data.ts` and “Played-only / DNP exclusion” in `.cursor/rules/nba-prop-website.mdc`).
  - **“Last game: DNP” badge**: `getPlayerLastGameStatus(playerName)` returns the most recent game row (by date) and `isDnp: true` when that row’s `minutes_played` is one of the DNP values above. The player page shows “Last game: DNP (excluded from averages)” when `lastGameStatus?.isDnp` is true.

## Summary

| Data           | Source of truth   | How frontend gets it                         | Pipeline step(s)                          |
|----------------|-------------------|---------------------------------------------|-------------------------------------------|
| Player names   | `players` table   | `getPlayerNames()`, `getPlayerExists(name)` | update_players_to_db                      |
| Prop markets   | `prop_markets`    | Drizzle when needed                         | update_prop_markets_to_db (seed once)     |
| DNP / minutes  | `player_game_stats.minutes_played` | Queries filter DNP; `getPlayerLastGameStatus` for badge | Rescrape gamelogs → update_player_game_stats_to_db |

## Backend rule note

The backend (`.cursor/rules/nba-data-backend.mdc`) and this directive describe what the frontend can rely on: players and player_game_stats (including DNP) come from the pipeline; prop_markets from the seed script. No separate “player list API” is required—the frontend reads `players` via Drizzle.
