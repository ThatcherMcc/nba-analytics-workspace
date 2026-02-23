# Seed prop_markets Table (DB)

## Goal
Populate the **prop_markets** lookup table so `player_props` (and future ML pipelines) can reference markets by `market_id`. No external API; just a fixed list of (market_code, market_name).

## Plan to fill prop_markets

| Step | Action | Notes |
|------|--------|--------|
| 1 | **Prerequisites** | Neon DB reachable. `POSTGRES_URL` set in `nba-data-backend/.env.local` (or workspace root `.env.local` per script). Table `prop_markets` must exist (see `directives/infrastructure/neon_schema.md`). |
| 2 | **Run the seed script** | From workspace root: `python execution/nba_data/update_prop_markets_to_db.py` — or from backend: `cd nba-data-backend && source .venv/bin/activate && python3 -m src.api.update_db.update_db_prop_markets`. |
| 3 | **Verify** | Script prints e.g. `prop_markets: 13 rows upserted.` Optional: query `SELECT market_id, market_code, market_name FROM prop_markets ORDER BY market_code;` to confirm 13 rows (PTS, REB, AST, STL, BLK, TOV, FG3, FTM, PR, PA, RA, PRA, SB). |

No API calls or CSV inputs; the list is defined in `update_db_prop_markets.py` (`DEFAULT_MARKETS`). Run is idempotent (safe to re-run).

## Schema (Neon)
- **prop_markets**: market_id (serial PK), market_code VARCHAR(20) UNIQUE NOT NULL, market_name VARCHAR(50) NOT NULL, created_at.
- **player_props** (for later): references prop_markets(market_id), players(player_id), games(game_id). Used for ML later; separate task from seeding prop_markets.

## Tools / Scripts
1. **Execution**: `python execution/nba_data/update_prop_markets_to_db.py` (from workspace root).
2. **Backend**: `nba-data-backend/src/api/update_db/update_db_prop_markets.py`.

## Default markets (aligned with NBA full-game over/under player props API)
PTS, REB, AST, STL, BLK, TOV, FG3, FTM, PR, PA, RA, PRA, SB. See `DEFAULT_MARKETS` in `update_db_prop_markets.py`. API returns **statID** (e.g. `points`, `threePointersMade`, `points+rebounds+assists`); map to these codes via `src/api/update_db/prop_market_mapping.py` (API_STAT_ID_TO_MARKET_CODE). See **prop_markets_api.md** for API shape.

## Success Criteria
- Script runs without errors; prop_markets has one row per market_code. Idempotent (re-run is safe).
