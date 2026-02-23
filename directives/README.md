# Directives (Layer 1: What to Do)

SOPs the agent reads before orchestrating. **For nba-data-backend work, start with `data/`.**

| Directory         | Purpose |
|------------------|---------|
| `data/`          | Data fetching, scraping, DB updates (backend data pipeline) |
| `features/`      | Feature development (backend + frontend) |
| `infrastructure/`| Deployment and ops |
| `testing/`       | Testing procedures |

When you ask for a task, the agent will read the relevant directive, then use MCP tools or execution scripts.
