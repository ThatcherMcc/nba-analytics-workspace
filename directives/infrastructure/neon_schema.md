# Neon Postgres schema (exported)

Use this file when you need the current DB schema (e.g. populating tables, writing SQL).
Refresh by running from nba-data-backend:
  `source .venv/bin/activate && python3 scripts/export_neon_schema.py`

---

## Table: `games`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| game_id | integer | NO | nextval('games_game_id_seq'::regclass) |
| game_date | date | NO |  |
| home_team_id | integer | NO |  |
| away_team_id | integer | NO |  |
| season | character varying(9) | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `check_different_teams`: `CHECK ((home_team_id <> away_team_id))`
- `games_pkey`: `PRIMARY KEY (game_id)`
- `unique_game`: `UNIQUE (game_date, home_team_id, away_team_id)`
- `games_home_team_id_fkey`: `FOREIGN KEY (home_team_id) REFERENCES teams(team_id)`
- `games_away_team_id_fkey`: `FOREIGN KEY (away_team_id) REFERENCES teams(team_id)`

**Indexes:**
- `games_pkey`
- `unique_game`
- `idx_games_date`

---

## Table: `player_game_stats`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| gamelog_id | integer | NO | nextval('player_game_stats_gamelog_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| team_id | integer | NO |  |
| is_home | boolean | NO |  |
| minutes_played | character varying(5) | YES |  |
| field_goals_made | integer | YES | 0 |
| field_goals_attempted | integer | YES | 0 |
| field_goal_pct | numeric | YES |  |
| three_pointers_made | integer | YES | 0 |
| three_pointers_attempted | integer | YES | 0 |
| three_point_pct | numeric | YES |  |
| two_pointers_made | integer | YES | 0 |
| two_pointers_attempted | integer | YES | 0 |
| two_point_pct | numeric | YES |  |
| free_throws_made | integer | YES | 0 |
| free_throws_attempted | integer | YES | 0 |
| free_throw_pct | numeric | YES |  |
| effective_fg_pct | numeric | YES |  |
| offensive_rebounds | integer | YES | 0 |
| defensive_rebounds | integer | YES | 0 |
| total_rebounds | integer | YES | 0 |
| assists | integer | YES | 0 |
| steals | integer | YES | 0 |
| blocks | integer | YES | 0 |
| turnovers | integer | YES | 0 |
| personal_fouls | integer | YES | 0 |
| points | integer | YES | 0 |
| pts_reb_ast | integer | YES |  |
| pts_reb | integer | YES |  |
| pts_ast | integer | YES |  |
| reb_ast | integer | YES |  |
| stl_blk | integer | YES |  |
| created_at | timestamp with time zone | NO | now() |
| updated_at | timestamp with time zone | NO | now() |

**Constraints:**
- `chk_rebounds`: `CHECK ((total_rebounds = (offensive_rebounds + defensive_rebounds)))`
- `player_game_stats_pkey`: `PRIMARY KEY (gamelog_id)`
- `unq_player_game`: `UNIQUE (player_id, game_id)`
- `player_game_stats_player_id_fkey`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `player_game_stats_game_id_fkey`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `player_game_stats_team_id_fkey`: `FOREIGN KEY (team_id) REFERENCES teams(team_id)`

**Indexes:**
- `player_game_stats_pkey`
- `unq_player_game`
- `idx_stats_lookup`

---

## Table: `player_props`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| prop_id | integer | NO | nextval('player_props_prop_id_seq'::regclass) |
| player_id | integer | NO |  |
| game_id | integer | NO |  |
| market_id | integer | NO |  |
| over_under | character varying(5) | YES |  |
| fair_line | numeric | YES |  |
| fair_odds | integer | YES |  |
| book_line | numeric | YES |  |
| book_odds | integer | YES |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `player_props_pkey`: `PRIMARY KEY (prop_id)`
- `unq_player_game_market`: `UNIQUE (player_id, game_id, market_id)`
- `player_props_player_id_fkey`: `FOREIGN KEY (player_id) REFERENCES players(player_id)`
- `player_props_game_id_fkey`: `FOREIGN KEY (game_id) REFERENCES games(game_id)`
- `player_props_market_id_fkey`: `FOREIGN KEY (market_id) REFERENCES prop_markets(market_id)`

**Indexes:**
- `player_props_pkey`
- `unq_player_game_market`
- `idx_props_lookup`

---

## Table: `players`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| player_id | integer | NO | nextval('players_player_id_seq'::regclass) |
| player_name | character varying(100) | NO |  |
| url | character varying(120) | NO |  |
| created_at | timestamp with time zone | NO | now() |
| player_abbreviation | character varying(9) | YES |  |

**Constraints:**
- `players_pkey`: `PRIMARY KEY (player_id)`
- `players_player_name_key`: `UNIQUE (player_name)`
- `players_slug_key`: `UNIQUE (url)`

**Indexes:**
- `players_pkey`
- `players_player_name_key`
- `players_slug_key`
- `idx_player_names`

---

## Table: `prop_markets`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| market_id | integer | NO | nextval('prop_markets_market_id_seq'::regclass) |
| market_code | character varying(20) | NO |  |
| market_name | character varying(50) | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `prop_markets_pkey`: `PRIMARY KEY (market_id)`
- `prop_markets_market_code_key`: `UNIQUE (market_code)`

**Indexes:**
- `prop_markets_pkey`
- `prop_markets_market_code_key`

---

## Table: `teams`

| Column | Type | Nullable | Default |
|--------|------|----------|---------|
| team_id | integer | NO | nextval('teams_team_id_seq'::regclass) |
| team_code | character varying(3) | NO |  |
| team_name | character varying(50) | NO |  |
| created_at | timestamp with time zone | NO | now() |

**Constraints:**
- `teams_pkey`: `PRIMARY KEY (team_id)`
- `teams_team_code_key`: `UNIQUE (team_code)`
- `teams_team_name_key`: `UNIQUE (team_name)`

**Indexes:**
- `teams_pkey`
- `teams_team_code_key`
- `teams_team_name_key`
- `idx_team_abbr`

---
