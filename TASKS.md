# Tasks

Big items that spawn Cursor plans. Check off when complete, move to Completed section.

---

## Current Sprint

**Backend agent** (see `directives/features/agent-prompts-sprint.md` for full prompts):

- [ ] **Backend data pipeline (DOE)** – Run full pipeline once: player names → player URLs → update players → rescrape gamelogs → update games → update player_game_stats. Align directives and execution scripts; document runbook.
- [ ] **Data readiness for frontend** – Players as source of truth; document or add way to fetch player names. Seed prop_markets. Confirm minutes_played/DNP in gamelogs for “Last game: DNP” badge.

**Frontend agent** (see `directives/features/agent-prompts-sprint.md` for full prompts):

- [ ] **Multi-stat view + DNP availability** – Player page: multi-stat view (tabs or small multiples). When last game was DNP, show “Last game: DNP” / “Inactive” badge.
- [ ] **Expand hot/cold + dynamic player list** – Home: add “Cold last 5” (and optional “Trending”). Replace static ALL_PLAYER_NAMES with DB-backed list (cached, revalidate with pipeline).

---

## Backlog

- [ ] [Future task 1]
- [ ] [Future task 2]

---

## Completed

- [x] Initial project setup from ai-project-start template
- [x] DOE setup for nba-data-backend: directives/data/, execution/nba_data/, AGENT.md backend section
