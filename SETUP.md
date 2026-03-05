# Workspace Setup

Clone the workspace and both sub-repos, then install dependencies.

## 1. Clone Everything

```bash
# Workspace (contains directives, execution scripts, CI config)
git clone https://github.com/ThatcherMcc/nba-analytics-workspace.git
cd nba-analytics-workspace
git checkout feat/edge-analytics-suite

# Backend (Python data pipeline)
git clone https://github.com/ThatcherMcc/nba-data-scraper.git nba-data-backend

# Frontend (Next.js prop website)
git clone https://github.com/ThatcherMcc/nba-prop-website.git
cd nba-prop-website
git checkout feat/edge-analytics-suite
cd ..
```

## 2. Install Tools

Requires [mise](https://mise.jdx.dev/) (manages Node 22.20.0 and Python 3.12):

```bash
# Install mise if you don't have it
curl https://mise.jdx.dev/install.sh | sh

# From workspace root — installs correct Node + Python versions
mise install
```

Or install manually: **Node 22.20.0**, **Python 3.12**, **pnpm**, **uv**.

## 3. Backend Setup

```bash
cd nba-data-backend
uv sync          # creates .venv and installs all Python deps
```

Copy env file (get values from your existing `.env.local`):

```bash
cp .env.example .env.local   # then fill in values
```

Required env vars:
- `POSTGRES_URL` — Neon connection string
- `APP_URL` — Frontend URL (e.g. `https://nba-prop-website.vercel.app`)
- `REVALIDATE_SECRET` — must match frontend

Optional:
- `SCRAPE_PROXIES` — comma-separated proxy list for Basketball Reference
- `ODDS_API_KEY` — SportsGameOdds API key
- `UPDATE_API_KEY` — API key for frontend write endpoints

## 4. Frontend Setup

```bash
cd nba-prop-website
pnpm install
```

Copy env file:

```bash
cp .env.example .env   # then fill in values
```

Required env vars:
- `POSTGRES_URL` — same Neon connection string
- `UPDATE_API_KEY` — must match backend
- `REVALIDATE_SECRET` — must match backend

## 5. Verify

```bash
# Backend — should connect to Neon and print schema
cd nba-data-backend
source .venv/bin/activate
set -a && source .env.local && set +a
python3 scripts/export_neon_schema.py

# Frontend — should start dev server on localhost:3000
cd ../nba-prop-website
pnpm dev
```

## Quick Reference

| What | Command | Where |
|------|---------|-------|
| Run daily pipeline | `./execution/nba_data/daily_gamelog_and_revalidate.sh` | workspace root |
| Scrape gamelogs | `python3 -m src.data_collection.scrapers.gamelogs` | nba-data-backend/ (venv active) |
| Fetch props | `python3 -m src.data_collection.scrapers.props --upcoming` | nba-data-backend/ (venv active) |
| Load props to DB | `python3 -m src.api.update_db.update_db_player_props` | nba-data-backend/ (venv active) |
| Frontend dev | `pnpm dev` | nba-prop-website/ |
| Frontend build | `pnpm build` | nba-prop-website/ |

## Pulling Updates

```bash
# From workspace root
git pull

# Backend
cd nba-data-backend && git pull

# Frontend
cd ../nba-prop-website && git pull
```
