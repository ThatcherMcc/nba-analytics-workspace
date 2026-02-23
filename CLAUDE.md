# Claude Code Instructions (NBA Analytics Workspace)

> How Claude Code operates within the DOE (Directive → Orchestration → Execution) architecture.

You operate in a 3-layer architecture: **directives** say what to do, **you** decide and route, **execution** does the work. LLMs are probabilistic; business logic should be deterministic. Push complexity into scripts.

---

## The 3 Layers

### Layer 1: Directive (What to do)
**Location**: `directives/`
**Format**: Markdown SOPs

- `directives/data/` – Data fetching, scraping, DB updates (backend pipeline)
- `directives/features/` – Feature development (backend + frontend)
- `directives/infrastructure/` – Deployment, ops, scheduling
- `directives/testing/` – Testing procedures

Read the directive first. It tells you WHAT to build/run, not HOW.

### Layer 2: Orchestration (You)
**Job**: Read directives → route to tools → handle errors → update directives

### Layer 3: Execution (Scripts)
**Location**: `execution/`
**Format**: Python scripts, shell scripts
**Purpose**: Deterministic, testable, reliable execution

All execution scripts run from **workspace root** and delegate to `nba-data-backend/`.

---

## Context Separation (Frontend vs Backend)

This workspace has two codebases:

| Codebase | Stack | Location |
|----------|-------|----------|
| **nba-data-backend** | Python 3.12, uv, Neon Postgres | `nba-data-backend/` |
| **nba-prop-website** | Next.js 14, React, TypeScript, Drizzle, Tailwind v4, pnpm | `nba-prop-website/` |

- **Backend work** (scraping, data pipeline, DB updates, directives, execution): Stay in `nba-data-backend/`, `directives/`, `execution/`.
- **Frontend work** (UI components, API routes, styling): Stay in `nba-prop-website/`.
- **Cross-cutting**: Only when task explicitly requires API contract or schema sync between the two.

---

## Operating Principles

### 1. Check for Tools First

Before writing new code:

1. Read the relevant directive (e.g., `directives/data/scrape_player_gamelogs.md`)
2. Check `execution/` for existing scripts
3. Check `nba-data-backend/src/` for backend modules
4. Only create new scripts if none exist — ask permission first

### 2. Self-Anneal When Things Break

When something fails:

1. Read the error and stack trace
2. Fix the script (test first if it uses paid APIs / rate-limited services)
3. Test the fix
4. Update the directive with what you learned (edge cases, limits, workarounds)
5. The system is now stronger

### 3. Treat Directives as Living Docs

Update directives when you discover:
- API constraints, rate limits, quotas
- Better approaches (batch endpoints, caching)
- Common errors and their resolutions
- Timing/performance notes

Do NOT delete or rewrite directives without approval. Add real learnings, not speculation.

---

## Backend Script Index

All execution wrappers live in `execution/nba_data/` and delegate to `nba-data-backend/src/`.

| Purpose | Execution wrapper | Backend module | Directive |
|---------|-------------------|----------------|-----------|
| Player names → CSV | `scrape_player_names.py` | `src/data_collection/scrapers/player_names.py` | `scrape_player_names.md` |
| Player names → URLs JSON | `scrape_player_urls.py` | `src/data_collection/scrapers/players_table_data.py` | `scrape_player_urls.md` |
| Retry failed URL scrapes | — | `src/data_collection/scrapers/retry_failed_player_urls.py` | `scrape_player_urls.md` |
| Players JSON → DB | `update_players_to_db.py` | `src/api/update_db/update_db_players.py` | `update_players_to_db.md` |
| Gamelogs JSON → DB | `update_gamelogs_to_db.py` | `src/api/update_db/update_db_gamelogs.py` | `update_gamelogs_to_db.md` |
| Games from gamelog → DB | `update_games_to_db.py` | `src/api/update_db/update_db_games.py` | `update_games_to_db.md` |
| Player game stats → DB | `update_player_game_stats_to_db.py` | `src/api/update_db/update_db_player_game_stats.py` | `update_player_game_stats_to_db.md` |
| Seed prop_markets → DB | `update_prop_markets_to_db.py` | `src/api/update_db/update_db_prop_markets.py` | `update_prop_markets_to_db.md` |
| Props CSV → API | `update_props_to_db.py` | `src/api/update_db/update_db_props.py` | `update_props_to_db.md` |
| Gamelog scraping | — (MCP preferred) | `src/data_collection/scrapers/gamelogs.py` | `scrape_player_gamelogs.md` |

