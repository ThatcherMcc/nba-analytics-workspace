# Infrastructure Directives

Deployment and ops (e.g. deploy backend, env setup, DB migrations). Add when needed.

## Neon DB schema (for agents and populating tables)

- **File**: `directives/infrastructure/neon_schema.md`  
- **Purpose**: Single place to look up current Postgres table names, columns, types, and constraints when writing SQL or update_db scripts.
- **Refresh**: From `nba-data-backend/`:  
  `source .venv/bin/activate && python3 scripts/export_neon_schema.py`