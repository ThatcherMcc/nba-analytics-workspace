# Agent Instructions (NBA Analytics Workspace)

> This file defines how you (the AI) operate within the DOE architecture.

You operate within a 3-layer architecture that separates concerns to maximize reliability. LLMs are probabilistic, whereas most business logic is deterministic and requires consistency. This system fixes that mismatch.

---

## The 3-Layer Architecture

### Layer 1: Directive (What to do)
**Location**: `directives/`
**Format**: Markdown SOPs
**Purpose**: Define goals, inputs, tools/scripts to use, outputs, and edge cases

These are natural language instructions, like you'd give a mid-level employee. They live in:
- `directives/features/` - Feature development instructions
- `directives/infrastructure/` - Deployment and ops procedures
- `directives/data/` - Data fetching and processing instructions
- `directives/testing/` - Testing procedures

**Example**: `directives/features/build_player_props_analysis.md` tells you WHAT to build, not HOW.

---

### Layer 2: Orchestration (Decision making)
**Who**: This is you (the AI)
**Job**: Intelligent routing

Your responsibilities:
1. **Read directives** to understand what needs to happen
2. **Call execution tools** in the right order
3. **Handle errors** by reading stack traces and fixing scripts
4. **Ask for clarification** when inputs are ambiguous
5. **Update directives** with learnings (API limits, timing, edge cases)
6. **Use MCP tools** when available (`mcp_nba-engine_*` tools from your backend)

**Key principle**: You don't try scraping websites yourself—you read `directives/data/fetch_player_props.md` and then run `execution/nba_api/fetch_props.py`.

---

### Layer 3: Execution (Doing the work)
**Location**: `execution/`
**Format**: Python scripts, Node.js utilities, shell scripts
**Purpose**: Deterministic, testable, reliable execution

Environment variables and API tokens live in `.env` (never commit these).

Scripts handle:
- API calls to NBA stats, odds providers
- Data processing (gamelogs, player props, predictions)
- Database operations (Drizzle ORM)
- File operations
- Browser testing

**Why this works**: If you do everything yourself, errors compound. 90% accuracy per step = 59% success over 5 steps. Push complexity into deterministic code. You focus on decision-making.

---

## Operating Principles

### 0. Context separation (frontend vs backend)

This workspace contains both **nba-data-backend** (Python, data pipeline, MCP, directives/execution) and **nba-prop-website** (Next.js frontend).

- **When the user’s focus or open files are under `nba-prop-website/`**: The rule **nba-prop-website.mdc** applies (file-scoped). Prefer that rule’s context. Do not assume backend directives, MCP tools, or execution scripts are the primary context unless the task explicitly requires API/DB integration or pipeline orchestration.
- **When working in `nba-data-backend/`, `directives/`, or `execution/`**: The rule **nba-data-backend.mdc** applies (file-scoped). Prefer that rule's context; it points back here (AGENT.md) for full workflow (directives → MCP/execution → self-anneal). Do not assume frontend/Next.js changes unless the task explicitly requires API contract or schema sync.

This keeps frontend work from being cluttered by backend-specific steps and vice versa.

---

### 1. Check for Tools First

**Before writing any code:**
1. Read the relevant directive (e.g., `directives/data/fetch_player_props.md`)
2. Check `execution/` for existing scripts
3. Check MCP tools (type `/` in Cursor, look for `mcp_nba-engine_*`)
4. Only create new scripts if none exist. You must ask permission first.

**Your project has**:
- **MCP Server**: `nba-data-backend/ai-tools/mcp/skills_mcp.py` exposes backend capabilities
- **Backend**: Python scripts in `nba-data-backend/src/`
- **Frontend**: Next.js app in `nba-prop-website/`

**Example**:
```
Task: Fetch LeBron James' prop predictions

✅ DO:
1. Check directive: directives/data/fetch_player_props.md
2. Check MCP: mcp_nba-engine_get_props (if available)
3. Check execution: execution/nba_api/fetch_props.py
4. Use existing tool with correct inputs

❌ DON'T:
- Write inline code to call Odds API
- Manually parse JSON responses
- Hardcode API keys
```

---

### 2. Self-Anneal When Things Break

Errors are learning opportunities. When something breaks:

**The Self-Annealing Loop**:
1. Read error message and stack trace
2. Fix the script (test first if it uses paid APIs/credits)
3. Test the fix thoroughly
4. Update the directive with what you learned
5. System is now stronger

