# NBA Data Execution Scripts

Wrappers that run `nba-data-backend` modules from the workspace root (`python -m <module>`, cwd=backend). Requires backend deps (e.g. `.venv` or `uv sync` in `nba-data-backend/`). For DB scripts, set `POSTGRES_URL` in `nba-data-backend/.env.local` (see **ENV_SETUP.md**).

- Use **MCP** first when the agent has access: `mcp_nba-engine_scrape_player_names`, etc.
- Use these when running in terminal or when MCP script paths don’t match backend (e.g. update_db submodule paths).