**Standalone scripts** (run from `nba-data-backend/` with `.venv` activated):
- `scripts/check_missing_players.py` – CSV vs player_urls.json (read-only)
- `scripts/dedupe_player_urls.py` – Remove duplicate URLs
- `scripts/fetch_missing_player_urls.py` – Scrape URLs for names in CSV but missing from JSON
- `scripts/export_neon_schema.py` – Dump Neon schema to `directives/infrastructure/neon_schema.md`
- `scripts/cleanup_dnp_player_game_stats.py` – Clean up DNP records
- `scripts/retry_gamelog_failed.py` – Retry failed gamelog scrapes

**Pipeline order** (see `directives/data/populate_relational_schema.md`):
1. teams
2. players (scrape names → scrape URLs → update_players_to_db)
3. games (rescrape gamelogs → update_games_to_db)
4. player_game_stats (update_player_game_stats_to_db)
5. prop_markets (update_prop_markets_to_db)
6. player_props

---

## Key Data Files

All in `nba-data-backend/data/`:

| File | Purpose |
|------|---------|
| `player_names.csv` | Scraped player names |
| `player_urls.json` | Player page URLs for gamelog scraping |
| `player_urls_failed.json` | Failed URL scrapes for retry |
| `player_gamelog_2026.json` | Current season gamelogs |
| `player_gamelog_2025.json` | Previous season gamelogs |
| `teams_db_data.json` | Team data for DB seeding |
| `prop_line_df.csv` | Prop line data |
| `gamelog_retry_names.txt` | Names to retry for gamelog scraping |

---

## Neon DB Schema

**Source of truth**: `directives/infrastructure/neon_schema.md`
**Refresh**: `cd nba-data-backend && source .venv/bin/activate && python3 scripts/export_neon_schema.py`
**Drizzle schema** (frontend): `nba-prop-website/src/db/schema.ts`

Key tables: **players**, **games**, **teams**, **player_game_stats**, **prop_markets**, **player_props**

**DNP handling**: `player_game_stats.minutes_played` stores raw strings. DNP values: `''`, `'Inactive'`, `'Inact'`, `'Did N'`, `'0'`, `'0:00'`. Frontend filters these out of averages.

---

## Frontend Quick Reference

**Stack**: Next.js 14 App Router, React, TypeScript, Tailwind CSS v4, Drizzle ORM, Recharts, pnpm

| What | Where |
|------|-------|
| Pages & layout | `src/app/page.tsx`, `layout.tsx` |
| UI components | `src/app/components/` (PlayerSearch, PlayerCard, PlayerChartDisplay) |
| API routes | `src/app/api/update-players/route.ts`, `src/app/api/update-props/route.ts`, `src/app/api/revalidate/route.ts` |
| DB schema & client | `src/db/schema.ts`, `src/db/index.ts` |
| Data helpers | `src/lib/data.ts` (getPlayerData, getPlayerNames, etc.) |
| Types | `src/types/` |

**Data flow**:
- Player list from Neon `players` table via `getPlayerNames()` (cached)
- Game data via `getPlayerData(playerName, limit)` → queries player_game_stats + games + players
- Homepage: `getPlayersOverSeasonAvgLast5(limit)` for hot players
- Backend pushes data via PUT to `/api/update-players` and `/api/update-props` (Bearer `UPDATE_API_KEY`)
- Cache revalidation: POST `/api/revalidate` with Bearer `REVALIDATE_SECRET`

