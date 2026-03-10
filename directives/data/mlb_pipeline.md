# MLB Prop Betting Pipeline

## Overview

Build an MLB prop betting pipeline mirroring the NBA architecture: scrape gamelogs and splits from Baseball Reference, pull confirmed starters from the MLB Stats API, run separate batter and pitcher prediction models, and surface prop edges on the frontend. The Neon Postgres DB, Python backend, and Next.js frontend are all shared with the NBA stack — add MLB tables alongside existing NBA tables.

---

## Bettable Markets (Prioritized)

Focus only on markets with consistent liquidity and genuine signal.

| Rank | Market | Notes |
|------|--------|-------|
| 1 | Pitcher Strikeouts (K) | Best market — high variance, platoon splits matter hugely |
| 2 | Total Bases (TB) | Batter power vs. pitcher + park + platoon |
| 3 | Hits | Simpler than TB; BA vs. handedness is the core signal |
| 4 | Outs Recorded (pitcher) | Closely tied to K model; stamina + opponent K% |
| 5 | Home Runs | Low base rate but park factor + ISO + pitcher HR/9 |

**Skip entirely**: RBI (too lineup/context dependent), walks (books price these extremely tight), hits allowed (correlates with outs recorded but adds noise without independent signal).

---

## DB Tables Needed

Add to the shared Neon Postgres instance. All tables prefixed `mlb_`.

### `mlb_teams`
Seed table. One row per MLB franchise.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| team_code | varchar(3) UNIQUE | e.g. `NYY`, `BOS`, `LAD` |
| team_name | varchar(100) | |
| league | varchar(2) | `AL` or `NL` |
| division | varchar(5) | e.g. `ALE`, `NLW` |

### `mlb_players`
One row per player, updated at season start and on roster moves.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| player_name | varchar(100) | Full name, Baseball Reference canonical |
| bbref_slug | varchar(50) UNIQUE | e.g. `judgeaa01` |
| team_id | int FK → mlb_teams | Current team; update on trade |
| position | varchar(5) | `SP`, `RP`, `C`, `1B`, `OF`, etc. |
| bats | varchar(1) | `L`, `R`, `S` (switch) |
| throws | varchar(1) | `L`, `R` |
| active | boolean | False if DL/retired |

### `mlb_games`
One row per game, derived from gamelog scrapes.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| game_date | date | |
| home_team_id | int FK → mlb_teams | |
| away_team_id | int FK → mlb_teams | |
| season | varchar(9) | e.g. `2025-2026` |
| park_name | varchar(100) | Nullable; for park factor lookup |
| UNIQUE | (game_date, home_team_id, away_team_id) | |

### `mlb_batter_game_stats`
One row per batter per game. Source: Baseball Reference standard batting gamelogs.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| player_id | int FK → mlb_players | |
| game_id | int FK → mlb_games | |
| team_id | int FK → mlb_teams | Player's team that game |
| pa | int | Plate appearances |
| ab | int | At-bats |
| hits | int | H |
| doubles | int | 2B |
| triples | int | 3B |
| home_runs | int | HR |
| rbi | int | |
| walks | int | BB |
| strikeouts | int | SO |
| total_bases | int | TB (computed: 1×H + 1×2B + 2×3B + 3×HR) |
| batting_order | int | Nullable; 1-9, from MLB Stats API or lineup scrape |
| opp_pitcher_id | int FK → mlb_players | Nullable; starting pitcher faced |
| UNIQUE | (player_id, game_id) | |

### `mlb_pitcher_game_stats`
One row per pitcher per game (starters only; closers optional later).

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| player_id | int FK → mlb_players | |
| game_id | int FK → mlb_games | |
| team_id | int FK → mlb_teams | |
| outs_recorded | int | IP × 3; e.g. 6.0 IP = 18 |
| hits_allowed | int | H |
| runs_allowed | int | R |
| earned_runs | int | ER |
| walks | int | BB |
| strikeouts | int | K |
| home_runs_allowed | int | HR |
| pitches | int | Nullable; total pitches thrown |
| strikes | int | Nullable |
| game_score | int | Nullable; computed quality start proxy |
| is_starter | boolean | True = SP; False = reliever |
| UNIQUE | (player_id, game_id) | One row per pitcher appearance |

