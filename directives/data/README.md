# Data Directives (nba-data-backend)

Procedures for scraping, processing, and loading NBA data. All paths and scripts refer to `nba-data-backend/` unless noted.

- **scrape_player_names.md** – Refresh the list of active players (Basketball Reference → CSV).
- **scrape_player_gamelogs.md** – Scrape game logs for specific players (Basketball Reference → JSON).
- **scrape_player_urls.md** – Build player URL list ("name", "player_abbreviation", url) from player names (used before DB player load).
- **update_players_to_db.md** – Load players from `player_urls.json` into Postgres.
- **update_games_to_db.md** – Load **games** table from `player_gamelog_2026.json` (unique date + home/away team).
- **update_player_game_stats_to_db.md** – Load **player_game_stats** from same JSON (run after rescrape and update_games).
- **update_gamelogs_to_db.md** – Load scraped gamelog JSON into Postgres (e.g. flat player_data_2026 or Next.js API).
- **update_prop_markets_to_db.md** – Seed **prop_markets** table (market_code, market_name). Run once.
- **prop_markets_api.md** – NBA full-game over/under player props API: statID, oddID, mapping to prop_markets; parse one event for all markets.
- **update_props_to_db.md** – Load prop lines (CSV) into Postgres (currently via Next.js API; player_props in Neon is for ML later).
- **fetch_player_props.md** – Get prop odds (Odds API) and optional parsing.
- **populate_relational_schema.md** – Order and plan for filling all Neon tables (teams, players, games, player_game_stats, prop_markets, player_props); read before adding update_db scripts.
- **mlb_pipeline.md** – Full MLB prop betting pipeline SOP: DB tables, data sources, build phases (Foundation → CI/CD), bettable markets, MLB-specific modeling notes (platoon splits, park factors, pitcher rest).

Read the directive for your task, then use the listed MCP tools or execution scripts.

**DB schema**: When populating or updating tables, read `directives/infrastructure/neon_schema.md` for current Neon table definitions. Refresh it with `nba-data-backend/scripts/export_neon_schema.py` when the schema changes.