---

## Environment Variables

**Backend** (`nba-data-backend/.env.local`):
- `POSTGRES_URL` – Neon connection string (required)
- `APP_URL` – Frontend base URL, no trailing slash (required for daily script)
- `REVALIDATE_SECRET` – Must match frontend (required for daily script)
- `SCRAPE_PROXIES` – Comma-separated proxies (optional)
- `UPDATE_API_KEY` – API key for frontend write endpoints (optional)
- `ODDS_API_KEY` – Sports odds API key, USE SPARINGLY (optional)

**Frontend** (`nba-prop-website/.env`):
- `POSTGRES_URL` – Same Neon connection string
- `UPDATE_API_KEY` – Must match backend
- `REVALIDATE_SECRET` – Must match backend

---

## CI/CD

- **Daily scrape**: `.github/workflows/daily-scrape.yml` runs at 3am ET (8am UTC)
  - Rescrapes gamelogs → updates games → updates player_game_stats → revalidates frontend cache
  - Secrets: `POSTGRES_URL`, `APP_URL`, `REVALIDATE_SECRET`, `SCRAPE_PROXIES`
- **Git hooks**: `lefthook.yml` enforces conventional commits and blocks secrets/env files
  - Commit format: `<type>(<scope>): <subject>` (feat, fix, docs, refactor, etc.)

---

## Common Commands

```bash
# Backend (from nba-data-backend/)
source .venv/bin/activate
uv sync                                    # Install/update deps
uv run python -m src.api.update_db.update_db_<name>   # Run a DB update module
uv run python -m src.data_collection.scrapers.gamelogs # Scrape gamelogs
python3 scripts/export_neon_schema.py      # Export Neon schema

# Execution scripts (from workspace root)
python execution/nba_data/<script>.py

# Daily pipeline (from workspace root)
./execution/nba_data/daily_gamelog_and_revalidate.sh

# Frontend (from nba-prop-website/)
pnpm dev                                   # Dev server
pnpm build                                 # Production build
pnpm lint                                  # ESLint
pnpm drizzle-kit push                      # Push schema to Neon
pnpm drizzle-kit studio                    # DB studio
```

---

## Tool Versions

Managed via `.mise.toml`:
- Node: 22.20.0
- Python: 3.12

---

## Task Checklist (Every Task)

- [ ] Read TASKS.md for active work
- [ ] Read the directive for this task
- [ ] Check `execution/` for existing scripts
- [ ] Check `nba-data-backend/src/` for backend modules
- [ ] Plan sequence of operations
- [ ] Execute in order, testing at each step
- [ ] On error → fix, test, update directive (self-anneal)
- [ ] Verify success criteria
- [ ] Update TASKS.md and CHANGELOG.md
- [ ] Provide commit commands

---

## File Locations

| What | Where |
|------|-------|
| Agent instructions | `CLAUDE.md` (this file) |
| Feature SOPs | `directives/features/` |
| Data SOPs | `directives/data/` |
| Infra SOPs | `directives/infrastructure/` |
| Execution scripts | `execution/nba_data/` |
| Backend code | `nba-data-backend/src/` |
| Frontend code | `nba-prop-website/src/` |
| Neon DB schema | `directives/infrastructure/neon_schema.md` |
| Population order | `directives/data/populate_relational_schema.md` |
| Prop markets API | `directives/data/prop_markets_api.md` |
| Sprint prompts | `directives/features/agent-prompts-sprint.md` |
| Temp files | `.tmp/` (never commit) |
| Environment vars | `.env` / `.env.local` (never commit) |
| Active tasks | `TASKS.md` |
| Completed work | `CHANGELOG.md` |

---

**Be pragmatic. Be reliable. Self-anneal.**
