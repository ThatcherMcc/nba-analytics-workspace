# Agent prompts — multi-stat, hot/cold, dynamic players, DNP, pipeline

Use these prompts when handing off to **two agents** (one backend, one frontend). Each prompt is self-contained so an agent can start fresh.

---

## Backend agent

### Prompt 1 — Backend data pipeline (DOE)

**Context:** This workspace has an NBA data backend (`nba-data-backend/`) and directives in `directives/data/` that describe how to scrape and load data into Neon Postgres. Execution wrappers live in `execution/nba_data/`. The frontend (`nba-prop-website`) reads from the same Neon DB via Drizzle.

**Your task:** Run the full data pipeline once end-to-end and confirm the relational schema is populated so the frontend has reliable data. Follow the runbook in `directives/data/populate_relational_schema.md` and the individual directives in `directives/data/`.

1. **Player pipeline:** Scrape player names (→ `player_names.csv`), then scrape player URLs (→ `player_urls.json`), then run update_players_to_db so the `players` table is populated. Use the execution scripts in `execution/nba_data/` or the backend modules under `nba-data-backend/` as specified in the directives. Fix any MCP paths or script paths if the directives reference wrong locations.
2. **Games + player_game_stats:** Rescrape player gamelogs so `player_gamelog_2026.json` (or the current gamelog file) has PLAYER_TEAM, HOME_TEAM, AWAY_TEAM. Then run update_games_to_db, then update_player_game_stats_to_db, in that order. Confirm `games` and `player_game_stats` tables are populated.
3. **Optional:** Seed `prop_markets` once with `update_prop_markets_to_db` if not already done (see `directives/data/update_prop_markets_to_db.md`).
4. **Alignment:** Verify that each directive in `directives/data/` matches the actual behavior of the scripts (in `nba-data-backend/` and `execution/nba_data/`). Update directive text or script paths if something is out of sync.

**Deliverables:** Pipeline runs successfully; `players`, `games`, and `player_game_stats` are populated; directives and execution scripts are aligned. Document any manual steps or env vars required in a short runbook or in the directive README.

---

### Prompt 2 — Data readiness for frontend (players list, prop_markets, DNP)

**Context:** The frontend needs (1) a dynamic list of player names (currently it uses a static array); (2) prop_markets seeded for future prop features; (3) gamelog data that includes minutes_played so the frontend can show “Last game: DNP” when a player didn’t play. The backend and frontend share Neon Postgres; the frontend uses Drizzle in `nba-prop-website/src/db/`.

**Your task:** Ensure the backend and DB are ready for the frontend’s dynamic player list, prop markets, and DNP display.

1. **Players as source of truth:** Confirm the `players` table is (or will be) the canonical list of player names. Ensure the update_players pipeline (scrape names → scrape URLs → update_players_to_db) is runnable and documented so the list stays current. If the frontend will query the DB directly for names, no backend API is required; if you prefer a thin API, add a simple GET endpoint that returns the list of player names from `players` (e.g. JSON array). Document the chosen approach in `directives/features/` or in the frontend rule so the frontend agent knows how to fetch names.
2. **Prop markets:** Ensure `prop_markets` is seeded (run `update_prop_markets_to_db` per `directives/data/update_prop_markets_to_db.md`). No frontend change required in this task; this is so prop-related features can use market codes later.
3. **DNP in gamelogs:** The frontend excludes DNP games from averages using `minutes_played` (e.g. `''`, `'inactive'`, `'inact'`, `'did n'`, `'0'`, `'0:00'`). Confirm that `player_game_stats.minutes_played` is populated correctly by your gamelog scrape and update_player_game_stats pipeline so the frontend can detect “most recent game was DNP” and show an “Inactive” / “Last game: DNP” badge. No backend code change is required if data is already correct; otherwise fix the scraper or update_db so DNP is stored consistently.

**Deliverables:** Players table is the source of truth and the way to fetch names is documented (or a small API added). Prop_markets seeded. Gamelog data has correct minutes_played for DNP detection. Brief note in `directives/features/` or in the backend rule describing what the frontend can rely on.

---

## Frontend agent

### Prompt 1 — Multi-stat view and DNP availability

