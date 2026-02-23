# Env setup for connections

Use this to wire Postgres, the daily pipeline, and the frontend.

---

## 1. Backend: `nba-data-backend/.env.local`

Create or edit (copy from `nba-data-backend/.env.example`). **Required for scrape + DB updates + daily script:**

| Variable | Required | Description |
|----------|----------|-------------|
| `POSTGRES_URL` | Yes | Neon (or Postgres) connection string. Used by all update_db scripts. |
| `APP_URL` | Yes for daily script | Frontend base URL, e.g. `https://your-app.vercel.app` or `http://localhost:3000`. No trailing slash. |
| `REVALIDATE_SECRET` | Yes for daily script | Same string as in the frontend. Used when the daily script calls `POST /api/revalidate`. |

**Optional:**

| Variable | Description |
|----------|-------------|
| `SCRAPE_PROXIES` | Comma-separated proxy URLs for the gamelog scraper (helps with rate limits). |
| `UPDATE_API_KEY` | If you call the website’s update API from the backend. |
| `ODDS_API_KEY` | For prop odds; use sparingly. |

The **daily script** (`execution/nba_data/daily_gamelog_and_revalidate.sh`) sources this file, so once `POSTGRES_URL`, `APP_URL`, and `REVALIDATE_SECRET` are set here, cron (or a manual run) can use it without extra env.

---

## 2. Frontend: `nba-prop-website/.env`

**Required for DB and revalidate:**

| Variable | Required | Description |
|----------|----------|-------------|
| `POSTGRES_URL` | Yes | Same Neon URL (Drizzle connects to the same DB). |
| `REVALIDATE_SECRET` | Yes | Secret for `POST /api/revalidate`. **Must match** `REVALIDATE_SECRET` in the backend so the daily script can call revalidate. |

On Vercel (or any host), set these in the project’s environment. Locally, use `nba-prop-website/.env` (do not commit; add to `.gitignore` if needed).

---

## 3. Checklist

- [ ] **nba-data-backend/.env.local**: `POSTGRES_URL`, `APP_URL`, `REVALIDATE_SECRET` (and optional `SCRAPE_PROXIES`).
- [ ] **nba-prop-website/.env** (or host env): `POSTGRES_URL`, `REVALIDATE_SECRET` (same value as backend).
- [ ] Daily script is executable: `chmod +x execution/nba_data/daily_gamelog_and_revalidate.sh` (already done).
- [ ] Cron (if local): point at the script and ensure it runs in an environment where backend `.env.local` is loaded (the script sources it), or export `APP_URL` and `REVALIDATE_SECRET` in the cron line.

---

## 4. Quick test (local)

From repo root, with backend `.env.local` and frontend `.env` set:

```bash
execution/nba_data/daily_gamelog_and_revalidate.sh
```

If `APP_URL` is your deployed site, the script will rescrape, update Neon, and revalidate that deployment. If `APP_URL` is `http://localhost:3000`, start the frontend first so the revalidate request succeeds.