### `mlb_team_stats`
Rolling team-level offensive and pitching stats, updated daily. Used as opponent context features.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| team_id | int FK → mlb_teams | |
| season | varchar(9) | |
| stat_date | date | Snapshot date (update daily) |
| team_k_pct | numeric(5,3) | Strikeout rate vs. pitchers (for K model) |
| team_bb_pct | numeric(5,3) | Walk rate |
| team_avg | numeric(5,3) | Team batting average |
| team_obp | numeric(5,3) | |
| team_slg | numeric(5,3) | |
| team_iso | numeric(5,3) | Isolated power (SLG - AVG) |
| team_wrc_plus | int | Nullable; wRC+ if available |
| team_era | numeric(5,2) | Team ERA (for batter context) |
| UNIQUE | (team_id, season, stat_date) | |

### `mlb_park_factors`
Static per-season park factor multipliers. Seed at season start, refresh mid-season if needed.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| team_id | int FK → mlb_teams | Home team = the park |
| season | varchar(9) | |
| pf_runs | numeric(5,3) | Run park factor (1.0 = neutral) |
| pf_hr | numeric(5,3) | HR park factor |
| pf_hits | numeric(5,3) | Hits park factor |
| pf_k | numeric(5,3) | Strikeout park factor (foul territory etc.) |
| source | varchar(50) | e.g. `fangraphs`, `bbref` |
| UNIQUE | (team_id, season) | |

### `mlb_pitcher_splits`
Seasonal pitcher performance split by batter handedness. Scraped from Baseball Reference splits pages. Refresh weekly.

| Column | Type | Notes |
|--------|------|-------|
| id | serial PK | |
| player_id | int FK → mlb_players | |
| season | varchar(9) | |
| split | varchar(5) | `vsL` or `vsR` |
| pa | int | |
| k_pct | numeric(5,3) | K/PA against this handedness |
| bb_pct | numeric(5,3) | BB/PA |
| avg_against | numeric(5,3) | |
| slg_against | numeric(5,3) | |
| hr_per_9 | numeric(5,2) | |
| UNIQUE | (player_id, season, split) | |

---

## Data Sources

### Baseball Reference (scraping)
- **Batter gamelogs**: `https://www.baseball-reference.com/players/[initial]/[slug]/batting_gamelogs/[year]`
- **Pitcher gamelogs**: `https://www.baseball-reference.com/players/[initial]/[slug]/pitching_gamelogs/[year]`
- **Pitcher splits**: `https://www.baseball-reference.com/players/[initial]/[slug]#plato_pitching` (splits table)
- **Player index**: `https://www.baseball-reference.com/players/[initial]/` (for slug discovery)
- **Rate limit**: Same as NBA — 7s between requests per IP/proxy. Use `SCRAPE_PROXIES` for parallel runs. Expect 403s on data-center IPs; US residential proxies preferred.
- **Scraper location**: `nba-data-backend/src/data_collection/scrapers/mlb_gamelogs.py` (to be created)

### MLB Stats API (free, no auth)
- **Confirmed starters**: `https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=YYYY-MM-DD&hydrate=probablePitcher`
- **Roster data**: `https://statsapi.mlb.com/api/v1/teams/{teamId}/roster?season=YYYY`
- No API key required. Rate limit generous (unofficial: ~100 req/min). Use for daily starter confirmation only — do not backfill historical data from this API.
- **Scraper location**: `nba-data-backend/src/data_collection/scrapers/mlb_starters.py` (to be created)

### SportsGameOdds (props — save for later)
- Same API as NBA (`/v2/events`, `ODDS_API_KEY`). Budget: 2,500 objects/month shared with NBA. Do not integrate until models are validated. See `fetch_player_props.md` for API pattern.

---

## Build Phases

### Phase 1: Foundation (target: late March)

1. Create DB migration script: `nba-data-backend/scripts/migrate_mlb_schema.py` — adds all 7 `mlb_*` tables to Neon. Run once; idempotent (`CREATE TABLE IF NOT EXISTS`).
2. Seed `mlb_teams`: 30 teams, codes, league, division. Static JSON at `nba-data-backend/data/mlb_teams.json`.
3. Scrape active player index (batters + starters) from Baseball Reference → `mlb_players`. Script: `src/data_collection/scrapers/mlb_player_index.py`.
4. Verify FK relationships are intact before moving to Phase 2.