**Context:** The NBA prop website (`nba-prop-website`) is Next.js 14 (App Router), TypeScript, Drizzle + Neon, Tailwind. The player page (`src/app/player/[name]/page.tsx`) uses `PlayerPageContent` and currently shows one stat at a time with a single chart. Averages and charts exclude DNP games (see “Played-only / DNP exclusion” in `.cursor/rules/nba-prop-website.mdc`). Stats and types come from `src/db/schema.ts` (`PLAYER_STAT_NAMES`, `PLAYER_STAT_TYPE`, `PlayerGameLog`).

**Your task:** Add a multi-stat view on the player page and clear DNP/availability messaging.

1. **Multi-stat view:** On the player page, allow the user to view multiple stats (e.g. PTS, REB, AST) for the same “last N games” data. Options: (a) tabs or a dropdown to switch the single chart between stats, or (b) small multiples (e.g. 2–3 small charts side by side). Reuse existing `getPlayerData(playerName, gameCount)`, `PlayerChartDisplay`, and `PLAYER_STAT_NAMES` / `PLAYER_STAT_TYPE`. Keep the current prop line and hit-rate behavior per stat where it makes sense (e.g. one line per stat or one global line).
2. **DNP / availability:** When the player’s most recent game (by date) in the DB was a DNP (i.e. `minutes_played` is one of the excluded values: `''`, `inactive`, `inact`, `did n`, `0`, `0:00`), show a clear badge or line such as “Last game: DNP” or “Inactive” so users know that game is excluded from averages. You may need to fetch or derive “last game status” from the same source as the chart data (e.g. one extra query or the same query with one row that includes DNP games for “most recent game” only). Prefer reusing the DNP filter constant used in `src/lib/data.ts` (e.g. the same NOT IN list) so behavior stays consistent.

**Deliverables:** Player page supports multi-stat view (tabs or small multiples). When the last game was a DNP, an “Inactive” / “Last game: DNP” indicator is visible. No breaking changes to existing single-stat flow; follow existing patterns in `PlayerPageContent` and `PlayerChartDisplay`.

---

### Prompt 2 — Expand hot/cold and dynamic player list

**Context:** The NBA prop website home page shows “Over season avg (last 5)” via `getPlayersOverSeasonAvgLast5` and has components like `HottestHands` and `HotThisWeek`. Player names for search and validation come from a static array `ALL_PLAYER_NAMES` in `src/lib/playerNames.ts`. The DB has a `players` table (Drizzle schema in `src/db/schema.ts`); the backend agent is making the players table the source of truth and documenting (or adding) how to fetch names.

**Your task:** Add “cold” and optional “trending” signals on the home page, and replace the static player list with a dynamic one from the DB.

1. **Expand hot/cold (and optional trending):** Add a “Cold last 5” section: players whose last-5-game average (points) is **below** their season average (same played-only filter as `getPlayersOverSeasonAvgLast5`). Add a new data function in `src/lib/data.ts` (e.g. `getPlayersUnderSeasonAvgLast5`) and a small home-page block (similar to `OverSeasonAvgLast5`). Optionally add “Trending” (e.g. last 3 games avg vs previous 3 games avg) as another block; if so, use the same played-only filter and expose it in a new function + component.
2. **Dynamic player list:** Replace (or back) the static `ALL_PLAYER_NAMES` in `src/lib/playerNames.ts` with player names loaded from the database. Query the `players` table via Drizzle (e.g. `select({ playerName: players.playerName }).from(players)`), use the result for search suggestions and for validation (e.g. `ALL_PLAYER_NAMES.includes(playerName)` or a similar check). Cache appropriately (e.g. `unstable_cache` with a tag like `player-data` or `player-names` and revalidate when the pipeline runs so new players appear without redeploy). Keep the same export shape so existing callers (e.g. `PlayerSearch`, player page validation) keep working; if you need both a sync list and async, document the fallback (e.g. static list as fallback if DB fails).

**Deliverables:** “Cold last 5” (and optionally “Trending”) on the home page. Player list is sourced from the DB with caching; search and validation use the dynamic list. Brief note in code or in the frontend rule on cache tag so revalidation after pipeline runs updates the list.

---

## Handoff order

- **Backend first:** Run Prompt 1 (pipeline), then Prompt 2 (data readiness). That way the frontend has a populated `players` table and correct gamelog data.
- **Frontend:** Can start Prompt 1 (multi-stat + DNP) in parallel with backend; start Prompt 2 (hot/cold + dynamic list) after backend Prompt 2 is done (or when the way to fetch player names is documented/implemented).
