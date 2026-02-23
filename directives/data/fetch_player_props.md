# Fetch Player Props (SportsGameOdds API)

## Goal
Fetch current player prop lines from the SportsGameOdds API, save raw JSON locally, parse all 13 markets, and upsert into the `player_props` table in Neon.

## API Details
- **Endpoint**: `https://api.sportsgameodds.com/v2/events`
- **Auth**: `X-Api-Key` header with `ODDS_API_KEY` from `.env.local`
- **Tier**: Amateur (free) — 2,500 objects/month, 10 requests/minute
- **1 event = 1 object** (regardless of odds count inside)
- **Usage check**: `GET /v2/account/usage` (costs 0 objects)
- **Pagination**: `limit=20` + `cursor` from `nextCursor` in response

## Scripts

| Step | Script | Module |
|------|--------|--------|
| Check quota | `execution/nba_data/fetch_props.py --usage` | `src.data_collection.scrapers.props` |
| Fetch upcoming | `execution/nba_data/fetch_props.py --upcoming` | Same |
| Fetch season | `execution/nba_data/fetch_props.py --season --max-objects 500` | Same |
| Parse + insert | `execution/nba_data/update_player_props_to_db.py --json-dir=.../2025-26` | `src.api.update_db.update_db_player_props` |
| Dry run | `execution/nba_data/update_player_props_to_db.py --dry-run` | Same |

## Data Flow
1. **Fetch**: API → raw JSON files in `data/raw_json/2025-26/`
2. **Parse**: `EventJsonParser.parse_all_props()` → DataFrame (both over+under sides, all 13 markets)
3. **Insert**: `update_db_player_props.py` filters to OVER side, matches player/game/market, upserts into `player_props`

## File Naming
- Historical (2024-25): `data/raw_json/nba_events_{start}to{end}.json`
- Current (2025-26): `data/raw_json/2025-26/nba_props_p{page}_{start_date}_to_{end_date}.json`

## Team Code Mapping
API uses standard NBA codes; DB uses Basketball Reference codes. Three mismatches:
- `CHA` → `CHO` (Charlotte Hornets)
- `BKN` → `BRK` (Brooklyn Nets)
- `PHX` → `PHO` (Phoenix Suns)

Handled in `update_db_player_props.py` via `TEAM_CODE_MAP`.

## 13 Prop Markets
PTS, REB, AST, STL, BLK, TOV, FG3, FTM, PR, PA, RA, PRA, SB

API also returns extra stat types (fantasyScore, fieldGoalsMade, etc.) that we skip.

## Edge Cases
- **Game not in DB**: Props for future/recent games won't match until `games` table is updated via daily pipeline. Run gamelog scrape + update_games first.
- **Player name mismatch**: API player names generally match DB, but ~14% don't (different formatting). These are skipped.
- **UTC → ET date**: API returns UTC timestamps; games table uses ET dates. `utc_to_et_date()` handles conversion (ET_OFFSET = -5h).
- **Rate limits**: 10 req/min enforced. Fetcher waits 7s between requests.
- **Safety cap**: `--max-objects` flag prevents accidental over-use (default: 100).

## Budget Planning (2,500 objects/month)
- **Daily upcoming games**: ~15-30 objects/day → ~450-900/month
- **Full season backfill**: ~1,000-1,800 objects (do once, not every month)
- Always check `--usage` before fetching

## Success Criteria
- `--usage` shows remaining quota
- Raw JSON saved locally before any parsing
- All 13 markets parsed per event
- Props upserted into `player_props` with correct player/game/market matching
- Frontend shows prop lines on player detail page

## Results (2026-02-20)
- First run: 79 objects used, 4,656 props inserted (Feb 10-12 games)
- 248 players with prop data
- Frontend "Prop Lines" tab live on player pages
