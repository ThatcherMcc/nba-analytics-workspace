# Daily Gamelog Rescrape (3am)

Run every day around 3am: rescrape gamelogs → update Neon (games, player_game_stats) → revalidate frontend cache.

## Local vs GitHub Actions

| | Local (cron) | GitHub Actions |
|--|--------------|----------------|
| **Cost** | No GH minutes; only your machine/network. | Uses Actions minutes; long scrape can approach limits. |
| **Reliability** | Machine must be on at 3am (or use a small VPS/server). | Runs in the cloud; no dependency on your PC. |
| **Secrets** | Keep in `.env.local` or cron env; never leave the machine. | Stored in repo Secrets; used only in the workflow. |
| **Best for** | Always-on machine, homelab, or cheap VPS. | Repo-only setup, no server to maintain. |

**Recommendation:** If you have a machine that’s on at 3am (or a small server), run **locally** to avoid Actions cost and rate-limit risk. Use **GitHub Actions** for manual runs or if you don’t want to host anything.

---

## Option A: Local (cron)

### 1. One-shot script

From repo root (or anywhere with `WORKSPACE` set):

```bash
execution/nba_data/daily_gamelog_and_revalidate.sh
```

Requires:

- **POSTGRES_URL** – Backend uses this; usually in `nba-data-backend/.env.local` (script sources it if present).
- **APP_URL** – Frontend base URL, e.g. `https://your-app.vercel.app` (no trailing slash).
- **REVALIDATE_SECRET** – Same value as the frontend’s `REVALIDATE_SECRET` (used to auth `POST /api/revalidate`).

Optional: **SCRAPE_PROXIES** in backend `.env.local` for the gamelog scraper.

### 2. Schedule with cron (e.g. 3am)

```bash
crontab -e
```

Add (adjust paths and env to match your setup):

```cron
# 3am daily: gamelog rescrape → DB update → revalidate
0 3 * * * cd /path/to/nba-analytics-workspace && . nba-data-backend/.env.local 2>/dev/null; export APP_URL=https://your-app.vercel.app REVALIDATE_SECRET=your-secret; execution/nba_data/daily_gamelog_and_revalidate.sh >> /tmp/daily-gamelog.log 2>&1
```

Or put `APP_URL` and `REVALIDATE_SECRET` in a small env file (e.g. `nba-data-backend/.env.revalidate`) and source it in the cron line so you don’t put secrets in crontab.

### 3. Make the script executable

```bash
chmod +x execution/nba_data/daily_gamelog_and_revalidate.sh
```

---

## Option B: GitHub Actions

See **`.github/workflows/README.md`** and **`.github/workflows/daily-scrape.yml`**.  
Secrets: `POSTGRES_URL`, `APP_URL`, `REVALIDATE_SECRET`; optional `SCRAPE_PROXIES`.  
Schedule is in the workflow (e.g. 3am US Eastern). You can also trigger **Run workflow** from the Actions tab.

---

## Pipeline steps (both options)

1. **Rescrape gamelogs** – `src.data_collection.scrapers.gamelogs` → writes `nba-data-backend/data/player_gamelog_2026.json`. On failure (e.g. rate limit), local script continues with existing JSON.
2. **Update games** – `src.api.update_db.update_db_games` → Neon `games` table.
3. **Update player_game_stats** – `src.api.update_db.update_db_player_game_stats` → Neon `player_game_stats` (skips DNP rows).
4. **Revalidate** – `POST ${APP_URL}/api/revalidate` with `Authorization: Bearer ${REVALIDATE_SECRET}` so the frontend clears cached player/home data.