**Example**:
```
Error: Odds API rate limit hit (429 Too Many Requests)

Self-anneal process:
1. Read error → Rate limit is 10 requests/minute
2. Check API docs → Find batch endpoint for multiple props
3. Update execution/nba_api/fetch_props.py:
   - Add rate limiter with 6-second delay between calls
   - Implement batch fetching (100 props per request)
   - Add exponential backoff for retries
4. Test → Works, no more 429 errors
5. Update directives/data/fetch_player_props.md:
   Edge Cases:
   - API rate limit (10/min) → Use batch endpoint
   - Always wait 6s between individual requests
   - Cache responses for 5 minutes
6. Done → Future runs won't hit this error
```

---

### 3. Update Directives as You Learn

Directives are **living documents**. When you discover:
- API constraints (rate limits, quotas)
- Better approaches (batch endpoints, caching strategies)
- Common errors (missing data, timeout patterns)
- Timing expectations (how long operations take)
- Edge cases (player injuries, postponed games)

→ **Update the directive**

**Important**: Don't create or overwrite directives without asking (unless explicitly told to). Directives are your instruction set and must be preserved.

**What to update**:
- ✅ Add edge cases discovered during execution
- ✅ Add timing/performance notes ("This takes ~30s for full roster")
- ✅ Add better approaches found ("Use batch endpoint instead")
- ✅ Add common error resolutions

**What NOT to do**:
- ❌ Don't delete existing directives
- ❌ Don't rewrite directives from scratch without approval
- ❌ Don't add speculative edge cases (only real ones you encountered)

---

## File Organization

### Deliverables vs Intermediates

**Deliverables** (what the user sees):
- Live Next.js app at `nba-prop-website/`
- Database with predictions (Drizzle + Neon/Supabase)
- Charts and visualizations in web UI
- API endpoints returning JSON data

**Intermediates** (processing artifacts):
- Raw JSON from Odds API
- Scraped player gamelogs
- Cached API responses
- Temporary CSV exports

### Directory Structure

```
nba-analytics-workspace/
├── .cursor/
│   ├── rules/
│   │   └── AGENT.md              # This file (YOU READ THIS)
│   └── mcp.json                  # MCP server connection
│
├── directives/                   # Layer 1: WHAT TO DO
│   ├── README.md                 # Index; for backend start with data/
│   ├── data/                     # Data fetching (nba-data-backend pipeline)
│   ├── features/                 # Feature development
│   ├── infrastructure/           # Deployment procedures
│   └── testing/                  # Testing procedures
│
├── execution/                    # Layer 3: DOING THE WORK
│   ├── README.md                 # When to use MCP vs scripts
│   ├── nba_data/                 # Backend data scripts (players, gamelogs, props)
│   ├── nba_api/                  # Data fetching scripts
│   ├── data_processing/          # ML and analytics scripts
│   ├── frontend/                 # Frontend scaffolding
│   ├── deployment/               # Deployment automation
│   └── testing/                  # Test automation
│
├── .tmp/                         # Intermediate files (NEVER COMMIT)
│   ├── cache/
│   ├── raw_json/
│   └── temp_exports/
│
├── nba-data-backend/            # Python backend (existing)
│   ├── ai-tools/mcp/
│   │   └── skills_mcp.py        # MCP server
│   └── src/                     # Your existing backend code
│
├── nba-prop-website/            # Next.js frontend (existing)
│   └── src/                     # Your existing frontend code
│
├── .env                         # Environment variables (in .gitignore)
├── TASKS.md                     # Sprint planning (YOU READ THIS)
└── CHANGELOG.md                 # Progress tracking (YOU UPDATE THIS)
```

### nba-data-backend DOE (use this scope first when asked)

When the user asks for **backend-only** or **nba-data-backend** work:

1. **Directive**: Read from `directives/data/` (see `directives/data/README.md` for the list). Each `.md` describes goal, inputs, tools (MCP + execution + backend path), outputs, and edge cases.
2. **Orchestration**: Prefer MCP tools (`mcp_nba-engine_*`). If an MCP tool is missing or uses a wrong script path (e.g. update_db scripts live under `src/api/update_db/`), use `execution/nba_data/*.py` from workspace root.
3. **Execution**: Run backend via MCP or via `python execution/nba_data/<script>.py`. Backend data paths are under `nba-data-backend/data/` (player_names.csv, player_urls.json, player_gamelog_2026.json, etc.).
4. **Self-anneal**: On errors, fix the script or MCP, then update the corresponding directive’s Edge Cases.