**Success criteria**: `mlb_teams` has 30 rows; `mlb_players` has ~200+ active players with `bbref_slug`.

### Phase 2: Data Collection (target: early April)

1. **Batter gamelog scraper**: `src/data_collection/scrapers/mlb_batter_gamelogs.py`. Mirror `gamelogs.py` pattern — read player list from `mlb_players` table, scrape BBRef batting gamelog page per player, clean, write to `data/mlb_batter_gamelog_2026.json`.
2. **Pitcher gamelog scraper**: `src/data_collection/scrapers/mlb_pitcher_gamelogs.py`. Same pattern for SPs only initially.
3. **Pitcher splits scraper**: `src/data_collection/scrapers/mlb_pitcher_splits.py`. Scrape splits table per pitcher; write to `data/mlb_pitcher_splits_2026.json`. Run weekly (splits page only updates once the pitcher has appeared).
4. **DB update scripts**:
   - `src/api/update_db/update_db_mlb_games.py`
   - `src/api/update_db/update_db_mlb_batter_stats.py`
   - `src/api/update_db/update_db_mlb_pitcher_stats.py`
   - `src/api/update_db/update_db_mlb_pitcher_splits.py`
5. **Park factors**: Scrape from Baseball Reference park factors page once per season → seed `mlb_park_factors`. Script: `scripts/seed_mlb_park_factors.py`.
6. **Execution wrappers** in `execution/nba_data/`: `update_mlb_gamelogs_to_db.py`, `update_mlb_pitcher_splits_to_db.py`.

**Success criteria**: 2025-2026 batter and pitcher gamelogs in DB; splits populated for all active SPs; park factors seeded.

### Phase 3: Feature Engineering (target: mid-April)

Feature module: `nba-data-backend/src/ml/mlb_features.py`. Two separate feature sets.

**Batter features**:
- Rolling avg/std/median for H, TB, HR over windows 5/10/20 games
- Hit rate at/above line (e.g. `hit_rate_last10_vs_line`)
- Platoon split: batter handedness vs. opponent starter `split` from `mlb_pitcher_splits`
- Park factor for the game venue (`pf_hits`, `pf_hr` from `mlb_park_factors`)
- Opponent team K% (`team_k_pct` from `mlb_team_stats`) — high K% = fewer balls in play = lower H/TB
- Batting order position (1-2 vs. 7-9 = different PA volume)
- Season phase (games 1-30 = unstable; games 60+ = reliable)
- Z-score vs. line (same pattern as NBA model)

**Pitcher features**:
- Rolling K/9, K/BB, K%, IP over windows 3/5/10 starts
- Platoon K% from `mlb_pitcher_splits` (vsL, vsR) × opponent lineup handedness composition
- Park factor for K (`pf_k`)
- Opponent team K% (how often this lineup strikes out)
- Pitcher rest days (short rest = lower K ceiling; extra rest = minimal benefit)
- Pitch count in recent starts (flag if last start was 100+ pitches; more likely to be pulled early)
- Season phase
- Z-score vs. K line

### Phase 4: Models (target: late April)

Two separate LightGBM models mirroring `nba-data-backend/src/ml/`:

| Model | File | Target |
|-------|------|--------|
| Batter props | `src/ml/mlb_batter_model.py` | Binary: over/under TB, H, HR per line |
| Pitcher props | `src/ml/mlb_pitcher_model.py` | Binary: over/under K, outs recorded per line |

- Training data: 2024-2025 season gamelogs (backfill in Phase 2). Use same train/eval split as NBA model.
- Minimum 10 games per player before generating predictions (same threshold as NBA).
- Save models to `src/ml/models/mlb_batter_model.txt` and `mlb_pitcher_model.txt`.
- Evaluation thresholds: target conf >= 0.20 before surfacing picks to frontend.

### Phase 5: Props Integration (target: early May)

1. Pull MLB props from SportsGameOdds when quota allows (check `--usage` first).
2. Add `mlb_prop_markets` seed table (K, TB, H, outs, HR market codes).
3. Add `mlb_player_props` table (same shape as NBA `player_props`).
4. Run predictions against today's props; write edge scores to DB.
5. Execution wrapper: `execution/nba_data/update_mlb_props_to_db.py`.

### Phase 6: Frontend (target: mid-May)

