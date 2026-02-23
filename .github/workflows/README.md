# Daily scrape (3am)

**Prefer local?** To avoid GitHub Actions cost and run the same pipeline on your machine or a small server, see **`directives/infrastructure/daily_gamelog_schedule.md`** (local cron + one-shot script).

The **daily-scrape** workflow runs at **3am US Eastern** (8am UTC) and:

1. Rescrapes player gamelogs → writes `nba-data-backend/data/player_gamelog_2026.json`
2. Updates the **games** table from that JSON
3. Updates the **player_game_stats** table
4. Calls **POST /api/revalidate** on the frontend so cached homepage and player pages refresh

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

- **3am US Eastern** (current): `cron: "0 8 * * *"` (8am UTC).
- **3am UTC**: `cron: "0 3 * * *"`.
- **3am Pacific**: `cron: "0 15 * * *"` (3am PT = 11am UTC next day; or `0 15 * * *` is 3am PT in winter).

[Cron syntax](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#schedule): minute hour day month weekday (UTC).

## Manual run

From the repo: **Actions → Daily scrape → Run workflow**.

## If the scrape step fails

The workflow uses `continue-on-error: true` for the gamelog scrape. If the scrape fails (e.g. rate limits), the run still executes **Update games** and **Update player_game_stats** using the existing `player_gamelog_2026.json`, then revalidates. Fix the scraper or add proxies and re-run.