**Key principle**: Local files in `.tmp/` are only for processing. Deliverables live in the database or web app. Everything in `.tmp/` can be deleted and regenerated.

---

## Your NBA Analytics Workspace Specifics

### Current Structure You Have

**Backend** (`nba-data-backend/`):
- Data collection: `src/data_collection/`
- API endpoints: `src/api/`
- Database updates: `src/api/update_db/`
- MCP server: `ai-tools/mcp/skills_mcp.py`

**Backend script index** (no overlap; execution/ wrappers call these):
| Purpose | Backend script | Directive |
|---------|----------------|-----------|
| Player names → CSV | `src/data_collection/scrapers/player_names.py` | scrape_player_names.md |
| Player names → URLs JSON | `src/data_collection/scrapers/players_table_data.py` | scrape_player_urls.md |
| Retry failed URL scrapes | `src/data_collection/scrapers/retry_failed_player_urls.py` | scrape_player_urls.md |
| Players JSON → DB | `src/api/update_db/update_db_players.py` | update_players_to_db.md |
| Gamelogs JSON → API | `src/api/update_db/update_db_gamelogs.py` | update_gamelogs_to_db.md |
| Games from gamelog JSON → DB | `src/api/update_db/update_db_games.py` | update_games_to_db.md |
| Player game stats from gamelog JSON → DB | `src/api/update_db/update_db_player_game_stats.py` | update_player_game_stats_to_db.md (run after rescrape + update_games) |
| Seed prop_markets → DB | `src/api/update_db/update_db_prop_markets.py` | update_prop_markets_to_db.md |
| Props CSV → API | `src/api/update_db/update_db_props.py` | update_props_to_db.md (sends to Next.js; Neon player_props for ML later) |
| Teams JSON → DB | `src/api/update_db/update_db_teams.py` | (infra) |
| Gamelog scraping | `src/data_collection/scrapers/gamelogs.py` | scrape_player_gamelogs.md |
| Fetch player_data from DB | `src/api/fetch_db.py` (optional; no callers) | — |

**Standalone scripts** (run from `nba-data-backend/` with `.venv` activated):
- `scripts/check_missing_players.py` – CSV vs player_urls.json (read-only).
- `scripts/dedupe_player_urls.py` – Remove duplicate URLs in player_urls.json.
- `scripts/fetch_missing_player_urls.py` – Scrape URLs for names in CSV but missing from JSON.
- `scripts/export_neon_schema.py` – Dump Neon schema to `directives/infrastructure/neon_schema.md`.

**Proposed deletions** (reduce dead code):
- `src/main.py` – Stub only (`print("Hello from nba-data-backend!")`); no callers. Safe to delete.
- `src/api/fetch_db.py` – Optional: not imported anywhere; only fetches `player_data`. Keep if you want a reusable fetch helper, or delete and use ad-hoc queries when needed.

**Neon DB schema (for populating tables):**
- **Source of truth**: `directives/infrastructure/neon_schema.md` – tables, columns, types, constraints.
- **When to use**: Before writing INSERT/upsert logic or new update_db scripts, read that file.
- **Refresh**: From `nba-data-backend/`: `source .venv/bin/activate && python3 scripts/export_neon_schema.py`

**Relational schema population:**
- **Directive**: `directives/data/populate_relational_schema.md` – dependency order (teams → players → games → player_game_stats; prop_markets → player_props), what’s populated vs TBD, and recommended next steps.
- **Order**: 1) teams, 2) players (done), 3) games, 4) player_game_stats, 5) prop_markets, 6) player_props. Read the directive before adding or changing update_db scripts.
- **Prop markets API**: `directives/data/prop_markets_api.md` – NBA full-game over/under player props (statID, oddID). Map API statID → market_code via `nba-data-backend/src/api/update_db/prop_market_mapping.py` (API_STAT_ID_TO_MARKET_CODE). Parse one event response for all prop markets; use fair/book odds.

**MCP / skills_mcp (when you edit or extend tools):**
- Point tools at backend scripts under `nba-data-backend/src/` (see Backend script index above).
- Schema context: `directives/infrastructure/neon_schema.md`; population order: `directives/data/populate_relational_schema.md`.
- Data paths: `nba-data-backend/data/` (player_names.csv, player_urls.json, player_gamelog_2026.json, teams_db_data.json, prop_line_df.csv).

**Frontend** (`nba-prop-website/`):
- Next.js 14 App Router
- Components: `src/app/components/`
- API routes: `src/app/api/`
- Database schema: `src/db/schema.ts` (Drizzle ORM)

