# Update Players Table (DB)

## Goal
Load players from `nba-data-backend/data/player_urls.json` into the Postgres `players` table.

## Inputs
- **player_urls.json**: Must exist and contain `successful_players` with at least `name`, `url`, `web_index` (or columns matching DB schema). Create via **scrape_player_urls.md** first.

## Tools / Scripts
1. **Execution**: `python execution/nba_data/update_players_to_db.py` (from workspace root; runs backend as module).
2. **Backend**: From `nba-data-backend/`: `python3 -m src.api.update_db.update_db_players`. Requires `POSTGRES_URL` in `nba-data-backend/.env.local` (or `.env`).

## Outputs
- `players` table updated (INSERTs). Script prints success or connection/query error.

## Edge Cases (update as you learn)
- Missing `POSTGRES_URL`: script exits with error; ensure backend `.env.local` is configured.
- Duplicate key / unique constraint: document whether backend uses upsert or insert-only; add conflict handling if needed.
- Empty `successful_players`: script may run but insert nothing; ensure **scrape_player_urls** has been run.

## Success Criteria
- Script runs without connection errors.
- Row count in `players` reflects new data (or intended idempotent behavior).