This phase requires frontend work in `nba-prop-website/`. Scope to agree with frontend owner:
- MLB slate page: `/mlb-slate`
- Pitcher card: today's starter + K line + edge score + platoon split badge
- Batter card: TB/H line + edge score + park factor badge
- Mirror the NBA `SlatePageContent.tsx` pattern — do not rebuild from scratch.

### Phase 7: CI/CD (target: late May)

Add MLB steps to `.github/workflows/daily-scrape.yml`:
1. Scrape MLB batter + pitcher gamelogs (daily, after games complete ~12am ET)
2. Update `mlb_batter_game_stats` + `mlb_pitcher_game_stats`
3. Fetch confirmed starters for today (MLB Stats API, no quota cost)
4. Generate MLB predictions
5. Post MLB picks to Discord (reuse `post_discord.py`)
6. Refresh pitcher splits (weekly, Monday only)

---

## Key MLB-Specific Modeling Notes

- **Platoon splits are non-negotiable**: A lefty pitcher vs. a right-handed-heavy lineup is the strongest single feature in both batter and pitcher models. Never skip this.
- **Park factors change the ceiling**: Coors Field inflates TB/H by ~15%; pitchers there should be faded on K lines.
- **Pitcher rest**: 4-day rest is normal. 3-day rest tanks K upside. 6+ days has minimal effect (don't over-weight).
- **Batting order volatility**: Order position 1-5 delivers ~3-4 PA/game; 6-9 delivers ~2-3. Lines are often set assuming a spot but managers change daily. If batting order is unavailable, use season-average plate appearances instead.
- **Season phase caution**: First 2-3 weeks of the season (late March/early April) have high variance. Roll windows will be short; widen confidence intervals or require more games before generating picks.
- **Avoid RBI and walks**: RBI is heavily context-dependent (runners on base = lineup correlation, not individual skill). Walks are priced efficiently and books shade aggressively; skip unless a clear structural edge appears.

---

## Pipeline Order (dependency)

1. `mlb_teams` (seed once)
2. `mlb_players` (scrape index; update on roster moves)
3. `mlb_games` (derived from gamelog scrapes)
4. `mlb_batter_game_stats` (from batter gamelogs, after games)
5. `mlb_pitcher_game_stats` (from pitcher gamelogs, after games)
6. `mlb_pitcher_splits` (weekly scrape)
7. `mlb_park_factors` (seed once per season)
8. `mlb_team_stats` (computed from game stats; update daily)
9. `mlb_prop_markets` (seed once)
10. `mlb_player_props` (from SportsGameOdds; Phase 5)

---

## File Locations (when built)

| What | Where |
|------|-------|
| Batter gamelog scraper | `nba-data-backend/src/data_collection/scrapers/mlb_batter_gamelogs.py` |
| Pitcher gamelog scraper | `nba-data-backend/src/data_collection/scrapers/mlb_pitcher_gamelogs.py` |
| Pitcher splits scraper | `nba-data-backend/src/data_collection/scrapers/mlb_pitcher_splits.py` |
| Confirmed starters scraper | `nba-data-backend/src/data_collection/scrapers/mlb_starters.py` |
| Feature engineering | `nba-data-backend/src/ml/mlb_features.py` |
| Batter model | `nba-data-backend/src/ml/mlb_batter_model.py` |
| Pitcher model | `nba-data-backend/src/ml/mlb_pitcher_model.py` |
| Saved models | `nba-data-backend/src/ml/models/mlb_batter_model.txt`, `mlb_pitcher_model.txt` |
| DB migration script | `nba-data-backend/scripts/migrate_mlb_schema.py` |
| Park factors seed | `nba-data-backend/scripts/seed_mlb_park_factors.py` |
| Team seed data | `nba-data-backend/data/mlb_teams.json` |
| Batter gamelog data | `nba-data-backend/data/mlb_batter_gamelog_2026.json` |
| Pitcher gamelog data | `nba-data-backend/data/mlb_pitcher_gamelog_2026.json` |
| Pitcher splits data | `nba-data-backend/data/mlb_pitcher_splits_2026.json` |
| Execution wrappers | `execution/nba_data/update_mlb_*.py` |

---

## Edge Cases (update as you learn)

- **BBRef slug format**: Pitchers and batters use the same slug scheme (`[first5last][first2first][##].shtml`). Watch for name collisions (two players with same name) — BBRef disambiguates with `01`/`02` suffix.
- **Outs recorded vs. IP**: Baseball Reference stores IP as a float (e.g. `6.2` = 6 innings + 2 outs = 20 outs). Multiply by 3 carefully: `int(ip) * 3 + round((ip % 1) * 10)`. Do not cast directly.
- **Total bases computation**: BBRef gamelogs do not always provide TB directly. Compute as `H + 2B + (2 × 3B) + (3 × HR)`. Validate totals against box scores on first scrape.
- **Pitcher splits page load**: The splits table is rendered from a comment block on BBRef (hidden in HTML). Use the same comment-stripping pattern used in the NBA scraper if applicable.
- **MLB Stats API starter confirmation**: Probable pitchers from this API are often set 1-2 days out but can change up to first pitch. Pull starters as close to post time as possible (~1-2 hours before first pitch).
- **NaN handling**: Cast all scraped values to `str()` before string operations. Numeric columns: use `pd.to_numeric(..., errors='coerce')` then fill NaN with 0 for counting stats.

## Success Criteria (Phase 1 complete)

- `mlb_teams`: 30 rows
- `mlb_players`: 200+ active players with valid `bbref_slug`
- Migration script is idempotent (safe to re-run)
- No FK violations when inserting test rows into `mlb_batter_game_stats`

---

## Phase 1 Implementation Notes (completed 2026-03-09)

**Shared-table approach used**: Rather than creating separate `mlb_teams`, `mlb_players`, and `mlb_games` tables, MLB data is stored in the existing shared `teams`, `players`, and `games` tables. All new MLB-specific tables (`mlb_batter_game_stats`, `mlb_pitcher_game_stats`, `mlb_team_stats`, `mlb_park_factors`, `mlb_pitcher_splits`) reference these shared tables via FK.

**`sport` column added to `teams`**: `ALTER TABLE teams ADD COLUMN sport VARCHAR(10) DEFAULT 'NBA'`. All 30 existing NBA rows now have `sport='NBA'`. Query MLB teams with `WHERE sport = 'MLB'`.

**team_code widened**: `teams.team_code` was `VARCHAR(3)` — widened to `VARCHAR(6)` to accommodate the 10 MLB teams whose standard abbreviation collides with an existing NBA team code.

**Team code collision resolution**: 10 MLB teams share their standard abbreviation with an existing NBA team (ATL, BOS, CLE, DET, HOU, MIA, MIL, MIN, PHI, TOR). These are stored with a `M-` prefix in `team_code` (e.g. `M-ATL` = Atlanta Braves, `M-BOS` = Boston Red Sox). The `mlb_abbr` field in `data/mlb_teams_db_data.json` records the canonical MLB abbreviation for reference.

**Colliding codes (10 teams)**:

| team_code in DB | MLB team | MLB standard abbr |
|-----------------|----------|-------------------|
| M-ATL | Atlanta Braves | ATL |
| M-BOS | Boston Red Sox | BOS |
| M-CLE | Cleveland Guardians | CLE |
| M-DET | Detroit Tigers | DET |
| M-HOU | Houston Astros | HOU |
| M-MIA | Miami Marlins | MIA |
| M-MIL | Milwaukee Brewers | MIL |
| M-MIN | Minnesota Twins | MIN |
| M-PHI | Philadelphia Phillies | PHI |
| M-TOR | Toronto Blue Jays | TOR |

**Scripts created**:
- `scripts/create_mlb_schema.sql` — DDL for all 5 MLB stat tables + indexes
- `scripts/run_mlb_schema.py` — applies the SQL via psycopg2 (use instead of psql, which is not installed)
- `scripts/seed_mlb_teams.py` — seeds `data/mlb_teams_db_data.json` into the `teams` table; adds `sport` column if missing

**Data files**:
- `data/mlb_teams_db_data.json` — 30 MLB teams with `team_code`, `team_name`, `sport`, `mlb_abbr`
- `data/mlb_park_factors_2025.json` — 2025 park factors keyed by `team_code` (uses M-prefix for colliding teams)

**Note for future phases**: When looking up a team by MLB abbreviation, query `WHERE sport = 'MLB' AND (team_code = %s OR team_code = 'M-' || %s)` to handle both prefixed and non-prefixed codes.