### Your MCP Tools

Your backend exposes tools via `mcp_nba-engine_*`. To see available tools:
1. Type `/` in Cursor
2. Look for `mcp_nba-engine_` prefix
3. These tools call your backend Python code directly

**Common MCP tools you might have**:
- `mcp_nba-engine_fetch_props` - Get player prop odds
- `mcp_nba-engine_fetch_gamelogs` - Get player game history
- `mcp_nba-engine_update_database` - Trigger database updates
- `mcp_nba-engine_get_predictions` - Get ML model predictions

### Integration with Existing Code

**When building features**:
1. Read directive for the feature
2. Check if MCP tool exists for backend operations
3. Check if `nba-data-backend/src/` has the function
4. Check if `execution/` has a wrapper script
5. Use the most appropriate tool

**Example**:
```
Task: Update player props in database

Flow:
1. Read: directives/data/update_player_props.md
2. Check MCP: mcp_nba-engine_update_props (if available)
3. Check backend: nba-data-backend/src/api/update_db/update_db_props.py
4. Check execution: execution/nba_api/update_props.py
5. Use MCP tool if available, else call backend script
6. Test: Verify database updated correctly
7. Update directive if you learned anything new
```

---

## Workflow Example: Building a Feature

### Scenario: Add Player Prop Prediction Charts

**Step 1: Read Directive** (Layer 1)
```
File: directives/features/build_prop_prediction_charts.md

Goal: Display prop prediction trends for any player
Inputs: Player name, prop type (points/rebounds/assists)
Tools: 
  - MCP: mcp_nba-engine_get_predictions
  - Backend: nba-data-backend/src/data_collection/processing.py
  - Script: execution/data_processing/generate_chart_data.py
Outputs:
  - React component: PropPredictionChart
  - API route: /api/predictions/[playerId]/[propType]
Edge Cases:
  - Player has no predictions → Show "No data available"
  - Prediction confidence < 50% → Show warning indicator
Success Criteria:
  - Chart displays last 10 games with predictions
  - Mobile responsive
  - Loading states
```

**Step 2: Orchestrate** (Layer 2 - You)

Your internal decision-making:
```
1. Check TASKS.md → Confirm this is active task
2. Check MCP tools → mcp_nba-engine_get_predictions exists ✓
3. Plan sequence:
   a. Test MCP tool with sample player
   b. Create API route using MCP tool
   c. Build React component in style guide
   d. Wire component to API
   e. Test with browser tools
   f. Verify success criteria
   g. Update docs
```

**Step 3: Execute** (Layer 3)

Call tools in sequence:
```python
# 1. Test MCP tool
mcp_nba-engine_get_predictions(player_id=2544, prop_type="points", last_n_games=10)

# 2. If MCP fails, use execution script
python execution/data_processing/generate_chart_data.py --player-id 2544 --prop points

# 3. Create API route (in nba-prop-website/)
# File: src/app/api/predictions/[playerId]/[propType]/route.ts
# Uses MCP tool or calls backend directly

# 4. Build component
# File: src/app/components/PropPredictionChart.tsx
# Designed in style guide first

# 5. Test with browser tools
python execution/testing/browser_test_helper.py --test prop-prediction-chart
```

**Step 4: Self-Anneal** (If Error)

```
Error: MCP tool times out after 10s

Fix:
1. Check backend: nba-data-backend/src/data_collection/processing.py
2. Issue: ML model inference takes 15s for 10 games
3. Solution: Add caching layer for predictions
4. Update: Add Redis cache with 5-min TTL
5. Test: Now returns in <1s with cache
6. Update directive: "Predictions cached for 5 minutes"
```

**Step 5: Complete**

```
✅ Update TASKS.md: Mark feature complete
✅ Update CHANGELOG.md: Add feature description
✅ Update directive: Add timing notes, cache strategy
✅ Provide commit commands
```

---

## Self-Annealing Loop (Detailed)

When something breaks:

### 1. Read the Error
```
Error: requests.exceptions.Timeout: HTTPSConnectionPool(host='api.the-odds-api.com', port=443)
```

### 2. Fix the Script
```python
# execution/nba_api/fetch_props.py

# Before:
response = requests.get(url, params=params)

# After:
response = requests.get(url, params=params, timeout=30)
# Add retry logic
for attempt in range(3):
    try:
        response = requests.get(url, params=params, timeout=30)
        break
    except requests.exceptions.Timeout:
        if attempt == 2:
            raise
        time.sleep(2 ** attempt)  # Exponential backoff
```

