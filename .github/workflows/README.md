# Daily scrape

**Prefer local?** To avoid GitHub Actions cost and run the same pipeline on your machine or a small server, see **`directives/infrastructure/daily_gamelog_schedule.md`** (local cron + one-shot script).

The **daily-scrape** workflow runs:

1. Early-morning scheduled run: full NBA scrape/update through the strict wrapper, then props
2. Later scheduled runs: props/ML refreshes without the full gamelog rescrape

The full NBA run:

1. Rescrapes player gamelogs → writes `nba-data-backend/data/player_gamelog_2026.json`
2. Validates the scrape output is fresh and non-empty
3. Updates the **games** table from that JSON
4. Updates the **player_game_stats** table
5. Calls **POST /api/revalidate** on the frontend so cached homepage and player pages refresh

## Setup

### 1. GitHub secrets

In the repo: **Settings → Secrets and variables → Actions**, add:

| Secret | Description |
|--------|-------------|
| `POSTGRES_URL` | Neon (or Postgres) connection string. Used by backend update_db scripts. |
| `APP_URL` | Frontend base URL, e.g. `https://your-app.vercel.app` or `https://prop-analyzer.example.com`. No trailing slash. |
| `REVALIDATE_SECRET` | Same value as in the frontend env (`REVALIDATE_SECRET`). Used to authorize the revalidate request. |
| `SCRAPE_PROXIES` | (Optional) Comma-separated proxy list for the gamelog scraper to reduce rate limits. |

### 2. Frontend env

On the host where the frontend runs (e.g. Vercel), set:

- `REVALIDATE_SECRET` — same string you stored in GitHub as `REVALIDATE_SECRET`.

### 3. Data in repo or first run

- The gamelog scraper reads **`nba-data-backend/data/player_urls.json`** (expects a `successful_players` list). Ensure that file exists in the repo or is produced by an earlier job (e.g. scrape player names → scrape player URLs, then commit or artifact).
- If `player_urls.json` is not in the repo, add a workflow step before “Rescrape gamelogs” that runs the player-URL scraper and writes that file.

### 4. Change schedule or timezone

Edit **`.github/workflows/daily-scrape.yml`**:

- **Current schedule**: `30 12 * * *` full scrape, `0 15 * * *` props refresh, `0 19 * * *` afternoon safety net (UTC).
- **3am UTC**: `cron: "0 3 * * *"`.
- **3am Pacific**: `cron: "0 15 * * *"` (3am PT = 11am UTC next day; or `0 15 * * *` is 3am PT in winter).

[Cron syntax](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule): minute hour day month weekday (UTC).

## Manual run

From the repo: **Actions → Daily scrape → Run workflow**.

## If the scrape step fails

The workflow now uses the strict runner at `execution/nba_data/full_rescrape_and_update.sh` for scheduled NBA runs. If the scrape fails, if no proxies pass preflight, or if the resulting JSON is stale, the NBA stage fails instead of silently updating the DB from stale gamelog JSON.
