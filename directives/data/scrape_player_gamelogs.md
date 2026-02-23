# Scrape Player Game Logs

## Goal
Scrape game log data for NBA players from Basketball Reference and write to the backend’s gamelog JSON file.

## Inputs
- **Primary**: **players** table (Neon). If `POSTGRES_URL` is set and the table has rows, the scraper loads `player_name` and `url` from the DB and iterates using those URLs (no name→URL resolution). This saves time on iteration.
- **Fallback**: **player_urls.json** with `successful_players` (each has `name`, `url`). Used when the DB is empty or unreachable. Create/refresh via **scrape_player_urls.md** or **update_players_to_db.md**.
- **use_proxies**: Optional; env `SCRAPE_PROXIES` or `PROXY_URLS`. Use when running many players to reduce rate-limit risk.

## Tools / Scripts
1. **MCP** (preferred): `mcp_nba-engine_scrape_player_gamelogs` (if it uses backend; may pass player list or use player_urls.json).
2. **Execution**: Run backend module from `nba-data-backend`: `python3 -m src.data_collection.scrapers.gamelogs`.
3. **Backend**: `nba-data-backend/src/data_collection/scrapers/gamelogs.py` loads player list from the **players** table (if `POSTGRES_URL` set and table populated), else **player_urls.json**; calls `acquisition.get_player_gamelog_from_url(url, name)` per player, then `processing.clean_gamelog`; writes to `data/player_gamelog_2026.json`.

## Outputs
- Gamelog data written to `nba-data-backend/data/player_gamelog_2026.json` (format defined by backend). Each player entry has `name` and `gamelogs` (array of rows). Each row includes **DATE**, **LOCATION** (Home/Away), **OPPONENT**, **PLAYER_TEAM** (player’s team code), **HOME_TEAM**, **AWAY_TEAM** (derived in `processing.py`), **MP** (minutes, string e.g. "32:15"—processing must not convert MP to numeric or it becomes 0), plus stat columns. This file is the source of truth for populating **games** and **player_game_stats**.
- MCP returns per-player status: success + game count, or error message.

## Waterfall retry (built-in)
- The scraper now retries failed players automatically (up to 3 rounds). After Pass 1, any failures are re-scraped across the same proxies. If a retry round makes no progress, it stops early.
- Remaining failures are written to **data/gamelog_retry_names.txt** for manual follow-up.

## Manual retry
- For manual retries: **scripts/retry_gamelog_failed.py** reads `data/gamelog_retry_names.txt` (one name per line) and merges results into **player_gamelog_2026.json**: `python3 scripts/retry_gamelog_failed.py`.

## Why some requests fail (403 Forbidden)
- **Basketball Reference** returns **403 Forbidden** when it treats the traffic as automated or too heavy:
  - **Rate / concurrency**: With multiple workers (one per proxy), each proxy waits 7s between its own GETs, but N proxies = N requests in parallel every ~7s. That can still trigger 403.
  - **No proxies**: With `SCRAPE_PROXIES` unset, the scraper uses one worker and waits 7s before every GET (single global rate limit). Fewer 403s, but the site may still block by IP or User-Agent.
  - **Bot detection**: Data-center IPs or non-browser clients can get blocked regardless of delay.
- **Mitigations**: (1) Use residential proxies in `SCRAPE_PROXIES` so each proxy gets its own 7s spacing. (2) Run with no proxies (single worker, 7s between requests) for a slower but gentler run. (3) Retry failed players later with **scripts/retry_gamelog_failed.py** (add names to `data/gamelog_retry_names.txt`).

## Terminal commands
From the **workspace root** (`nba-analytics-workspace`):

```bash
# Full pipeline: rescrape gamelogs → update games → update player_game_stats → revalidate frontend
# Requires: nba-data-backend/.env.local (POSTGRES_URL; optional SCRAPE_PROXIES); APP_URL and REVALIDATE_SECRET in env
. nba-data-backend/.env.local
export APP_URL=https://your-app.vercel.app   # or http://localhost:3000
export REVALIDATE_SECRET=your-secret
execution/nba_data/daily_gamelog_and_revalidate.sh
```

Rescrape only (no DB update, no revalidate):

```bash
cd nba-data-backend && . .venv/bin/activate && python3 -m src.data_collection.scrapers.gamelogs
```

Update DB from existing gamelog JSON (no rescrape):

```bash
cd nba-data-backend && . .venv/bin/activate && python3 -m src.api.update_db.update_db_games
cd nba-data-backend && . .venv/bin/activate && python3 -m src.api.update_db.update_db_player_game_stats
```

Retry only failed players (after adding names to `data/gamelog_retry_names.txt`):

```bash
cd nba-data-backend && . .venv/bin/activate && python3 scripts/retry_gamelog_failed.py
```

## Edge Cases (update as you learn)
- **Player with no games** (e.g. Georges Niang, out all season): scraper returns rows but `clean_gamelog` produces 0 games. All stat columns are missing/NaN. This is not a bug — the player simply has no data. They'll appear in `gamelog_retry_names.txt` but will never succeed.
- **NaN in location column**: Fixed in `processing.py:20`. The `looks_like_location()` check now casts values to `str()` before the `"@" in v` membership test to avoid `TypeError` on float NaN.
- **Proxy geo-blocking**: Basketball Reference blocks non-US data-center IPs. UK and Japan proxies return 403 Forbidden. US proxies work best; Spain (Madrid) also works. Always test proxies with a single-URL check before a full scrape.
- **Rate limits / 403**: Each proxy waits 7s between its own GETs. With 6 proxies that's 6 parallel requests every ~7s — Basketball Reference may still flag some. The waterfall retry catches most of these.
- **Timeouts**: `acquisition.py` retries up to `max_network_retries` with exponential backoff (0.4s × 2^attempt, capped at 2.5s). Default timeout is set in `get_player_gamelog_from_url`.

## Success Criteria
- Each requested player either has gamelog data in the JSON or a clear error in the MCP response.
- File path matches backend `Utils.get_player_gamelog_data_path()`.
