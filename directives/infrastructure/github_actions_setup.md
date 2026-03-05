# GitHub Actions Setup — Daily Pipeline

## Overview

The daily scrape pipeline runs at **3:00 AM Eastern (8:00 AM UTC)** via `.github/workflows/daily-scrape.yml`. It scrapes gamelogs, updates the database, fetches prop lines, and revalidates the frontend cache.

## Required Secrets

Go to **Settings → Secrets and variables → Actions → New repository secret** and add:

| Secret | Required | Value | Notes |
|--------|----------|-------|-------|
| `POSTGRES_URL` | Yes | Neon connection string | Starts with `postgresql://` or `postgres://` |
| `APP_URL` | Yes | Frontend Vercel URL | e.g. `https://your-app.vercel.app` — **no trailing slash** |
| `REVALIDATE_SECRET` | Yes | Auth token | Must match the `REVALIDATE_SECRET` in Vercel env vars |
| `SCRAPE_PROXIES` | No | Comma-separated proxy URLs | Format: `http://user:pass@host:port,http://...` |
| `ODDS_API_KEY` | No | SportsGameOdds API key | Enables automatic prop line fetching. Budget: 2,500 objects/month |

## Vercel Environment Variables

Ensure these match in your Vercel project settings (Settings → Environment Variables):

| Variable | Must Match |
|----------|-----------|
| `POSTGRES_URL` | Same as GitHub secret |
| `REVALIDATE_SECRET` | Same as GitHub secret |
| `UPDATE_API_KEY` | Same as backend `.env.local` |

## Testing

### Manual Trigger

1. Go to **Actions** tab in GitHub
2. Select **"Daily scrape"** workflow
3. Click **"Run workflow"**
4. Optional: check "Skip gamelog scraping" or "Skip props pipeline" for faster test runs
5. Watch the run — check the **Summary** tab for the results table

### Verify Success

After a run, check:
- **Actions → run → Summary**: Shows step-by-step results table
- **Health check**: `curl https://your-app.vercel.app/api/health` should return `{"status":"ok"}`
- **Frontend**: Homepage should show fresh data with "Updated Xh ago" indicator

### If It Fails

- A GitHub Issue with label `pipeline-failure` is auto-created listing which steps failed
- Check the run logs for error details
- Common issues:
  - Missing secrets → steps fail immediately
  - Rate limiting → gamelog scrape fails (continues with existing data)
  - Props budget exhausted → props steps are skipped

## Pipeline Phases

```
Phase 1: Gamelog Pipeline
  1. Scrape gamelogs from Basketball Reference (30min timeout)
  2. Update games table from scraped data (5min)
  3. Update player_game_stats table (5min)

Phase 2: Props Pipeline (requires ODDS_API_KEY)
  4. Fetch prop lines from SportsGameOdds API (10min)
  5. Check API budget remaining (1min)
  6. Update games from API events (5min)
  7. Insert player props into DB (5min)

Phase 3: Cache
  8. Revalidate frontend cache via POST /api/revalidate (2min)

Phase 4: Verification
  9. Health check GET /api/health (1min)

Phase 5: Reporting
  10. Write summary to GitHub Step Summary
  11. Create GitHub Issue if any step failed
```

## Monitoring

- **Pipeline failures**: Auto-creates GitHub Issues with `pipeline-failure` label
- **Budget warnings**: Props API budget < 500 objects triggers a warning annotation
- **Health check**: GET `/api/health` returns DB connectivity + latency
- **Step summary**: Every run produces a markdown table in the Actions Summary tab