### 3. Test the Fix
```bash
python execution/nba_api/fetch_props.py --player "LeBron James" --prop points
# ✓ Works now
```

### 4. Update the Directive
```markdown
# directives/data/fetch_player_props.md

## Edge Cases
...
- **API timeout**: Odds API can be slow during peak hours
  - Set timeout to 30s
  - Retry 3x with exponential backoff (2s, 4s, 8s)
  - If all fail, use cached data from database
```

### 5. System Improved
Future runs won't hit timeout errors, and the directive documents the solution.

---

## Working with Your Existing Code

### Backend Integration (`nba-data-backend/`)

Your backend has:
- `src/api/fetch_db.py` - Database queries
- `src/api/odds_api_get_nba_events.py` - Fetch NBA games from Odds API
- `src/api/odds_api_get_props.py` - Fetch player props from Odds API
- `src/api/update_db/` - Database update scripts
- `src/data_collection/scrapers/` - Web scraping utilities

**When to use each**:
- **Direct import**: For simple operations, import and use
- **MCP tool**: For operations exposed via MCP server
- **Execution script**: For complex workflows needing orchestration

### Frontend Integration (`nba-prop-website/`)

Your frontend has:
- `src/app/components/PlayerCard.tsx` - Display player info
- `src/app/components/PlayerChartDisplay.tsx` - Chart display
- `src/app/components/PlayerSearch.tsx` - Search functionality
- `src/app/api/update-players/route.ts` - Trigger player DB update
- `src/app/api/update-props/route.ts` - Trigger props DB update

**When building features**:
1. Design components in style guide first (create `/style-guide` route)
2. Build all states (loading, error, empty, success)
3. Wire to API routes (which call backend via MCP or direct)
4. Test with browser tools
5. Deploy when all criteria pass

---

## Quick Reference

### Your Checklist for Every Task

- [ ] Read TASKS.md to confirm active task
- [ ] Read the directive for this task
- [ ] Check for existing execution scripts
- [ ] Check available MCP tools (type `/`)
- [ ] Check your existing backend code (`nba-data-backend/src/`)
- [ ] Plan the sequence of tool calls
- [ ] Execute in order, testing at each step
- [ ] If error → self-anneal (fix, test, update directive)
- [ ] Verify all success criteria pass
- [ ] Update TASKS.md and CHANGELOG.md
- [ ] Provide commit commands

### File Locations Quick Guide

| What | Where | Why |
|------|-------|-----|
| Orchestration instructions | `.cursor/rules/AGENT.md` | How you operate |
| Feature SOPs | `directives/features/` | What to build |
| Data SOPs | `directives/data/` | How to fetch data |
| Execution scripts | `execution/` | Deterministic tools |
| Backend code | `nba-data-backend/src/` | Existing Python code |
| Frontend code | `nba-prop-website/src/` | Existing Next.js code |
| Temp files | `.tmp/` | Intermediate artifacts |
| **Neon DB schema** | `directives/infrastructure/neon_schema.md` | Tables/columns for SQL and update_db scripts |
| Environment vars | `.env` | Secrets (never commit) |
| Active tasks | `TASKS.md` | What to build next |
| Completed work | `CHANGELOG.md` | History |

### Common Commands

```bash
# Backend (from nba-data-backend/)
uv run src/main.py                    # Run backend
uv run ai-tools/mcp/skills_mcp.py     # Test MCP server

# Frontend (from nba-prop-website/)
pnpm dev                              # Start dev server
pnpm build                            # Build for production

# Execution scripts
python execution/nba_api/fetch_props.py --help
python execution/testing/browser_test_helper.py --test <test-name>

# Database
pnpm drizzle-kit push                 # Push schema changes (frontend)
pnpm drizzle-kit studio               # Open DB studio
# Export current Neon schema to directives (backend)
cd nba-data-backend && source .venv/bin/activate && python3 scripts/export_neon_schema.py
```

---

## Summary

You sit between human intent (directives) and deterministic execution (scripts + MCP tools).

**Your job**:
1. Read directives → Understand what to do
2. Route to tools → Call execution layer or MCP tools
3. Handle errors → Self-anneal when things break
4. Update directives → Improve system over time
5. Verify outputs → Ensure success criteria met

**Be pragmatic. Be reliable. Self-anneal.**

The system gets smarter every time something breaks, because you fix it once and update the directive.